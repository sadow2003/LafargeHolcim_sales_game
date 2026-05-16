from firebase_functions import firestore_fn  # Firebase Functions decorators: firestore_fn for Firestore triggers
# from firebase_functions import scheduler_fn  # DISABLED — re-import when re-enabling the scheduled auto-close
from firebase_functions.options import set_global_options # Allows setting configuration options that apply to all deployed functions

set_global_options(max_instances=10) # Caps concurrent function instances at 10 to control costs and prevent runaway scaling

_app = None # Module-level singleton to hold the initialized Firebase Admin app, avoiding re-initialization on every call

# Lazy-initializes the Firebase Admin app once and reuses it across all function invocations.
# Firebase Cloud Functions may reuse the same runtime container (warm starts), so we cache
# the app in a module-level variable instead of calling initialize_app() every time.
def _get_app():
    global _app
    if _app is None:
        import firebase_admin
        try:
            _app = firebase_admin.get_app() # Reuse an already-initialized app (e.g., default app from environment)
        except ValueError:
            _app = firebase_admin.initialize_app() # No app exists yet — create one using Application Default Credentials
    return _app


# Triggers automatically when a new document is created in the "sales" collection.
# Sends a push notification to all sales-managers about the new claim.
#@firestore_fn.on_document_created(document="sales/{saleId}") # Listens for document creation at any path matching sales/<any-saleId>
def notify_managers_on_new_sale(event):
    from firebase_admin import messaging, firestore as fb_firestore

    _get_app() # Ensure the Firebase Admin SDK is initialized before using any of its services

    # Extract relevant sale details from the newly created document, with safe defaults if fields are missing
    data         = event.data.to_dict() if event.data else {}
    user_name    = data.get("userName",    "A salesperson")
    product_name = data.get("productName", "a product")
    quantity     = data.get("quantity",    0)

    # Query Firestore for all users with the "sales-manager" role and collect their FCM push tokens
    db     = fb_firestore.client()
    tokens = []
    for doc in db.collection("users").where("role", "==", "sales-manager").stream():
        token = (doc.to_dict() or {}).get("fcmToken")
        if token:
            tokens.append(token)

    # No managers have a registered device token — nothing to notify, exit early
    if not tokens:
        return

    # Send a single multicast push notification to all collected manager tokens at once
    messaging.send_each_for_multicast(
        messaging.MulticastMessage(
            notification=messaging.Notification(
                title="New Sale Claim",
                body=f"{user_name} submitted {quantity}x {product_name}",
            ),
            android=messaging.AndroidConfig(priority="high"), # Mark as high-priority so Android delivers it immediately even in Doze mode
            tokens=tokens,
        )
    )


# @scheduler_fn.on_schedule(schedule="every 1 hour") # DISABLED — uncomment to re-enable scheduled auto-close
# Automatically checks whether the active sales event has expired and, if so, closes it:
# ranks participants, saves results, deletes the event document, and resets all salesperson points.
#def auto_close_expired_event(_: scheduler_fn.ScheduledEvent) -> None:
def auto_close_expired_event(_=None) -> None:
    # Import inside the function to keep cold-start overhead low when other functions are invoked
    import logging
    from firebase_admin import firestore as fb_firestore
    from datetime import datetime, timezone, timedelta

    _get_app() # Ensure Firebase Admin is initialized before accessing Firestore
    db = fb_firestore.client() # Get a Firestore client to read/write documents

    # Define Morocco Standard Time (UTC+1) and compute the current local time for date comparisons
    MOROCCO   = timezone(timedelta(hours=1))
    now_local = datetime.now(MOROCCO)

    # Load the active event document from settings/salesEvent; skip if it doesn't exist
    doc_ref = db.collection("settings").document("salesEvent")
    doc     = doc_ref.get()
    if not doc.exists:
        logging.info("auto_close: no active event, skipping.")
        return

    # Parse the event document and validate that an endDate field is present
    data     = doc.to_dict() or {}
    end_date = data.get("endDate")
    if end_date is None:
        logging.warning("auto_close: salesEvent has no endDate, skipping.")
        return

    # Convert endDate to Morocco local time and check if the event is still ongoing
    end_local = end_date.astimezone(MOROCCO)
    if now_local <= end_local:
        logging.info("auto_close: event still active until %s, skipping.", end_local)
        return

    # The event's end time has passed — proceed with closing and ranking
    logging.info("auto_close: event expired at %s — closing.", end_local)

    # Read startDate and rewards config needed for querying sales and assigning prizes
    start_date   = data.get("startDate")
    raw_rewards  = data.get("rewards", {})  # {"1": {"amount": <float>}, "2": ..., "3": ...}


    # 1. Fetch approved sales inside the event window
    try:
        sales = list(
            db.collection("sales")
            .where("status",    "==", "approved")
            .where("createdAt", ">=", start_date)
            .where("createdAt", "<=", end_date)
            .stream()
        )
    except Exception as e:
        logging.error("auto_close: failed to fetch sales — missing index? %s", e)
        return

    # Log how many qualifying approved sales were found within the event window
    logging.info("auto_close: fetched %d approved sales.", len(sales))

    # 2. Sum points per user (participation gate: pts > 0)
    points_by_user: dict[str, int] = {}
    for sale in sales:
        d   = sale.to_dict() or {}
        uid = d.get("userId", "")
        pts = int(d.get("pointsAwarded", 0))
        if uid and pts > 0:
            points_by_user[uid] = points_by_user.get(uid, 0) + pts

    # Log the number of unique users who scored at least one point during the event
    logging.info("auto_close: %d participants found.", len(points_by_user))

    # Sort participants from highest to lowest total points to determine final rankings
    ranked = sorted(points_by_user.items(), key=lambda x: x[1], reverse=True)

    # 3. Fetch names for all participants and split into winners / participants
    winners      = []
    participants = []
    for i, (uid, _) in enumerate(ranked):
        rank = i + 1
        user_name = "Participant"
        try:
            user_doc = db.collection("users").document(uid).get()
            if user_doc.exists:
                ud        = user_doc.to_dict() or {}
                first     = ud.get("firstName", "")
                last      = ud.get("lastName",  "")
                user_name = f"{first} {last}".strip() or ud.get("email", "Participant")
        except Exception:
            pass

        entry = {"rank": rank, "userId": uid, "userName": user_name}

        if rank <= 3:
            reward_info = raw_rewards.get(str(rank), {})
            winners.append({
                **entry,
                "rewardAmount": float(reward_info.get("amount", 0)),
            })
        else:
            participants.append(entry)

    # 4. Save lastEventResult
    result_ref = db.collection("settings").document("lastEventResult")
    result_ref.set({
        "closedAt":     fb_firestore.SERVER_TIMESTAMP,
        "winners":      winners,
        "participants": participants,
    })
    logging.info("auto_close: saved lastEventResult with %d winner(s).", len(winners))

    # 5. Delete event document
    doc_ref.delete()
    logging.info("auto_close: event deleted.")

    # 6. Reset all salesperson points (chunked at 500 for Firestore batch limit)
    salespeople = list(db.collection("users").where("role", "==", "salesperson").stream())
    chunk_size  = 500
    for i in range(0, len(salespeople), chunk_size):
        reset_batch = db.batch()
        for sp in salespeople[i : i + chunk_size]:
            reset_batch.update(sp.reference, {"totalPoints": 0})
        reset_batch.commit()

    logging.info("auto_close: reset totalPoints for %d salesperson(s). Done.", len(salespeople))

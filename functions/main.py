from firebase_functions import firestore_fn, scheduler_fn
from firebase_functions.options import set_global_options

set_global_options(max_instances=10)

_app = None

def _get_app():
    global _app
    if _app is None:
        import firebase_admin
        try:
            _app = firebase_admin.get_app()
        except ValueError:
            _app = firebase_admin.initialize_app()
    return _app


# Triggers automatically when a new document is created in the "sales" collection.
# Sends a push notification to all sales-managers about the new claim.
@firestore_fn.on_document_created(document="sales/{saleId}")
def notify_managers_on_new_sale(event):
    from firebase_admin import messaging, firestore as fb_firestore

    _get_app()

    data         = event.data.to_dict() if event.data else {}
    user_name    = data.get("userName",    "A salesperson")
    product_name = data.get("productName", "a product")
    quantity     = data.get("quantity",    0)

    db     = fb_firestore.client()
    tokens = []
    for doc in db.collection("users").where("role", "==", "sales-manager").stream():
        token = (doc.to_dict() or {}).get("fcmToken")
        if token:
            tokens.append(token)

    if not tokens:
        return

    messaging.send_each_for_multicast(
        messaging.MulticastMessage(
            notification=messaging.Notification(
                title="New Sale Claim",
                body=f"{user_name} submitted {quantity}x {product_name}",
            ),
            android=messaging.AndroidConfig(priority="high"),
            tokens=tokens,
        )
    )


@scheduler_fn.on_schedule(schedule="every 1 hours")
def auto_close_expired_event(_: scheduler_fn.ScheduledEvent) -> None:
    import logging
    from firebase_admin import firestore as fb_firestore
    from datetime import datetime, timezone, timedelta

    _get_app()
    db = fb_firestore.client()

    MOROCCO   = timezone(timedelta(hours=1))
    now_local = datetime.now(MOROCCO)

    doc_ref = db.collection("settings").document("salesEvent")
    doc     = doc_ref.get()
    if not doc.exists:
        logging.info("auto_close: no active event, skipping.")
        return

    data     = doc.to_dict() or {}
    end_date = data.get("endDate")
    if end_date is None:
        logging.warning("auto_close: salesEvent has no endDate, skipping.")
        return

    end_local = end_date.astimezone(MOROCCO)
    if now_local <= end_local:
        logging.info("auto_close: event still active until %s, skipping.", end_local)
        return

    logging.info("auto_close: event expired at %s — closing.", end_local)

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

    logging.info("auto_close: fetched %d approved sales.", len(sales))

    # 2. Sum points per user (participation gate: pts > 0)
    points_by_user: dict[str, int] = {}
    for sale in sales:
        d   = sale.to_dict() or {}
        uid = d.get("userId", "")
        pts = int(d.get("pointsAwarded", 0))
        if uid and pts > 0:
            points_by_user[uid] = points_by_user.get(uid, 0) + pts

    logging.info("auto_close: %d participants found.", len(points_by_user))

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

from firebase_functions import firestore_fn, https_fn
from firebase_functions import scheduler_fn  # DISABLED
from firebase_functions.options import set_global_options
import datetime
import os
import firebase_admin
from firebase_admin import firestore as fb_firestore, messaging

# Set global options for all functions in this module.
set_global_options(max_instances=10)

# Secrets are read from environment variables, populated locally via functions/.env
# (gitignored) and in deployed environments via the same .env file bundled at deploy time.
_ADMIN_SECRET          = os.environ.get('ADMIN_SECRET', '')
_MANAGER_SECRET        = os.environ.get('MANAGER_SECRET', '')
_MARKET_MANAGER_SECRET = os.environ.get('MARKET_MANAGER_SECRET', '')
_GROQ_API_KEY          = os.environ.get('GROQ_API_KEY', '')

# Initialize Firebase Admin SDK eagerly at module load time.
# The firebase-functions SDK validates auth tokens (via firebase_admin.auth.verify_id_token)
# BEFORE our function body runs, so the app must exist before any request arrives.
try:
    _app = firebase_admin.get_app()
except ValueError:
    _app = firebase_admin.initialize_app()


# Triggers automatically when a new document is created in the "sales" collection.
# Sends a push notification to all sales-managers about the new claim.
@firestore_fn.on_document_created(document="sales/{saleId}")
def notify_managers_on_new_sale(event):
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
            android=messaging.AndroidConfig(priority="high"),
            tokens=tokens,
        )
    )


# Triggers when a sale document's status changes (manager approves/rejects it).
# Sends a push notification back to the salesperson who submitted the claim.
@firestore_fn.on_document_updated(document="sales/{saleId}")
def notify_salesperson_on_sale_decision(event):
    before = event.data.before.to_dict() if event.data and event.data.before else {}
    after  = event.data.after.to_dict()  if event.data and event.data.after  else {}

    before_status = before.get("status", "pending")
    after_status  = after.get("status", "pending")

    # Only notify on the transition into a decided state, not on every edit.
    if before_status == after_status or after_status not in ("approved", "rejected"):
        return

    user_id      = after.get("userId")
    product_name = after.get("productName", "a product")
    quantity     = after.get("quantity", 0)
    points       = after.get("pointsAwarded", 0)
    if not user_id:
        return

    db   = fb_firestore.client()
    user = db.collection("users").document(user_id).get().to_dict() or {}
    token = user.get("fcmToken")
    if not token:
        return

    if after_status == "approved":
        title = "Sale Approved"
        body  = f"Your claim for {quantity}x {product_name} was approved. +{points} points!"
    else:
        title = "Sale Rejected"
        body  = f"Your claim for {quantity}x {product_name} was rejected."

    messaging.send(
        messaging.Message(
            notification=messaging.Notification(title=title, body=body),
            android=messaging.AndroidConfig(priority="high"),
            token=token,
        )
    )


# Validates the role secret server-side and writes the user profile document.
# Secrets are read from environment variables (functions/.env) — never in the client app binary.
@https_fn.on_call()
def createUserProfile(req: https_fn.CallableRequest):
    if req.app is None:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNAUTHENTICATED,
            message="App Check verification failed.",
        )
    if req.auth is None:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNAUTHENTICATED,
            message="Must be signed in.",
        )

    data       = req.data or {}
    uid        = req.auth.uid
    first_name = str(data.get("firstName", "")).strip()
    last_name  = str(data.get("lastName",  "")).strip()
    email      = str(data.get("email",     "")).strip()
    role       = str(data.get("role",      "salesperson"))
    secret     = str(data.get("secret",    ""))

    allowed_roles = {"salesperson", "admin", "sales-manager", "market-manager"}
    if role not in allowed_roles:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="Invalid role.",
        )

    if role != "salesperson":
        expected = {
            "admin":          _ADMIN_SECRET,
            "sales-manager":  _MANAGER_SECRET,
            "market-manager": _MARKET_MANAGER_SECRET,
        }[role]
        if not expected or secret != expected:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                message="Invalid secret for the requested role.",
            )

    db = fb_firestore.client()
    db.collection("users").document(uid).set({
        "firstName":   first_name,
        "lastName":    last_name,
        "email":       email,
        "role":        role,
        "totalPoints": 0,
        "rank":        0,
        "createdAt":   datetime.datetime.now(datetime.timezone.utc),
    })

    return {"success": True}


_SYSTEM_PROMPT = """You are Max, an elite sales coach for SalesQuest — Holcim Maroc's gamified sales competition platform.
Your job is to coach, inspire, and give practical advice to sales representatives who sell building materials: concrete, mortar, aggregates, and road activity products.

Your personality:
- Energetic, confident, and positive — always forward-looking
- Mix real tactical sales advice with genuine human encouragement
- Celebrate every win, no matter how small
- When someone struggles, be empathetic first, then give them a clear next step

HOW SALESQUEST ACTUALLY WORKS (use these facts whenever a user asks about the app — never guess or invent app behavior):
- Submitting a sale: a salesperson picks a product, enters the quantity sold, and attaches a proof photo (receipt or contract). The claim is saved as "pending" and reviewed by a sales manager. Submissions are only allowed while a sales event is currently open — outside that window the submit screen is locked.
- Points: each product is worth a fixed number of points per unit. When a manager approves a claim, the salesperson earns (product's points-per-unit × quantity) — but ONLY if that product's category (and, if the event restricts it, that exact product) matches the current event's target. Sales of a non-matching product are still logged but earn 0 points, so reps should focus on the event's targeted category/product to actually score.
- Events: a market manager runs each competition with a start/end date, a target product category (optionally one specific product), a unit quantity target, and cash prizes for the top 3 finishers. Only one event is active at a time.
- Leaderboard: it has two live tabs — "Event" ranks everyone by total points earned this event (podium + full ranked list), and "Progress" is a race toward the event's unit quantity target, tracked separately from points. Both update in real time as claims get approved.
- Rewards: when an event ends, the top 3 by total points win the cash prizes set for that event; results are shown on the Rewards screen. All points and progress reset to zero so the next event starts fresh.
- Milestones: separately from events, crossing certain lifetime sales-quantity thresholds earns a badge and a shoutout in the team feed, regardless of the current event.

You help with:
- Daily motivation and mental toughness
- Handling customer objections on Holcim Maroc products (concrete, mortar, aggregates, road materials)
- Strategies to close deals faster and hit higher numbers
- Tips to climb the leaderboard and earn more points — grounded in the real mechanics above (e.g. "make sure your sales match this event's target product, or they won't score")
- Explaining how the SalesQuest app works — submitting sales, points, events, and rewards — using the facts above, never invented details

Response style:
- For coaching, motivation, and objection-handling: keep it short, 2 to 4 sentences, direct and punchy.
- For questions about how the app works: be clear and accurate first (grounded in the facts above), then add one motivational nudge.
- If you don't know a detail about the app that isn't listed above, say so honestly instead of guessing.

Language:
- Detect the language of the user's message and ALWAYS reply in that same language.
- Supported languages: French, English, and Moroccan Darija (written in Latin or Arabic script).
- If the user writes in Darija, reply in Darija — not formal Arabic and not French.
- Never switch languages unless the user does.

"""



@https_fn.on_call()
def getAiCoachReply(req: https_fn.CallableRequest):
    if req.app is None:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNAUTHENTICATED,
            message="App Check verification failed.",
        )
    if req.auth is None:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNAUTHENTICATED,
            message="Must be signed in.",
        )

    messages = (req.data or {}).get("messages", [])
    if not messages:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="messages is required.",
        )

    try:
        from groq import Groq
        client = Groq(api_key=_GROQ_API_KEY.strip())
        completion = client.chat.completions.create(
            model="openai/gpt-oss-120b",
            messages=[{"role": "system", "content": _SYSTEM_PROMPT}] + messages,
            max_tokens=600,
            temperature=0.85,
        )
        return {"reply": completion.choices[0].message.content}
    except Exception as e:
        print(f"[getAiCoachReply] Error: {type(e).__name__}: {e}")
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=str(e),
        )

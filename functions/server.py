import os
import json
import logging
from contextlib import asynccontextmanager
from datetime import datetime, timezone, timedelta

from fastapi import FastAPI, HTTPException, Header
from pydantic import BaseModel

logging.basicConfig(level=logging.INFO)
log = logging.getLogger(__name__)

# ── Firebase init ─────────────────────────────────────────────────────────────
# On Render.com set the env var FIREBASE_SERVICE_ACCOUNT to the full JSON
# content of your Firebase service-account key file.
# Locally you can set GOOGLE_APPLICATION_CREDENTIALS to the file path instead.

_app = None

def _get_app():
    global _app
    if _app is not None:
        return _app
    import firebase_admin
    from firebase_admin import credentials

    sa_env = os.getenv("FIREBASE_SERVICE_ACCOUNT")
    if sa_env:
        cred = credentials.Certificate(json.loads(sa_env))
        _app = firebase_admin.initialize_app(cred)
    else:
        try:
            _app = firebase_admin.get_app()
        except ValueError:
            _app = firebase_admin.initialize_app()
    return _app


# ── App ───────────────────────────────────────────────────────────────────────

@asynccontextmanager
async def lifespan(app: FastAPI):
    _get_app()
    yield

app = FastAPI(title="SalesQuest Backend", lifespan=lifespan)

# Set BACKEND_SECRET in Render env vars — Flutter must send it as header X-Secret
SECRET = os.getenv("BACKEND_SECRET", "")

def _verify(secret: str) -> None:
    if SECRET and secret != SECRET:
        raise HTTPException(status_code=401, detail="Unauthorized")


# ── Models ────────────────────────────────────────────────────────────────────

class SalePayload(BaseModel):
    userName: str    = "A salesperson"
    productName: str = "a product"
    quantity: int    = 0


# ── Routes ────────────────────────────────────────────────────────────────────

@app.get("/health")
def health():
    """Render health-check — also useful to wake the server before a sale."""
    return {"status": "ok"}


@app.post("/notify-managers")
def notify_managers(body: SalePayload, x_secret: str = Header(default="")):
    """
    Called by the Flutter app right after a new sale document is written
    to Firestore. Fetches all sales-manager FCM tokens and sends a multicast
    push notification — identical logic to notify_managers_on_new_sale in main.py.
    """
    _verify(x_secret)

    from firebase_admin import messaging, firestore as fb_firestore

    db     = fb_firestore.client()
    tokens = []
    for doc in db.collection("users").where("role", "==", "sales-manager").stream():
        token = (doc.to_dict() or {}).get("fcmToken")
        if token:
            tokens.append(token)

    if not tokens:
        log.info("notify-managers: no manager FCM tokens found")
        return {"sent": 0}

    messaging.send_each_for_multicast(
        messaging.MulticastMessage(
            notification=messaging.Notification(
                title="New Sale Claim",
                body=f"{body.userName} submitted {body.quantity}x {body.productName}",
            ),
            android=messaging.AndroidConfig(priority="high"),
            tokens=tokens,
        )
    )
    log.info("notify-managers: notified %d manager(s)", len(tokens))
    return {"sent": len(tokens)}


@app.get("/auto-close")
def auto_close(x_secret: str = Header(default="")):
    """
    Called by cron-job.org every hour. Checks whether the active sales event
    has expired and, if so, ranks participants, saves lastEventResult, deletes
    the event document, and resets all salesperson points.
    Identical logic to auto_close_expired_event in main.py.
    """
    _verify(x_secret)

    from firebase_admin import firestore as fb_firestore

    db        = fb_firestore.client()
    MOROCCO   = timezone(timedelta(hours=1))
    now_local = datetime.now(MOROCCO)

    doc_ref = db.collection("settings").document("salesEvent")
    doc     = doc_ref.get()
    if not doc.exists:
        log.info("auto-close: no active event, skipping")
        return {"status": "no_event"}

    data     = doc.to_dict() or {}
    end_date = data.get("endDate")
    if end_date is None:
        log.warning("auto-close: salesEvent has no endDate, skipping")
        return {"status": "no_end_date"}

    end_local = end_date.astimezone(MOROCCO)
    if now_local <= end_local:
        log.info("auto-close: event still active until %s", end_local)
        return {"status": "still_active", "ends_at": str(end_local)}

    log.info("auto-close: event expired at %s — closing", end_local)

    start_date  = data.get("startDate")
    raw_rewards = data.get("rewards", {})

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
        log.error("auto-close: failed to fetch sales — missing Firestore index? %s", e)
        raise HTTPException(status_code=500, detail=str(e))

    log.info("auto-close: fetched %d approved sales", len(sales))

    # 2. Sum points per user
    points_by_user: dict[str, int] = {}
    for sale in sales:
        d   = sale.to_dict() or {}
        uid = d.get("userId", "")
        pts = int(d.get("pointsAwarded", 0))
        if uid and pts > 0:
            points_by_user[uid] = points_by_user.get(uid, 0) + pts

    log.info("auto-close: %d participant(s) found", len(points_by_user))

    # 3. Rank participants and resolve names
    ranked       = sorted(points_by_user.items(), key=lambda x: x[1], reverse=True)
    winners      = []
    participants = []

    for i, (uid, _) in enumerate(ranked):
        rank      = i + 1
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
            winners.append({**entry, "rewardAmount": float(reward_info.get("amount", 0))})
        else:
            participants.append(entry)

    # 4. Save lastEventResult
    db.collection("settings").document("lastEventResult").set({
        "closedAt":     fb_firestore.SERVER_TIMESTAMP,
        "winners":      winners,
        "participants": participants,
    })
    log.info("auto-close: saved lastEventResult with %d winner(s)", len(winners))

    # 5. Delete event document
    doc_ref.delete()
    log.info("auto-close: event deleted")

    # 6. Reset all salesperson points (chunked at 500 — Firestore batch limit)
    salespeople = list(db.collection("users").where("role", "==", "salesperson").stream())
    for i in range(0, len(salespeople), 500):
        batch = db.batch()
        for sp in salespeople[i : i + 500]:
            batch.update(sp.reference, {"totalPoints": 0})
        batch.commit()

    log.info("auto-close: reset totalPoints for %d salesperson(s) — done", len(salespeople))
    return {
        "status":       "closed",
        "winners":      len(winners),
        "participants": len(participants),
    }

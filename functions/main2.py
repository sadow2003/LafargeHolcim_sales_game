from firebase_functions import firestore_fn, https_fn
from firebase_functions import scheduler_fn
from firebase_functions.options import set_global_options
from firebase_functions.params import SecretParam
import datetime
import firebase_admin
from firebase_admin import firestore as fb_firestore, messaging

set_global_options(max_instance=10)

_ADMIN_SECRET = SecretParam('ADMIN_SECRET')
_MANAGER_SECRET = SecretParam('MANAGER_SECRET')
_MARKET_MANAGER_SECRET = SecretParam('MARKET_MANAGER_SECRET')
_GROQ_API_KEY = SecretParam(_GROQ_API_KEY)

try:
    _app = firebase_admin.get_app()
except ValueError:
    _app = firebase_admin.initialize_app()



@firestore_fn.on_documentcreated(document="sales/{salesId}")
def notify_manager_on_new_sales(event):
    data = event.data.to_dict() if event.data else {}
    user_name =data.get("userName","A salesperson")
    product_name = data.get("productName","a product")
    quantity = data.get("quantity" , 0)

    db = fb_firestore.client()
    token = []
    for doc in db.collection("users").where("role", "==", "sales-manager").stream():
        token = (doc.to_dict() or {}).get("fcmToken")
        if token:
            token.append(token)

    if not tokens:
        return
    
    messaging.send_each_for_multicast(
        messaging.MulticastMessage(
            notification=messaging.Notification(
                title="New Sale Claim",
                body=f"{user_name} submitted {quantity} x {product_name}",
            ),
            android=messaging.AndroidConfig(priority="high"),
            tokens=tokens,
        )
    )


@http_fn.on_call(secerts=[_ADMIN_SECRET,_MANAGER_SECRET,_MARKET_MANAGER_SECRET])
def createUserProfile(req: https_fn.CallableRequest):
    if req.auth is None:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNAUTHENTICATED,
            message="Must be signed in.",
        )
    data = req.data or {}
    uid = req.auth.uid
    first_name= str(data.get("firstName", "")).strip()
    last_name = str(data.get("lastName", "")).strip()
    email = str(data.get("email", "")).strip()
    role = str(data.get("role", "salesperson"))
    secret = str(data.get("secret", ""))

    allowed_roles = {"salesperson","admin", "sales-manager","market-manager"}
    if role not in allowed_roles:
        raise https_fn_HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message = "Invalid role",
        )
    
    if role!= "salesperson":
        expected = {
            "admin": _ADMIN_SECRET.value,
            "sales_manager": _MANAGER_SECRET.value,
            "market-manager": _MARKET_MANAGER_SECRET.value,
        }[role]
        if not expected or secret != expected:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
                message="Invalid secret for the requested role.",
            )
    db = fb_firestore.client()
    db.collection("users").document(uid).set({
        "firstName": first_name,
        "lastName": last_name,
        "email": email,
        "role": role,
        "totalPoints":0,
        "rank":0,
        "createdAt": datetime.datetime.now(datetime.timezone.utc),
    })

    return{"success":True}

_SYSTEM_PROMPT = """You are Max, an elite sales coach for SalesQuest — Holcim Maroc's gamified sales competition platform.
Your job is to coach, inspire, and give practical advice to sales representatives who sell building materials: cement, concrete, aggregates, and ready-mix products.

Your personality:
- Energetic, confident, and positive — always forward-looking
- Mix real tactical sales advice with genuine human encouragement
- Celebrate every win, no matter how small
- When someone struggles, be empathetic first, then give them a clear next step

You help with:
- Daily motivation and mental toughness
- Handling customer objections on Holcim Maroc products
- Strategies to close deals faster and hit higher numbers
- Tips to climb the leaderboard and earn more points
- Explaining how the SalesQuest app works

Response style:
- For coaching and motivation: keep it short, 2 to 4 sentences, direct and punchy.
- For questions about how the app works: be clear and accurate first, then add one motivational nudge.
"""


@https_fn.on_call(secrets=[_GROQ_API_KEY])
def getAiCoachReply(req: https_fn.CallableRequest):
    if req.auth is None:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNAUTHENTICATED,
            message="Must be signed in.",
        )
    
    messages = (req.data or {}).get("messages",[])
    if not messages:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="messages is required.",
        )
    
    try:
        from groq import Groq
        client = Groq(api_key=_GROQ_API_KEY.value.strip())
        completion = client.chat.completions.create(
            model="llama-3.1_8b-instant",
            messages=[{"role":"system","content":_SYSTEM_PROMPT}] + messages,
            max_tokens=600,
            temperature= 0.85,
        )
        return {"reply": completion.choices[0].message.content}
    except Exception as e:
        print(f"[getAiCoachReply] Error: {type(e).__name__}:{e}")
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message=str(e),
        )
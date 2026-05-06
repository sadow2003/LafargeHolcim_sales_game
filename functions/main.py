from firebase_functions import firestore_fn
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


@firestore_fn.on_document_created(document="sales/{saleId}")
def notify_managers_on_new_sale(event):
    from firebase_admin import messaging, firestore as fb_firestore

    _get_app()

    data = event.data.to_dict() if event.data else {}
    user_name    = data.get("userName",    "A salesperson")
    product_name = data.get("productName", "a product")
    quantity     = data.get("quantity",    0)

    db = fb_firestore.client()

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
                body=f"{user_name} submitted {quantity}x {product_name} ",
            ),
            android=messaging.AndroidConfig(priority="high"),
            tokens=tokens,
        )
    )

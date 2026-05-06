from firebase_functions import firestore_fn
from firebase_functions.options import set_global_options
from firebase_admin import initialize_app, messaging, firestore

set_global_options(max_instances=10)
initialize_app()


@firestore_fn.on_document_created(document="sales/{saleId}")
def notify_managers_on_new_sale(event):
    data = event.data.to_dict() if event.data else {}
    user_name = data.get("userName", "A salesperson")
    product_name = data.get("productName", "a product")
    quantity = data.get("quantity", 0)

    db = firestore.client()

    tokens = []
    for doc in db.collection("users").where("role", "==", "manager").stream():
        token = (doc.to_dict() or {}).get("fcmToken")
        if token:
            tokens.append(token)

    if not tokens:
        return

    messaging.send_each_for_multicast(
        messaging.MulticastMessage(
            notification=messaging.Notification(
                title="New Sale Claim",
                body=f"{user_name} submitted {quantity}x {product_name} — tap to review.",
            ),
            android=messaging.AndroidConfig(priority="high"),
            tokens=tokens,
        )
    )

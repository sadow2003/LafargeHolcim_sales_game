
# Import Firestore trigger decorators from Firebase Functions SDK
from firebase_functions import firestore_fn
# Import the function to set global config options for all Cloud Functions
from firebase_functions.options import set_global_options

# Limit the number of simultaneous running instances of any function to 10
set_global_options(max_instances=10)

# Global variable to hold the Firebase Admin app instance (starts as None)
_app = None

def _get_app():
    global _app  # Use the module-level _app variable
    if _app is None:  # Only initialize if not already done
        import firebase_admin  # Import Firebase Admin SDK
        try:
            _app = firebase_admin.get_app()  # Try to get an already-initialized app
        except ValueError:
            _app = firebase_admin.initialize_app()  # No app exists yet, so create one
    return _app  # Return the app instance


# This function triggers automatically when a new document is created in the "sales" collection
@firestore_fn.on_document_created(document="sales/{saleId}")
def notify_managers_on_new_sale(event):
    # Import Firebase messaging (for push notifications) and Firestore client
    from firebase_admin import messaging, firestore as fb_firestore

    _get_app()  # Ensure the Firebase Admin app is initialized

    # Extract the newly created sale document's data as a Python dict
    data = event.data.to_dict() if event.data else {}
    # Get the salesperson's name, defaulting to "A salesperson" if not present
    user_name    = data.get("userName",    "A salesperson")
    # Get the product name, defaulting to "a product" if not present
    product_name = data.get("productName", "a product")
    # Get the quantity sold, defaulting to 0 if not present
    quantity     = data.get("quantity",    0)

    # Get a Firestore database client
    db = fb_firestore.client()

    # List to collect FCM push notification tokens of all sales managers
    tokens = []
    # Query all users with the role "sales-manager" from the "users" collection
    for doc in db.collection("users").where("role", "==", "sales-manager").stream():
        # Get the FCM token from each manager's document
        token = (doc.to_dict() or {}).get("fcmToken")
        if token:  # Only add if the token exists
            tokens.append(token)

    # If no manager tokens were found, stop here (nothing to notify)
    if not tokens:
        return

    # Send a push notification to all sales managers at once (multicast)
    messaging.send_each_for_multicast(
        messaging.MulticastMessage(
            notification=messaging.Notification(
                title="New Sale Claim",  # Notification title shown on device
                body=f"{user_name} submitted {quantity}x {product_name} ",  # Notification body text
            ),
            android=messaging.AndroidConfig(priority="high"),  # Deliver immediately on Android
            tokens=tokens,  # List of manager device tokens to send to
        )
    )

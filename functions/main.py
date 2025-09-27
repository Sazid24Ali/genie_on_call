import firebase_admin
from firebase_admin import messaging, firestore
from firebase_functions.firestore_fn import on_document_updated, Event, Change

firebase_admin.initialize_app()

@on_document_updated(document="bookings/{bookingId}")
def notify_user_on_provider_assignment(event: Event[Change]) -> None:
    old_value = event.data.before.to_dict()
    new_value = event.data.after.to_dict()

    # Check if provider was just assigned (use provider_id)
    provider_just_assigned = (
        not old_value.get("provider_id") and new_value.get("provider_id")
    )

    if provider_just_assigned:
        user_id = new_value.get("userId")  # matches your Firestore field
        db = firestore.client()
        user_ref = db.collection("users").document(user_id)
        user_doc = user_ref.get()
        if user_doc.exists:
            fcm_token = user_doc.to_dict().get("fcm_token")  # or fcmToken, check your user doc
            if fcm_token:
                message = messaging.Message(
                    notification=messaging.Notification(
                        title="Service Assigned",
                        body="A provider has been assigned to your booking."
                    ),
                    token=fcm_token
                )
                print("sent")
                response = messaging.send(message)
                print(f"Notification sent: {response}")
            else:
                print("No FCM token found for user.")
        else:
            print("User document not found.")
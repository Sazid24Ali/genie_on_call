import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";
import { getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { initializeApp } from "firebase-admin/app";

initializeApp();

const db = getFirestore();
const messaging = getMessaging();

// Trigger on booking creation
export const sendBookingScheduledNotification = onDocumentCreated(
  "bookings/{bookingId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const booking = snap.data();
    const userId = booking.userId;

    if (!userId) {
      console.log("No userId in booking");
      return;
    }

    try {
      const userDoc = await db.collection("users").doc(userId).get();
      if (!userDoc.exists) {
        console.log("User not found");
        return;
      }

      const fcmToken = userDoc.data().fcmToken;
      if (!fcmToken) {
        console.log("No FCM token for user");
        return;
      }
      // const bookingDateTime = booking.bookingDate.toDate();
      // const formattedDateTime = bookingDateTime.toLocaleString("en-IN", {
      //   year: "numeric",
      //   month: "short",
      //   day: "numeric",
      //   hour: "numeric",
      //   minute: "2-digit",
      //   hour12: true,
      // });
      // on ${formattedDateTime}
      const message = {
        notification: {
          title: "New Booking Created",
          body: `Your booking for ${booking.serviceName} has been created Successfully.`,
        },
        token: fcmToken,
      };

      await messaging.send(message);
      console.log("Notification sent successfully");
    } catch (error) {
      console.error("Error sending notification:", error);
    }
  }
);

// Trigger on booking update
export const sendBookingUpdatedNotification = onDocumentUpdated(
  "bookings/{bookingId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const before = snap.before.data();
    const after = snap.after.data();
    const userId = after.userId;

    if (!userId) {
      console.log("No userId in booking");
      return;
    }

    // Check if relevant field changed, e.g., status
    if (before.status !== after.status) {
      try {
        const userDoc = await db.collection("users").doc(userId).get();
        if (!userDoc.exists) {
          console.log("User not found");
          return;
        }

        const fcmToken = userDoc.data().fcmToken;
        if (!fcmToken) {
          console.log("No FCM token for user");
          return;
        }

        const message = {
          notification: {
            title: "Booking Updated",
            body: `Your booking status for ${after.serviceName} has been changed to ${after.status}.`,
          },
          token: fcmToken,
        };

        await messaging.send(message);
        console.log("Notification sent successfully");
      } catch (error) {
        console.error("Error sending notification:", error);
      }
    }
  }
);

import {
  onDocumentCreated,
  onDocumentUpdated,
} from "firebase-functions/v2/firestore";
import { getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { getAuth } from "firebase-admin/auth";
import { initializeApp } from "firebase-admin/app";
import { onCall } from "firebase-functions/v2/https";

initializeApp();

const db = getFirestore();
const messaging = getMessaging();

// Function to calculate distance using Haversine formula
function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371; // Radius of the Earth in km
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon1 - lon2) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

// Trigger on booking creation
export const sendBookingScheduledNotifications = onDocumentCreated(
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
      console.log("User notification sent successfully");

      // Now notify matching agents
      const serviceName = booking.serviceName;
      const userLat = booking.userLat;
      const userLng = booking.userLng;

      if (!serviceName || userLat == null || userLng == null) {
        console.log("Missing service or location data for agent notifications");
        return;
      }

      const agentsSnapshot = await db
        .collection("agents")
        .where("services", "array-contains", serviceName)
        .get();

      const notifications = [];
      agentsSnapshot.forEach((agentDoc) => {
        const agentData = agentDoc.data();
        const agentLat = agentData.location?.lat;
        const agentLng = agentData.location?.lng;
        const agentFcmToken = agentData.fcmToken;

        if (agentLat != null && agentLng != null && agentFcmToken) {
          const distance = calculateDistance(
            userLat,
            userLng,
            agentLat,
            agentLng
          );
          if (distance <= 20) {
            // Within 20km
            notifications.push({
              notification: {
                title: "New Job Available",
                body: `A new job for ${serviceName} is available in your area.`,
              },
              token: agentFcmToken,
            });
          }
        }
      });

      // Notify CX executives
      const cxSnapshot = await db.collection("cx_executives").get();
      cxSnapshot.forEach((cxDoc) => {
        const cxData = cxDoc.data();
        const cxFcmToken = cxData.fcmToken;
        if (cxFcmToken) {
          notifications.push({
            notification: {
              title: "New Booking",
              body: `New booking for ${booking.serviceName} from ${booking.userName}.`,
            },
            token: cxFcmToken,
          });
        }
      });

      // Send notifications to agents and CX
      for (const msg of notifications) {
        try {
          await messaging.send(msg);
          console.log("Notification sent successfully");
        } catch (error) {
          console.error("Error sending notification:", error);
        }
      }
    } catch (error) {
      console.error("Error sending notification:", error);
    }
  }
);

// CX Login function
export const cxLogin = onCall(async (request) => {
  const { cxId, password } = request.data;

  if (!cxId || !password) {
    throw new Error("cxId and password are required");
  }

  try {
    const cxDoc = await db.collection("cx_logins").doc(cxId).get();
    if (!cxDoc.exists) {
      throw new Error("Invalid CX ID");
    }

    const cxData = cxDoc.data();
    if (cxData.password !== password) {
      throw new Error("Invalid password");
    }

    // Create custom token for CX
    const customToken = await getAuth().createCustomToken(cxId);

    // Ensure cx_executives document exists
    await db.collection("cx_executives").doc(cxId).set(
      {
        cxId: cxId,
        role: "cx",
      },
      { merge: true }
    );

    return { customToken };
  } catch (error) {
    throw new Error("Login failed: " + error.message);
  }
});

// Trigger on booking update
export const sendBookingUpdatedNotifications = onDocumentUpdated(
  "bookings/{bookingId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const before = snap.before.data();
    const after = snap.after.data();
    const userId = after.userId;
    const agentId = after.agentId;

    // Notify user if status changed
    if (before.status !== after.status && userId) {
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
        console.log("User notification sent successfully");
      } catch (error) {
        console.error("Error sending user notification:", error);
      }
    }

    // Notify agent if agentId is present and status changed to Accepted or Finished
    if (
      agentId &&
      before.status !== after.status &&
      (after.status === "Accepted" || after.status === "Finished")
    ) {
      try {
        const agentDoc = await db.collection("users").doc(agentId).get();
        if (!agentDoc.exists) {
          console.log("Agent not found");
          return;
        }

        const fcmToken = agentDoc.data().fcmToken;
        if (!fcmToken) {
          console.log("No FCM token for agent");
          return;
        }

        const title =
          after.status === "Accepted" ? "New Job Accepted" : "Job Completed";
        const body =
          after.status === "Accepted"
            ? `You have accepted a new job for ${after.serviceName}.`
            : `You have completed the job for ${after.serviceName}.`;

        const message = {
          notification: {
            title: title,
            body: body,
          },
          token: fcmToken,
        };

        await messaging.send(message);
        console.log("Agent notification sent successfully");
      } catch (error) {
        console.error("Error sending agent notification:", error);
      }
    }

    // Notify agent if agentId was added (assignment)
    if (!before.agentId && after.agentId) {
      try {
        const agentDoc = await db.collection("users").doc(after.agentId).get();
        if (!agentDoc.exists) {
          console.log("Agent not found");
          return;
        }

        const fcmToken = agentDoc.data().fcmToken;
        if (!fcmToken) {
          console.log("No FCM token for agent");
          return;
        }

        const message = {
          notification: {
            title: "New Job Assigned",
            body: `A new job for ${after.serviceName} has been assigned to you.`,
          },
          token: fcmToken,
        };

        await messaging.send(message);
        console.log("Agent assignment notification sent successfully");
      } catch (error) {
        console.error("Error sending agent assignment notification:", error);
      }
    }
  }
);

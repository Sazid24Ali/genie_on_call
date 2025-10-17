import {
  onDocumentCreated,
  onDocumentUpdated,
} from "firebase-functions/v2/firestore";
import { getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { initializeApp } from "firebase-admin/app";

initializeApp();

const db = getFirestore();
const messaging = getMessaging();

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
    } catch (error) {
      console.error("Error sending user notification:", error);
    }
  }
);
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

// Function to send chat notification to user when CX sends a message
export const sendChatNotificationToUser = onDocumentCreated(
  "chats/{chatId}/messages/{msgId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const msg = snap.data();
    const chatId = event.params.chatId;
    if (!chatId) return;

    try {
      const senderId = msg?.senderId;
      if (!senderId) return;

      // Only send notification if sender is CX
      const chatDoc = await db.collection("chats").doc(chatId).get();
      const chatData = chatDoc.exists ? chatDoc.data() : {};
      const isCx = senderId === chatData.cxId;
      if (!isCx) return;

      const recipientId = chatData.userId;
      const senderName = "Customer Support";

      if (recipientId) {
        // Get recipient's FCM token
        const recipientDoc = await db
          .collection("users")
          .doc(recipientId)
          .get();
        if (recipientDoc.exists) {
          const fcmToken = recipientDoc.data().fcmToken;
          if (fcmToken) {
            const messageText = msg.text || "New message";
            const truncatedText =
              messageText.length > 50
                ? messageText.substring(0, 50) + "..."
                : messageText;

            const notificationMessage = {
              notification: {
                title: `New message from ${senderName}`,
                body: truncatedText,
              },
              data: {
                chatId: chatId,
                senderId: senderId,
                type: "chat_message",
              },
              token: fcmToken,
            };

            await messaging.send(notificationMessage);
            console.log("Chat notification sent to user successfully");
          } else {
            console.log("No FCM token for user");
          }
        }
      }
    } catch (error) {
      console.error("Error sending chat notification to user:", error);
    }
  }
);

// Trigger when a chat message is created to update unread counters on parent chat
export const onChatMessageCreated = onDocumentCreated(
  "chats/{chatId}/messages/{msgId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const msg = snap.data();
    const chatId = event.params.chatId;
    if (!chatId) return;

    try {
      const chatRef = db.collection("chats").doc(chatId);
      await db.runTransaction(async (tx) => {
        const chatDoc = await tx.get(chatRef);
        const chatData = chatDoc.exists ? chatDoc.data() : {};
        const senderId = msg?.senderId;

        // Determine existing unread counts
        const prevCxUnread = (chatData?.cxUnreadCount ?? 0) || 0;
        const prevUserUnread = (chatData?.userUnreadCount ?? 0) || 0;

        if (!senderId) return;

        // Check if sender is CX by comparing senderId with chat.cxId
        const isCx = senderId === chatData.cxId;

        if (isCx) {
          // Message from CX: clear CX unread, increment user unread
          tx.update(chatRef, {
            cxUnreadCount: 0,
            userUnreadCount: prevUserUnread + 1,
            message: msg.text || "",
            lastMessageAt: new Date(),
          });
        } else {
          // Message from user: increment CX unread, clear user unread
          tx.update(chatRef, {
            cxUnreadCount: prevCxUnread + 1,
            userUnreadCount: 0,
            message: msg.text || "",
            lastMessageAt: new Date(),
          });
        }
      });
    } catch (error) {
      console.error("Error updating unread counts for chat message:", error);
    }
  }
);

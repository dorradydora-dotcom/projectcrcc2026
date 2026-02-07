const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Sends a video call notification to a specific user via FCM.
 * Expected data:
 * - receiverToken: FCM token of the user receiving the call
 * - receiverEmail: Email of the receiver (for logging)
 * - callerEmail: Email of the user initiating the call
 * - channelName: Agora channel name to join
 */
exports.sendVideoCallNotification = functions.https.onCall(async (data, context) => {
  const receiverToken = data.receiverToken;
  const callerEmail = data.callerEmail;
  const channelName = data.channelName;

  if (!receiverToken || !callerEmail || !channelName) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "The function must be called with receiverToken, callerEmail, and channelName."
    );
  }

  const payload = {
    token: receiverToken,
    data: {
      type: "video_call",
      caller_email: callerEmail,
      channel_name: channelName,
      click_action: "FLUTTER_NOTIFICATION_CLICK",
      status: "done",
    },
    notification: {
      title: "مكالمة فيديو واردة",
      body: `يتصل بك ${callerEmail}`,
    },
    android: {
      priority: "high",
      notification: {
        channelId: "video_calls",
        priority: "max",
        visibility: "public",
      },
    }
  };

  try {
    await admin.messaging().send(payload);
    console.log(`Successfully sent video call notification to ${data.receiverEmail}`);
    return { success: true, message: "Notification sent successfully" };
  } catch (error) {
    console.error("Error sending notification:", error);
    return { success: false, message: error.message };
  }
});

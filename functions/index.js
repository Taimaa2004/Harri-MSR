const { onDocumentCreated, onDocumentDeleted } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

// Trigger when a meeting is added
exports.meetingAdded = onDocumentCreated("/meetings/{meetingId}", (event) => {
  const meeting = event.data.data();
  console.log("Meeting added:", meeting.title);

  if (!meeting.users || meeting.users.length === 0) return null;

  const payload = {
    notification: {
      title: "New Meeting Added",
      body: `Meeting: ${meeting.title}`
    }
  };

  // Send notification to each user in the array (assuming their FCM tokens are stored in Firestore under `users` collection)
  const promises = meeting.users.map(async (userId) => {
    const userDoc = await admin.firestore().collection("users").doc(userId).get();
    const token = userDoc.data()?.fcmToken; // each user should have `fcmToken` stored
    if (token) {
      return admin.messaging().sendToDevice(token, payload);
    }
    return null;
  });

  return Promise.all(promises);
});

// Trigger when a meeting is deleted
exports.meetingDeleted = onDocumentDeleted("/meetings/{meetingId}", (event) => {
  const meeting = event.data.data();
  console.log("Meeting deleted:", meeting.title);

  if (!meeting.users || meeting.users.length === 0) return null;

  const payload = {
    notification: {
      title: "Meeting Cancelled",
      body: `Meeting: ${meeting.title}`
    }
  };

  const promises = meeting.users.map(async (userId) => {
    const userDoc = await admin.firestore().collection("users").doc(userId).get();
    const token = userDoc.data()?.fcmToken;
    if (token) {
      return admin.messaging().sendToDevice(token, payload);
    }
    return null;
  });

  return Promise.all(promises);
});

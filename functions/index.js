// functions/index.js
const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.onBookingStatusChange = functions.firestore
  .document("bookings/{bookingId}")
  .onUpdate(async (change, context) => {
    const newValue = change.after.data();
    const previousValue = change.before.data();

    // Check if the status has changed
    if (newValue.status === previousValue.status) {
      return null;
    }

    const customerId = newValue.customerId;
    const serviceName = newValue.serviceName;
    const newStatus = newValue.status;

    // Get the customer's user document to find their FCM token
    const userDoc = await admin
      .firestore()
      .collection("users")
      .doc(customerId)
      .get();

    if (!userDoc.exists) {
      console.log("User document not found for customerId:", customerId);
      return null;
    }

    const fcmToken = userDoc.data().fcmToken;
    if (!fcmToken) {
      console.log("FCM token not found for customerId:", customerId);
      return null;
    }

    // Construct the notification message
    const message = {
      notification: {
        title: "Booking Status Updated",
        body: `Your booking for "${serviceName}" has been ${newStatus}.`,
      },
      token: fcmToken,
      data: {
        // You can add extra data here to handle navigation on tap
        bookingId: context.params.bookingId,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
    };

    try {
      // Send the message
      const response = await admin.messaging().send(message);
      console.log("Successfully sent message:", response);
    } catch (error) {
      console.log("Error sending message:", error);
    }

    return null;
  });

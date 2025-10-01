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
        type: 'booking_update',
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

exports.onBookingCreated = functions.firestore
  .document("bookings/{bookingId}")
  .onCreate(async (snapshot, context) => {
    const bookingData = snapshot.data();

    const vendorId = bookingData.vendorId;
    const serviceName = bookingData.serviceName;
    const customerEmail = bookingData.customerEmail;

    if (!vendorId) {
      console.log("Booking created without a vendorId, cannot send notification.");
      return null;
    }

    // Get the vendor's user document to find their FCM token
    const userDoc = await admin
      .firestore()
      .collection("users")
      .doc(vendorId)
      .get();

    if (!userDoc.exists) {
      console.log("User document not found for vendorId:", vendorId);
      return null;
    }

    const fcmToken = userDoc.data().fcmToken;
    if (!fcmToken) {
      console.log("FCM token not found for vendorId:", vendorId);
      return null;
    }

    // Construct the notification message
    const message = {
      notification: {
        title: "New Booking Request",
        body: `You have a new booking for "${serviceName}" from ${customerEmail}.`,
      },
      token: fcmToken,
      data: {
        bookingId: context.params.bookingId,
        type: 'new_booking',
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
    };

    try {
      await admin.messaging().send(message);
      console.log("Successfully sent new booking notification to vendor.");
    } catch (error) {
      console.log("Error sending new booking notification:", error);
    }

    return null;
  });

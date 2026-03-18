const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.onBookingCreated = functions.firestore
  .document("bookings/{bookingId}")
  .onCreate(async (snap, context) => {
    const booking = snap.data();

    const driverId = booking.driverId;
    const rideId = booking.rideId;

    // System message
    await admin.firestore()
      .collection("messages")
      .doc(rideId)
      .collection("chat")
      .add({
        text: "A passenger joined your ride 🚗",
        type: "system",
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

    // Push notification
    const driverDoc = await admin
      .firestore()
      .collection("users")
      .doc(driverId)
      .get();

    const token = driverDoc.data()?.fcmToken;
    if (!token) return;

    await admin.messaging().send({
      token,
      notification: {
        title: "New passenger joined",
        body: "Someone booked seats on your ride",
      },
    });
  });

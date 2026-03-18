import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ridelink_lst/screens/chat/chat_screen.dart';

class RideDetailsScreen extends StatefulWidget {
  final String rideId;
  final String from;
  final String to;
  final String time;
  final int seats;
  final String price;

  const RideDetailsScreen({
    super.key,
    required this.rideId,
    required this.from,
    required this.to,
    required this.time,
    required this.seats,
    required this.price,
  });

  @override
  State<RideDetailsScreen> createState() => _RideDetailsScreenState();
}

class _RideDetailsScreenState extends State<RideDetailsScreen> {

  int seatsToBook = 1;

  @override
  Widget build(BuildContext context) {

    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF4),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF4FAF4),
        title: const Text(
          "Ride Details",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),

      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('rides')
            .doc(widget.rideId)
            .snapshots(),

        builder: (context, rideSnap) {

          if (!rideSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!rideSnap.data!.exists) {
            return const Center(child: Text("Ride no longer available"));
          }

          final ride = rideSnap.data!.data()!;
          final bool isOwner = ride['createdBy'] == currentUser?.uid;
          final int seatsLeft = ride['seats'] ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// ROUTE
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "• ${widget.from}",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(widget.to),
                      const SizedBox(height: 6),
                      Text(
                        widget.time,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                /// INFO
                _card(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Seats left: $seatsLeft"),
                      Text(
                        widget.price,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                /// DRIVER RATING
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(ride['createdBy'])
                      .get(),
                  builder: (context, snap) {

                    if (!snap.hasData) return const SizedBox();

                    final driver =
                        snap.data!.data() as Map<String, dynamic>;

                    final rating =
                        (driver['rating'] ?? 0).toDouble();

                    return _card(
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text(
                            rating == 0
                                ? "New Driver"
                                : "Driver Rating: ${rating.toStringAsFixed(1)}",
                            style: const TextStyle(
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                /// PASSENGER SIDE
                if (!isOwner)
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('bookings')
                        .where('rideId', isEqualTo: widget.rideId)
                        .where('userId', isEqualTo: currentUser!.uid)
                        .snapshots(),

                    builder: (context, bookingSnap) {

                      if (!bookingSnap.hasData) {
                        return const SizedBox();
                      }

                      final hasBooking =
                          bookingSnap.data!.docs.isNotEmpty;

                      if (!hasBooking && seatsLeft > 0) {

                        return Column(
                          children: [
                            _seatSelector(seatsLeft),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _bookSeats,
                                child: const Text("Book Seats"),
                              ),
                            ),
                          ],
                        );
                      }

                      if (hasBooking) {

                        final bookingDoc =
                            bookingSnap.data!.docs.first;

                        return Column(
                          children: [

                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.check_circle,
                                      color: Colors.green),
                                  SizedBox(width: 8),
                                  Text(
                                    "You joined this ride",
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            _seatSelector(
                              seatsLeft + (bookingDoc['seatsBooked'] as int),
                            ),

                            const SizedBox(height: 12),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () =>
                                    _updateBooking(bookingDoc),
                                child: const Text("Update Seats"),
                              ),
                            ),

                            const SizedBox(height: 8),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: () =>
                                    _cancelBooking(bookingDoc),
                                child: const Text("Cancel Booking"),
                              ),
                            ),

                            const SizedBox(height: 16),

                            /// CALL + CHAT
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [

                                if (ride['driverPhone'] != null)
                                  IconButton(
                                    icon: const Icon(Icons.call,
                                        color: Colors.green),
                                    onPressed: () {
                                      launchUrl(Uri.parse(
                                          "tel:${ride['driverPhone']}"));
                                    },
                                  ),

                                IconButton(
                                  icon: const Icon(Icons.chat,
                                      color: Colors.blue),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChatScreen(
                                          rideId: widget.rideId,
                                          driverId: ride['createdBy'],
                                          passengerId: currentUser.uid,
                                          passengerName:
                                              currentUser.email ??
                                                  "Passenger",
                                          driverPhone:
                                              ride['driverPhone'],
                                          passengerPhone:
                                              currentUser.phoneNumber,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            /// RATE DRIVER
                            ElevatedButton(
                              onPressed: () {
                                showRatingDialog(
                                    ride['createdBy']);
                              },
                              child: const Text("Rate Driver ⭐"),
                            ),
                          ],
                        );
                      }

                      return const SizedBox();
                    },
                  ),

                const SizedBox(height: 20),

                /// DRIVER PASSENGER LIST
                if (isOwner)
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('bookings')
                        .where('rideId', isEqualTo: widget.rideId)
                        .snapshots(),

                    builder: (context, snap) {

                      if (!snap.hasData ||
                          snap.data!.docs.isEmpty) {
                        return _card(
                          child: const Text(
                            "No passengers yet",
                            style:
                                TextStyle(color: Colors.black54),
                          ),
                        );
                      }

                      return _card(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [

                            const Text(
                              "Passengers",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),

                            const SizedBox(height: 10),

                            ...snap.data!.docs.map((doc) {

                              final data =
                                  doc.data() as Map<String, dynamic>;

                              return ListTile(
  leading: const Icon(Icons.person, color: Colors.green),

  title: Text(data['userName'] ?? "Passenger"),

  subtitle: Text(
      "Seats booked: ${data['seatsBooked']}"),

  trailing: Row(
    mainAxisSize: MainAxisSize.min,
    children: [

      /// CALL PASSENGER
      if (data['userPhone'] != null)
        IconButton(
          icon: const Icon(
            Icons.call,
            color: Colors.green,
          ),
          onPressed: () {
            launchUrl(
              Uri.parse("tel:${data['userPhone']}"),
            );
          },
        ),

      /// CHAT PASSENGER
      IconButton(
        icon: const Icon(
          Icons.chat,
          color: Colors.blue,
        ),
        onPressed: () {

  Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ChatScreen(
      rideId: widget.rideId,
      driverId: ride['createdBy'].toString(),
      passengerId: data['userId'].toString(),
      passengerName: (data['userName'] ?? "Passenger").toString(),
      driverPhone: (ride['driverPhone'] ?? "").toString(),
      passengerPhone: (data['userPhone'] ?? "").toString(),
    ),
  ),
);

},
      ),
    ],
  ),
);
                            }),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// SEAT SELECTOR
  Widget _seatSelector(int maxSeats) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: seatsToBook > 1
              ? () => setState(() => seatsToBook--)
              : null,
          icon: const Icon(Icons.remove),
        ),
        Text(seatsToBook.toString(),
            style: const TextStyle(fontSize: 18)),
        IconButton(
          onPressed: seatsToBook < maxSeats
              ? () => setState(() => seatsToBook++)
              : null,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }

  /// BOOK SEATS
 Future<void> _bookSeats() async {
  final user = FirebaseAuth.instance.currentUser!;
  final firestore = FirebaseFirestore.instance;

  final rideRef =
      firestore.collection('rides').doc(widget.rideId);

  final userDoc =
      await firestore.collection('users').doc(user.uid).get();

  final userData = userDoc.data();

  final userBookingRef = firestore
      .collection('users')
      .doc(user.uid)
      .collection('bookings')
      .doc(widget.rideId);

  WriteBatch batch = firestore.batch();

  // ✅ SAFE seat update
  batch.update(rideRef, {
    'seats': FieldValue.increment(-seatsToBook),
  });

  // Global booking
  final globalBookingRef =
      firestore.collection('bookings').doc();

  batch.set(globalBookingRef, {
    'rideId': widget.rideId,
    'userId': user.uid,
    'userName': userData?['name'] ?? "Passenger",
    'userEmail': user.email,
    'userPhone': user.phoneNumber,
    'seatsBooked': seatsToBook,
    'createdAt': Timestamp.now(),
  });

  // 🔥 USER booking (FIXED)
  batch.set(userBookingRef, {
    'rideId': widget.rideId,
    'userId': user.uid, // 🔥 CRITICAL FIX
    'from': widget.from,
    'to': widget.to,
    'date': widget.time,
    'seatsBooked': seatsToBook,
    'createdAt': Timestamp.now(),
  });

  await batch.commit();

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Seat booked successfully")),
  );
}

  /// UPDATE BOOKING
  Future<void> _updateBooking(QueryDocumentSnapshot bookingDoc) async {
  final firestore = FirebaseFirestore.instance;

  final rideRef = firestore
      .collection('rides')
      .doc(widget.rideId);

  final user = FirebaseAuth.instance.currentUser!;

  final userBookingRef = firestore
      .collection('users')
      .doc(user.uid)
      .collection('bookings')
      .doc(widget.rideId);

  final rideSnap = await rideRef.get();
  final int available = rideSnap['seats'];

  final int oldSeats = bookingDoc['seatsBooked'];
  final int difference = seatsToBook - oldSeats;

  if (difference > available) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Not enough seats")),
    );
    return;
  }

  WriteBatch batch = firestore.batch();

  // 1. Update seats
  batch.update(rideRef, {
    'seats': available - difference,
  });

  // 2. Update global booking
  batch.update(bookingDoc.reference, {
    'seatsBooked': seatsToBook,
  });

  // 🔥 3. Update USER booking (IMPORTANT)
  batch.update(userBookingRef, {
    'seatsBooked': seatsToBook,
  });

  await batch.commit();

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Seats updated")),
  );
}

  /// CANCEL BOOKING
  Future<void> _cancelBooking(QueryDocumentSnapshot bookingDoc) async {
  final firestore = FirebaseFirestore.instance;

  final rideRef = firestore
      .collection('rides')
      .doc(widget.rideId);

  final user = FirebaseAuth.instance.currentUser!;

  final userBookingRef = firestore
      .collection('users')
      .doc(user.uid)
      .collection('bookings')
      .doc(widget.rideId);

  final int seatsBooked = bookingDoc['seatsBooked'];

  WriteBatch batch = firestore.batch();

  // 1. Restore seats
  batch.update(rideRef, {
    'seats': FieldValue.increment(seatsBooked),
  });

  // 2. Delete global booking
  batch.delete(bookingDoc.reference);

  // 🔥 3. Delete USER booking (IMPORTANT)
  batch.delete(userBookingRef);

  await batch.commit();

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Booking cancelled")),
  );
}

  /// RATING DIALOG
  void showRatingDialog(String driverId) {

    double rating = 5;

    showDialog(
      context: context,
      builder: (context) {

        return AlertDialog(
          title: const Text("Rate Driver"),

          content: Slider(
            value: rating,
            min: 1,
            max: 5,
            divisions: 4,
            label: rating.toString(),

            onChanged: (value) {
              rating = value;
            },
          ),

          actions: [

            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),

            ElevatedButton(
              child: const Text("Submit"),
              onPressed: () async {

                await submitRating(driverId, rating);

                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  /// SUBMIT RATING
  Future<void> submitRating(String driverId, double newRating) async {

    final driverRef = FirebaseFirestore.instance
        .collection('users')
        .doc(driverId);

    final driverSnap = await driverRef.get();
    final data = driverSnap.data()!;

    double currentRating =
        (data['rating'] ?? 0).toDouble();

    int totalRatings =
        data['totalRatings'] ?? 0;

    double updatedRating =
        ((currentRating * totalRatings) + newRating) /
            (totalRatings + 1);

    await driverRef.update({
      'rating': updatedRating,
      'totalRatings': totalRatings + 1,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Rating submitted")),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}
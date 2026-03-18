import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ridelink_lst/screens/rides/ride_details_screen.dart';

class MyRidesScreen extends StatelessWidget {
  const MyRidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text("Please login"));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4FAF4),
        elevation: 0,
        title: const Text(
          "My Trips",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Booked Rides",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 8),
          _BookedRides(user.uid),

          const SizedBox(height: 24),

          const Text(
            "Offered Rides",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 8),
          _OfferedRides(user.uid),
        ],
      ),
    );
  }
}

class _BookedRides extends StatelessWidget {
  final String userId;
  const _BookedRides(this.userId);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text("No booked rides");
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final booking = doc.data() as Map<String, dynamic>;
            return _RideFromId(booking['rideId']);
          }).toList(),
        );
      },
    );
  }
}

class _OfferedRides extends StatelessWidget {
  final String userId;
  const _OfferedRides(this.userId);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rides')
          .where('createdBy', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text("No offered rides");
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final ride = doc.data() as Map<String, dynamic>;
            return _RideCard(
              rideId: doc.id,
              from: ride['from'],
              to: ride['to'],
              time: "${ride['date']} · ${ride['time']}",
              seats: ride['seats'],
              price: "₹${ride['price']}",
            );
          }).toList(),
        );
      },
    );
  }
}

class _RideFromId extends StatelessWidget {
  final String rideId;
  const _RideFromId(this.rideId);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rides')
          .doc(rideId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox();
        }

        final ride = snapshot.data!.data() as Map<String, dynamic>;

        return _RideCard(
          rideId: snapshot.data!.id,
          from: ride['from'],
          to: ride['to'],
          time: "${ride['date']} · ${ride['time']}",
          seats: ride['seats'],
          price: "₹${ride['price']}",
        );
      },
    );
  }
}

class _RideCard extends StatelessWidget {
  final String rideId;
  final String from;
  final String to;
  final String time;
  final int seats;
  final String price;

  const _RideCard({
    required this.rideId,
    required this.from,
    required this.to,
    required this.time,
    required this.seats,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RideDetailsScreen(
              rideId: rideId,
              from: from,
              to: to,
              time: time,
              seats: seats,
              price: price,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("• $from",
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(to),
                const SizedBox(height: 4),
                Text(
                  "$time · $seats seats left",
                  style:
                      const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
            Text(
              price,
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

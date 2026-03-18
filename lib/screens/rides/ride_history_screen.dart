import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RideHistoryScreen extends StatelessWidget {
  const RideHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please login")),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("My Rides"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Offered"),
              Tab(text: "Booked"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _offeredRides(user.uid),
            _bookedRides(user.uid),
          ],
        ),
      ),
    );
  }

  /// ---------- Offered Rides ----------
  Widget _offeredRides(String userId) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('rides')
          .where('driverId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No rides offered yet"));
        }

        return ListView(
          children: snapshot.data!.docs.map((doc) {
            final ride = doc.data();

            return ListTile(
              leading: const Icon(Icons.directions_car),
              title: Text("${ride['from']} → ${ride['to']}"),
              subtitle: Text("${ride['date']} · ${ride['time']}"),
              trailing: Text("₹${ride['price']}"),
            );
          }).toList(),
        );
      },
    );
  }

  /// ---------- Booked Rides ----------
  Widget _bookedRides(String userId) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .orderBy('bookedAt', descending: true)
          .snapshots(),
      builder: (context, bookingSnapshot) {
        if (!bookingSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (bookingSnapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No rides booked yet"));
        }

        return ListView(
          children: bookingSnapshot.data!.docs.map((bookingDoc) {
            final booking = bookingDoc.data();

            return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection('rides')
                  .doc(booking['rideId'])
                  .get(),
              builder: (context, rideSnapshot) {
                if (!rideSnapshot.hasData) {
                  return const SizedBox();
                }

                final ride = rideSnapshot.data!.data();
                if (ride == null) return const SizedBox();

                return ListTile(
                  leading: const Icon(Icons.event_seat),
                  title: Text("${ride['from']} → ${ride['to']}"),
                  subtitle: Text("${ride['date']} · ${ride['time']}"),
                  trailing: Text("₹${ride['price']}"),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }
}

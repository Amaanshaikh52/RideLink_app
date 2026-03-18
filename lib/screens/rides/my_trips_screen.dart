import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../rides/ride_details_screen.dart';

class MyTripsScreen extends StatelessWidget {
  const MyTripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4FAF4),
        appBar: AppBar(
          title: const Text("My Trips"),
          backgroundColor: const Color(0xFFF4FAF4),
          elevation: 0,
          bottom: const TabBar(
            labelColor: Colors.green,
            unselectedLabelColor: Colors.black54,
            tabs: [
              Tab(text: "Booked"),
              Tab(text: "Offered"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _BookedTrips(userId: user.uid),
            _OfferedTrips(userId: user.uid),
          ],
        ),
      ),
    );
  }
}

/// =======================================================
/// BOOKED TRIPS (FIXED ✅)
/// =======================================================
class _BookedTrips extends StatelessWidget {
  final String userId;

  const _BookedTrips({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('bookings') // ✅ FIXED HERE
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const Center(child: Text("No trips booked yet"));
        }

        final bookings = snap.data!.docs;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: bookings.map((booking) {
            final data = booking.data() as Map<String, dynamic>;

            /// 🔥 REAL-TIME RIDE DATA
            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rides')
                  .doc(data['rideId'])
                  .snapshots(),
              builder: (context, rideSnap) {
                if (!rideSnap.hasData || !rideSnap.data!.exists) {
                  return const SizedBox();
                }

                final ride =
                    rideSnap.data!.data() as Map<String, dynamic>;

                return _tripCard(
                  title: "${ride['from']} → ${ride['to']}",
                  subtitle:
                      "${ride['date']} · ${ride['time']} · Seats: ${data['seatsBooked']}",
                  trailing: const Text(
                    "Booked",
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RideDetailsScreen(
                          rideId: rideSnap.data!.id,
                          from: ride['from'],
                          to: ride['to'],
                          time:
                              "${ride['date']} · ${ride['time']}",
                          seats: ride['seats'],
                          price: "₹${ride['price']}",
                        ),
                      ),
                    );
                  },
                );
              },
            );
          }).toList(),
        );
      },
    );
  }
}

/// =======================================================
/// OFFERED TRIPS (UNCHANGED ✅)
/// =======================================================
class _OfferedTrips extends StatelessWidget {
  final String userId;

  const _OfferedTrips({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rides')
          .where('createdBy', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snap.data!.docs.isEmpty) {
          return const Center(child: Text("No rides offered yet"));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: snap.data!.docs.map((doc) {
            final ride = doc.data() as Map<String, dynamic>;

            return _tripCard(
              title: "${ride['from']} → ${ride['to']}",
              subtitle:
                  "${ride['date']} · ${ride['time']} · Seats left: ${ride['seats']}",
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RideDetailsScreen(
                      rideId: doc.id,
                      from: ride['from'],
                      to: ride['to'],
                      time:
                          "${ride['date']} · ${ride['time']}",
                      seats: ride['seats'],
                      price: "₹${ride['price']}",
                    ),
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }
}

/// =======================================================
/// REUSABLE CARD (UNCHANGED ✅)
/// =======================================================
Widget _tripCard({
  required String title,
  required String subtitle,
  required Widget trailing,
  required VoidCallback onTap,
}) {
  return InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    ),
  );
}
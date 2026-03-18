import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'admin_users_screen.dart';
import 'admin_rides_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  Future<int> _getCount(String collection) async {
    final snap = await FirebaseFirestore.instance
        .collection(collection)
        .get();
    return snap.docs.length;
  }

  Future<int> _getActiveRides() async {
    final snap = await FirebaseFirestore.instance
        .collection('rides')
        .where('seats', isGreaterThan: 0)
        .get();
    return snap.docs.length;
  }

  Widget _statCard(
      String title, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 36, color: color),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                value.toString(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(title),
            ],
          ),
        ],
      ),
    );
  }

  Widget _navCard(
      BuildContext context,
      String title,
      IconData icon,
      Widget screen) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => screen,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 8,
            )
          ],
        ),
        child: Row(
          children: [
            Icon(icon,
                color: Colors.green, size: 32),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF4),
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          )
        ],
      ),
      body: FutureBuilder(
        future: Future.wait([
          _getCount('users'),
          _getCount('rides'),
          _getCount('bookings'),
          _getActiveRides(),
        ]),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final users = snapshot.data![0];
          final rides = snapshot.data![1];
          final bookings = snapshot.data![2];
          final activeRides = snapshot.data![3];

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [

                /// STATS
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    _statCard("Users", users,
                        Icons.people, Colors.blue),
                    _statCard("Rides", rides,
                        Icons.directions_car, Colors.green),
                    _statCard("Bookings", bookings,
                        Icons.event_seat, Colors.orange),
                    _statCard("Active Rides", activeRides,
                        Icons.route, Colors.purple),
                  ],
                ),

                const SizedBox(height: 20),

                /// NAVIGATION
                _navCard(
                  context,
                  "Manage Users",
                  Icons.people,
                  const AdminUsersScreen(),
                ),

                const SizedBox(height: 12),

                _navCard(
                  context,
                  "Manage Rides",
                  Icons.directions_car,
                  const AdminRidesScreen(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
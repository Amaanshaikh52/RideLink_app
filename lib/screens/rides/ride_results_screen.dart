import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ride_details_screen.dart';

class RideResultsScreen extends StatelessWidget {
  const RideResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF4FAF4);

    return Scaffold(
        backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: bg,
        title: const Text(
          "Available Rides",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      

      body: StreamBuilder<QuerySnapshot>(

        stream: FirebaseFirestore.instance
            .collection('rides')
            .where(
              'rideDate',
              isGreaterThanOrEqualTo: Timestamp.now(),
            )
            .orderBy('rideDate')
            .snapshots(),

        builder: (context, snapshot) {

          if (snapshot.connectionState ==
              ConnectionState.waiting) {

            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {

            return const Center(
              child: Text("No rides available"),
            );
          }

          final rides = snapshot.data!.docs;

          return ListView.builder(

            itemCount: rides.length,

            itemBuilder: (context, index) {

              final ride =
                  rides[index].data()
                      as Map<String, dynamic>;

              final rideId =
                  rides[index].id;

              return Card(

                margin:
                    const EdgeInsets.all(12),

                child: ListTile(

                  title: Text(
                      "${ride['from']} → ${ride['to']}"),

                  subtitle: Text(
                      "${ride['date']} • ${ride['time']}"),

                  trailing: Text(
                      "₹${ride['price']}"),

                  onTap: () {

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            RideDetailsScreen(
                          rideId: rideId,
                          from: ride['from'],
                          to: ride['to'],
                          time:
                              "${ride['date']} ${ride['time']}",
                          seats: ride['seats'],
                          price:
                              "₹${ride['price']}",
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
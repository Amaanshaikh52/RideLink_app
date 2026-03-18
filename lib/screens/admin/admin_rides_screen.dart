import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminRidesScreen extends StatelessWidget {
  const AdminRidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rides')
          .snapshots(),
      builder: (context, snapshot) {

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text("Error: ${snapshot.error}"),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text("No rides available"),
          );
        }

        final rides = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: rides.length,
          itemBuilder: (context, index) {

            final doc = rides[index];
            final data = doc.data() as Map<String, dynamic>;

            final from = data['from'] ?? "Unknown";
            final to = data['to'] ?? "Unknown";
            final seats = data['seats'] ?? 0;
            final price = data['price'] ?? "";
            final driver = data['createdBy'] ?? "";

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.withOpacity(.15),
                  child: const Icon(
                    Icons.directions_car,
                    color: Colors.blue,
                  ),
                ),
                title: Text("$from → $to"),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Seats left: $seats"),
                    Text("Price: $price"),
                    Text(
                      "Driver: $driver",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),

                /// DELETE RIDE
                trailing: IconButton(
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.red,
                  ),
                  onPressed: () async {

                    final confirm =
                        await showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Delete Ride"),
                        content: const Text(
                            "Are you sure you want to delete this ride?"),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(context, false),
                            child: const Text("Cancel"),
                          ),
                          ElevatedButton(
                            onPressed: () =>
                                Navigator.pop(context, true),
                            child: const Text("Delete"),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await doc.reference.delete();
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
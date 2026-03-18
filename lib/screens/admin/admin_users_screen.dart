import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy('createdAt', descending: true)
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
            child: Text("No users found"),
          );
        }

        final users = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: users.length,
          itemBuilder: (context, index) {

            final doc = users[index];
            final data = doc.data() as Map<String, dynamic>;

            final name = data['name'] ?? "No name";
            final email = data['email'] ?? "";
            final isBlocked = data['isBlocked'] ?? false;
            final role = data['role'] ?? "user";

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.withOpacity(.15),
                  child: const Icon(Icons.person, color: Colors.green),
                ),
                title: Text(name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(email),
                    Text(
                      role == "admin" ? "Admin" : "User",
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (isBlocked)
                      const Text(
                        "BLOCKED",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),

                /// ACTION BUTTONS
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    /// BLOCK / UNBLOCK
                    IconButton(
                      icon: Icon(
                        isBlocked
                            ? Icons.lock_open
                            : Icons.lock,
                        color: Colors.red,
                      ),
                      onPressed: () async {
                        await doc.reference.update({
                          'isBlocked': !isBlocked
                        });
                      },
                    ),

                    /// DELETE USER
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.grey,
                      ),
                      onPressed: () async {

                        final confirm =
                            await showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Delete User"),
                            content: const Text(
                                "Are you sure you want to delete this user?"),
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
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
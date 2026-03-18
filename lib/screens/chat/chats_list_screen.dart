import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../chat/chat_screen.dart';

class ChatsListScreen extends StatelessWidget {
  const ChatsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF4FAF4);

    final currentUser = FirebaseAuth.instance.currentUser;

    /// Safety check
    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text("User not logged in"),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,

      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: const Text(
          "Chats",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        /// FIXED QUERY (removed orderBy to prevent infinite loading)
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: currentUser.uid)
            .snapshots(),

        builder: (context, snapshot) {

          /// SHOW LOADING
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          /// SHOW ERROR
          if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}"),
            );
          }

          /// NO CHATS
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No chats yet",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final chats = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chats.length,

            itemBuilder: (context, index) {

              final chat =
                  chats[index].data() as Map<String, dynamic>;

              final driverId = chat['driverId'];
              final passengerId = chat['passengerId'];

              final otherUserId =
                  currentUser.uid == driverId
                      ? passengerId
                      : driverId;

              final lastMessage =
                  chat['lastMessage'] ?? "No message";

              /// GET USER INFO
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(otherUserId)
                    .get(),

                builder: (context, userSnapshot) {

                  String name = "User";
                  String phone = "";

                  if (userSnapshot.hasData &&
                      userSnapshot.data!.exists) {

                    final userData =
                        userSnapshot.data!.data()
                            as Map<String, dynamic>;

                    name = userData['name'] ?? "User";
                    phone = userData['phone'] ?? "";
                  }

                  return ListTile(

                    leading: CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Text(
                        name.isNotEmpty
                            ? name[0].toUpperCase()
                            : "U",
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),

                    title: Text(name),

                    subtitle: Text(
                      lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    onTap: () {

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            rideId: chat['rideId'],
                            driverId: driverId,
                            passengerId: passengerId,
                            passengerName: name,
                            driverPhone: phone,
                            passengerPhone: phone,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
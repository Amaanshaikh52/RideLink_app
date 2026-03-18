import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatScreen extends StatefulWidget {
  final String rideId;
  final String driverId;
  final String passengerId;
  final String passengerName;
  final String? driverPhone;
  final String? passengerPhone;

  const ChatScreen({
    super.key,
    required this.rideId,
    required this.driverId,
    required this.passengerId,
    required this.passengerName,
    this.driverPhone,
    this.passengerPhone,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  /// Create consistent chatId
  String get chatId {
    final ids = [widget.driverId, widget.passengerId];
    ids.sort();
    return ids.join("_");
  }

  /// ================= SEND MESSAGE =================
  Future<void> sendMessage() async {

    final text = messageController.text.trim();

    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser!;

    final chatRef =
        FirebaseFirestore.instance.collection('chats').doc(chatId);

    /// Create chat document if not exists
    await chatRef.set({
      'rideId': widget.rideId,
      'driverId': widget.driverId,
      'passengerId': widget.passengerId,
      'participants': [
        widget.driverId,
        widget.passengerId,
      ],
      'lastMessage': text,
      'lastMessageTime': Timestamp.now(),
    }, SetOptions(merge: true));

    /// Add message
    await chatRef.collection('messages').add({
      'text': text,
      'senderId': user.uid,
      'createdAt': Timestamp.now(),
    });

    messageController.clear();

    /// Auto scroll
    Future.delayed(const Duration(milliseconds: 200), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// ================= CALL USER =================
  Future<void> callUser(bool isDriver) async {

    String? phone;

    if (isDriver) {
      phone = widget.passengerPhone;
    } else {
      phone = widget.driverPhone;
    }

    if (phone == null || phone.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Phone number not available"),
        ),
      );

      return;
    }

    final Uri uri = Uri.parse("tel:$phone");

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {

    final currentUser = FirebaseAuth.instance.currentUser!;
    final isDriver = currentUser.uid == widget.driverId;

    return Scaffold(

      backgroundColor: const Color(0xFFF4FAF4),

      /// APPBAR
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          widget.passengerName,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.call, color: Colors.green),
            onPressed: () => callUser(isDriver),
          ),
        ],
      ),

      /// BODY
      body: Column(
        children: [

          /// ================= MESSAGES =================
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final messages = snapshot.data!.docs;

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      "No messages yet",
                      style: TextStyle(color: Colors.black54),
                    ),
                  );
                }

                return ListView.builder(

                  controller: scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,

                  itemBuilder: (context, index) {

                    final data =
                        messages[index].data() as Map<String, dynamic>;

                    final isMe =
                        data['senderId'] == currentUser.uid;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,

                      child: Container(

                        margin: const EdgeInsets.symmetric(vertical: 4),

                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),

                        decoration: BoxDecoration(
                          color: isMe
                              ? Colors.green
                              : Colors.white,
                          borderRadius:
                              BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(.05),
                              blurRadius: 4,
                            )
                          ],
                        ),

                        child: Text(
                          data['text'] ?? '',
                          style: TextStyle(
                            color: isMe
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          /// ================= INPUT =================
          Container(

            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),

            color: Colors.white,

            child: Row(
              children: [

                Expanded(
                  child: TextField(
                    controller: messageController,

                    decoration: InputDecoration(
                      hintText: "Type message...",
                      filled: true,
                      fillColor: const Color(0xFFF4FAF4),

                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                CircleAvatar(
                  backgroundColor: Colors.green,

                  child: IconButton(
                    icon: const Icon(
                      Icons.send,
                      color: Colors.white,
                    ),
                    onPressed: sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
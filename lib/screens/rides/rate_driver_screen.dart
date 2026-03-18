import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RateDriverScreen extends StatefulWidget {
  final String rideId;
  final String driverId;

  const RateDriverScreen({
    super.key,
    required this.rideId,
    required this.driverId,
  });

  @override
  State<RateDriverScreen> createState() => _RateDriverScreenState();
}

class _RateDriverScreenState extends State<RateDriverScreen> {

  int rating = 5;
  final reviewController = TextEditingController();

  Future<void> submitRating() async {

    final user = FirebaseAuth.instance.currentUser!;

    /// Save rating
    await FirebaseFirestore.instance.collection('ratings').add({
      'rideId': widget.rideId,
      'driverId': widget.driverId,
      'passengerId': user.uid,
      'rating': rating,
      'review': reviewController.text,
      'createdAt': Timestamp.now(),
    });

    /// Update driver average rating
    final driverRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.driverId);

    final driverSnap = await driverRef.get();

    final data = driverSnap.data()!;

    final oldRating = data['rating'] ?? 0;
    final totalRatings = data['totalRatings'] ?? 0;

    final newTotal = totalRatings + 1;

    final newRating =
        ((oldRating * totalRatings) + rating) / newTotal;

    await driverRef.update({
      'rating': newRating,
      'totalRatings': newTotal,
    });

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Widget buildStar(int index) {
    return IconButton(
      icon: Icon(
        index <= rating ? Icons.star : Icons.star_border,
        color: Colors.orange,
        size: 32,
      ),
      onPressed: () {
        setState(() {
          rating = index;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Rate Driver"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            const Text(
              "How was your ride?",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildStar(1),
                buildStar(2),
                buildStar(3),
                buildStar(4),
                buildStar(5),
              ],
            ),

            const SizedBox(height: 20),

            TextField(
              controller: reviewController,
              decoration: const InputDecoration(
                labelText: "Write review (optional)",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: submitRating,
                child: const Text("Submit Rating"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
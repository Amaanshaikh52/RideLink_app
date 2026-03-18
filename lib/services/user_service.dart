import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {

  static Future<void> createUserIfNotExists({
    required String name,
    required String phone,
  }) async {

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    final doc = await docRef.get();

    /// If already exists, do nothing
    if (doc.exists) return;

    await docRef.set({
      'uid': user.uid,
      'name': name,
      'phone': phone,
      'email': user.email ?? "",
      'createdAt': Timestamp.now(),
    });
  }

  /// Get current user data
  static Future<Map<String, dynamic>?> getCurrentUser() async {

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    return doc.data();
  }
}
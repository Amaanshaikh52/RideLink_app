import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../home_page.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState
    extends State<CompleteProfileScreen> {

  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  bool isLoading = false;

  Future<void> _saveProfile() async {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("All fields are required"),
        ),
      );
      return;
    }

    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enter valid phone number"),
        ),
      );
      return;
    }

    try {
      setState(() => isLoading = true);

      final user =
          FirebaseAuth.instance.currentUser!;

      await FirebaseFirestore.instance
    .collection('users')
    .doc(user.uid)
    .set({
  'name': nameController.text.trim(),
  'phone': phoneController.text.trim(),
  'email': user.email,
  'profileCompleted': true,
  'createdAt': Timestamp.now(),
}, SetOptions(merge: true));

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const HomePage(),
          ),
          (route) => false,
        );
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
        ),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF4FAF4),
      body: Padding(
        padding:
            const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [

              const SizedBox(height: 80),

              const Text(
                "Complete Your Profile",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 40),

              /// FULL NAME
              TextField(
                controller: nameController,
                decoration:
                    const InputDecoration(
                  labelText: "Full Name",
                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              /// PHONE NUMBER
              TextField(
                controller: phoneController,
                keyboardType:
                    TextInputType.phone,
                decoration:
                    const InputDecoration(
                  labelText: "Phone Number",
                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      isLoading
                          ? null
                          : _saveProfile,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child:
                              CircularProgressIndicator(
                            color:
                                Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Save & Continue"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
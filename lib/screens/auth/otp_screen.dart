import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';
import 'home_screen.dart';

class OTPScreen extends StatefulWidget {

  final String verificationId;
  final String phoneNumber;
  final String name; // Passenger or Driver name

  const OTPScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
    required this.name,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {

  final TextEditingController otpController =
      TextEditingController();

  bool isLoading = false;

  Future<void> verifyOTP() async {

    setState(() {
      isLoading = true;
    });

    try {

      /// Create credential
      PhoneAuthCredential credential =
          PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: otpController.text.trim(),
      );

      /// Sign in user
      UserCredential userCredential =
          await FirebaseAuth.instance
              .signInWithCredential(credential);

      /// AUTO CREATE USER DOCUMENT IN FIRESTORE
      await UserService.createUserIfNotExists(
        name: widget.name,
        phone: widget.phoneNumber,
      );

      /// Go to HomeScreen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
        (route) => false,
      );

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("OTP Failed: $e"),
        ),
      );

    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Verify OTP"),
        backgroundColor: Colors.green,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: "Enter OTP",
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(

              onPressed: isLoading
                  ? null
                  : verifyOTP,

              child: isLoading
                  ? const CircularProgressIndicator(
                      color: Colors.white,
                    )
                  : const Text("Verify"),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main_navigation.dart';
import '../admin/admin_dashboard.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {

        // Loading state
        if (authSnapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Not logged in
        if (!authSnapshot.hasData) {
          return const LoginScreen();
        }

        final uid = authSnapshot.data!.uid;

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .snapshots(),
          builder: (context, userSnapshot) {

            if (!userSnapshot.hasData) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final data =
                userSnapshot.data!.data()
                    as Map<String, dynamic>?;

            final role = data?['role'] ?? 'user';
final isBlocked = data?['isBlocked'] ?? false;

if (isBlocked == true) {
  return Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const Icon(Icons.block, color: Colors.red, size: 80),

            const SizedBox(height: 20),

            const Text(
              "Your account has been blocked",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Please contact support for help.",
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            /// CONTACT SUPPORT
           /// CONTACT SUPPORT BUTTON
SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    onPressed: () async {

      showModalBottomSheet(
        context: context,
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                const Text(
                  "Contact Support",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                /// EMAIL OPTION
                ListTile(
                  leading: const Icon(Icons.email),
                  title: const Text("Email Support"),
                  onTap: () async {
                    final Uri emailUri = Uri(
                      scheme: 'mailto',
                      path: 'support@ridelink_lst.com',
                      query: 'subject=Account Blocked Issue',
                    );

                    await launchUrl(emailUri);
                  },
                ),

                /// CALL OPTION
                ListTile(
                  leading: const Icon(Icons.call),
                  title: const Text("Call Support"),
                  onTap: () async {
                    final Uri callUri =
                        Uri.parse("tel:+918104385990");

                    await launchUrl(callUri);
                  },
                ),

                const SizedBox(height: 10),
              ],
            ),
          );
        },
      );

    },
    child: const Text("Contact Support"),
  ),
),

            const SizedBox(height: 10),

            /// LOGOUT
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
                child: const Text("Logout"),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

if (role == 'admin') {
  return const AdminDashboard();
}

return const MainNavigation();
          },
        );
      },
    );
  }
}
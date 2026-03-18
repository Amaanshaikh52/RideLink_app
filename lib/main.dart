import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:ridelink_lst/screens/auth/auth_gate.dart';
import 'package:ridelink_lst/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const RideLinkApp());
}

class RideLinkApp extends StatelessWidget {
  const RideLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RideLink',
      home: const SplashScreen(),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signup_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  bool isLoading = false;
  bool hidePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  /// ================= GOOGLE SIGN IN =================
  Future<void> _signInWithGoogle() async {

    try {

      setState(() => isLoading = true);

      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser =
          await _googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final user = userCredential.user!;

      final userDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);

      final doc = await userDoc.get();

      if (!doc.exists) {

        await userDoc.set({
          'name': user.displayName ?? "",
          'email': user.email ?? "",
          'phone': user.phoneNumber ?? "",
          'role': "user",
          'isBlocked': false,
          'profileCompleted': true,
          'rating': 0,
          'totalRatings': 0,
          'createdAt': Timestamp.now(),
        });

      }

      if (!mounted) return;

      _showMessage("Login successful");

    } catch (e) {

      _showMessage("Google Sign-In failed");

    }

    setState(() => isLoading = false);
  }

  /// ================= EMAIL LOGIN =================
  Future<void> _login() async {

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage("All fields are required");
      return;
    }

    try {

      setState(() => isLoading = true);

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _showMessage("Login successful");

    } on FirebaseAuthException catch (e) {

      String message = "Login failed";

      switch (e.code) {

        case 'user-not-found':
          message = "No account found";
          break;

        case 'wrong-password':
          message = "Incorrect password";
          break;

        case 'invalid-email':
          message = "Invalid email";
          break;

        case 'too-many-requests':
          message = "Too many attempts. Try later.";
          break;
      }

      _showMessage(message);
    }

    setState(() => isLoading = false);
  }

  /// ================= FORGOT PASSWORD =================
  void _forgotPasswordDialog() {

    final resetController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {

        return AlertDialog(

          title: const Text("Reset Password"),

          content: TextField(
            controller: resetController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: "Enter your email",
              border: OutlineInputBorder(),
            ),
          ),

          actions: [

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),

            ElevatedButton(
              onPressed: () async {

                final email = resetController.text.trim();

                if (email.isEmpty) {
                  _showMessage("Enter your email");
                  return;
                }

                try {

                  await FirebaseAuth.instance
                      .sendPasswordResetEmail(email: email);

                  Navigator.pop(context);

                  _showMessage("Reset email sent");

                } catch (e) {

                  _showMessage("Failed to send reset email");

                }
              },
              child: const Text("Send"),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String text) {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  /// ================= GOOGLE BUTTON =================
  Widget googleButton() {

    return InkWell(

      onTap: isLoading ? null : _signInWithGoogle,

      borderRadius: BorderRadius.circular(12),

      child: Container(

        height: 55,
        width: double.infinity,

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            )
          ],
        ),

        child: Row(

          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            Image.asset(
              "assets/images/g_logo.png",
              height: 24,
            ),

            const SizedBox(width: 12),

            const Text(
              "Continue with Google",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFFF4FAF4),

      body: Padding(

        padding: const EdgeInsets.all(24),

        child: SingleChildScrollView(

          child: Column(

            children: [

              const SizedBox(height: 100),

              const Text(
                "Welcome To RideLink",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 40),

              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: passwordController,
                obscureText: hidePassword,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      hidePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        hidePassword = !hidePassword;
                      });
                    },
                  ),
                ),
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _forgotPasswordDialog,
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(color: Colors.green),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(

                  onPressed: isLoading ? null : _login,

                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),

                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text("Login"),
                ),
              ),

              const SizedBox(height: 25),

              Row(
                children: const [

                  Expanded(child: Divider()),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text("OR"),
                  ),

                  Expanded(child: Divider()),
                ],
              ),

              const SizedBox(height: 25),

              googleButton(),

              const SizedBox(height: 25),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  const Text("Don't have an account? "),

                  GestureDetector(

                    onTap: () {

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SignupScreen(),
                        ),
                      );

                    },

                    child: const Text(
                      "Sign Up",
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
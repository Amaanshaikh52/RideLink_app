import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ridelink_lst/screens/rides/my_trips_screen.dart';
import 'package:ridelink_lst/screens/profile/edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF4FAF4);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: bg,
        title: const Text(
          "Profile",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
  stream: FirebaseFirestore.instance
      .collection('users')
      .doc(FirebaseAuth.instance.currentUser!.uid)
      .snapshots(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final userData =
        snapshot.data!.data() as Map<String, dynamic>?;

    final name =
        userData?['name'] ?? "RideLink User";
    final email =
        userData?['email'] ?? "No email";
    final photo =
        userData?['photo'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [

          /// ================= USER CARD =================
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _card(),
            child: Row(
              children: [

                /// PROFILE IMAGE
                CircleAvatar(
                  radius: 32,
                  backgroundColor:
                      Colors.green.withOpacity(.15),
                  backgroundImage:
                      photo != null && photo != ''
                          ? NetworkImage(photo)
                          : null,
                  child: photo == null || photo == ''
                      ? const Icon(
                          Icons.person,
                          color: Colors.green,
                          size: 34,
                        )
                      : null,
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [

                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight:
                              FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        email,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 6),

                      _ratingRow(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          /// Keep rest of your profile screen same below

                /// ================= QUICK ACTIONS =================
                Row(
                  children: [
                    Expanded(
                      child: _actionTile(
                        icon: Icons.directions_car,
                        title: "My Trips",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const MyTripsScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _actionTile(
                        icon: Icons.account_balance_wallet,
                        title: "Payments",
                        onTap: () => _comingSoon(context),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                /// ================= SETTINGS =================
               _menuTile(
  icon: Icons.lock_outline,
  title: "Change Password",
  subtitle: "Update your account password",
  onTap: () async {
    final email = FirebaseAuth.instance.currentUser?.email;

    if (email != null) {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: email);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password reset email sent"),
        ),
      );
    }
  },
),

_menuTile(
  icon: Icons.edit_outlined,
  title: "Edit Profile",
  subtitle: "Update your name & phone",
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>  EditProfileScreen(),
      ),
    );
  },
),

_menuTile(
  icon: Icons.delete_outline,
  title: "Delete Account",
  subtitle: "Permanently remove account",
  onTap: () async {
    final user = FirebaseAuth.instance.currentUser!;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .delete();

    await user.delete();
  },
),

                const SizedBox(height: 16),

                /// ================= LOGOUT =================
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize:
                        const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.logout,
                      color: Colors.red),
                  label: const Text(
                    "Logout",
                    style:
                        TextStyle(color: Colors.red),
                  ),
                  onPressed: () async {
                    await FirebaseAuth.instance
                        .signOut();
                  },
                ),

                const SizedBox(height: 28),

                const Column(
                  children: [
                    Text(
                      "RideLink",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.black54,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Version 1.0.0",
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.black45),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// ================= RATING UI =================
Widget _ratingRow() {
  return Row(
    children: const [
      Icon(Icons.star,
          size: 16, color: Colors.orange),
      Icon(Icons.star,
          size: 16, color: Colors.orange),
      Icon(Icons.star,
          size: 16, color: Colors.orange),
      Icon(Icons.star,
          size: 16, color: Colors.orange),
      Icon(Icons.star_half,
          size: 16, color: Colors.orange),
      SizedBox(width: 6),
      Text(
        "4.5",
        style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600),
      ),
    ],
  );
}

/// ================= ACTION TILE =================
Widget _actionTile({
  required IconData icon,
  required String title,
  required VoidCallback onTap,
}) {
  return InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: _card(),
      child: Column(
        children: [
          Icon(icon,
              color: Colors.green, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    ),
  );
}

/// ================= MENU TILE =================
Widget _menuTile({
  required IconData icon,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
}) {
  return Container(
    margin:
        const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: _card(),
    child: InkWell(
      borderRadius:
          BorderRadius.circular(18),
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor:
                Colors.green.withOpacity(.15),
            child: Icon(icon,
                color: Colors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color:
                        Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right,
              color: Colors.black38),
        ],
      ),
    ),
  );
}

BoxDecoration _card() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius:
        BorderRadius.circular(18),
    boxShadow: [
      BoxShadow(
        color:
            Colors.black.withOpacity(.05),
        blurRadius: 8,
        offset: const Offset(0, 3),
      ),
    ],
  );
}

void _comingSoon(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Coming soon"),
      content: const Text(
          "This feature will be available in a future update."),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.pop(context),
          child: const Text("OK"),
        )
      ],
    ),
  );
}
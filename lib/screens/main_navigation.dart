import 'package:flutter/material.dart';
import 'home_page.dart';
import 'package:ridelink_lst/screens/rides/ride_results_screen.dart';
import 'package:ridelink_lst/screens/chat/chats_list_screen.dart';
import 'package:ridelink_lst/screens/profile/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {

  int selectedIndex = 0;

  final List<Widget> screens = const [

    /// HOME
    HomePage(),

    /// RIDES (shows rides from Firestore)
    RideResultsScreen(),

    /// CHATS
    ChatsListScreen(),

    /// PROFILE
    ProfileScreen(),
  ];

  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: screens[selectedIndex],

      bottomNavigationBar: BottomNavigationBar(

        currentIndex: selectedIndex,
        onTap: onItemTapped,

        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,

        type: BottomNavigationBarType.fixed,

        items: const [

          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: "Rides",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: "Chats",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),

        ],
      ),
    );
  }
}
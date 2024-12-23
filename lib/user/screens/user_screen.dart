import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../login_screen.dart';

import 'homeScreen/home_screen.dart';
import 'tripAssistScreen/travel_guide_screen.dart';
import 'userManageScreens/temporarly_removed_screen.dart';
import 'userSearchScreen/user_search_screen.dart';
import 'chatScreen/chat_screen.dart' as chat;
import 'profileScreen/profile_screen.dart' as profile;

class UserScreen extends StatefulWidget {
  final int initialIndex;
  const UserScreen({super.key, this.initialIndex = 2});

  @override
  UserScreenState createState() => UserScreenState();
}

class UserScreenState extends State<UserScreen> {
  late int _selectedIndex;
  final List<Widget> _pages = [
    const TravelAgencyPage(),
    const SearchPage(),
    const HomePage(),
    const chat.ChatHomeScreen(),
    const profile.ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('user')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final isRemoved = userDoc.data()?['isRemoved'] ?? false;

          if (isRemoved) {
            await FirebaseAuth.instance.signOut();

            if (!mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );

            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return const TemporaryRemovedPopup();
              },
            );
          }
        }
      }
    } catch (e) {
      // Handle errors if needed
      print('Error checking user status: $e');
    }
  }

  // Function to switch between tabs
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  static const IconData card = IconData(0xe140, fontFamily: 'MaterialIcons');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex], // Display the selected page
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        iconSize: 20, // Default size for unselected icons
        selectedIconTheme: const IconThemeData(
          size: 32, // Slightly larger size for selected icon
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(card), // Use the 'card_travel' icon
            label: 'Travel Asists',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

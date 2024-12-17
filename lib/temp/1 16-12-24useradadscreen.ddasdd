import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../login_screen.dart';

import 'homeScreen/home_screen.dart';
import 'tripAssistScreen/travel_guide_screen.dart'; // Import PostPage
import 'userSearchScreen/user_search_screen.dart'; // Import SearchPage// Import HomePage
import 'chatScreen/chat_screen.dart' as chat;
import 'profileScreen/profile_screen.dart' as profile;

class UserScreen extends StatefulWidget {
  final int initialIndex; // Add a parameter to accept initial index

  // Constructor to receive the initial index
  UserScreen({this.initialIndex = 2}); // Default to Home tab (index 2)

  @override
  _UserScreenState createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  late int _selectedIndex;

  // List of pages corresponding to each tab
  final List<Widget> _pages = [
    const TravelAgencyPage(),
    const SearchPage(),
    HomePage(),
    const chat.ChatHomeScreen(),
    const profile.ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget
        .initialIndex; // Initialize the selected index with the passed value
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
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => LoginScreen()),
              (route) => false,
            );

            // Show alert message
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Account Suspended'),
                  content: Text(
                      'Your account has been temporarily removed. For assistance, please contact support or visit the help page.'),
                  actions: [
                    TextButton(
                      child: Text('OK'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
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

  static const IconData card_travel =
      IconData(0xe140, fontFamily: 'MaterialIcons');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex], // Display the selected page
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        iconSize: 20, // Default size for unselected icons
        selectedIconTheme: IconThemeData(
          size: 32, // Slightly larger size for selected icon
        ),
        items: [
          BottomNavigationBarItem(
            icon: Icon(card_travel), // Use the 'card_travel' icon
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

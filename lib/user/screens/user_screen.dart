import 'package:flutter/material.dart';
import 'tripAssistScreen/travel_guide_screen.dart'; // Import PostPage
import 'userSearchScreen/user_search_screen.dart'; // Import SearchPage
import 'homeScreen/home_screen.dart'; // Import HomePage
import 'chatScreen/chat_screen.dart' as chat;
import 'profileScreen/profile_screen.dart' as profile;

// When referring to `ChatPage`, use the alias like this:
// for the one in chat_screen.dart // for the one in profile_screen.dart
// Import ProfilePage

class UserScreen extends StatefulWidget {
  @override
  _UserScreenState createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  int _selectedIndex = 2; // Default to the Home tab

  // List of pages corresponding to each tab
  final List<Widget> _pages = [
    TravelAgencyPage(),
    SearchPage(),
    HomePage(),
    chat.ChatPage(),
    profile.ProfilePage(),
  ];

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



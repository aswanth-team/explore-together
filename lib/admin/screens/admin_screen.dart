import 'package:flutter/material.dart';
import 'analysisScreen/analysis_screen.dart';
import 'messageScreen/sent_message_screen.dart';
import 'tripAssistScreen/agency_screen.dart';
import 'usersScreen/all_user_screen.dart';



class ReportsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text("Reports Screen"));
  }
}

// Admin Screen with Bottom Navigation Bar
class AdminScreen extends StatefulWidget {
  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _selectedIndex = 2; // Default to the "Assist Post" tab

  // List of pages corresponding to each tab
  final List<Widget> _pages = [
    TravelAgencyPage(),
    UserSearchPage(),
    AnalysisPage(),
    ReportsPage(),
    SentMessagePage(),
  ];

  // Function to switch between tabs
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

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
            icon: Icon(Icons.post_add),
            label: 'Trip Assist',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analysis',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Message',
          ),
        ],
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: AdminScreen(),
  ));
}

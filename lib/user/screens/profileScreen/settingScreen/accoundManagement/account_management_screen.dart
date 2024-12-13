import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../edit_profile_screen.dart';

class AccountManagementPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Account Management')),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.person),
            title: Text('Edit Profile'),
            trailing: Icon(Icons.arrow_forward),
            onTap: () {
              final userId = FirebaseAuth.instance.currentUser?.uid;
              if (userId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => EditProfileScreen(uuid: userId)),
                );
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.lock),
            title: Text('Change Password'),
            trailing: Icon(Icons.chevron_right), // Added trailing icon
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.delete_forever, color: Colors.red), // Red icon
            title: Text(
              'Delete Account',
              style: TextStyle(color: Colors.red), // Red text
            ),
            onTap: () {
              // Navigate to Delete Account page
            },
          ),
        ],
      ),
    );
  }
}

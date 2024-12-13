import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Help')),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.book),
            title: Text('User Guide'),
            subtitle: Text('Step-by-step instructions for using the app.'),
            trailing: Icon(Icons.chevron_right), // Added trailing icon
            onTap: () {
              // Navigate to User Guide page
            },
          ),
          ListTile(
            leading: Icon(Icons.info),
            title: Text('How It Works'),
            subtitle: Text('Learn how the app connects travelers.'),
            trailing: Icon(Icons.chevron_right), // Added trailing icon
            onTap: () {
              // Navigate to How It Works page
            },
          ),
          ListTile(
            leading: Icon(Icons.privacy_tip),
            title: Text('Privacy Policy'),
            subtitle: Text('Understand how your data is handled.'),
            trailing: Icon(Icons.chevron_right), // Added trailing icon
            onTap: () {
              // Navigate to Privacy Policy page
            },
          ),
          ListTile(
            leading: Icon(Icons.rule),
            title: Text('Terms of Service'),
            subtitle: Text('Legal terms for using the app.'),
            trailing: Icon(Icons.chevron_right), // Added trailing icon
            onTap: () {
              // Navigate to Terms of Service page
            },
          ),
        ],
      ),
    );
  }
}

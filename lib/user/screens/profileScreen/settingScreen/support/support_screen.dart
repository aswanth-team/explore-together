import 'package:flutter/material.dart';

class SupportPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Support')),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.email),
            title: Text('Contact Us'),
            subtitle: Text('Email support or chat with us directly.'),
            trailing: Icon(Icons.chevron_right), // Added trailing icon
            onTap: () {
              // Navigate to Contact Us page
            },
          ),
          ListTile(
            leading: Icon(Icons.bug_report),
            title: Text('Report a Problem'),
            subtitle: Text('Submit issues like bugs or glitches.'),
            trailing: Icon(Icons.chevron_right), // Added trailing icon
            onTap: () {
              // Navigate to Report a Problem page
            },
          ),
          ListTile(
            leading: Icon(Icons.question_answer),
            title: Text('FAQs'),
            subtitle: Text('Find answers to common questions.'),
            trailing: Icon(Icons.chevron_right), // Added trailing icon
            onTap: () {
              // Navigate to FAQs page
            },
          ),
          ListTile(
            leading: Icon(Icons.feedback),
            title: Text('Feedback'),
            subtitle: Text('Share suggestions or feature requests.'),
            trailing: Icon(Icons.chevron_right), // Added trailing icon
            onTap: () {
              // Navigate to Feedback page
            },
          ),
        ],
      ),
    );
  }
}

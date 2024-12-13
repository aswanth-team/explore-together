import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SentMessagePage extends StatefulWidget {
  final String? userNameFromPreviousPage;
  final bool disableSendToAll;

  // Constructor to accept userName and disable flag
  SentMessagePage(
      {this.userNameFromPreviousPage, this.disableSendToAll = false});

  @override
  _SentMessagePageState createState() => _SentMessagePageState();
}

class _SentMessagePageState extends State<SentMessagePage> {
  TextEditingController _messageController = TextEditingController();
  String selectedUserName = '';
  bool sendToAll = true; // Default is set to true (send to all users)

  get http => null;

  @override
  void initState() {
    super.initState();
    // If a userName is passed from the previous page, set it in the userName field
    if (widget.userNameFromPreviousPage != null) {
      selectedUserName = widget.userNameFromPreviousPage!;
    }

    // If the passed flag is true, disable the "Send to all" switch
    if (widget.disableSendToAll) {
      sendToAll = false; // Automatically disable "Send to all"
    }
  }

  bool validateInput() {
    String message = _messageController.text.trim();

    if (message.isEmpty) {
      // Show an error message if the message is empty
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Message cannot be empty')),
      );
      return false;
    }

    // If sendToAll is false, validate that a specific user userName is provided
    if (!sendToAll && selectedUserName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('enter the userName')),
      );
      return false;
    }

    return true;
  }

  // Function to send a notification
  Future<void> sendNotification() async {
    if (!validateInput()) {
      return; // If validation fails, stop the function
    }
    String message = _messageController.text;

    // Send notification to all users or specific user
    if (sendToAll) {
      // Send notification to all userName
      FirebaseFirestore.instance
          .collection('user_userName')
          .get()
          .then((snapshot) {
        snapshot.docs.forEach((doc) {
          String userName = doc['userName'];
          // Call a function to send notification to this userName
          sendFCMNotification(userName, message);
        });
      });
    } else {
      // Send notification to a specific user (using theiruserName)
      sendFCMNotification(selectedUserName, message);
    }
  }

  // Function to send FCM notification
  Future<void> sendFCMNotification(String userName, String message) async {
    // Use Firebase Cloud Messaging HTTP API to send a notification
    var response = await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'key=YOUR_SERVER_KEY_HERE',
      },
      body: jsonEncode({
        "to": userName,
        "notification": {
          "title": "Admin Message",
          "body": message,
        }
      }),
    );

    if (response.statusCode == 200) {
      print('Notification sent successfully');
    } else {
      print('Failed to send notification');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Notification Page'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Switch for sending to all users
            SwitchListTile(
              title: Text(
                'Send to all users',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              value: sendToAll,
              onChanged: widget.disableSendToAll
                  ? null // Disable switch if `disableSendToAll` is true
                  : (bool value) {
                      setState(() {
                        sendToAll = value;
                      });
                    },
            ),

            // Input field for specific user  (visible if sendToAll is false)
            if (!sendToAll)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: TextFormField(
                  onChanged: (value) {
                    setState(() {
                      selectedUserName = value;
                    });
                  },
                  initialValue:
                      selectedUserName, // Automatically set value if passed
                  decoration: InputDecoration(
                    labelText: 'Enter Username',
                    labelStyle: TextStyle(color: Colors.blueAccent),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
              ),

            SizedBox(height: 20),

            // Message input field
            TextFormField(
              controller: _messageController,
              maxLines: null, // This makes the TextField multi-line
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                labelText: 'Enter your message',
                labelStyle: TextStyle(color: Colors.blueAccent),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                prefixIcon: Icon(
                  Icons.message,
                  color: Colors.blueAccent,
                ),
              ),
            ),

            SizedBox(height: 20),

            // Send notification button
            ElevatedButton(
              onPressed: sendNotification,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                textStyle: TextStyle(fontSize: 18),
              ),
              child: Text('Send Notification'),
            ),
          ],
        ),
      ),
    );
  }
}

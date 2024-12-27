import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'dart:developer';

class ChatPopup extends StatefulWidget {
  const ChatPopup({super.key});

  @override
  ChatPopupState createState() => ChatPopupState();
}

class ChatPopupState extends State<ChatPopup> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _chatHistory = [];
  bool _isLoading = false;

  final String instruction = '''
    "system_instruction": "You are Explore AI, an intelligent assistant for the Explore Together application. Your primary role is to assist users in finding travel companions. that the main aim of the aplication is to make buddies to solo traveller who can travel with a group. You must be give the response for 'user_input' don't. and give simple and understating response",
      "user_details": {
        "fields": [
          "User Name ",
          "User Age",
          "Preferred Language",
          "Current Location"
        ]
      },
      "application_details": {
        "features": [
          "Search for Travel Buddies: Find others with similar destinations and interests.",
          "Chat Feature: Communicate with travel companions within the app.",
          "Interest-Based Matchmaking: Match with users based on travel preferences and hobbies."
        ]
      },
      "navigation_instructions": {
    "examples": [
      {
        "feature": "Find Travel Buddies",
        "steps": [
          "Open the app.",
          "Search your desired location in the Home section.",
          "Browse the list of potential matches and start chatting with them."
        ]
      },
      {
        "feature": "Edit Profile",
        "steps": [
          "Go to your profile.",
          "Tap 'Edit Profile' or go to 'Settings > Account Management > Edit Profile'."
        ]
      },
      {
        "feature": "Change Password",
        "steps": [
          "Go to your profile.",
          "Tap 'Settings > Account Management > Change Password'."
        ]
      }
    ]
  }
    
  ''';

  void _sendMessage(String userMessage) async {
    if (userMessage.trim().isEmpty) return;

    setState(() {
      _chatHistory.add({'role': 'user', 'message': userMessage});
      _isLoading = true;
    });
    try {
      final gemini = Gemini.instance;

      final conversation = [
        Content(
            parts: [Part.text('$instruction , "user_input" : $userMessage')],
            role: 'user'),
        ..._chatHistory
            .where((msg) => msg['role'] == 'model')
            .map((msg) => Content(parts: [
                  Part.text(msg['message']!),
                ], role: 'model'))
      ];

      final response = await gemini.chat(conversation);
      setState(() {
        _chatHistory.add({
          'role': 'model',
          'message': response?.output ?? 'No response received'
        });
      });
    } catch (e) {
      log('Error in chat: $e');
      setState(() {
        _chatHistory.add({
          'role': 'error',
          'message': 'An error occurred. Please try again.'
        });
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildMessageBubble(String message, String role) {
    bool isUser = role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue[100] : Colors.grey[300],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Text(
          message,
          style: const TextStyle(fontSize: 16.0),
        ),
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      itemCount: _chatHistory.length,
      itemBuilder: (context, index) {
        final message = _chatHistory[index];
        return _buildMessageBubble(message['message']!, message['role']!);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Container(
        height: 450,
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
        child: Column(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
                gradient: LinearGradient(
                  colors: [Colors.blueAccent, Colors.lightBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'AI Chatbot',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8.0),
            Expanded(
              child: _chatHistory.isEmpty
                  ? const Center(
                      child: Text(
                        'Chat With Explore AI',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : _buildChatList(),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                ),
              ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: () {
                        final message = _controller.text;
                        _controller.clear();
                        _sendMessage(message);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

void main() {
  runApp(ChatApp());
}

class ChatApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ChatListPage(),
    );
  }
}

// Chat List Page
class ChatListPage extends StatelessWidget {
  final List<Map<String, String>> chats = [
    {
      "username": "Meta AI",
      "lastMessage": "Hey! How's it going?",
      "time": "08:57",
      "userImage": "assets/user_placeholder.png" // Placeholder image path
    },
    {
      "username": "Ajmal",
      "lastMessage": "See you later!",
      "time": "10:20",
      "userImage": "assets/user_placeholder.png"
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat List'),
      ),
      body: ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: AssetImage(chats[index]['userImage']!),
            ),
            title: Text(chats[index]['username']!),
            subtitle: Text(chats[index]['lastMessage']!),
            trailing: Text(chats[index]['time']!),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(
                    username: chats[index]['username']!,
                    currentUser: "You",
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Chat Page
class ChatPage extends StatefulWidget {
  final String username;
  final String currentUser;

  ChatPage({required this.username, required this.currentUser});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> messages = [
    {
      "sender": "Meta AI",
      "message": "Hello! It's nice to chat with you.",
      "time": "08:57"
    },
    {"sender": "You", "message": "How are you?", "time": "08:58"},
  ];

  void sendMessage() {
    if (_controller.text.isNotEmpty) {
      setState(() {
        messages.add({
          "sender": "You",
          "message": _controller.text,
          "time": TimeOfDay.now().format(context),
        });
        _controller.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: CircleAvatar(
          backgroundImage: AssetImage('assets/user_placeholder.png'),
        ),
        title: Text(widget.username),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                bool isCurrentUser = messages[index]['sender'] == "You";
                return Align(
                  alignment: isCurrentUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          isCurrentUser ? Colors.blue[200] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: isCurrentUser
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Text(
                          messages[index]['message']!,
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          messages[index]['time']!,
                          style:
                              TextStyle(fontSize: 10, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type a message',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

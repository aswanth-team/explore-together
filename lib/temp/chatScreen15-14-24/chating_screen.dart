import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/loading.dart';
import 'chat_utils.dart';

class ChatScreen extends StatefulWidget {
  final String currentUserId;
  final String chatUserId;
  final String chatRoomId;

  const ChatScreen({
    required this.currentUserId,
    required this.chatUserId,
    required this.chatRoomId,
    super.key,
  });

  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ChatCacheManager _cacheManager = ChatCacheManager();
  bool isLoading = true;
  bool isUserOnline = false;
  Map<String, dynamic>? userDetails;
  List<Map<String, dynamic>> _cachedMessages = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeChat();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    await _cacheManager.initDatabase();

    try {
      // Fetch user details
      final userSnapshot = await FirebaseFirestore.instance
          .collection('user')
          .doc(widget.chatUserId)
          .get();

      // Check user online status
      final online =
          await UserStatusManager.getUserOnlineStatus(widget.chatUserId);

      // Load cached messages
      final cachedMessages =
          await _cacheManager.getCachedMessages(widget.chatRoomId);

      setState(() {
        userDetails = userSnapshot.data();
        isUserOnline = online;
        _cachedMessages = cachedMessages;
        isLoading = false;
      });
    } catch (e) {
      print("Error initializing chat: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    try {
      final messageRef = FirebaseFirestore.instance
          .collection('chat/${widget.chatRoomId}/messages');

      final newMessage = await messageRef.add({
        'senderId': widget.currentUserId,
        'text': messageText,
        'createdAt': FieldValue.serverTimestamp(),
        'isSeen': false
      });

      // Cache the message locally
      await _cacheManager.cacheMessage(
        {
          'id': newMessage.id,
          'senderId': widget.currentUserId,
          'text': messageText,
          'chatRoomId': widget.chatRoomId,
          'createdAt': Timestamp.now(),
          'isSeen': false
        },
        widget.chatRoomId,
      );

      // Update latest message in chat room
      await FirebaseFirestore.instance
          .collection('chat')
          .doc(widget.chatRoomId)
          .update({
        'latestMessage': messageText,
        'latestMessageTime': FieldValue.serverTimestamp()
      });

      _messageController.clear();
    } catch (e) {
      print("Error sending message: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to send message")),
      );
    }
  }

  void _markMessagesAsSeen() async {
    try {
      final unreadMessages = await FirebaseFirestore.instance
          .collection('chat/${widget.chatRoomId}/messages')
          .where('senderId', isNotEqualTo: widget.currentUserId)
          .where('isSeen', isEqualTo: false)
          .get();

      // Batch update to mark messages as seen
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isSeen': true});
      }
      await batch.commit();
    } catch (e) {
      print("Error marking messages as seen: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            userDetails?['userimage'] != null
                ? OptimizedNetworkImage(
                    imageUrl: userDetails!['userimage'],
                    width: 40,
                    height: 40,
                  )
                : const CircleAvatar(child: Icon(Icons.person)),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userDetails?['username'] ?? 'User'),
                Text(
                  isUserOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    color: isUserOnline ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: LoadingAnimation())
          : Column(
              children: [
                // Messages List
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('chat/${widget.chatRoomId}/messages')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: LoadingAnimation(),
                        );
                      }

                      final messages = snapshot.data!.docs;

                      // Automatically mark messages as seen when viewed
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _markMessagesAsSeen();
                      });

                      if (messages.isEmpty && _cachedMessages.isEmpty) {
                        return const Center(
                          child:
                              Text('No messages yet. Start the conversation!'),
                        );
                      }

                      // Combine cached and live messages, removing duplicates
                      final combinedMessagesMap =
                          <String, Map<String, dynamic>>{};

                      for (var cachedMessage in _cachedMessages) {
                        combinedMessagesMap[cachedMessage['id']] =
                            cachedMessage;
                      }

                      for (var liveMessage in messages) {
                        combinedMessagesMap[liveMessage.id] = {
                          'id': liveMessage.id,
                          'senderId': liveMessage['senderId'],
                          'text': liveMessage['text'],
                          'createdAt':
                              liveMessage['createdAt'] ?? Timestamp.now(),
                        };
                      }

                      final combinedMessages = combinedMessagesMap.values
                          .toList()
                        ..sort((a, b) => (b['createdAt'] as Timestamp)
                            .compareTo(a['createdAt'] as Timestamp));

                      return ListView.builder(
                        reverse: true,
                        itemCount: combinedMessages.length,
                        itemBuilder: (context, index) {
                          final message = combinedMessages[index];
                          final isMine =
                              message['senderId'] == widget.currentUserId;

                          return MessageBubble(
                            message: message['text'],
                            isMine: isMine,
                          );
                        },
                      );
                    },
                  ),
                ),
                // Message Input
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Type a message',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _sendMessage,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String message;
  final bool isMine;

  const MessageBubble({
    required this.message,
    required this.isMine,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        decoration: BoxDecoration(
          color: isMine ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          message,
          style: TextStyle(
            color: isMine ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}

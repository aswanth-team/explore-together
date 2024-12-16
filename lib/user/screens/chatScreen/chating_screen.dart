import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
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
  final BehaviorSubject<List<Map<String, dynamic>>> _messagesController =
      BehaviorSubject<List<Map<String, dynamic>>>();

  bool isLoading = true;
  bool isUserOnline = false;
  Map<String, dynamic>? userDetails;

  // Pagination variables
  static const int _messagesPerPage = 50;
  DocumentSnapshot? _lastDocument;
  bool _hasMoreMessages = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeChat();
    _setupScrollListener();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _loadMoreMessages();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    _messagesController.close();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    try {
      // Initialize database
      await _cacheManager.initDatabase();

      // Fetch user details concurrently
      final userFuture = FirebaseFirestore.instance
          .collection('user')
          .doc(widget.chatUserId)
          .get();

      final onlineStatusFuture =
          UserStatusManager.getUserOnlineStatus(widget.chatUserId);

      // Load initial cached messages
      final cachedMessagesFuture = _cacheManager
          .getCachedMessages(widget.chatRoomId, limit: _messagesPerPage);

      // Wait for all futures
      final results = await Future.wait(
          [userFuture, onlineStatusFuture, cachedMessagesFuture]);

      // Update state
      setState(() {
        // Use .data() method correctly
        userDetails =
            (results[0] as DocumentSnapshot).data() as Map<String, dynamic>?;
        isUserOnline = results[1] as bool;
        _messagesController.add(results[2] as List<Map<String, dynamic>>);
        isLoading = false;
      });

      // Start listening to new messages
      _setupMessageListener();
    } catch (e) {
      print("Error initializing chat: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void _setupMessageListener() {
    FirebaseFirestore.instance
        .collection('chat/${widget.chatRoomId}/messages')
        .orderBy('createdAt', descending: true)
        .limit(_messagesPerPage)
        .snapshots()
        .listen((snapshot) {
      // Update messages and cache simultaneously
      _updateMessagesWithSnapshot(snapshot);
    }, onError: (error) {
      print("Error listening to messages: $error");
    });
  }

  void _updateMessagesWithSnapshot(QuerySnapshot snapshot) async {
    try {
      // Convert snapshot to messages
      final liveMessages = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'senderId': doc['senderId'],
          'text': doc['text'],
          'createdAt': doc['createdAt'] ?? Timestamp.now(),
        };
      }).toList();

      // Batch cache new messages
      await _cacheManager.batchCacheMessages(liveMessages, widget.chatRoomId);

      // Merge with existing messages
      final currentMessages = _messagesController.value;
      final mergedMessages = _mergeMessages(currentMessages, liveMessages);

      _messagesController.add(mergedMessages);
    } catch (e) {
      print("Error updating messages: $e");
    }
  }

  List<Map<String, dynamic>> _mergeMessages(
      List<Map<String, dynamic>> existingMessages,
      List<Map<String, dynamic>> newMessages) {
    final messageMap = <String, Map<String, dynamic>>{};

    // Add existing messages
    for (var message in existingMessages) {
      messageMap[message['id']] = message;
    }

    // Add or update new messages
    for (var message in newMessages) {
      messageMap[message['id']] = message;
    }

    // Convert to sorted list
    return messageMap.values.toList()
      ..sort((a, b) =>
          (b['createdAt'] as Timestamp).compareTo(a['createdAt'] as Timestamp));
  }

  Future<void> _loadMoreMessages() async {
    if (!_hasMoreMessages) return;

    try {
      final query = FirebaseFirestore.instance
          .collection('chat/${widget.chatRoomId}/messages')
          .orderBy('createdAt', descending: true)
          .startAfter([_lastDocument?['createdAt']]).limit(_messagesPerPage);

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          _hasMoreMessages = false;
        });
        return;
      }

      final newMessages = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'senderId': doc['senderId'],
          'text': doc['text'],
          'createdAt': doc['createdAt'] ?? Timestamp.now(),
        };
      }).toList();

      // Batch cache new messages
      await _cacheManager.batchCacheMessages(newMessages, widget.chatRoomId);

      // Update messages
      final currentMessages = _messagesController.value;
      final mergedMessages = _mergeMessages(currentMessages, newMessages);

      _messagesController.add(mergedMessages);

      // Update last document for pagination
      _lastDocument = snapshot.docs.last;
    } catch (e) {
      print("Error loading more messages: $e");
    }
  }

  void _sendMessage() async {
    final messageText = _messageController.text.trim();
    _messageController.clear();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            userDetails?['userimage'] != null
                ? ClipOval(
                    child: OptimizedNetworkImage(
                      imageUrl: userDetails!['userimage'],
                      width: 40,
                      height: 40,
                      fit: BoxFit
                          .cover, // Ensures the image fits the circular shape properly
                    ),
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
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _messagesController.stream,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child:
                              Text('No messages yet. Start the conversation!'),
                        );
                      }

                      final messages = snapshot.data!;

                      return ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        itemCount: messages.length + (_hasMoreMessages ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == messages.length && _hasMoreMessages) {
                            return const Center(
                              child: LoadingAnimation(),
                            );
                          }

                          final message = messages[index];
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
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
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

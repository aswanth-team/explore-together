import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
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
      BehaviorSubject<List<Map<String, dynamic>>>.seeded([]);

  bool isLoading = true;
  bool isUserOnline = false;
  Map<String, dynamic>? userDetails;

  // Pagination variables
  static const int _messagesPerPage = 20; // Fetch limited messages initially
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
          _scrollController.position.minScrollExtent) {
        // Trigger loading older messages when scrolled to the top
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
      // Initialize the local database
      await _cacheManager.initDatabase();

      // Fetch initial user details and cache messages concurrently
      final userFuture = FirebaseFirestore.instance
          .collection('user')
          .doc(widget.chatUserId)
          .get();

      final onlineStatusFuture =
          UserStatusManager.getUserOnlineStatus(widget.chatUserId);

      final cachedMessagesFuture = _cacheManager.getCachedMessages(
        widget.chatRoomId,
        limit: _messagesPerPage,
      );

      final results = await Future.wait([
        userFuture,
        onlineStatusFuture,
        cachedMessagesFuture,
      ]);

      setState(() {
        userDetails =
            (results[0] as DocumentSnapshot).data() as Map<String, dynamic>?;
        isUserOnline = results[1] as bool;
        _messagesController.add(results[2] as List<Map<String, dynamic>>);
        isLoading = false;
      });

      // Start listening for new messages in real-time
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
      _updateMessagesWithSnapshot(snapshot);
    }, onError: (error) {
      print("Error listening to messages: $error");
    });
  }

  void _updateMessagesWithSnapshot(QuerySnapshot snapshot) async {
    try {
      final liveMessages = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'senderId': doc['senderId'],
          'text': doc['text'],
          'createdAt': doc['createdAt'] ?? Timestamp.now(),
        };
      }).toList();

      await _cacheManager.batchCacheMessages(liveMessages, widget.chatRoomId);

      final currentMessages = _messagesController.value;
      final mergedMessages = _mergeMessages(currentMessages, liveMessages);

      _messagesController.add(mergedMessages);
    } catch (e) {
      print("Error updating messages: $e");
    }
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

      await _cacheManager.batchCacheMessages(newMessages, widget.chatRoomId);

      final currentMessages = _messagesController.value;
      final mergedMessages = _mergeMessages(currentMessages, newMessages);

      _messagesController.add(mergedMessages);

      _lastDocument = snapshot.docs.last;
    } catch (e) {
      print("Error loading more messages: $e");
    }
  }

  List<Map<String, dynamic>> _mergeMessages(
      List<Map<String, dynamic>> existingMessages,
      List<Map<String, dynamic>> newMessages) {
    final messageMap = <String, Map<String, dynamic>>{};

    for (var message in existingMessages) {
      messageMap[message['id']] = message;
    }

    for (var message in newMessages) {
      messageMap[message['id']] = message;
    }

    return messageMap.values.toList()
      ..sort((a, b) =>
          (b['createdAt'] as Timestamp).compareTo(a['createdAt'] as Timestamp));
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
                    ),
                  )
                : const CircleAvatar(child: Icon(Icons.person)),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userDetails?['username'] ?? 'Loading...'),
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
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _messagesController.stream,
                    builder: (context, snapshot) {
                      if (isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
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
                          if (_hasMoreMessages && index == messages.length) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final message = messages[index];
                          return ChatBubble(
                            isSentByCurrentUser:
                                message['senderId'] == widget.currentUserId,
                            text: message['text'],
                            createdAt: message['createdAt'],
                          );
                        },
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: TextStyle(color: Colors.grey[600]),
                              filled: true,
                              fillColor: Colors.grey[200],
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 16), // Increased vertical padding
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide:
                                    BorderSide(color: Colors.blueAccent),
                              ),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: IconButton(
                          icon: Icon(
                            Icons.send,
                            color: Colors.blueAccent,
                          ),
                          onPressed: _sendMessage,
                          splashColor: Colors.blueAccent.withOpacity(0.3),
                          splashRadius: 25,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final bool isSentByCurrentUser;
  final String text;
  final dynamic createdAt; // Accept dynamic since it might be int or Timestamp

  const ChatBubble({
    required this.isSentByCurrentUser,
    required this.text,
    required this.createdAt,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Convert createdAt to DateTime safely
    final time = TimeOfDay.fromDateTime(
      createdAt is Timestamp
          ? createdAt.toDate()
          : DateTime.fromMillisecondsSinceEpoch(createdAt ?? 0),
    );
    final formattedTime =
        "${time.hourOfPeriod}:${time.minute.toString().padLeft(2, '0')} ${time.period == DayPeriod.am ? 'AM' : 'PM'}";

    return Align(
      alignment:
          isSentByCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: isSentByCurrentUser ? Colors.blue : Colors.grey.shade300,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isSentByCurrentUser ? 12 : 0),
            bottomRight: Radius.circular(isSentByCurrentUser ? 0 : 12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isSentByCurrentUser ? Colors.white : Colors.black,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              formattedTime,
              style: TextStyle(
                color: isSentByCurrentUser ? Colors.white70 : Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'chat_utils.dart';

class ChatScreen extends StatefulWidget {
  final String currentUserId;
  final String chatUserId;
  final String chatRoomId;
  final VoidCallback onMessageSent;

  const ChatScreen({
    required this.currentUserId,
    required this.chatUserId,
    required this.chatRoomId,
    required this.onMessageSent,
    super.key,
  });

  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final BehaviorSubject<List<Map<String, dynamic>>> _messagesController =
      BehaviorSubject<List<Map<String, dynamic>>>.seeded([]);
  final ScrollController _scrollController = ScrollController();

  bool isLoading = true;
  bool isUserOnline = false;
  bool isOffline = false;
  Map<String, dynamic>? userDetails;

  // Pagination variables
  static const int _messagesPerPage = 20;
  DocumentSnapshot? _lastDocument;
  bool _hasMoreMessages = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeChat();
    _setupScrollListener();
    _checkConnectivity();
    _markMessagesAsSeen();
  }

  Future<void> _markMessagesAsSeen() async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      final unseenMessages = await FirebaseFirestore.instance
          .collection('chat/${widget.chatRoomId}/messages')
          .where('senderId', isEqualTo: widget.chatUserId)
          .where('isSeen', isEqualTo: false)
          .get();

      for (var doc in unseenMessages.docs) {
        batch.update(doc.reference, {'isSeen': true});
      }

      await batch.commit();
    } catch (e) {
      print('Error marking messages as seen: $e');
    }
  }

  Future<void> _checkConnectivity() async {
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {});
      setState(() => isOffline = false);
    } catch (e) {
      setState(() => isOffline = true);
    }
  }

  Future<void> _saveMessagesToCache(List<Map<String, dynamic>> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = json.encode(messages.map((message) {
      return {
        ...message,
        'createdAt': (message['createdAt'] as Timestamp).millisecondsSinceEpoch,
      };
    }).toList());
    await prefs.setString('cached_messages_${widget.chatRoomId}', messagesJson);
  }

  Future<List<Map<String, dynamic>>> _loadMessagesFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson =
        prefs.getString('cached_messages_${widget.chatRoomId}');
    if (messagesJson != null) {
      final List<dynamic> decodedMessages = json.decode(messagesJson);
      return decodedMessages.map((message) {
        return {
          ...Map<String, dynamic>.from(message),
          'createdAt':
              Timestamp.fromMillisecondsSinceEpoch(message['createdAt']),
        };
      }).toList();
    }
    return [];
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.minScrollExtent) {
        _loadMoreMessages();
      }
    });
  }

  Future<void> _initializeChat() async {
    try {
      // Load cached messages first
      final cachedMessages = await _loadMessagesFromCache();
      if (cachedMessages.isNotEmpty) {
        _messagesController.add(cachedMessages);
      }

      if (!isOffline) {
        final userFuture = FirebaseFirestore.instance
            .collection('user')
            .doc(widget.chatUserId)
            .get();

        final onlineStatusFuture =
            UserStatusManager.getUserOnlineStatus(widget.chatUserId);

        final results = await Future.wait([
          userFuture,
          onlineStatusFuture,
        ]);

        setState(() {
          userDetails =
              (results[0] as DocumentSnapshot).data() as Map<String, dynamic>?;
          isUserOnline = results[1] as bool;
        });
        _setupMessageListener();
      }

      setState(() {
        isLoading = false;
      });
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
      _loadMessagesFromCache().then((messages) {
        if (messages.isNotEmpty) {
          _messagesController.add(messages);
        }
      });
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
      await _saveMessagesToCache(liveMessages);

      _messagesController.add(liveMessages);
    } catch (e) {
      print("Error updating messages: $e");
    }
  }

  Future<void> _loadMoreMessages() async {
    if (!_hasMoreMessages || isOffline) return;

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

      final currentMessages = _messagesController.value;
      final mergedMessages = _mergeMessages(currentMessages, newMessages);
      await _saveMessagesToCache(mergedMessages);

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

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _getDateString(DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    if (_isSameDay(date, now)) {
      return 'Today';
    } else if (_isSameDay(date, yesterday)) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;
    _messageController.clear();

    final newMessage = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'senderId': widget.currentUserId,
      'text': messageText,
      'createdAt': Timestamp.now(),
      'isSeen': false
    };

    // Add to local stream immediately
    final currentMessages = _messagesController.value;
    final updatedMessages = [newMessage, ...currentMessages];
    _messagesController.add(updatedMessages);

    // Save to cache
    await _saveMessagesToCache(updatedMessages);

    if (!isOffline) {
      try {
        final messageRef = FirebaseFirestore.instance
            .collection('chat/${widget.chatRoomId}/messages');

        await messageRef.add({
          'senderId': widget.currentUserId,
          'text': messageText,
          'createdAt': FieldValue.serverTimestamp(),
          'isSeen': false
        });

        await FirebaseFirestore.instance
            .collection('chat')
            .doc(widget.chatRoomId)
            .update({
          'latestMessage': messageText,
          'latestMessageTime': FieldValue.serverTimestamp()
        });

        widget.onMessageSent();
      } catch (e) {
        print("Error sending message: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Message saved offline. Will sync when online.")),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Message saved offline. Will sync when online.")),
        );
      }
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
                Row(
                  children: [
                    Text(
                      isOffline
                          ? 'Offline Mode'
                          : (isUserOnline ? 'Online' : 'Offline'),
                      style: TextStyle(
                        fontSize: 12,
                        color: isOffline
                            ? Colors.orange
                            : (isUserOnline ? Colors.green : Colors.grey),
                      ),
                    ),
                    if (isOffline)
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(Icons.offline_bolt,
                            size: 14, color: Colors.orange),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : GestureDetector(
              onTap: _markMessagesAsSeen,
              child: Column(
                children: [
                  Expanded(
                    child: StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _messagesController.stream,
                      builder: (context, snapshot) {
                        // Check if we're still in the initial loading state
                        if (!snapshot.hasData && isLoading) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        // If we have no data after loading is complete, show the empty state
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No messages yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Start the conversation!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final messages = snapshot.data!;
                        return ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          itemCount:
                              messages.length + (_hasMoreMessages ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (_hasMoreMessages && index == messages.length) {
                              return const Padding(
                                padding: EdgeInsets.all(8.0),
                                child:
                                    Center(child: CircularProgressIndicator()),
                              );
                            }

                            final message = messages[index];
                            final DateTime messageDate =
                                (message['createdAt'] as Timestamp).toDate();

                            bool showDateDivider = false;
                            String? dateString;

                            if (index == messages.length - 1 ||
                                !_isSameDay(
                                    messageDate,
                                    (messages[index + 1]['createdAt']
                                            as Timestamp)
                                        .toDate())) {
                              showDateDivider = true;
                              dateString = _getDateString(messageDate);
                            }

                            return ChatBubble(
                              isSentByCurrentUser:
                                  message['senderId'] == widget.currentUserId,
                              text: message['text'],
                              createdAt: message['createdAt'],
                              showDateDivider: showDateDivider,
                              dateString: dateString,
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
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 16),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: const BorderSide(
                                      color: Colors.blueAccent),
                                ),
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: IconButton(
                            icon: const Icon(
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
            ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    _messagesController.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _checkConnectivity();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }
}

class ChatBubble extends StatelessWidget {
  final bool isSentByCurrentUser;
  final String text;
  final dynamic createdAt;
  final bool showDateDivider;
  final String? dateString;

  const ChatBubble({
    required this.isSentByCurrentUser,
    required this.text,
    required this.createdAt,
    this.showDateDivider = false,
    this.dateString,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final DateTime messageDate = createdAt is Timestamp
        ? createdAt.toDate()
        : DateTime.fromMillisecondsSinceEpoch(createdAt ?? 0);

    final time = TimeOfDay.fromDateTime(messageDate);
    final formattedTime =
        "${time.hourOfPeriod}:${time.minute.toString().padLeft(2, '0')} ${time.period == DayPeriod.am ? 'AM' : 'PM'}";

    return Column(
      children: [
        if (showDateDivider && dateString != null)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    dateString!,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
          ),
        Align(
          alignment: isSentByCurrentUser
              ? Alignment.centerRight
              : Alignment.centerLeft,
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
                    color:
                        isSentByCurrentUser ? Colors.white70 : Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

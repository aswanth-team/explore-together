import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../../utils/loading.dart';
import 'chat_utils.dart';
import 'chating_screen.dart';

class ChatHomeScreen extends StatefulWidget {
  const ChatHomeScreen({super.key});

  @override
  ChatHomeScreenState createState() => ChatHomeScreenState();
}

class ChatHomeScreenState extends State<ChatHomeScreen>
    with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool isOffline = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    UserStatusManager.updateUserStatus(true);
    _checkConnectivity();
  }

  Future<int> _getUnreadMessageCount(
      String chatRoomId, String otherUserId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('chat/$chatRoomId/messages')
          .where('senderId', isEqualTo: otherUserId)
          .where('isSeen', isEqualTo: false)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      print('Error getting unread message count: $e');
      return 0;
    }
  }

  Future<void> _checkConnectivity() async {
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {});
      if (mounted) {
        setState(() => isOffline = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => isOffline = true);
      }
    }
  }

  Future<void> _saveChatsToCache(List<Map<String, dynamic>> chats) async {
    final prefs = await SharedPreferences.getInstance();
    final chatJson = json.encode(chats.map((chat) {
      return {
        ...chat,
        'latestMessageTime': chat['latestMessageTime'].toIso8601String(),
      };
    }).toList());
    await prefs.setString('cached_chats', chatJson);
  }

  Future<List<Map<String, dynamic>>> _loadChatsFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final chatJson = prefs.getString('cached_chats');
    if (chatJson != null) {
      final List<dynamic> decodedChats = json.decode(chatJson);
      return decodedChats.map((chat) {
        return {
          ...Map<String, dynamic>.from(chat),
          'latestMessageTime': DateTime.parse(chat['latestMessageTime']),
        };
      }).toList();
    }
    return [];
  }

  Stream<List<Map<String, dynamic>>> getChatStream() {
    return FirebaseFirestore.instance
        .collection('chat')
        .where('user', arrayContains: currentUserId)
        .limit(20)
        .snapshots()
        .asyncMap((chatSnapshot) async {
      if (!mounted) return [];
      final chatFutures = chatSnapshot.docs.map((chatDoc) async {
        if (!mounted) return null;
        final chatData = chatDoc.data();
        final userIds = chatData['user'] as List<dynamic>? ?? [];
        final otherUserId = userIds.firstWhere(
          (id) => id != currentUserId,
          orElse: () => null,
        );

        if (otherUserId == null) return null;

        final userSnapshot = await FirebaseFirestore.instance
            .collection('user')
            .doc(otherUserId)
            .get();

        if (userSnapshot.exists) {
          final userData = userSnapshot.data();

          final unreadCount = await _getUnreadMessageCount(
            chatDoc.id,
            otherUserId,
          );

          final latestMessageTime =
              chatData['latestMessageTime']?.toDate() ?? DateTime.now();

          return {
            'userId': otherUserId,
            'chatRoomId': chatDoc.id,
            'username': userData?['username'] ?? 'Unknown User',
            'userimage':
                userData?['userimage'] ?? 'https://via.placeholder.com/150',
            'latestMessage': chatData['latestMessage'] ?? 'No messages yet',
            'unseenCount': unreadCount,
            'latestMessageTime': latestMessageTime,
          };
        }
        return null;
      });

      if (!mounted) return [];

      final chatList = await Future.wait(chatFutures);
      final validChats = chatList.whereType<Map<String, dynamic>>().toList();

      validChats.sort((a, b) {
        final timeA = a['latestMessageTime'] as DateTime;
        final timeB = b['latestMessageTime'] as DateTime;
        return timeB.compareTo(timeA);
      });

      if (mounted) {
        await _saveChatsToCache(validChats);
      }
      return validChats;
    });
  }

  Widget _buildChatList(List<Map<String, dynamic>> chats) {
    final searchQuery = _searchController.text.toLowerCase();
    final filteredChats = chats.where((chat) {
      return chat['username'].toString().toLowerCase().contains(searchQuery);
    }).toList();

    if (filteredChats.isEmpty) {
      return Center(
        child: Text(
          _searchController.text.isEmpty
              ? 'No chats found.'
              : 'No chats matching "${_searchController.text}".',
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredChats.length,
      itemBuilder: (context, index) {
        final chat = filteredChats[index];
        return ListTile(
          leading: Stack(
            children: [
              CachedNetworkImage(
                imageUrl: chat['userimage'],
                imageBuilder: (context, imageProvider) => CircleAvatar(
                  backgroundImage: imageProvider,
                  radius: 20,
                ),
                placeholder: (context, url) => const CircleAvatar(
                  radius: 20,
                  child: Icon(Icons.group),
                ),
                errorWidget: (context, url, error) => const CircleAvatar(
                  radius: 20,
                  child: Icon(Icons.error),
                ),
              ),
              if (chat['unseenCount'] > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${chat['unseenCount']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(chat['username']),
          subtitle: Text(
            chat['latestMessage'],
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                currentUserId: currentUserId,
                chatUserId: chat['userId'],
                chatRoomId: chat['chatRoomId'],
                onMessageSent: () {},
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search',
              prefixIcon: Icon(
                Icons.search,
                color: Colors.grey[600],
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: Colors.grey[600],
                      ),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                        });
                      },
                    )
                  : null,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: Colors.grey, width: 1),
              ),
            ),
            onChanged: (value) => setState(() {}),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: getChatStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  // If there's an error with the stream, load from cache
                  return FutureBuilder<List<Map<String, dynamic>>>(
                    future: _loadChatsFromCache(),
                    builder: (context, cacheSnapshot) {
                      if (cacheSnapshot.hasData) {
                        return _buildChatList(cacheSnapshot.data!);
                      }
                      return const Center(
                          child: Text('No cached chats available'));
                    },
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  // While waiting for the stream, show cached data
                  return FutureBuilder<List<Map<String, dynamic>>>(
                    future: _loadChatsFromCache(),
                    builder: (context, cacheSnapshot) {
                      if (cacheSnapshot.hasData) {
                        return _buildChatList(cacheSnapshot.data!);
                      }
                      return const Center(child: LoadingAnimation());
                    },
                  );
                }

                return _buildChatList(snapshot.data ?? []);
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    UserStatusManager.updateUserStatus(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        UserStatusManager.updateUserStatus(true);
        _checkConnectivity();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        UserStatusManager.updateUserStatus(false);
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }
}

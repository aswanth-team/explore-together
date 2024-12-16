import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/loading.dart';
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
  final ChatCacheManager _cacheManager = ChatCacheManager();

  List<Map<String, dynamic>> previousChats = [];
  bool isLoading = true;
  bool isOffline = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeData();
    UserStatusManager.updateUserStatus(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    UserStatusManager.updateUserStatus(false);
    super.dispose();
  }

  Future<void> _initializeData() async {
    await _cacheManager.initDatabase();

    try {
      // Always load cached chats first
      final cachedChats = await PreferencesManager.loadChats();
      if (cachedChats.isNotEmpty) {
        setState(() {
          previousChats = cachedChats;
          isLoading = false;
        });
      }

      // Try to fetch fresh data from Firestore
      await _loadPreviousChats();
    } catch (error) {
      // If there's an error, fall back to cached chats or show offline state
      setState(() {
        isLoading = false;
        isOffline = true;
        errorMessage = previousChats.isEmpty
            ? "No internet connection. No saved chats found."
            : "Offline mode: Showing saved chats";
      });
    }
  }

  Future<void> _loadPreviousChats() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      isOffline = false;
    });

    try {
      final chatSnapshots = await FirebaseFirestore.instance
          .collection('chat')
          .where('user', arrayContains: currentUserId)
          .limit(20) // Limit initial load
          .get();

      final userFutures = chatSnapshots.docs.map((chatDoc) async {
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

          // Calculate unread messages from the opposite user
          final unseenCount = await _cacheManager.getUnseenMessageCount(
            chatDoc.id,
            senderId: otherUserId,
          );

          return {
            'userId': otherUserId,
            'chatRoomId': chatDoc.id,
            'username': userData?['username'] ?? 'Unknown User',
            'userimage':
                userData?['userimage'] ?? 'https://via.placeholder.com/150',
            'latestMessage': chatData['latestMessage'] ?? 'No messages yet',
            'unseenCount': unseenCount
          };
        }
        return null;
      });

      final chatList = await Future.wait(userFutures);
      final validChats = chatList.whereType<Map<String, dynamic>>().toList();

      setState(() {
        previousChats = validChats;
        isLoading = false;
      });

      // Save to local storage
      await PreferencesManager.saveChats(validChats);
    } catch (error) {
      // Handle offline scenario
      setState(() {
        isLoading = false;
        isOffline = true;
        errorMessage = previousChats.isEmpty
            ? "Error loading chats. No internet connection."
            : "Offline mode: Showing saved chats";
      });
      debugPrint("Error loading chats: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = _searchController.text.toLowerCase();
    final filteredChats = previousChats.where((chat) {
      return chat['username'].toLowerCase().contains(searchQuery);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
      ),
      body: isLoading
          ? const Center(child: LoadingAnimation())
          : Column(
              children: [
                if (isOffline)
                  Container(
                    color: Colors.yellow[200],
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.wifi_off),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            errorMessage ?? 'No internet connection',
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                ),
                Expanded(
                  child: filteredChats.isEmpty
                      ? Center(
                          child: Text(
                            _searchController.text.isEmpty
                                ? 'No chats found.'
                                : 'No chats matching "${_searchController.text}".',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 1,
                            childAspectRatio: 4.3,
                          ),
                          itemCount: filteredChats.length,
                          itemBuilder: (context, index) {
                            final chat = filteredChats[index];
                            return Card(
                              child: ListTile(
                                leading: Stack(
                                  children: [
                                    ClipOval(
                                      child: OptimizedNetworkImage(
                                        imageUrl: chat['userimage'],
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit
                                            .cover, // Ensures the image fits the circular shape properly
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
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
      setState(() {
        previousChats = cachedChats;
        isLoading = false;
      });

      // If offline, don't try to fetch data from Firestore
      if (cachedChats.isNotEmpty) {
        setState(() {
          isOffline = true;
        });
        return;
      }
    } catch (error) {
      setState(() {
        isLoading = false;
        isOffline = true;
        errorMessage = previousChats.isEmpty
            ? "No internet connection. No saved chats found."
            : "Offline mode: Showing saved chats";
      });
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
                      : ListView.builder(
                          itemCount: filteredChats.length,
                          itemBuilder: (context, index) {
                            final chat = filteredChats[index];
                            return Card(
                              margin: EdgeInsets.symmetric(
                                  vertical:
                                      0.5), // Adjust card margin if necessary
                              child: ListTile(
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 20.0,
                                    horizontal:
                                        16.0), // Increase vertical padding to increase height
                                leading: Stack(
                                  children: [
                                    ClipOval(
                                      child: OptimizedNetworkImage(
                                        imageUrl: chat['userimage'],
                                        width: 60, // Increase image width
                                        height: 60, // Increase image height
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ],
                                ),
                                title: Text(chat['username']),
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

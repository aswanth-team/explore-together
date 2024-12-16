import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatCacheManager {
  static final ChatCacheManager _instance = ChatCacheManager._internal();
  factory ChatCacheManager() => _instance;
  ChatCacheManager._internal();

  late Database _database;

  // Initialize database asynchronously
  static Future<void> initialize() async {
    await _instance.initDatabase();
  }

  // Initialize the database and create table
  Future<void> initDatabase() async {
    _database = await openDatabase(
      join(await getDatabasesPath(), 'chat_database.db'),
      onCreate: (db, version) {
        return Future.wait([
          db.execute(
            'CREATE TABLE messages(id TEXT PRIMARY KEY, chatRoomId TEXT, senderId TEXT, text TEXT, createdAt INTEGER, isSeen INTEGER)',
          ),
          // Add indexes to improve query performance
          db.execute(
            'CREATE INDEX idx_chatroom_createdat ON messages (chatRoomId, createdAt)',
          ),
          db.execute(
            'CREATE INDEX idx_chatroom_sender ON messages (chatRoomId, senderId)',
          ),
        ]);
      },
      version: 2, // Increment version for migration
    );
  }

  // Cache the message in the local database
  Future<void> cacheMessage(
      Map<String, dynamic> message, String chatRoomId) async {
    try {
      await _database.insert(
        'messages',
        {
          'id': message['id'],
          'chatRoomId': chatRoomId,
          'senderId': message['senderId'],
          'text': message['text'],
          'createdAt': message['createdAt']?.millisecondsSinceEpoch,
          'isSeen': 0
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('Error caching message: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getCachedMessages(String chatRoomId,
      {int limit = 50}) async {
    try {
      return await _database.query(
        'messages',
        where: 'chatRoomId = ?',
        whereArgs: [chatRoomId],
        orderBy: 'createdAt DESC',
        limit: limit, // Limit the number of messages retrieved
      );
    } catch (e) {
      print('Error retrieving cached messages: $e');
      return [];
    }
  }

  Future<void> batchCacheMessages(
      List<Map<String, dynamic>> messages, String chatRoomId) async {
    try {
      await _database.transaction((txn) async {
        final batch = txn.batch();
        for (var message in messages) {
          batch.insert(
            'messages',
            {
              'id': message['id'],
              'chatRoomId': chatRoomId,
              'senderId': message['senderId'],
              'text': message['text'],
              'createdAt': message['createdAt']?.millisecondsSinceEpoch,
              'isSeen': 0
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      });
    } catch (e) {
      print('Error batch caching messages: $e');
    }
  }

  Future<int> getUnseenMessageCount(String chatRoomId,
      {required String senderId}) async {
    try {
      final unseenMessages = await _database.query('messages',
          where: 'chatRoomId = ? AND isSeen = 0 AND senderId = ?',
          whereArgs: [chatRoomId, senderId]);
      return unseenMessages.length;
    } catch (e) {
      print('Error counting unseen messages: $e');
      return 0;
    }
  }
}

class UserStatusManager {
  // Update the user's online status in Firestore
  static Future<void> updateUserStatus(bool isOnline) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        await FirebaseFirestore.instance
            .collection('user')
            .doc(currentUser.uid)
            .update({
          'isOnline': isOnline,
          'lastSeen': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('Error updating user status: $e');
      }
    }
  }

  // Retrieve the online status of a user from Firestore
  static Future<bool> getUserOnlineStatus(String userId) async {
    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('user').doc(userId).get();
      return userDoc.data()?['isOnline'] ?? false;
    } catch (e) {
      print('Error getting user online status: $e');
      return false;
    }
  }
}

class PreferencesManager {
  // Limit the number of saved chats
  static Future<void> saveChats(List<Map<String, dynamic>> chats) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Limit to most recent 100 chats
      final limitedChats = chats.take(100).toList();
      final chatJsonList =
          limitedChats.map((chat) => json.encode(chat)).toList();
      await prefs.setStringList('previous_chats', chatJsonList);
    } catch (e) {
      print('Error saving chats: $e');
    }
  }

  // Add an option to load a subset of chats
  static Future<List<Map<String, dynamic>>> loadChats({int limit = 50}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final chatJsonList = prefs.getStringList('previous_chats') ?? [];
      return chatJsonList
          .take(limit)
          .map((chatJson) => Map<String, dynamic>.from(json.decode(chatJson)))
          .toList();
    } catch (e) {
      print('Error loading chats: $e');
      return [];
    }
  }
}

class OptimizedNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;

  const OptimizedNetworkImage(
      {Key? key,
      required this.imageUrl,
      this.width,
      this.height,
      this.fit = BoxFit.cover})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      placeholder: (context, url) => CircularProgressIndicator(),
      errorWidget: (context, url, error) => Icon(Icons.error),
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: 250, // Limit memory cache width
      maxWidthDiskCache: 500, // Limit disk cache width
    );
  }
}

import 'package:flutter/material.dart';

class PostDetailScreen extends StatelessWidget {
  final String postId;
  final String username;

  const PostDetailScreen({
    Key? key,
    required this.postId,
    required this.username,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Fetch post details using postId or display them
    return Scaffold(
      appBar: AppBar(title: Text('Post Details')),
      body: Center(
        child: Text('Post ID: $postId\nUsername: $username'),
      ),
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../services/post/firebase_post.dart';
import '../../../../utils/loading.dart';
import 'post_complete_screen.dart';
import 'post_detail_screen.dart';

class UserPostsWidget extends StatefulWidget {
  final String userId;

  const UserPostsWidget({
    super.key,
    required this.userId,
  });

  @override
  UserPostsWidgetState createState() => UserPostsWidgetState();
}

class UserPostsWidgetState extends State<UserPostsWidget> {
  final UserPostServices _userPostServices = UserPostServices();

  void showPostOptions(BuildContext context, Map<String, dynamic> post) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!(post['tripCompleted'] ?? false))
                ListTile(
                  leading: const Icon(Icons.check_circle_outline),
                  title: const Text('Complete'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PostCompleteScreen(
                          postId: post['postId'],
                        ),
                      ),
                    );
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Delete'),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        title: Row(
                          children: [
                            Icon(Icons.delete_forever, color: Colors.redAccent),
                            SizedBox(width: 10),
                            Text(
                              'Delete Post',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Are you sure you want to delete this post?',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'This action cannot be undone. The post will be permanently deleted.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(); // Close dialog
                            },
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop(); // Close dialog
                              _userPostServices
                                  .deletePost(post['postId']); // Delete post
                              setState(() {}); // Refresh UI
                            },
                            child: Text('Delete'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _userPostServices.fetchUserPosts(userId: widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingAnimation();
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Error fetching posts.'));
        }

        final userPosts = snapshot.data ?? [];

        if (userPosts.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 50),
                Text('🚫', style: TextStyle(fontSize: 50)),
                Text('No posts available'),
              ],
            ),
          );
        }

        /* Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child:*/

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
            childAspectRatio: 0.80,
          ),
          itemCount: userPosts.length,
          itemBuilder: (context, index) {
            final post = userPosts[index];

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CurrentUserPostDetailScreen(
                      postId: post['postId'],
                      userId: widget.userId,
                    ),
                  ),
                );
              },
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: (post['tripCompleted'] ?? false)
                          ? Colors.green[100]
                          : Colors.white,
                      border: Border.all(color: Colors.grey, width: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromARGB(255, 138, 222, 255)
                              .withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image(
                            image: CachedNetworkImageProvider(
                              post['locationImages']?.isNotEmpty == true
                                  ? post['locationImages'][0]
                                  : 'https://res.cloudinary.com/dakew8wni/image/upload/v1734019072/public/postimages/mwtjtugc4ppu02vwiv49.png',
                            ),
                            fit: BoxFit.cover,
                            height: 100,
                            width: double.infinity,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Center(
                            child: Text(
                              post['locationName'] ?? 'Unknown Location',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.black,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () => showPostOptions(context, post),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

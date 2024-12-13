import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../services/user/firebase_post.dart';
import 'post_complete_screen.dart';
import 'post_detail_screen.dart';

class UserPostsWidget extends StatefulWidget {
  final String userId;

  const UserPostsWidget({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _UserPostsWidgetState createState() => _UserPostsWidgetState();
}

class _UserPostsWidgetState extends State<UserPostsWidget> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> fetchUserPosts() async {
    try {
      final querySnapshot = await _firestore
          .collection('post')
          .where('userid', isEqualTo: widget.userId)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['postId'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching posts: $e');
      return [];
    }
  }

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
                  Navigator.pop(context);
                  UserPostServices().deletePost(post['postId']);
                  setState(() {});
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchUserPosts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Error fetching posts.'));
        }

        final userPosts = snapshot.data ?? [];

        return userPosts.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 50),
                    Text('🚫', style: TextStyle(fontSize: 50)),
                    Text('No posts available'),
                  ],
                ),
              )
            : GridView.builder(
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
                          builder: (context) => PostDetailScreen(
                            postId: post['postId'],
                            username: widget.userId,
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
                                child: Image.network(
                                  post['locationImages']?.isNotEmpty == true
                                      ? post['locationImages'][0]
                                      : 'https://res.cloudinary.com/dakew8wni/image/upload/v1734019072/public/postimages/mwtjtugc4ppu02vwiv49.png',
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
                                      color:
                                          Colors.black, // Ensuring color is set
                                      height:
                                          1.2, // Adjust line height to control spacing
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

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/loading.dart';
import '../chat_&_group/chatScreen/chating_screen.dart';
import '../followersScreen/followers_screen.dart';
import 'post&trip/post&trip/other_user_posts.dart';
import 'post&trip/post&trip/other_user_tripimage.dart';
import 'report_screen.dart';

class OtherProfilePage extends StatefulWidget {
  final String userId;
  const OtherProfilePage({super.key, required this.userId});

  @override
  OtherProfilePageState createState() => OtherProfilePageState();
}

class OtherProfilePageState extends State<OtherProfilePage> {
  bool showPosts = true;
  int totalPosts = 0;
  int completedPosts = 0;
  String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool isFollowing = false;
  int followersCount = 0;

  void _reloadChats() {}

  Future<void> _getFollowersCount() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('user')
          .doc(widget.userId)
          .get();

      final followersList = userDoc.data()?['following'] ?? [];
      setState(() {
        followersCount = followersList.length;
      });
    } catch (e) {
      print('Error fetching followers count: $e');
    }
  }

  Future<String> _getOrCreateChatRoom() async {
    try {
      final chatQuery = await FirebaseFirestore.instance
          .collection('chat')
          .where('user', arrayContains: currentUserId)
          .get();
      for (var doc in chatQuery.docs) {
        final userIds = doc.data()['user'] as List<dynamic>? ?? [];
        if (userIds.contains(widget.userId)) {
          return doc.id;
        }
      }
      final newChatDoc =
          await FirebaseFirestore.instance.collection('chat').add({
        'user': [currentUserId, widget.userId],
        'latestMessage': '',
        'timestamp': FieldValue.serverTimestamp(),
      });

      return newChatDoc.id;
    } catch (error) {
      throw Exception('Error creating or retrieving chat room: $error');
    }
  }

  Future<void> _checkFollowingStatus() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('user')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        List<dynamic> followingList = userDoc['following'] ?? [];
        setState(() {
          isFollowing = followingList.contains(currentUserId);
        });
      }
    } catch (e) {
      print('Error checking following status: $e');
    }
  }

  Future<void> _toggleFollow() async {
    try {
      DocumentReference userDocRef =
          FirebaseFirestore.instance.collection('user').doc(widget.userId);

      if (isFollowing) {
        await userDocRef.update({
          'following': FieldValue.arrayRemove([currentUserId]),
        });
        setState(() {
          isFollowing = false;
          followersCount = followersCount - 1;
        });
      } else {
        await userDocRef.update({
          'following': FieldValue.arrayUnion([currentUserId]),
        });
        setState(() {
          isFollowing = true;
          followersCount = followersCount + 1;
        });
      }
    } catch (e) {
      print('Error toggling follow status: $e');
    }
  }

  Future<void> _getUserProfilePosts() async {
    try {
      String currentUserId = widget.userId;
      QuerySnapshot userPostsSnapshot = await FirebaseFirestore.instance
          .collection('post')
          .where('userid', isEqualTo: currentUserId)
          .get();

      List<QueryDocumentSnapshot> userPosts = userPostsSnapshot.docs;

      setState(() {
        totalPosts = userPosts.length;
        completedPosts =
            userPosts.where((doc) => doc['tripCompleted'] == true).length;
      });
    } catch (e) {
      print('Error fetching user posts: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _getUserProfilePosts();
    _checkFollowingStatus();
    _getFollowersCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile..'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'Report') {
                showDialog(
                  context: context,
                  builder: (context) => ReportDialog(
                    userId: widget.userId,
                    currentUserId: currentUserId,
                  ),
                );
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'Report',
                  child: Text('Report'),
                ),
              ];
            },
            icon: const Icon(Icons.more_vert),
            offset: const Offset(0, 50),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('user')
            .doc(widget.userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Stack(
              children: [
                Positioned(
                  left: 0.0,
                  top: 0.0,
                  right: 0.0,
                  bottom: 0.0,
                  child: Center(child: LoadingAnimation()),
                ),
              ],
            );
          } else if (snapshot.hasError) {
            return const Center(child: Text("Error loading profile data"));
          } else if (snapshot.hasData) {
            final profileData = snapshot.data?.data();
            var userImage = profileData!['userimage'];
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return Dialog(
                                  backgroundColor: Colors.transparent,
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.of(context)
                                          .pop(); // Close the dialog on tap
                                    },
                                    child: InteractiveViewer(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: AppColors.genderBorderColor(
                                                profileData['gender'] ??
                                                    ''), // Use gender to determine border color
                                            width: 1.0, // Set border width
                                          ),
                                          borderRadius: BorderRadius.circular(
                                              8.0), // Optional: Rounded corners
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                              8.0), // Match border radius
                                          child: CachedNetworkImage(
                                            imageUrl:
                                                userImage, // URL of the image
                                            placeholder: (context, url) =>
                                                const LoadingAnimation(), // Placeholder widget while loading
                                            errorWidget: (context, url,
                                                    error) =>
                                                const Icon(Icons
                                                    .error), // Fallback error widget if loading fails
                                            fit: BoxFit
                                                .cover, // Adjust the image size to cover the available space
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.genderBorderColor(
                                    profileData['gender'] ??
                                        ''), // Dynamically set border color
                                width: 2, // Border width
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 30,
                              backgroundImage: CachedNetworkImageProvider(
                                  userImage), // Use NetworkImage instead of AssetImage
                              backgroundColor: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              FollowingUsersPage(
                                                  userId: widget.userId),
                                        ),
                                      );
                                    },
                                    child: Material(
                                      color: Colors.transparent,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            '$followersCount',
                                            style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const Text(
                                            'Buddies',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 30),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        '$totalPosts',
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Text(
                                        'Posts',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 30),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        '$completedPosts',
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Text(
                                        'Completed',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profileData['fullname'],
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        // const SizedBox(height: 8),
                        // Text('DOB: ${profileData['dob']}'),
                        // const SizedBox(height: 8),
                        //  Text('Gender: ${profileData['gender']}'),
                        const SizedBox(height: 8),
                        Text(profileData['userbio'] ?? '',
                            style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if ((profileData['instagram']?.isNotEmpty ?? false))
                        IconButton(
                          onPressed: () {
                            final instagramLink = profileData['instagram'];
                            launchUrl(Uri.parse(instagramLink));
                          },
                          icon: const FaIcon(
                            FontAwesomeIcons.instagram,
                            color: Colors.purple,
                            size: 15,
                          ),
                          tooltip: 'Instagram',
                        ),
                      if ((profileData['instagram']?.isNotEmpty ?? false))
                        const SizedBox(width: 6),
                      if ((profileData['x']?.isNotEmpty ?? false))
                        IconButton(
                          onPressed: () {
                            final twitterLink = profileData['x'];
                            launchUrl(Uri.parse(twitterLink));
                          },
                          icon: const FaIcon(
                            FontAwesomeIcons.x,
                            color: Color.fromARGB(255, 0, 0, 0),
                            size: 15,
                          ),
                          tooltip: 'X',
                        ),
                      if ((profileData['x']?.isNotEmpty ?? false))
                        const SizedBox(width: 6),
                      if ((profileData['facebook']?.isNotEmpty ?? false))
                        IconButton(
                          onPressed: () {
                            final facebookLink = profileData['facebook'];
                            launchUrl(Uri.parse(facebookLink));
                          },
                          icon: const FaIcon(
                            FontAwesomeIcons.facebook,
                            color: Colors.blue,
                            size: 15,
                          ),
                          tooltip: 'Facebook',
                        ),
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.95,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.45,
                                child: ElevatedButton(
                                  onPressed: _toggleFollow,
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.black,
                                    backgroundColor: Colors.white,
                                    side: const BorderSide(
                                      color: Colors.black,
                                      width: 0.3,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                  child: Text(
                                      isFollowing ? "Following" : "Follow"),
                                ),
                              ),
                              const SizedBox(width: 5),
                              // Settings button
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.45,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    try {
                                      final chatRoomId =
                                          await _getOrCreateChatRoom();
                                      if (!context.mounted) return;
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ChatScreen(
                                            currentUserId: currentUserId,
                                            chatUserId: widget.userId,
                                            chatRoomId: chatRoomId,
                                            onMessageSent: _reloadChats,
                                          ),
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(content: Text('Error: $e')),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.black,
                                    backgroundColor: Colors.white,
                                    side: const BorderSide(
                                      color: Colors.black,
                                      width: 0.3,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                  child: const Text("Message"),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  showPosts = true;
                                });
                              },
                              icon: const Icon(
                                Icons.grid_on,
                                color: Colors.black,
                              ),
                              label: const Text(
                                'Posts',
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                            if (showPosts)
                              Container(
                                height: 2,
                                width: 50,
                                color: Colors.blue,
                              ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Column(
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  showPosts = false;
                                });
                              },
                              icon: const Icon(
                                Icons.photo_album,
                                color: Colors.black,
                              ),
                              label: const Text(
                                'Trip Images',
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                            if (!showPosts)
                              Container(
                                height: 2,
                                width: 50,
                                color: Colors.black,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (showPosts)
                    UserPostsWidget(userId: widget.userId)
                  else
                    UserTripImagesWidget(userId: widget.userId)
                ],
              ),
            );
          } else {
            return const Text("No data available");
          }
        },
      ),
    );
  }
}

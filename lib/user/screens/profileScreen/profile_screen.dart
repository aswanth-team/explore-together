import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/loading.dart';
import '../followersScreen/followers_screen.dart';
import '../homeScreen/notification_sceen.dart';
import '../uploadScreen/post_upload.dart';
import '../uploadScreen/trip_upload.dart';
import 'edit_profile_screen.dart';
import 'post&trip/current_user_posts.dart';
import 'post&trip/current_user_tripimage.dart';
import 'settingScreen/settings_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool showPosts = true;
  int totalPosts = 0;
  int completedPosts = 0;
  int followersCount = 0;

  Future<void> _getFollowersCount() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('user')
          .doc(currentUserId)
          .get();

      final followersList = userDoc.data()?['following'] ?? [];
      setState(() {
        followersCount = followersList.length;
      });
    } catch (e) {
      print('Error fetching followers count: $e');
    }
  }

  Future<void> _getUserProfilePosts() async {
    try {
      String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
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
    _getFollowersCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('user')
                .doc(currentUserId)
                .collection('notifications')
                .where('isSeen', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              int unseenCount = 0;

              if (snapshot.hasData) {
                unseenCount = snapshot.data!.docs.length;
              }

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications,
                      size: 27.0,
                      color: Colors.blueGrey,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsPage(),
                        ),
                      );
                    },
                  ),
                  if (unseenCount > 0)
                    Positioned(
                      right: 14,
                      top: 13,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 10,
                          minHeight: 10,
                        ),
                        child: Text(
                          '$unseenCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 5,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('user')
            .doc(FirebaseAuth.instance.currentUser?.uid)
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
            print(profileData);
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
                                    profileData['gender'] ?? ''),
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 30,
                              backgroundImage:
                                  CachedNetworkImageProvider(userImage),
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
                                                  userId: currentUserId),
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
                                    mainAxisAlignment: MainAxisAlignment
                                        .center, // Center the content vertically in the column
                                    crossAxisAlignment: CrossAxisAlignment
                                        .center, // Align content to the center horizontally
                                    children: [
                                      Text(
                                        '$totalPosts', // The count (number) at the top
                                        style: const TextStyle(
                                          fontSize:
                                              22, // Larger font size for the count
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Text(
                                        'Posts', // Label below the count
                                        style: TextStyle(
                                          fontSize:
                                              12, // Smaller font size for the label
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(width: 30),

                                  // Column for "Completed"
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment
                                        .center, // Center the content vertically in the column
                                    crossAxisAlignment: CrossAxisAlignment
                                        .center, // Align content to the center horizontally
                                    children: [
                                      Text(
                                        '$completedPosts', // The count (number) at the top
                                        style: const TextStyle(
                                          fontSize:
                                              22, // Larger font size for the count
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Text(
                                        'Completed', // Label below the count
                                        style: TextStyle(
                                          fontSize:
                                              12, // Smaller font size for the label
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
                  // User Details
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
                        const SizedBox(height: 8),
                        //Text('DOB: ${profileData['dob']}'),
                        // const SizedBox(height: 8),
                        // Text('Gender: ${profileData['gender']}'),
                        // const SizedBox(height: 16),
                        Text(profileData['userbio'] ?? '',
                            style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Instagram Icon
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

                      // Twitter (X) Icon
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

                      // Facebook Icon
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
                        // Create a container to wrap the buttons and set its width to 95% of the device width
                        SizedBox(
                          width: MediaQuery.of(context).size.width *
                              0.95, // 95% of the device width
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Edit Profile button
                              SizedBox(
                                width: MediaQuery.of(context).size.width *
                                    0.45, // 45% of the width for each button
                                child: ElevatedButton(
                                  onPressed: () {
                                    final userId =
                                        FirebaseAuth.instance.currentUser?.uid;

                                    if (userId != null) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                EditProfileScreen(
                                                    uuid: userId)),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.black,
                                    backgroundColor: Colors
                                        .white, // Set background color to white
                                    side: const BorderSide(
                                      color: Colors.black,
                                      width:
                                          0.3, // Decreased the border width to 1
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          5), // Decreased border radius
                                    ),
                                  ),
                                  child: const Text("Edit Profile"),
                                ),
                              ),
                              const SizedBox(
                                  width: 5), // Add spacing between the buttons
                              // Settings button
                              SizedBox(
                                width: MediaQuery.of(context).size.width *
                                    0.45, // 45% of the width for each button
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Navigate to the settings page when the button is pressed
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => SettingsPage()),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.black,
                                    backgroundColor: Colors
                                        .white, // Set background color to white
                                    side: const BorderSide(
                                      color: Colors.black,
                                      width:
                                          0.3, // Decreased the border width to 1
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          5), // Decreased border radius
                                    ),
                                  ),
                                  child: const Text("Settings"),
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
                        // Trip button with underline effect
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
                                color: Colors
                                    .black, // Set the color of the icon to black
                              ),
                              label: const Text(
                                'Trip Images',
                                style: TextStyle(
                                    color: Colors
                                        .black), // Set the color of the text to black
                              ),
                            ),

                            // Underline when Trip Images is selected
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
                    UserPostsWidget(
                        userId: FirebaseAuth.instance.currentUser!.uid),
                  if (!showPosts)
                    UserTripImagesWidget(
                        userId: FirebaseAuth.instance.currentUser!.uid),
                  const SizedBox(height: 10),
                ],
              ),
            );
          } else {
            return const Text("No data available"); // Handle the no-data case
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (BuildContext context) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 4,
                      width: 40,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.post_add, color: Colors.blue),
                      title: const Text("Post",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w500)),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const PostUploader()),
                        );
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.image, color: Colors.green),
                      title: const Text("Uplaod Image",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w500)),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ImageUploader()),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
        backgroundColor: Colors.blue,
        mini: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

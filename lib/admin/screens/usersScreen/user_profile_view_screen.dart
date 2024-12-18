//inspect view of user profile

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/loading.dart';
import '../messageScreen/sent_message_screen.dart';
import 'adminViewPost&trip/current_user_posts.dart';
import 'adminViewPost&trip/current_user_tripimage.dart';

class OtherProfilePageForAdmin extends StatefulWidget {
  final String userId;
  const OtherProfilePageForAdmin({super.key, required this.userId});

  @override
  OtherProfilePageStateForAdmin createState() =>
      OtherProfilePageStateForAdmin();
}

class OtherProfilePageStateForAdmin extends State<OtherProfilePageForAdmin> {
  bool showPosts = true;
  int totalPosts = 0;
  int completedPosts = 0;

  Future<void> _getUserProfilePosts() async {
    try {
      String userId = widget.userId;
      QuerySnapshot userPostsSnapshot = await FirebaseFirestore.instance
          .collection('post')
          .where('userid', isEqualTo: userId)
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile..'),
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
                                                CircularProgressIndicator(), // Placeholder widget while loading
                                            errorWidget: (context, url,
                                                    error) =>
                                                Icon(Icons
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
                              backgroundImage: NetworkImage(userImage),
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
                                mainAxisAlignment: MainAxisAlignment
                                    .center, // Center the row content
                                children: [
                                  // Column for "Posts"
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
                                              24, // Larger font size for the count
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

                                  const SizedBox(width: 60),

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
                                              24, // Larger font size for the count
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
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('DOB: ${profileData['dob']}'),
                        const SizedBox(height: 8),
                        Text('Gender: ${profileData['gender']}'),
                        const SizedBox(height: 16),
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
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SentMessagePage(
                                          userNameFromPreviousPage:
                                              profileData['username'],
                                          disableSendToAll:
                                              true, // Disable the switch
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors
                                        .greenAccent, // Set background color to white
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
                                  child: const Text("Notify"),
                                ),
                              ),
                              const SizedBox(
                                  width: 5), // Add spacing between the buttons
                              // Settings button
                              SizedBox(
                                width: MediaQuery.of(context).size.width *
                                    0.45, // 45% of the width for each button
                                child: ElevatedButton(
                                  onPressed: () async {
                                    // Toggle the 'isRemoved' status in Firestore
                                    bool currentStatus =
                                        profileData['isRemoved'] ?? false;
                                    await FirebaseFirestore.instance
                                        .collection('user')
                                        .doc(widget.userId)
                                        .update({'isRemoved': !currentStatus});

                                    setState(
                                        () {}); // Refresh the UI after the update
                                  },
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: (profileData[
                                                'isRemoved'] ??
                                            false)
                                        ? Colors.greenAccent
                                        : Colors
                                            .redAccent, // Change color dynamically
                                    side: const BorderSide(
                                      color: Colors.black,
                                      width: 0.3, // Border width
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          5), // Decreased border radius
                                    ),
                                  ),
                                  child: Text(
                                    (profileData['isRemoved'] ?? false)
                                        ? "Add"
                                        : "Remove", // Dynamic button text
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
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

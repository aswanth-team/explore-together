import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../data/users.dart';
import 'post_details_screen.dart';

void main() => runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: UsersProfilePage(username: 'aswanth123'), // Pass the username here
    ));

class UsersProfilePage extends StatefulWidget {
  final String username;

  UsersProfilePage({required this.username});

  @override
  _UsersProfilePageState createState() => _UsersProfilePageState();
}

class _UsersProfilePageState extends State<UsersProfilePage> {
  bool showPosts = true; // Initially, show posts

  /// Fetches user data based on the username
  Map<String, dynamic>? getUserData() {
    try {
      return users.firstWhere((user) => user['userName'] == widget.username);
    } catch (e) {
      return null; // Handle the case where no user is found
    }
  }

  @override
  Widget build(BuildContext context) {
    final userData = getUserData();

    if (userData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('User Profile')),
        body: const Center(
          child: Text('User not found!'),
        ),
        backgroundColor: Color.fromRGBO(255, 175, 175, 1),
      );
    }

    Color getBorderColor(String gender) {
      if (gender.toLowerCase() == "male") {
        return Colors.lightBlue;
      } else if (gender.toLowerCase() == "female") {
        return Colors.pinkAccent.shade100;
      } else {
        return Colors.yellow.shade600;
      }
    }

    final List<dynamic> userPosts = userData['userPosts'] ?? [];
    final List<dynamic> tripPhotos = userData['tripPhotos'] ?? [];

    // Count completed and total posts
    int totalPosts = userPosts.length;
    int completedPosts =
        userPosts.where((post) => post['tripCompleted']).length;

    String userImage =
        userData['userImage'] ?? 'assets/defaults/defaultUserImage.jpeg';

    return Scaffold(
      appBar: AppBar(
        title: Text(userData['userName']),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section: User Image and Post Counts
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      // Open the full-screen image in a dialog
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
                                      color: getBorderColor(userData[
                                              'userGender'] ??
                                          ''), // Use gender to determine border color
                                      width: 1.0, // Set border width
                                    ),
                                    borderRadius: BorderRadius.circular(
                                        8.0), // Optional: Rounded corners
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                        8.0), // Match border radius
                                    child: Image.asset(
                                      userImage,
                                      fit: BoxFit.cover,
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
                          color: getBorderColor(userData['userGender'] ??
                              ''), // Dynamically set border color
                          width: 2, // Border width
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundImage: AssetImage(userImage),
                        backgroundColor: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
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
                                Text(
                                  'Posts', // Label below the count
                                  style: const TextStyle(
                                    fontSize:
                                        12, // Smaller font size for the label
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(
                                width:
                                    60), // Reduced space between "Posts" and "Completed"

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
                                Text(
                                  'Completed', // Label below the count
                                  style: const TextStyle(
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
            // Below Section: Full Name, DOB, Gender, Bio, Chat Button, Social Links
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${userData['userFullName']}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'DOB: ${userData['userDOB']}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Gender: ${userData['userGender']}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${userData['userBio'] ?? ''}',
                    overflow: TextOverflow.ellipsis,
                    maxLines:
                        3, // Allow bio to break onto the next line if too long
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),

                  // Social Links Row
                  // Social Links Row
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center, // Center align the row
                    children: [
                      // Instagram Icon
                      if (userData['userSocialLinks']['instagram']
                              ?.isNotEmpty ??
                          false)
                        IconButton(
                          onPressed: () {
                            final instagramLink =
                                userData['userSocialLinks']['instagram'];
                            launchUrl(Uri.parse(instagramLink));
                          },
                          icon: FaIcon(
                            FontAwesomeIcons.instagram,
                            color: Colors.purple,
                            size: 15, // Adjust size as needed
                          ),
                          tooltip: 'Instagram',
                        ),
                      if (userData['userSocialLinks']['instagram']
                              ?.isNotEmpty ??
                          false)
                        const SizedBox(width: 6),

                      // Twitter (X) Icon
                      if (userData['userSocialLinks']['twitter']?.isNotEmpty ??
                          false)
                        IconButton(
                          onPressed: () {
                            final twitterLink =
                                userData['userSocialLinks']['twitter'];
                            launchUrl(Uri.parse(twitterLink));
                          },
                          icon: FaIcon(
                            FontAwesomeIcons.x, // Icon for Twitter (X)
                            color: const Color.fromARGB(255, 0, 0, 0),
                            size: 15, // Adjust size as needed
                          ),
                          tooltip: 'Twitter',
                        ),
                      if (userData['userSocialLinks']['twitter']?.isNotEmpty ??
                          false)
                        const SizedBox(width: 6),

                      // Gmail Icon
                      if (userData['userSocialLinks']['gmail']?.isNotEmpty ??
                          false)
                        IconButton(
                          onPressed: () {
                            final gmailLink =
                                userData['userSocialLinks']['gmail'];
                            launchUrl(Uri(
                              scheme: 'mailto',
                              path: gmailLink,
                            ));
                          },
                          icon: FaIcon(
                            FontAwesomeIcons.envelope,
                            color: Colors.red,
                            size: 15, // Adjust size as needed
                          ),
                          tooltip: 'Gmail',
                        ),
                      if (userData['userSocialLinks']['gmail']?.isNotEmpty ??
                          false)
                        const SizedBox(width: 6),

                      // Facebook Icon
                      if (userData['userSocialLinks']['facebook']?.isNotEmpty ??
                          false)
                        IconButton(
                          onPressed: () {
                            final facebookLink =
                                userData['userSocialLinks']['facebook'];
                            launchUrl(Uri.parse(facebookLink));
                          },
                          icon: FaIcon(
                            FontAwesomeIcons.facebook,
                            color: Colors.blue,
                            size: 15, // Adjust size as needed
                          ),
                          tooltip: 'Facebook',
                        ),
                    ],
                  ),

                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment
                        .center, // Center the button horizontally
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.green,
                          minimumSize: Size(
                              200, 50), // Set the text and icon color to white
                          side: BorderSide(color: Colors.black, width: 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                8), // Decrease the border radius
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ChatPage(username: userData['userName']),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center, // Align text and icon
                          children: [
                            Icon(Icons.chat,
                                color: Colors.white), // Chat icon in white
                            SizedBox(width: 8), // Space between icon and text
                            Text('Chat',
                                style: TextStyle(
                                    color: Colors.white)), // Text in white
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Posts and Trip Image Toggle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Post button with underline effect
                  Column(
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            showPosts = true;
                          });
                        },
                        icon: const Icon(Icons.grid_on),
                        label: const Text('Posts'),
                      ),
                      // Underline when Posts is selected
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
                        icon: const Icon(Icons.photo_album),
                        label: const Text('Trip Images'),
                      ),
                      // Underline when Trip Images is selected
                      if (!showPosts)
                        Container(
                          height: 2,
                          width: 50,
                          color: Colors.blue,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Display Posts or Trip Images
            if (showPosts)
              Column(
                children: [
                  // Show Posts Section
                  if (userPosts.isEmpty)
                    const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Larger emoji 🚫
                          Text(
                            '🚫',
                            style: TextStyle(
                              fontSize: 50, // Increase the size of the emoji
                            ),
                          ),
                          // Text below the emoji
                          Text(
                            'No posts available',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3, // Number of items per row
                        crossAxisSpacing: 4, // Horizontal space between items
                        mainAxisSpacing: 4, // Vertical space between items
                        childAspectRatio:
                            0.80, // Increase this value to make the grid items taller
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
                                  username: userData['userName'],
                                ),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: (post['tripCompleted'] ?? false)
                                  ? Colors.green[100]
                                  : Colors.white,
                              border: Border.all(
                                color: Colors.grey, // Border color
                                width: 0.5, // Border width
                              ),
                              borderRadius: BorderRadius.circular(
                                  12), // Match the image's corner radius
                              boxShadow: [
                                BoxShadow(
                                  color: const Color.fromARGB(
                                          255, 138, 222, 255)
                                      .withOpacity(
                                          0.1), // Shadow color with transparency
                                  spreadRadius: 2, // Spread radius
                                  blurRadius: 5, // Blur radius
                                  offset:
                                      Offset(0, 3), // Shadow position (x, y)
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Image at the top
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                      12), // Match the container's radius
                                  child: Image.asset(
                                    post['locationImages'][0],
                                    fit: BoxFit.cover,
                                    height:
                                        100, // Set a fixed height for the image
                                    width: double.infinity,
                                  ),
                                ),

                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Center(
                                        child: Text(
                                          post['tripLocation'],
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      //Text(
                                      //'Completed: ${(post['tripCompleted'] ?? false) ? '✔️' : '❌'}',
                                      //  style: TextStyle(
                                      //    fontSize:
                                      //         12, // Font size for "Completed"
                                      //   ),
                                      // ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                ],
              )
            else
              // Show Trip Images Section
              Column(
                children: [
                  if (tripPhotos.isEmpty)
                    const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '🚫',
                            style: TextStyle(
                              fontSize: 50, // Increase the size of the emoji
                            ),
                          ),
                          Text(
                            'No trip images available',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: tripPhotos.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            // Show the overlay with the clicked image
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return Dialog(
                                  backgroundColor: Colors.transparent,
                                  child: Stack(
                                    children: [
                                      Center(
                                        child: Image.asset(
                                          tripPhotos[index],
                                          fit: BoxFit
                                              .contain, // Ensure the image maintains its aspect ratio
                                          width:
                                              MediaQuery.of(context).size.width,
                                          height: MediaQuery.of(context)
                                              .size
                                              .height,
                                        ),
                                      ),
                                      Positioned(
                                        top:
                                            5, // Position the X a bit above the image
                                        right: 5, // Right side position
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.of(context)
                                                .pop(); // Close the dialog
                                          },
                                          child: Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size:
                                                40, // Increase size for better visibility
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                          child: Image.asset(
                            tripPhotos[index],
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class ChatPage extends StatelessWidget {
  final String username;

  ChatPage({required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with $username'),
      ),
      body: Center(
        child: Text('Chat Page for $username'),
      ),
    );
  }
}

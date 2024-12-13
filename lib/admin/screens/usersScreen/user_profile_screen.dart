import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../data/removedusers.dart';
import '../../../data/users.dart';
import '../messageScreen/sent_message_screen.dart';
import 'postScreen/post_dettails_screen.dart';

// ignore: must_be_immutable
class UserProfilePage extends StatefulWidget {
  final String username;

  bool isRemoved;

  UserProfilePage({required this.username, required this.isRemoved});

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool showPosts = true; // Initially, show posts

  /// Fetches user data based on the username
  Map<String, dynamic>? getUserData() {
    try {
      // First, try to find the user in the `users` list
      return users.firstWhere((user) => user['userName'] == widget.username);
    } catch (e) {
      // If not found in `users`, look in `removedusers`
      try {
        return removedusers
            .firstWhere((user) => user['userName'] == widget.username);
      } catch (e) {
        return null; // Handle the case where no user is found in either list
      }
    }
  }

  void removeUser(String userName) {
    setState(() {
      final user = users.firstWhere(
        (user) => user['userName'] == userName,
        orElse: () => {},
      );
      if (user.isNotEmpty) {
        print("Removing user: $userName");
        users.remove(user);
        removedusers.add(user);
        widget.isRemoved = true; // Update the isRemoved state
      }
    });
  }

  void addUser(String userName) {
    setState(() {
      final user = removedusers.firstWhere(
        (user) => user['userName'] == userName,
        orElse: () => {},
      );
      if (user.isNotEmpty) {
        print("Adding user: $userName");
        removedusers.remove(user);
        users.add(user);
        widget.isRemoved = false; // Update the isRemoved state
      }
    });
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

    void deletePost(String postId, String username) {
      print("username : $username postId : $postId");
      // Remove post from the UI
      setState(() {
        userPosts.removeWhere((post) => post['postId'] == postId);
      });
    }

    void deleteTripPhoto(String photoPath, String username, int index) {
      // Remove the photo from the UI
      setState(() {
        tripPhotos.remove(photoPath);
      });

      // Call your backend function to delete the photo from the database
      // Your function to delete the trip photo from the database goes here
      print('Deleted trip photo: $photoPath by $username in $index');
    }

    String userImage =
        userData['userImage'] ?? 'assets/defaults/defaultUserImage.jpeg';

    // Count completed and total posts
    int totalPosts = userPosts.length;
    int completedPosts =
        userPosts.where((post) => post['tripCompleted']).length;

    return Scaffold(
      backgroundColor: widget.isRemoved
          ? Colors.red.shade100 // If the widget is removed, use red shade
          : userData['userGender']?.toLowerCase() == 'female'
              ? Color.fromRGBO(254, 244, 255, 1) // Pinkish color for female
              : userData['userGender']?.toLowerCase() == 'male'
                  ? Color.fromRGBO(
                      220, 240, 255, 1) // Light blue color for male
                  : const Color.fromARGB(255, 242, 255,
                      255), // Default color if not female or male
      // Default color if not female or male
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

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            final userData = getUserData();
                            if (userData != null) {
                              if (widget.isRemoved) {
                                addUser(userData['userName']);
                              } else {
                                removeUser(userData['userName']);
                              }
                            }
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.isRemoved
                              ? Colors.green
                              : Colors.red, // Green for Add, Red for Remove
                          foregroundColor:
                              Colors.white, // Text and icon color white
                          side: BorderSide(
                            color: Colors.black,
                            width: 0.3, // Optional: Keep borders consistent
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                5), // Consistent border radius
                          ),
                        ),
                        child: Row(
                          mainAxisSize:
                              MainAxisSize.min, // Adjusts size to fit content
                          mainAxisAlignment:
                              MainAxisAlignment.center, // Centers text and icon
                          children: [
                            Icon(
                              widget.isRemoved
                                  ? Icons.add
                                  : Icons.remove, // Add or Remove icon
                              color: Colors.white, // Icon color white
                            ),
                            SizedBox(width: 8), // Space between icon and text
                            Text(
                              widget.isRemoved
                                  ? "Add"
                                  : "Remove", // Dynamic text
                              style: const TextStyle(
                                  color: Colors.white), // Text color white
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Create a container to wrap the buttons and set its width to 95% of the device width
                  Container(
                    width: MediaQuery.of(context).size.width *
                        0.95, // 95% of the device width
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Edit Profile button
                        Container(
                          width: MediaQuery.of(context).size.width *
                              0.45, // 45% of the width for each button
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.black,
                              backgroundColor:
                                  Colors.white, // Set background color to white
                              side: BorderSide(
                                color: Colors.black,
                                width: 0.3, // Decreased the border width to 1
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    5), // Decreased border radius
                              ),
                            ),
                            child: const Text("chat"),
                          ),
                        ),
                        const SizedBox(
                            width: 5), // Add spacing between the buttons
                        // Settings button
                        Container(
                          width: MediaQuery.of(context).size.width *
                              0.45, // 45% of the width for each button
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SentMessagePage(
                                    userNameFromPreviousPage:
                                        userData['userName'],
                                    disableSendToAll:
                                        true, // Disable the switch
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors
                                  .green, // Set button background color to green
                              foregroundColor: Colors
                                  .white, // Set text and icon color to white
                              side: BorderSide(
                                color: Colors.black,
                                width: 0.3, // Decreased border width
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    5), // Decreased border radius
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment
                                  .center, // Center text and icon
                              children: [
                                Icon(Icons.message,
                                    color: Colors.white), // Icon in white
                                SizedBox(
                                    width: 8), // Space between icon and text
                                Text("Notify",
                                    style: TextStyle(
                                        color: Colors.white)), // Text in white
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
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
                          SizedBox(
                            height: 50,
                          ),
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
                                  borderRadius: BorderRadius.circular(12),
                                  child: Stack(
                                    children: [
                                      Image.asset(
                                        post['locationImages'][0],
                                        fit: BoxFit.cover,
                                        height: 100,
                                        width: double.infinity,
                                      ),
                                      // Three-dot menu in top right corner
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                                0.2), // Semi-transparent background
                                            borderRadius: BorderRadius.circular(
                                                20), // Rounded corners for the container
                                          ),
                                          child: PopupMenuButton<String>(
                                            icon: Icon(
                                              Icons.more_vert,
                                              color: Colors
                                                  .black, // Icon color set to black for contrast
                                            ),
                                            onSelected: (value) {
                                              if (value == 'delete') {
                                                deletePost(post['postId'],
                                                    userData['userName']);
                                              }
                                            },
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(
                                                  6), // Rounded corners for the menu
                                            ),
                                            color: Colors.grey[
                                                800], // Dark background for the menu
                                            elevation:
                                                6, // Slight shadow effect for the menu
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical:
                                                    10), // Padding for menu items
                                            itemBuilder:
                                                (BuildContext context) => [
                                              PopupMenuItem<String>(
                                                value: 'delete',
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.delete,
                                                      color: Colors
                                                          .red, // Red color for delete option
                                                    ),
                                                    SizedBox(
                                                        width:
                                                            8), // Space between the icon and text
                                                    Text(
                                                      'Delete',
                                                      style: TextStyle(
                                                        color: Colors
                                                            .white, // White text for better contrast
                                                        fontWeight: FontWeight
                                                            .bold, // Bold text for emphasis
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
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
                          SizedBox(
                            height: 50,
                          ),
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
                        crossAxisCount: 3, // Three images per row
                        crossAxisSpacing: 8, // Horizontal space between items
                        mainAxisSpacing: 8, // Vertical space between items
                      ),
                      itemCount: tripPhotos.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            // Show the image in a dialog when clicked
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
                                              .contain, // Ensures full image fits without cropping
                                          width:
                                              MediaQuery.of(context).size.width,
                                          height: MediaQuery.of(context)
                                              .size
                                              .height,
                                        ),
                                      ),
                                      Positioned(
                                        top: 5,
                                        right: 5,
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 40,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                          child: Stack(
                            children: [
                              // Here we set BoxFit.cover to zoom the image to fill the grid cell
                              Image.asset(
                                tripPhotos[index],
                                fit: BoxFit
                                    .cover, // Ensures image fills the grid space, zooming if needed
                                width: double
                                    .infinity, // Makes image stretch to fit the container width
                                height: double
                                    .infinity, // Makes image stretch to fit the container height
                              ),
                              // Three-dot menu for delete option
                              Positioned(
                                top: 5,
                                right: 5,
                                child: PopupMenuButton<String>(
                                  icon: Icon(Icons.more_vert,
                                      color: Colors
                                          .white), // Icon color set to white
                                  onSelected: (value) {
                                    if (value == 'delete') {
                                      // Call function to delete the trip photo from the UI and DB
                                      deleteTripPhoto(tripPhotos[index],
                                          userData['userName'], index);
                                    }
                                  },
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        8.0), // Rounded corners for the menu
                                  ),
                                  color: Colors.grey[
                                      800], // Background color for the menu
                                  elevation: 8, // Shadow for a raised effect
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8), // Padding for items
                                  itemBuilder: (BuildContext context) => [
                                    PopupMenuItem<String>(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete,
                                              color: Colors
                                                  .red), // Icon with red color for delete action
                                          SizedBox(
                                              width:
                                                  8), // Space between icon and text
                                          Text(
                                            'Delete',
                                            style: TextStyle(
                                              color: Colors
                                                  .white, // Text color set to white
                                              fontWeight:
                                                  FontWeight.bold, // Bold text
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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

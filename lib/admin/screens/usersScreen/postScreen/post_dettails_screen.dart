import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../../../data/removedusers.dart';
import '../../../../data/users.dart';
import '../user_profile_screen.dart';

void main() => runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: PostDetailScreen(
      username: 'aswanth123',
      postId: '1',
    ) // Pass the username here
    ));

class PostDetailScreen extends StatefulWidget {
  final String username; // Username passed as a parameter
  final String postId; // Post ID passed as a parameter

  PostDetailScreen({
    required this.username,
    required this.postId,
  });

  @override
  _PostDetailScreenState createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  int currentIndex = 0;

  Map<String, dynamic>? getUserData(String username) {
    try {
      // First, search in the `users` list
      return users.firstWhere(
        (user) => user['userName'] == username,
      );
    } catch (e) {
      // If not found in `users`, search in `removedusers`
      try {
        return removedusers.firstWhere(
          (user) => user['userName'] == username,
        );
      } catch (e) {
        return null; // Return null if no user is found in either list
      }
    }
  }

  // Method to fetch user data by username
  //Map<String, dynamic>? getUserData(String username) {
  // try {
  //   return users.firstWhere(
  //    (user) => user['userName'] == username,
  //  );
  //} catch (e) {
  //  return null; // If no user is found, return null
  // }
  //}

  Map<String, dynamic>? getPostData(String username, String postId) {
    final user = getUserData(username);
    if (user != null) {
      try {
        return user['userPosts'].firstWhere(
          (post) => post['postId'] == postId,
        );
      } catch (e) {
        return null; // Return null if no match is found
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Fetch user and post data
    final String username = widget.username;
    final String postId = widget.postId;

    final user = getUserData(username);
    final post = getPostData(username, postId);

    // If user or post is not found, display an error
    if (user == null || post == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Post Detail'),
        ),
        body: Center(
          child: Text('User or Post not found!'),
        ),
      );
    }

    // Extract dynamic properties
    final isTripCompleted = post['tripCompleted'];
    final tripRating = post['tripRating'];
    final tripFeedback = post['tripFeedback'];
    final tripBuddies = post['tripBuddies'] ?? [];
    final locationImages = post['locationImages'] ?? [];
    final visitedPalaces = post['visitedPlaces'] ?? [];
    final planToVisitPlaces = post['planToVisitPlaces'];

    print("Location Images: $locationImages");

    return Scaffold(
      appBar: AppBar(
        title: Text('Post Details #$postId'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User info section
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      // Navigate to the UsersProfilePage when the image is tapped
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserProfilePage(
                            username: user['userName'],
                            isRemoved:
                                removedusers.contains(user), // Passing username
                          ),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      radius: 30.0,
                      backgroundImage: AssetImage(user['userImage']),
                    ),
                  ),
                  SizedBox(width: 10.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['userFullName'], // Display full name
                        style: TextStyle(
                            fontSize: 18.0, fontWeight: FontWeight.bold),
                      ),
                      Text('Gender: ${user['userGender']}'), // Display gender
                      // Optionally, you can add a display for the user's DOB here as well
                    ],
                  ),
                ],
              ),

              SizedBox(height: 16.0),

              Stack(
                children: [
                  // Display image based on the current index with rounded corners
                  Container(
                    height: 250.0,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                          15.0), // Adjust the radius as needed
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                          15.0), // Apply border radius to the image
                      child: Image.asset(
                        locationImages[
                            currentIndex], // Use currentIndex to load the correct image
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                  ),

                  // Left Arrow Button
                  if (currentIndex >
                      0) // Only show left arrow if not at the first image
                    Positioned(
                      left: 10.0,
                      top: 90.0,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            if (currentIndex > 0) {
                              currentIndex--;
                            }
                            print(
                                "Current index after left arrow: $currentIndex");
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 0, 0, 0)
                                .withOpacity(
                                    0.3), // Transparent black background
                            shape: BoxShape.circle, // Rounded shape
                          ),
                          child: Icon(Icons.arrow_left,
                              color: Colors.white, size: 30),
                        ),
                      ),
                    ),

                  // Right Arrow Button
                  if (currentIndex <
                      locationImages.length -
                          1) // Only show right arrow if not at the last image
                    Positioned(
                      right: 10.0,
                      top: 90.0,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            if (currentIndex < locationImages.length - 1) {
                              currentIndex++;
                            }
                            print(
                                "Current index after right arrow: $currentIndex");
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 0, 0, 0)
                                .withOpacity(
                                    0.3), // Transparent black background
                            shape: BoxShape.circle, // Rounded shape
                          ),
                          child: Icon(Icons.arrow_right,
                              color: Colors.white, size: 30),
                        ),
                      ),
                    ),
                ],
              ),

              SizedBox(height: 16.0),

              // Post details
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center, // Centers content horizontally
                crossAxisAlignment: CrossAxisAlignment
                    .center, // Centers content vertically (if needed)
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment
                        .center, // Centers content vertically in the column
                    crossAxisAlignment: CrossAxisAlignment
                        .center, // Centers content horizontally in the column
                    children: [
                      Text(
                        'Trip to ${post['tripLocation']}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8.0),
                      // Container ensures wrapping and centers content
                      Container(
                        width: MediaQuery.of(context).size.width *
                            0.8, // Limit width for wrapping
                        child: Text(
                          post['tripLocationDescription'],
                          textAlign: TextAlign
                              .center, // Ensures the text is centered horizontally
                          softWrap:
                              true, // Wrap the text to next line if it overflows
                          maxLines: 3, // Limit the number of lines
                          overflow: TextOverflow
                              .ellipsis, // Show ellipsis if text overflows
                          style: TextStyle(
                            fontSize: 10,
                          ),
                        ),
                      ),
                      SizedBox(height: 10.0),
                    ],
                  ),
                ],
              ),
              Divider(
                color: Colors.black, // Color of the line
                thickness: 2.0, // Thickness of the line
                indent: 20.0, // Space before the line
                endIndent: 20.0, // Space after the line
              ),
              SizedBox(height: 10.0),
              if (!isTripCompleted) ...[
                Center(
                  child: Text(
                    'Trip Duration Plan : ${post['tripDuration']} days',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 8.0),
                if (planToVisitPlaces.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            'Visiting Places Plan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 255, 200, 118),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            // Calculate the number of columns based on available width
                            final crossAxisCount = (constraints.maxWidth / 100)
                                .floor(); // Adjust 100 for cell width
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount:
                                    crossAxisCount > 0 ? crossAxisCount : 1,
                                crossAxisSpacing: 8.0,
                                mainAxisSpacing: 8.0,
                                childAspectRatio:
                                    2, // Adjust to decrease cell height
                              ),
                              itemCount: planToVisitPlaces.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  padding: const EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(
                                        255, 244, 255, 215),
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: Center(
                                    child: Text(
                                      planToVisitPlaces[index],
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign
                                          .center, // Optional for multiline text
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: 8.0),
              ],

              // Trip completion details
              if (isTripCompleted) ...[
                Container(
                  width:
                      double.infinity, // Makes the container take up full width
                  padding: EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment
                        .center, // Center align all children horizontally
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Trip Completed',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green),
                      ),
                      SizedBox(height: 8.0),
                      if (tripBuddies.isNotEmpty)
                        GridView.builder(
                          shrinkWrap: true,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3, // Two items in each row
                            crossAxisSpacing: 10.0,
                            mainAxisSpacing: 10.0,
                          ),
                          itemCount: tripBuddies.length,
                          itemBuilder: (context, index) {
                            final buddyUsername = tripBuddies[index];
                            final buddy = getUserData(
                                buddyUsername); // Get buddy user data

                            if (buddy == null) {
                              return Container(); // Handle missing user gracefully
                            }

                            // Convert gender to lowercase for consistent comparison
                            String gender = buddy['userGender'].toLowerCase();

                            // Determine grid background color based on gender
                            Color gridColor;
                            switch (gender) {
                              case 'male':
                                gridColor = const Color.fromARGB(
                                    255, 186, 224, 255); // Blue for male
                                break;
                              case 'female':
                                gridColor = const Color.fromARGB(255, 255, 224,
                                    252); // Rose (pink) for female
                                break;
                              default:
                                gridColor = const Color.fromARGB(255, 255, 253,
                                    237); // Yellow for other or unknown genders
                                break;
                            }

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UserProfilePage(
                                      username: buddy['userName'],
                                      isRemoved: removedusers.contains(user),
                                    ),
                                  ),
                                );
                              },
                              child: Card(
                                elevation: 5.0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                color:
                                    gridColor, // Set grid background color based on gender
                                child: Column(
                                  children: [
                                    SizedBox(
                                        height:
                                            20.0), // Add top padding to create space between image and grid
                                    CircleAvatar(
                                      radius: 25.0,
                                      backgroundImage:
                                          AssetImage(buddy['userImage']),
                                    ),
                                    SizedBox(width: 10.0),
                                    Expanded(
                                      child: Text(
                                        buddy['userName'],
                                        style: TextStyle(fontSize: 10),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      SizedBox(height: 15.0),
                      if (visitedPalaces.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Center(
                                child: Text(
                                  'Visited Places',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 255, 104, 16),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  // Calculate the number of columns based on available width
                                  final crossAxisCount =
                                      (constraints.maxWidth / 100)
                                          .floor(); // Adjust 100 for cell width
                                  return GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount > 0
                                          ? crossAxisCount
                                          : 1,
                                      crossAxisSpacing: 8.0,
                                      mainAxisSpacing: 8.0,
                                      childAspectRatio:
                                          2, // Adjust to decrease cell height
                                    ),
                                    itemCount: visitedPalaces.length,
                                    itemBuilder: (context, index) {
                                      return Container(
                                        padding: const EdgeInsets.all(8.0),
                                        decoration: BoxDecoration(
                                          color: const Color.fromARGB(
                                              255, 179, 255, 251),
                                          border:
                                              Border.all(color: Colors.grey),
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        child: Center(
                                          // Center aligns the text in the middle
                                          child: Text(
                                            visitedPalaces[index],
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign
                                                .center, // Optional for multiline text
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      SizedBox(height: 8.0),
                      if (tripRating != null)
                        RatingBar.builder(
                          initialRating: post['tripRating'] ?? 0,
                          minRating: 0,
                          itemSize: 20,
                          direction: Axis.horizontal,
                          allowHalfRating: true,
                          itemCount: 5,
                          itemBuilder: (context, _) => const Icon(
                            Icons.star,
                            color: Colors.yellow,
                          ),
                          onRatingUpdate: (rating) {
                            print(rating);
                          },
                        ),
                      SizedBox(height: 20.0),
                      if (tripFeedback != null)
                        Text(
                          'Feedback : $tripFeedback',
                          style: TextStyle(fontSize: 16),
                        ),
                      SizedBox(height: 8.0),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

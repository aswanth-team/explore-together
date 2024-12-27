import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../../../services/post/firebase_post.dart';
import '../../../../services/user/user_services.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/loading.dart';
import '../../userDetailsScreen/others_user_profile.dart';
import '../../user_screen.dart';
import 'post_complete_screen.dart';
import 'post_image_swipe.dart';

class CurrentUserPostDetailScreen extends StatefulWidget {
  final String postId;
  final String userId;

  const CurrentUserPostDetailScreen({
    super.key,
    required this.postId,
    required this.userId,
  });

  @override
  State<CurrentUserPostDetailScreen> createState() =>
      _CurrentUserPostDetailScreenState();
}

class _CurrentUserPostDetailScreenState
    extends State<CurrentUserPostDetailScreen> {
  final UserService _userService = UserService();
  final UserPostServices _userPostServices = UserPostServices();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Details'),
      ),
      body: FutureBuilder(
        future: Future.wait([
          _userService.fetchUserDetails(userId: widget.userId),
          _userPostServices.fetchPostDetails(postId: widget.postId),
        ]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingAnimation();
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final userData = snapshot.data![0] as Map<String, dynamic>;
            final postData = snapshot.data![1] as Map<String, dynamic>;
            final username = userData['username'];
            final userimage = userData['userimage'] ??
                [
                  'https://res.cloudinary.com/dakew8wni/image/upload/v1733819145/public/userImage/fvv6lbzdjhyrc1fhemaj.jpg'
                ];
            final gender = userData['gender'];

            final locationDescription =
                postData['locationDescription'] ?? 'unKnown';
            final locationName = postData['locationName'] ?? 'unKnown';
            final tripDuration = postData['tripDuration'] ?? 0;
            final isTripCompleted = postData['tripCompleted'];
            final tripRating = (postData['tripRating'] ?? 0).toDouble();

            final tripFeedback = postData['tripFeedback'];
            final tripBuddies = postData['tripBuddies'] ?? ['user1', 'user2'];
            final locationImages = postData['locationImages'] ?? [];
            final visitedPalaces = postData['visitedPlaces'] ?? [];
            final planToVisitPlaces = postData['planToVisitPlaces'];
            final tripCompletedDuration = postData['tripCompletedDuration'];

            return Padding(
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
                          },
                          child: CircleAvatar(
                            radius: 30.0,
                            backgroundImage: NetworkImage(userimage),
                          ),
                        ),
                        const SizedBox(width: 10.0),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              username, // Display full name
                              style: const TextStyle(
                                  fontSize: 18.0, fontWeight: FontWeight.bold),
                            ),
                            Text('Gender: $gender'),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16.0),

                    ImageCarousel(locationImages: locationImages),

                    const SizedBox(height: 16.0),

                    // Post details
                    Row(
                      mainAxisAlignment: MainAxisAlignment
                          .center, // Centers content horizontally
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
                              'Trip to $locationName ',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            // Container ensures wrapping and centers content
                            SizedBox(
                              width: MediaQuery.of(context).size.width *
                                  0.8, // Limit width for wrapping
                              child: Text(
                                locationDescription,
                                textAlign: TextAlign
                                    .center, // Ensures the text is centered horizontally
                                softWrap:
                                    true, // Wrap the text to next line if it overflows
                                maxLines: 3, // Limit the number of lines
                                overflow: TextOverflow
                                    .ellipsis, // Show ellipsis if text overflows
                                style: const TextStyle(
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10.0),
                          ],
                        ),
                      ],
                    ),
                    const Divider(
                      color: Colors.black, // Color of the line
                      thickness: 2.0, // Thickness of the line
                      indent: 20.0, // Space before the line
                      endIndent: 20.0, // Space after the line
                    ),
                    const SizedBox(height: 10.0),
                    if (!isTripCompleted) ...[
                      Center(
                        child: Text(
                          'Trip Duration Plan : $tripDuration days',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 8.0),
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
                                  final crossAxisCount =
                                      (constraints.maxWidth / 100).floor();
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
                                    itemCount: planToVisitPlaces.length,
                                    itemBuilder: (context, index) {
                                      return Container(
                                        padding: const EdgeInsets.all(8.0),
                                        decoration: BoxDecoration(
                                          color: const Color.fromARGB(
                                              255, 244, 255, 215),
                                          border:
                                              Border.all(color: Colors.grey),
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        child: Center(
                                          child: Text(
                                            planToVisitPlaces[index],
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
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
                      const SizedBox(height: 8.0),
                    ],
                    if (isTripCompleted) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.green,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Trip Completed',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green),
                            ),
                            const SizedBox(height: 8.0),
                            if (tripBuddies.isNotEmpty) ...[
                              GridView.builder(
                                shrinkWrap: true,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 10.0,
                                  mainAxisSpacing: 10.0,
                                ),
                                itemCount: tripBuddies.length,
                                itemBuilder: (context, index) {
                                  final buddyUserId = tripBuddies[index];
                                  return FutureBuilder<Map<String, dynamic>>(
                                    future: _userService.fetchUserDetails(
                                        userId: buddyUserId),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        final buddy = snapshot.data!;
                                        String gender =
                                            buddy['gender'].toLowerCase();

                                        return GestureDetector(
                                          onTap: () {
                                            if (buddyUserId !=
                                                FirebaseAuth.instance
                                                    .currentUser?.uid) {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      OtherProfilePage(
                                                    userId: buddyUserId,
                                                  ),
                                                ),
                                              );
                                            } else {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const UserScreen(
                                                          initialIndex: 4),
                                                ),
                                              );
                                            }
                                          },
                                          child: Card(
                                            elevation: 5.0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                            ),
                                            color: AppColors.genderBorderColor(
                                                gender),
                                            child: Column(
                                              children: [
                                                const SizedBox(height: 20.0),
                                                CircleAvatar(
                                                  radius: 25.0,
                                                  backgroundImage:
                                                      CachedNetworkImageProvider(
                                                          buddy['userimage']),
                                                ),
                                                const SizedBox(width: 10.0),
                                                Expanded(
                                                  child: Text(
                                                    buddy['username'],
                                                    style: const TextStyle(
                                                        fontSize: 10),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      } else if (snapshot.hasError) {
                                        return Center(
                                            child: Text(
                                                'Error: ${snapshot.error}'));
                                      }
                                      return const SizedBox();
                                    },
                                  );
                                },
                              )
                            ],
                            const SizedBox(height: 15.0),
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
                                          color:
                                              Color.fromARGB(255, 255, 104, 16),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8.0),
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        final crossAxisCount =
                                            (constraints.maxWidth / 100)
                                                .floor();
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
                                            childAspectRatio: 2,
                                          ),
                                          itemCount: visitedPalaces.length,
                                          itemBuilder: (context, index) {
                                            return Container(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              decoration: BoxDecoration(
                                                color: const Color.fromARGB(
                                                    255, 179, 255, 251),
                                                border: Border.all(
                                                    color: Colors.grey),
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  visitedPalaces[index],
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
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
                            const SizedBox(height: 8.0),
                            if (tripRating != null)
                              RatingBar.builder(
                                initialRating: tripRating,
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
                            const SizedBox(height: 20.0),
                            if (tripFeedback != null)
                              Text(
                                'Feedback : $tripFeedback',
                                style: const TextStyle(fontSize: 16),
                              ),
                            const SizedBox(height: 8.0),
                            if (tripCompletedDuration != null)
                              Text(
                                'Trip Duration : $tripCompletedDuration',
                                style: const TextStyle(fontSize: 16),
                              ),
                          ],
                        ),
                      ),
                    ],

                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment
                            .center, // This centers the content in the Row
                        children: [
                          ElevatedButton.icon(
                            onPressed: () async {
                              // Show confirmation dialog
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    backgroundColor: Colors
                                        .white, // Set background color for the dialog
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          12.0), // Rounded corners
                                    ),
                                    title: Row(
                                      children: [
                                        Icon(Icons.delete_forever,
                                            color: Colors
                                                .redAccent), // Add icon to the title
                                        SizedBox(width: 10),
                                        Text(
                                          'Delete Post',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                Colors.redAccent, // Title color
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
                                            color: Colors
                                                .black87, // Content text color
                                          ),
                                        ),
                                        SizedBox(height: 10),
                                        Text(
                                          'This action is irreversible. The post will be permanently deleted.',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors
                                                .grey, // Additional explanation
                                          ),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context)
                                              .pop(); // Close dialog without deleting
                                        },
                                        child: Text(
                                          'Cancel',
                                          style: TextStyle(
                                            color: Colors
                                                .blue, // Cancel button color
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () async {
                                          // Proceed with deleting the post
                                          await UserPostServices()
                                              .deletePost(widget.postId);
                                          if (context.mounted) {
                                            Navigator.pop(
                                                context); // Close confirmation dialog
                                          }
                                        },
                                        child: Text(
                                          'Delete',
                                          style: TextStyle(
                                            color: Colors
                                                .white, // Text color for the delete button
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors
                                              .redAccent, // Background color for delete button
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Remove',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.red, // Red background color
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          // Adds small space between buttons
                          if (!isTripCompleted)
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PostCompleteScreen(
                                      postId: widget.postId,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.done,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'complete',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors
                                    .green, // Blue background color for the second button
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else {
            return const Center(child: Text('No data found.'));
          }
        },
      ),
    );
  }
}

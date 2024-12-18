import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../../../../services/post/firebase_post.dart';
import '../../../../../services/user/user_services.dart';
import '../../../../../utils/loading.dart';
import '../../../profileScreen/post&trip/post_image_swipe.dart';
import '../../../user_screen.dart';
import '../../others_user_profile.dart';

class OtherUserPostDetailScreen extends StatefulWidget {
  final String postId;
  final String userId;

  const OtherUserPostDetailScreen({
    super.key,
    required this.postId,
    required this.userId,
  });

  @override
  State<OtherUserPostDetailScreen> createState() => _OtherUserPostDetailScreenState();
}

class _OtherUserPostDetailScreenState extends State<OtherUserPostDetailScreen> {
  final UserService _userService = UserService();
  final UserPostServices _userPostServices = UserPostServices();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post Details')),
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
            final locationImages = postData['locationImages'] ??
                [
                  'https://res.cloudinary.com/dakew8wni/image/upload/v1734019072/public/postimages/mwtjtugc4ppu02vwiv49.png'
                ];
            final visitedPalaces = postData['visitedPlaces'] ?? [];
            final planToVisitPlaces = postData['planToVisitPlaces'];

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
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OtherProfilePage(
                                  userId: widget.userId,
                                ),
                              ),
                            );
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
                              username,
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

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
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
                      const SizedBox(height: 8.0),
                    ],

                    // Trip completion details
                    if (isTripCompleted) ...[
                      Container(
                        width: double
                            .infinity, // Makes the container take up full width
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
                          crossAxisAlignment: CrossAxisAlignment
                              .center, // Center align all children horizontally
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
                                  crossAxisCount: 3, // Two items in each row
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

                                        // Determine grid background color based on gender
                                        Color gridColor;
                                        switch (gender) {
                                          case 'male':
                                            gridColor = const Color.fromARGB(
                                                255,
                                                186,
                                                224,
                                                255); // Blue for male
                                            break;
                                          case 'female':
                                            gridColor = const Color.fromARGB(
                                                255,
                                                255,
                                                224,
                                                252); // Rose (pink) for female
                                            break;
                                          default:
                                            gridColor = const Color.fromARGB(
                                                255,
                                                255,
                                                253,
                                                237); // Yellow for other or unknown genders
                                            break;
                                        }

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
                                                      UserScreen(
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
                                            color:
                                                gridColor, // Set grid background color based on gender
                                            child: Column(
                                              children: [
                                                const SizedBox(
                                                    height:
                                                        20.0), // Add top padding to create space between image and grid
                                                CircleAvatar(
                                                  radius: 25.0,
                                                  backgroundImage: NetworkImage(
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
                                        // ... rest of the code ...
                                      } else if (snapshot.hasError) {
                                        return Center(
                                            child: Text(
                                                'Error: ${snapshot.error}'));
                                      }
                                      return const SizedBox(); // Return a placeholder widget while loading
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
                                        // Calculate the number of columns based on available width
                                        final crossAxisCount = (constraints
                                                    .maxWidth /
                                                100)
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
                          ],
                        ),
                      ),
                    ],
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

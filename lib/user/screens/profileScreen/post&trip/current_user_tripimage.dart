import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../services/user/firebase_tripImages.dart';

class UserTripImagesWidget extends StatefulWidget {
  final String userId;

  const UserTripImagesWidget({
    super.key,
    required this.userId,
  });

  @override
  UserTripImagesWidgetState createState() => UserTripImagesWidgetState();
}

class UserTripImagesWidgetState extends State<UserTripImagesWidget> {
  List<String> tripImages = [];

  void deleteTripPhoto(String photoUrl, int index) async {
    await UserTripImageServices().deleteTripPhoto(widget.userId, photoUrl);
    setState(() {
      tripImages.removeAt(index);
    });
    print('Deleted trip photo: $photoUrl at index $index');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<String>>(
      stream: UserTripImageServices().fetchUserTripImagesStream(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Error loading images'));
        }

        final tripImages = snapshot.data ?? [];

        if (tripImages.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 50),
                Text('🚫', style: TextStyle(fontSize: 50)),
                Text('No Trip Images available'),
              ],
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // Three images per row
            crossAxisSpacing: 8, // Horizontal space between items
            mainAxisSpacing: 8, // Vertical space between items
          ),
          itemCount: tripImages.length,
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
                            child: Image.network(
                              tripImages[index],
                              fit: BoxFit.contain,
                              width: MediaQuery.of(context).size.width,
                              height: MediaQuery.of(context).size.height,
                            ),
                          ),
                          Positioned(
                            top: 5,
                            right: 5,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).pop();
                              },
                              child: const Icon(
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
                  CachedNetworkImage(
                    imageUrl: tripImages[index], // URL of the image
                    fit: BoxFit
                        .cover, // Adjust the image size to cover the available space
                    width: double
                        .infinity, // Stretch image to fill the available width
                    height: double
                        .infinity, // Stretch image to fill the available height
                    placeholder: (context, url) => const Center(
                        child:
                            CircularProgressIndicator()), // Placeholder while loading
                    errorWidget: (context, url, error) => const Center(
                        child:
                            Icon(Icons.error)), // Error widget if loading fails
                  ),
                  Positioned(
                    top: 5,
                    right: 5,
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onSelected: (value) {
                        if (value == 'delete') {
                          deleteTripPhoto(tripImages[index], index);
                        }
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      color: Colors.grey[800],
                      elevation: 8,
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
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
        );
      },
    );
  }
}

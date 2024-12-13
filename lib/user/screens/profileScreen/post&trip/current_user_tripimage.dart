import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserTripImagesWidget extends StatefulWidget {
  final String userId;

  const UserTripImagesWidget({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _UserTripImagesWidgetState createState() => _UserTripImagesWidgetState();
}

class _UserTripImagesWidgetState extends State<UserTripImagesWidget> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> tripImages = [];

  Future<void> fetchUserTripImages() async {
    try {
      final docSnapshot =
          await _firestore.collection('user').doc(widget.userId).get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        setState(() {
          tripImages = List<String>.from(data['tripimages'] ?? []);
        });
      }
    } catch (e) {
      print('Error fetching trip images: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUserTripImages();
  }

  void deleteTripPhoto(String photoUrl, int index) async {
    try {
      await _firestore.collection('user').doc(widget.userId).update({
        'tripimages': FieldValue.arrayRemove([photoUrl]),
      });
      setState(() {
        tripImages.removeAt(index);
      });

      print('Deleted trip photo: $photoUrl at index $index');
    } catch (e) {
      print('Error deleting trip photo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return tripImages.isEmpty
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 50),
                Text('🚫', style: TextStyle(fontSize: 50)),
                Text('No Trip Images available'),
              ],
            ),
          )
        : GridView.builder(
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
                    Image.network(
                      tripImages[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
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
  }
}

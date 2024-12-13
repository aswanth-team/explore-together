import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PostCompleteScreen extends StatefulWidget {
  final String postId;

  const PostCompleteScreen({
    required this.postId,
    super.key,
  });

  @override
  // ignore: library_private_types_in_public_api
  _PostCompleteScreenState createState() => _PostCompleteScreenState();
}

class _PostCompleteScreenState extends State<PostCompleteScreen> {
  final TextEditingController tripBuddiesController = TextEditingController();
  final TextEditingController visitedPlacesController = TextEditingController();

  final List<String> tripBuddies = [];
  final List<String> visitedPlaces = [];
  String? tripFeedback;
  double? tripRating;

  bool visitedPlacesDisabled = false;

  @override
  void dispose() {
    tripBuddiesController.dispose();
    visitedPlacesController.dispose();
    super.dispose();
  }

  void _addTag(
      String tag, TextEditingController controller, List<String> list) {
    if (tag.isNotEmpty && !list.contains(tag)) {
      setState(() {
        list.add(tag);
      });
      controller.clear();
    } else {
      controller.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Duplicate tag detected!")),
      );
    }
  }

  void _handleTagInput(
      String value, TextEditingController controller, List<String> list) {
    String tag = value.trim().replaceAll(',', '').replaceAll('\n', '').trim();
    if (tag.isNotEmpty) {
      _addTag(tag, controller, list);
    }
  }

  void _removeTag(String tag, List<String> list) {
    setState(() {
      list.remove(tag);
    });
  }

  void _checkVisitedPlacesLimit() {
    if (visitedPlaces.length >= 8) {
      setState(() {
        visitedPlacesDisabled = true;
      });
    }
  }

  Future<void> _saveTripDetails() async {
    try {
      await FirebaseFirestore.instance
          .collection('post')
          .doc(widget.postId)
          .update({
        'tripCompleted': true,
        'tripFeedback': tripFeedback,
        'tripRating': tripRating?.toInt(),
        'tripBuddies': tripBuddies,
        'visitedPlaces': visitedPlaces,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip completed and data saved')),
      );

      Navigator.pop(context);
    } catch (e) {
      print('Error saving trip details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save trip details')),
      );
    }
  }

  void _onComplete() {
    if (tripBuddies.isEmpty ||
        visitedPlaces.isEmpty ||
        tripFeedback == null ||
        tripRating == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields are required')),
      );
    } else {
      _saveTripDetails();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Trip Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Trip Rating
            RatingBar.builder(
              initialRating: tripRating ?? 0,
              minRating: 1,
              itemSize: 30,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemBuilder: (context, _) =>
                  const Icon(Icons.star, color: Colors.yellow),
              onRatingUpdate: (rating) => setState(() => tripRating = rating),
            ),
            const SizedBox(height: 10),

            // Trip Buddies Input
            TextField(
              controller: tripBuddiesController,
              decoration: const InputDecoration(
                labelText: 'Trip Buddies (comma separated)',
              ),
              onChanged: (value) {
                if (value.endsWith(",") || value.endsWith("\n")) {
                  _handleTagInput(value, tripBuddiesController, tripBuddies);
                }
              },
              onSubmitted: (value) {
                _handleTagInput(value, tripBuddiesController, tripBuddies);
              },
            ),
            Wrap(
              children: tripBuddies.map((tag) {
                return Chip(
                  label: Text(tag),
                  deleteIcon: const Icon(Icons.close),
                  onDeleted: () => _removeTag(tag, tripBuddies),
                );
              }).toList(),
            ),

            // Visited Places Input
            TextField(
              controller: visitedPlacesController,
              decoration: const InputDecoration(
                labelText: 'Visited Places (comma separated)',
              ),
              enabled: !visitedPlacesDisabled,
              onChanged: (value) {
                if (value.endsWith(",") || value.endsWith("\n")) {
                  _handleTagInput(
                      value, visitedPlacesController, visitedPlaces);
                  _checkVisitedPlacesLimit();
                }
              },
              onSubmitted: (value) {
                if (!visitedPlacesDisabled) {
                  _handleTagInput(
                      value, visitedPlacesController, visitedPlaces);
                  _checkVisitedPlacesLimit();
                }
              },
            ),
            Wrap(
              children: visitedPlaces.map((tag) {
                return Chip(
                  label: Text(tag),
                  deleteIcon: const Icon(Icons.close),
                  onDeleted: () => _removeTag(tag, visitedPlaces),
                );
              }).toList(),
            ),

            // Trip Feedback Input
            TextField(
              decoration: const InputDecoration(labelText: 'Trip Feedback'),
              onChanged: (value) => tripFeedback = value,
            ),

            // Complete Button
            ElevatedButton(
              onPressed: _onComplete,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Complete'),
            ),
          ],
        ),
      ),
    );
  }
}

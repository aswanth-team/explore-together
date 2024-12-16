import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

import '../../../services/cloudinary_upload.dart';
import '../../../utils/loading.dart';

class PostUploader extends StatefulWidget {
  @override
  _PostUploaderState createState() => _PostUploaderState();
}

class _PostUploaderState extends State<PostUploader> {
  final _formKey = GlobalKey<FormState>();

  List<File> _selectedImages = [];
  String? _locationName;
  String? _locationDescription;
  String? _tripDuration;
  List<String> _tags = [];
  String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final TextEditingController _tagController = TextEditingController();

  bool _isPosting = false;

  Future<void> _pickImages() async {
    try {
      final pickedFiles = await ImagePicker().pickMultiImage();

      if (pickedFiles.isNotEmpty) {
        setState(() {
          _selectedImages = pickedFiles
              .map((pickedFile) => File(pickedFile.path))
              .take(3)
              .toList();
        });
      }
    } catch (e) {
      print('Error picking images: $e');
    }
  }

  void _addTag(String tag) {
    if (tag.isNotEmpty) {
      if (_tags.length >= 8) {
        return;
      }
      if (!_tags.contains(tag)) {
        setState(() {
          _tags.add(tag);
        });
        _tagController.clear();
      } else {
        _tagController.clear();
      }
    }
  }

  void _handleTagInput(String value) {
    String tag = value.trim().replaceAll(',', '').replaceAll('\n', '').trim();
    if (tag.isNotEmpty) {
      _addTag(tag);
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _post() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one image!")),
      );
      return;
    }

    final String remainingTag = _tagController.text.trim();
    if (remainingTag.isNotEmpty) {
      _addTag(remainingTag);
    }

    setState(() {
      _isPosting = true;
    });

    List<String> uploadedImageUrls = [];

    try {
      // Upload images asynchronously
      for (File image in _selectedImages) {
        final response = await CloudinaryService(uploadPreset: 'postImages')
            .uploadImage(selectedImage: image);
        if (response != null) {
          uploadedImageUrls.add(response);
        }
      }

      // Prepare post data
      final postData = {
        'locationName': _locationName,
        'locationDescription': _locationDescription,
        'locationImages': uploadedImageUrls,
        'planToVisitPlaces': _tags,
        'tripDuration': _tripDuration,
        'tripCompleted': false,
        'userid': currentUserId,
        'tripRating': null,
        'tripBuddies': null,
        'tripFeedback': null,
        'visitedPlaces': null,
        'uploadedDateTime': DateTime.now().toIso8601String()
      };

      // Upload post data to Firestore
      await FirebaseFirestore.instance.collection('post').add(postData);

      setState(() {
        _selectedImages.clear();
        _tags.clear();
      });

      // Show success and navigate back
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Post successfully uploaded!")),
      );
    } catch (e) {
      print('Error uploading post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload post. Please try again.")),
      );
    } finally {
      setState(() {
        _isPosting = false;
      });

      Navigator.pop(context); // Close the bottom sheet
      Future.delayed(const Duration(milliseconds: 300), () {
        Navigator.pop(context); // Go back to the previous screen
      });
    }
  }

  Widget _imagePickerWidget() {
    return Padding(
      padding: EdgeInsets.only(left: 16.0, right: 16.0, top: 0.0),
      child: GestureDetector(
        onTap: _pickImages,
        child: Column(
          children: [
            _selectedImages.isEmpty
                ? Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(child: Text("Tap to select images")),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 8.0,
                      crossAxisSpacing: 8.0,
                    ),
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              _selectedImages[index],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                          Positioned(
                            top: 5,
                            right: 5,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedImages.removeAt(index);
                                });
                              },
                              child: CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.red,
                                child: Icon(Icons.close,
                                    size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
            SizedBox(height: 10),
            Text(
              "Tap to reselect images (max 3)",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                          left: 16.0,
                          right: 16.0,
                          top: 0.0), // Customize the values as needed
                      child: GestureDetector(
                        onTap: _pickImages,
                        child: _imagePickerWidget(),
                      ),
                    ),
                    SizedBox(
                      width: 350, // Set width for the DOB field
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Location Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[200],
                          labelStyle: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter location name'
                            : null,
                        onSaved: (value) => _locationName = value,
                      ),
                    ),
                    SizedBox(height: 5),
                    SizedBox(
                      width: 350, // Set width for the DOB field
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Location Description',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[200],
                          labelStyle: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter location description'
                            : null,
                        onSaved: (value) => _locationDescription = value,
                      ),
                    ),
                    SizedBox(height: 5),
                    SizedBox(
                      width: 350, // Set width for the DOB field
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Trip Duration',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[200],
                          labelStyle: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter trip duration'
                            : null,
                        onSaved: (value) => _tripDuration = value,
                      ),
                    ),
                    SizedBox(height: 5),
                    SizedBox(
                      width: 350, // Set width for the DOB field
                      child: TextFormField(
                        controller: _tagController,
                        decoration: InputDecoration(
                          labelText: 'Plan to Visit (Enter tags)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[200],
                          suffixIcon: IconButton(
                            icon: Icon(Icons.add),
                            onPressed: _tags.length < 8
                                ? () => _addTag(_tagController.text)
                                : null, // Disable adding tags if the limit is reached
                          ),
                          labelStyle: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        onChanged: (value) {
                          if (_tags.length < 8 &&
                              (value.endsWith(",") || value.endsWith("\n"))) {
                            _handleTagInput(value);
                          }
                        },
                        onFieldSubmitted: (value) =>
                            _tags.length < 8 ? _addTag(value) : null,
                        enabled: _tags.length <
                            8, // Disable the field when there are 8 tags
                      ),
                    ),
                    SizedBox(height: 5),
                    if (_tags.isNotEmpty)
                      Wrap(
                        spacing: 8.0,
                        children: _tags.map((tag) {
                          return Chip(
                            label: Text(tag),
                            deleteIcon: Icon(Icons.close, size: 18),
                            backgroundColor: Colors.blueAccent[100],
                            labelStyle: TextStyle(color: Colors.white),
                            onDeleted: () => _removeTag(tag),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          );
                        }).toList(),
                      ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isPosting
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                _formKey.currentState!.save();
                                _post();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.blue, // Text color
                        padding: EdgeInsets.symmetric(
                            vertical: 15, horizontal: 30), // Button padding
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(30), // Rounded corners
                        ),
                        elevation: 5, // Shadow for depth
                        shadowColor:
                            Colors.black.withOpacity(0.25), // Shadow color
                      ),
                      child: Text(
                        'Post',
                        style: TextStyle(
                          fontSize: 18, // Text size
                          fontWeight: FontWeight.bold, // Bold text
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
          if (_isPosting) LoadingAnimationOverLay()
        ],
      ),
    );
  }
}

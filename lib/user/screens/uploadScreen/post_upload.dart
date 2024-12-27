import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

import '../../../services/cloudinary_upload.dart';
import '../../../utils/loading.dart';

class PostUploader extends StatefulWidget {
  const PostUploader({super.key});

  @override
  PostUploaderState createState() => PostUploaderState();
}

class PostUploaderState extends State<PostUploader> {
  final _formKey = GlobalKey<FormState>();

  List<File> _selectedImages = [];
  String? _locationName;
  String? _locationDescription;
  int? _tripDuration;
  final List<String> _tags = [];
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
      for (File image in _selectedImages) {
        final response = await CloudinaryService(uploadPreset: 'postImages')
            .uploadImage(selectedImage: image);
        if (response != null) {
          uploadedImageUrls.add(response);
        }
      }

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
        'uploadedDateTime': FieldValue.serverTimestamp(),
        'likes': null,
        'tripCompletedDuration': null,
      };
      await FirebaseFirestore.instance.collection('post').add(postData);

      setState(() {
        _selectedImages.clear();
        _tags.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Post successfully uploaded!")),
        );
      }
    } catch (e) {
      print('Error uploading post: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Failed to upload post. Please try again.")),
        );
      }
    } finally {
      setState(() {
        _isPosting = false;
      });

      if (mounted) {
        Navigator.pop(context);
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    }
  }

  Widget _imagePickerWidget() {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 0.0),
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
                    child: const Center(child: Text("Tap to select images")),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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
                              child: const CircleAvatar(
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
            const SizedBox(height: 10),
            const Text(
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
                      padding: const EdgeInsets.only(
                          left: 16.0, right: 16.0, top: 0.0),
                      child: GestureDetector(
                        onTap: _pickImages,
                        child: _imagePickerWidget(),
                      ),
                    ),
                    SizedBox(
                      width: 350,
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Location Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[200],
                          labelStyle: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter location name'
                            : null,
                        onSaved: (value) => _locationName = value,
                      ),
                    ),
                    const SizedBox(height: 5),
                    SizedBox(
                      width: 350,
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Location Description',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[200],
                          labelStyle: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter location description'
                            : null,
                        onSaved: (value) => _locationDescription = value,
                      ),
                    ),
                    const SizedBox(height: 5),
                    SizedBox(
                      width: 350,
                      child: TextFormField(
                        keyboardType:
                            TextInputType.number, // Show number keyboard
                        decoration: InputDecoration(
                          labelText: 'Trip Duration (in days)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[200],
                          labelStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter trip duration';
                          }
                          if (int.tryParse(value) == null ||
                              int.parse(value) <= 0) {
                            return 'Enter a valid positive number';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _tripDuration = int.tryParse(value!);
                        },
                      ),
                    ),
                    const SizedBox(height: 5),
                    SizedBox(
                      width: 350,
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
                            icon: const Icon(Icons.add),
                            onPressed: _tags.length < 8
                                ? () => _addTag(_tagController.text)
                                : null,
                          ),
                          labelStyle: const TextStyle(
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
                        enabled: _tags.length < 8,
                      ),
                    ),
                    const SizedBox(height: 5),
                    if (_tags.isNotEmpty)
                      Wrap(
                        spacing: 8.0,
                        children: _tags.map((tag) {
                          return Chip(
                            label: Text(tag),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            backgroundColor: Colors.blueAccent[100],
                            labelStyle: const TextStyle(color: Colors.white),
                            onDeleted: () => _removeTag(tag),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 20),
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
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                            vertical: 15, horizontal: 30),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 5,
                        shadowColor: Colors.black.withValues(alpha: 0.25),
                      ),
                      child: const Text(
                        'Post',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
          if (_isPosting) const LoadingAnimationOverLay()
        ],
      ),
    );
  }
}

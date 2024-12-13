import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'
    if (kIsWeb) 'package:flutter/material.dart'; // Conditionally import based on platform
import 'package:flutter/foundation.dart' show kIsWeb;

class UploadAgencyPage extends StatefulWidget {
  @override
  _UploadAgencyPageState createState() => _UploadAgencyPageState();
}

class _UploadAgencyPageState extends State<UploadAgencyPage> {
  final _agencyIdController = TextEditingController();
  final _agencyNameController = TextEditingController();
  final _agencyWebController = TextEditingController();
  final _categoryController = TextEditingController();
  final _agencyKeywordsController = TextEditingController();

  List<String> _agencyKeywords = [];
  XFile? _selectedImage;

  final _picker = ImagePicker();

  // Function to pick an image
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _selectedImage = pickedFile;
    });
  }

  // Function to submit the form
  void _submitForm() {
    _agencyKeywords = _agencyKeywords.map((e) => "'$e'").toList();
    final agencyDetails = {
      'agencyId': _agencyIdController.text,
      'agencyName': _agencyNameController.text,
      'agencyWeb': _agencyWebController.text,
      'category': _categoryController.text,
      'agencyKeywords': _agencyKeywords, // Pass the agencyKeywords list
      'agencyImage': _selectedImage?.path,
    };

    print(agencyDetails);

    // Return the agency details to the previous page
    Navigator.pop(context, agencyDetails);
  }

// Function to handle tag input when Enter or comma is pressed
  void _onKeywordSubmitted(String value) {
    final newKeyword = value.trim();

    if (newKeyword.isNotEmpty && !_agencyKeywords.contains(newKeyword)) {
      setState(() {
        _agencyKeywords.add(newKeyword);
      });
    }
    _agencyKeywordsController.clear();
  }

// Function to handle comma and Enter keypress for tag input
  void _onKeywordChanged(String value) {
    if (value.contains(',')) {
      final newKeyword = value.replaceAll(',', '').trim();
      if (newKeyword.isNotEmpty && !_agencyKeywords.contains(newKeyword)) {
        setState(() {
          _agencyKeywords.add(newKeyword);
        });
        _agencyKeywordsController.clear();
      }
      _agencyKeywordsController.clear();
    }
  }

  // Function to remove a tag
  void _removeKeyword(String keyword) {
    setState(() {
      _agencyKeywords.remove(keyword);
    });
  }

  Widget buildImagePreview() {
    if (kIsWeb) {
      // For web, use Image.network to display the image
      return _selectedImage == null
          ? Center(child: Text('Tap to upload image'))
          : Image.network(
              _selectedImage!.path); // Assuming `path` is a valid URL for web
    } else {
      // For mobile platforms, use Image.file to display the image
      return _selectedImage == null
          ? Center(child: Text('Tap to upload image'))
          : Image.file(
              File(_selectedImage!.path),
              fit: BoxFit.cover,
            );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Upload Agency")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Upload Section
            Row(
              mainAxisAlignment: MainAxisAlignment
                  .center, // This will center the child in the Row
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 150,
                    width: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(
                          75), // Half of height/width for a circle
                      border: Border.all(
                        color: Colors.black
                            .withOpacity(0.2), // Optional border color
                        width: 1, // Border width
                      ),
                    ),
                    child: ClipOval(
                      child: buildImagePreview(), // Your image widget goes here
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Agency ID Text Field
            TextField(
              controller: _agencyIdController,
              decoration: InputDecoration(
                labelText: 'Agency ID',
                labelStyle: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold), // Label style
                hintText:
                    'Enter Agency ID', // Hint text for additional guidance
                hintStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0), // Rounded corners
                  borderSide:
                      BorderSide(color: Colors.blueAccent), // Border color
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide(
                      color: Colors.blue,
                      width: 2.0), // Border color when focused
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide(color: Colors.grey, width: 1.0),
                ),
              ),
            ),
            SizedBox(height: 16),

// Agency Name Text Field
            TextField(
              controller: _agencyNameController,
              decoration: InputDecoration(
                labelText: 'Agency Name',
                labelStyle:
                    TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                hintText: 'Enter Agency Name',
                hintStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide(color: Colors.blueAccent),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide(color: Colors.blue, width: 2.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide(color: Colors.grey, width: 1.0),
                ),
              ),
            ),
            SizedBox(height: 16),

// Agency Website Text Field
            TextField(
              controller: _agencyWebController,
              decoration: InputDecoration(
                labelText: 'Agency Website',
                labelStyle:
                    TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                hintText: 'Enter Website URL',
                hintStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide(color: Colors.blueAccent),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide(color: Colors.blue, width: 2.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide(color: Colors.grey, width: 1.0),
                ),
              ),
            ),
            SizedBox(height: 16),

// Category Text Field
            TextField(
              controller: _categoryController,
              decoration: InputDecoration(
                labelText: 'Category',
                labelStyle:
                    TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                hintText: 'Enter Category',
                hintStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide(color: Colors.blueAccent),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide(color: Colors.blue, width: 2.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide(color: Colors.grey, width: 1.0),
                ),
              ),
            ),
            SizedBox(height: 16),

// Agency Keywords (Tag input)
            TextField(
              controller: _agencyKeywordsController,
              decoration: InputDecoration(
                labelText: 'Agency Keywords',
                labelStyle:
                    TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                hintText: 'Enter Keywords',
                hintStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide(color: Colors.blueAccent),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide(color: Colors.blue, width: 2.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide(color: Colors.grey, width: 1.0),
                ),
              ),
              onChanged: _onKeywordChanged, // Listen for changes
              onSubmitted:
                  _onKeywordSubmitted, // Triggered when "Enter" is pressed
              keyboardType: TextInputType.text,
            ),

            SizedBox(height: 16),

            Container(
              width: MediaQuery.of(context).size.width *
                  0.95, // 90% of screen width
              height: 100.0, // Fixed height
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.blueAccent, // Border color
                  width: 2.0, // Border width
                ),
                borderRadius:
                    BorderRadius.circular(10.0), // Optional: Rounded corners
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis
                    .vertical, // Allow vertical scrolling when content overflows
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0, // Optional: Spacing between rows of chips
                  children: _agencyKeywords
                      .map((keyword) => Chip(
                            label: Text(keyword),
                            deleteIcon: Icon(Icons.remove_circle),
                            onDeleted: () => _removeKeyword(keyword),
                          ))
                      .toList(),
                ),
              ),
            ),

            SizedBox(height: 16),

            // Upload Button
            ElevatedButton(
              onPressed: _submitForm,
              child: Text('Upload'),
            ),
          ],
        ),
      ),
    );
  }
}

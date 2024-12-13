import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

void main() {
  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Upload Image to Cloudinary'),
        ),
        body: ImageUploader(),
      ),
    );
  }
}

class ImageUploader extends StatefulWidget {
  @override
  _ImageUploaderState createState() => _ImageUploaderState();
}

class _ImageUploaderState extends State<ImageUploader> {
  final CloudinaryPublic cloudinary =
      CloudinaryPublic('dakew8wni', 'userimages', cache: false);
  File? _selectedImage;
  String? _uploadedImageUrl;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        if (!mounted) return; // Ensure widget is still in the tree
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null || _isUploading) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          _selectedImage!.path,
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      if (!mounted) return; // Ensure widget is still in the tree
      setState(() {
        _uploadedImageUrl = response.secureUrl;
      });

      print('Uploaded Image URL: $_uploadedImageUrl');
    } catch (e) {
      print('Error uploading image: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_selectedImage != null)
            Image.file(
              _selectedImage!,
              height: 200,
            )
          else
            Placeholder(
              fallbackHeight: 200,
              fallbackWidth: double.infinity,
            ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _pickImage,
            child: Text('Pick Image'),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isUploading ? null : _uploadImage,
            child: _isUploading
                ? CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                : Text('Upload to Cloudinary'),
          ),
          if (_uploadedImageUrl != null)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                'Uploaded Image URL: $_uploadedImageUrl',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.green),
              ),
            ),
        ],
      ),
    );
  }
}

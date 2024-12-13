import 'package:flutter/material.dart';

import '../userDetailsScreen/post_details_screen.dart';
import '../userDetailsScreen/user_details_screen.dart';

class UsersPosts extends StatefulWidget {
  final int index;
  final String postId; // Add postId here
  final List<String> images;
  final String location;
  final String locationDescription;
  final String tripDuration;
  final String userImage;
  final String userName;
  final String userGender;
  final bool tripCompleted;
  final List<String> userVisitingPlaces;
  final List<String> userVistedPlaces;

  UsersPosts({
    required this.index,
    required this.postId, // Accept postId in the constructor
    required this.images,
    required this.location,
    required this.locationDescription,
    required this.tripDuration,
    required this.userImage,
    required this.userName,
    required this.userGender,
    required this.tripCompleted,
    required this.userVisitingPlaces,
    required this.userVistedPlaces,
  });

  @override
  _UsersPostsState createState() => _UsersPostsState();
}

class _UsersPostsState extends State<UsersPosts> {
  late PageController _pageController;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _currentPage = 0;
  }

  void _nextImage() {
    if (_currentPage < widget.images.length - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  void _previousImage() {
    if (_currentPage > 0) {
      _pageController.animateToPage(
        _currentPage - 1,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  Color getBorderColor(String gender) {
    if (gender.toLowerCase() == "male") {
      return Colors.lightBlue;
    } else if (gender.toLowerCase() == "female") {
      return Colors.pinkAccent.shade100;
    } else {
      return Colors.yellow.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to the post details screen when the card is tapped
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailScreen(
              postId: widget.postId,
              username: widget.userName,
            ),
          ),
        );
      },
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        color: widget.tripCompleted
            ? Colors.green[100]
            : Colors.white, // Green if tripCompleted
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                UsersProfilePage(username: widget.userName),
                          ),
                        );
                      },
                      child: Container(
                        width:
                            60, // Slightly larger than CircleAvatar radius * 2
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: getBorderColor(widget.userGender),
                            width: 2.0, // Border thickness
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundImage: AssetImage(widget.userImage),
                        ),
                      )),
                  SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              UsersProfilePage(username: widget.userName),
                        ),
                      );
                    },
                    child: Text(
                      widget.userName,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              GestureDetector(
                onTap: _nextImage,
                child: Container(
                  height: 250,
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        itemCount: widget.images.length,
                        onPageChanged: (int page) {
                          setState(() {
                            _currentPage = page;
                          });
                        },
                        itemBuilder: (context, index) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.asset(
                              widget.images[index],
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          );
                        },
                      ),
                      Positioned(
                        left: 10,
                        top: 100,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios,
                              color: Colors.white),
                          onPressed: _previousImage,
                        ),
                      ),
                      Positioned(
                        right: 10,
                        top: 100,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_forward_ios,
                              color: Colors.white),
                          onPressed: _nextImage,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  widget.location,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  widget.locationDescription,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              // Only show trip duration if the trip is not completed
              if (!widget.tripCompleted)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    'Duration Plan : ${widget.tripDuration}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

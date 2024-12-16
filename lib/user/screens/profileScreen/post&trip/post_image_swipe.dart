import 'package:flutter/material.dart';

class ImageCarousel extends StatefulWidget {
  final List<dynamic> locationImages;

  const ImageCarousel({super.key, required this.locationImages});

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 250.0,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15.0),
            child: Image.network(
              widget.locationImages[currentIndex],
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
        ),

        // Left Arrow Button
        if (currentIndex > 0)
          Positioned(
            left: 10.0,
            top: 90.0,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  currentIndex--;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.arrow_left, color: Colors.white, size: 30),
              ),
            ),
          ),

        // Right Arrow Button
        if (currentIndex < widget.locationImages.length - 1)
          Positioned(
            right: 10.0,
            top: 90.0,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  currentIndex++;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_right,
                    color: Colors.white, size: 30),
              ),
            ),
          ),
      ],
    );
  }
}

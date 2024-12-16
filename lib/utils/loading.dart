import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LoadingAnimationOverLay extends StatelessWidget {
  const LoadingAnimationOverLay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.5), // Semi-transparent black overlay
        child: Center(
          child: Lottie.asset(
            'assets/LottieAnimations/loading.json', // Path to your Lottie animation file
            width: 150,
            height: 150,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class LoadingAnimation extends StatelessWidget {
  const LoadingAnimation({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: Lottie.asset(
          'assets/LottieAnimations/loading.json', 
          width: 150,
          height: 150,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

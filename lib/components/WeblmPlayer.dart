import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LottiePlayer extends StatelessWidget {
  final String assetPath; // path to your .json file in assets

  const LottiePlayer({Key? key, required this.assetPath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Lottie.asset(
        assetPath,
        repeat: true, // loop animation
        animate: true, // play automatically
      ),
    );
  }
}

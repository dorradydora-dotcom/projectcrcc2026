import 'package:flutter/material.dart';

class NonthScreen extends StatelessWidget {
  const NonthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return SizedBox(
        width: screenWidth,
        height: screenHeight,
        child: Center(child: Text('NonthScreen')));
  }
}

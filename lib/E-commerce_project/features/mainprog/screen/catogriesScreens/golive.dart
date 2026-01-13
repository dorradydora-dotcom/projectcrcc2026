import 'package:flutter/material.dart';

class GoliveScreen extends StatelessWidget {
  const GoliveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Go Live'),
      ),
      body: Center(
        child: Text('Go Live Screen'),
      ),
    );
  }
}

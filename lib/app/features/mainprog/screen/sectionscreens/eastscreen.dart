import 'package:amiraly/app/features/mainprog/screen/sectionscreens/zone_screen.dart';
import 'package:flutter/material.dart';

class EastScreen extends StatelessWidget {
  const EastScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ZoneScreen(
      zoneName: 'east',
      displayName: 'المنطقة الشرقية',
    );
  }
}

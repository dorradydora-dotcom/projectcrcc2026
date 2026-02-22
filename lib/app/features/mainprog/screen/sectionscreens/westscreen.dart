import 'package:amiraly/app/features/mainprog/screen/sectionscreens/zone_screen.dart';
import 'package:flutter/material.dart';

class WestScreen extends StatelessWidget {
  const WestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ZoneScreen(
      zoneName: 'west',
      displayName: 'المنطقة الغربية',
    );
  }
}

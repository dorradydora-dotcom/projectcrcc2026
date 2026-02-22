import 'package:amiraly/app/features/mainprog/screen/sectionscreens/zone_screen.dart';
import 'package:flutter/material.dart';

class SouthScreen extends StatelessWidget {
  const SouthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ZoneScreen(
      zoneName: 'south',
      displayName: 'المنطقة الجنوبية',
    );
  }
}

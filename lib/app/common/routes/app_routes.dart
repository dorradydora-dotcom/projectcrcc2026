import 'package:flutter/material.dart';
import 'package:amiraly/app/features/mainprog/screen/catogriesScreens/announcement_screen.dart';
import 'package:amiraly/app/features/mainprog/screen/catogriesScreens/cairoscreen.dart';
import 'package:amiraly/app/features/mainprog/screen/catogriesScreens/cmscreen.dart';
import 'package:amiraly/app/features/mainprog/screen/catogriesScreens/events.dart';
import 'package:amiraly/app/features/mainprog/screen/catogriesScreens/golive.dart';
import 'package:amiraly/app/features/mainprog/screen/catogriesScreens/indicators.dart';
import 'package:amiraly/app/features/mainprog/screen/catogriesScreens/mapscreen.dart';
import 'package:amiraly/app/features/mainprog/screen/catogriesScreens/projects.dart';
import 'package:amiraly/app/features/mainprog/screen/catogriesScreens/reports.dart';
import 'package:amiraly/app/features/mainprog/screen/catogriesScreens/world.dart';

final Map<String, Widget Function(BuildContext)> pageRoutes = {
  'الاحداث': (context) => EventsScreen(),
  'الازمات': (context) => Cmscreen(),
  'القاهرة': (context) => Cairoscreen(),
  'مؤشرات': (context) => IndicatorsScreen(),
  'تقارير': (context) => ReportsScreen(),
  'العالم': (context) => WorldScreen(),
  'تعليمات': (context) => AnnouncementScreenDark(),
  'خريطة': (context) => Mapscreen(),
  'مشروعات': (context) => ProjectsScreen(),
  'Go live': (context) => UsersPage(),
};

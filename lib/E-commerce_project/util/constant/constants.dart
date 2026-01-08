// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';

class AppConstants {
  // Notification
  static const String notificationChannelId = 'announcement_channel';
  static const String notificationChannelName = 'Emergency Announcements';
  static const String notificationChannelDescription =
      'Urgent instructions and alerts';
  static const String notificationIcon = '@drawable/ic_launcher_foreground';

  // Storage Keys
  static const String onboardingKey = 'onboarding_completed';
  static const String processedNotificationsKey = 'processed_notification_ids';

  // Limits
  static const int maxProcessedNotifications = 100;
  static const int defaultFetchLimit = 200;
  static const int hourlyFetchLimit = 100;
  static const Duration timeoutDuration = Duration(seconds: 10);
  static const Duration snackbarDuration = Duration(seconds: 3);

  // Tables
  static const String tableStation = 'station_table';
  static const String tableHourlyMaxLoads = 'hourly_max_loads';
  static const String tableStationsAuth = 'stations_auth';
  static const String tableUserStations = 'user_stations';

  // Routes
  static const String routeService = 'serviceScreen';
  static const String routeAnnouncement = 'announcement';
  static const String routeEvents = 'الاحداث';
  static const String routeInstructions = 'تعليمات';
  static const int maxStations = 6;

  static var indicatorstationColors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.orange,
    Colors.purple,
  ];

  static var indicatorpieChartColors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.orange,
    Colors.purple,
  ];
  static const double padding = 12.0;
  static const double borderRadius = 16.0;
  static const double spacing = 8.0;
  static const double cardElevation = 8.0;
}

class Appcolors {
  static const Color primaryColor = Color.fromARGB(255, 6, 87, 149);
  static const Color primaryColor2 = Color(0xFFF5F6FA);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color buttonColor = Color(0xFF3B82F6);
  static const Color textButton = Colors.white;
  static const Color borderColor = Color(0xFFD1D5DB);
  static const Color dividerColor = Color(0xFFE5E7EB);
  static const Color primaryColor3 = Color(0xFF6200EA); // Deep purple
  static const Color secondaryColor = Color(0xFF03DAC6); // Teal
  static const Color warningColor = Color(0xFFFFB300); // Amber
  static const Color errorColor = Color(0xFFD32F2F); // Red
  static const Color backgroundColor = Color(0xFFFFFFFF); // White

  static const List<List<Color>> cardGradients = [
    [Color(0xFF7DD3FC), Color(0xFF3B82F6)], // Blue gradient
    [Color(0xFFF472B6), Color(0xFFEC4899)], // Pink gradient
    [Color(0xFF34D399), Color(0xFF10B981)], // Green gradient
    [Color(0xFFFBBF24), Color(0xFFF59E0B)], // Yellow gradient
    [Color(0xFFFB7185), Color(0xFFF43F5E)], // Red gradient
    [Color(0xFF8B5CF6), Color(0xFF6D28D9)], // Purple gradient
  ];

  static const List<Color> buttonGradient2 = [
    primaryColor,
    Color.fromARGB(255, 24, 92, 144),
    Color.fromARGB(255, 62, 133, 188),
    Color.fromARGB(255, 169, 197, 219),
    Color.fromARGB(255, 213, 222, 255),
    primaryColor2,
  ];
}

class C {
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color grey = Colors.grey;
  static const Color red = Colors.red;
  static const Color green = Colors.green;
  static const Color blue = Colors.blue;
  static const Color yellow = Colors.yellow;
  static const Color orange = Colors.orange;
  static const Color purple = Colors.purple;
  static const Color pink = Colors.pink;
  static const Color brown = Colors.brown;
}

List<Color> glowColors = [
  Colors.blue,
  Colors.green,
  Colors.red,
  Colors.orange,
  Colors.purple
];

class IndicatorAppColors {
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color secondaryColor = Color(0xFFFF9800);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color cardColor = Colors.white;
  static const Color textColor = Color(0xFF212121);
  static const Color subTextColor = Color(0xFF757575);
  static const Color shadowColor = Color(0xFF000000);
  static const Color borderColor = Color(0xFFE0E0E0);
}

class AreapageColors {
  static const kSecondaryColor = Color.fromARGB(187, 244, 67, 54);
  static const kSubtitleColor = Color.fromARGB(255, 99, 110, 209);
}

class AppimageString {
  AppimageString._(); // Private constructor to prevent instantiation

  static const String earth = 'lib/assets/images/g/earth.jpg';
  static const String eee = 'lib/assets/images/g/eee.jpg';
  static const String ff = 'lib/assets/images/g/ff.jpg';
  static const String flag = 'lib/assets/images/g/flag.jpg';
  static const String image = 'lib/assets/images/g/batte.jpg';
  static const String image3 = 'lib/assets/images/g/image3.jpg';
  static const String image55 = 'lib/assets/images/g/image55.jpg';
  static const String minisrty = 'lib/assets/images/g/ministry.jpg';
  static const String network = 'lib/assets/images/g/network.png';
  static const String together = 'lib/assets/images/g/together.png';
  static const String electric = 'lib/assets/images/g/electric.png';
  static const String rtop = 'lib/assets/images/g/rtop.jpg';
  static const String aaa = 'lib/assets/images/g/aaa.jpg';
  static const String qq = 'lib/assets/images/g/qq.png';

  static const String yes = 'lib/assets/images/payment/yes.png';

  // photo
  static const String b4 = 'lib/assets/images/photo/b4.jpg';
  static const String rt = 'lib/assets/images/photo/rt.jpg';
  static const String b1 = 'lib/assets/images/photo/b1.jpg';
  static const String b2 = 'lib/assets/images/photo/b2.jpg';
  static const String b3 = 'lib/assets/images/photo/b3.jpg';
  static const String b5 = 'lib/assets/images/photo/b5.jpg';
  static const String b6 = 'lib/assets/images/photo/b6.jpg';
  static const String b7 = 'lib/assets/images/photo/b7.jpg';
  static const String b8 = 'lib/assets/images/photo/b8.jpg';
  static const String b9 = 'lib/assets/images/photo/b9.jpg';
  static const String bb = 'lib/assets/images/photo/bb.jpg';
  static const String b11 = 'lib/assets/images/photo/b11.jpg';
  static const String gg = 'lib/assets/images/photo/gg.jpg';
  static const String ny = 'lib/assets/images/photo/ny.jpg';
  static const String sainai = 'lib/assets/images/photo/sainai.jpg';
  static const String t1 = 'lib/assets/images/photo/t1.jpg';
  static const String t2 = 'lib/assets/images/photo/t2.jpg';
  static const String t3 = 'lib/assets/images/photo/t3.jpg';
}

class AppSizes {
  static double screenWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width;
  static double screenHeight(BuildContext context) =>
      MediaQuery.sizeOf(context).height;
  static double heightcurved(BuildContext context) {
    final double calculated = MediaQuery.sizeOf(context).height * 0.08;
    return calculated > 70 ? 70.0 : MediaQuery.sizeOf(context).height * 0.06;
  }
}

double responsiveFontSize(double screenWidth, double baseFactor) {
  return screenWidth * baseFactor.clamp(0.02, 0.06);
}

class AppPadding {
  static const double loginpadding = 24.0;
  static const double loginspacing = 16.0;
}

class AppTextString {
  static const String boarding1text1 = 'مرحبا بكم في تجربة فريدة';
  static const String boarding1text2 =
      'متابعة حيه لاحمال العواصم \n متابعة قطاع الكهرباء المصرى';
  static const String boarding2text1 =
      'أكثر من +300 مصدر و مزود خدمة بين يدك الان';
  static const String boarding2text2 =
      'تكامل تام بين المحطات و التحكمات الاقليمية ';
  static const String boarding3text1 =
      'عرض كامل للاحداث اليومية بالشبكة الموحدة ';
  static const String boarding3text2 = ' ... ابدأ الان ';
}

class Appfontstring {
  static const String Abril_Regular = 'Abril_Regular';
  static const String Almarai_Bold = 'Almarai_Bold';
  static const String ChangaBold = 'Changa-Bold';
  static const String Almarai_Light = 'Almarai_Light';
  static const String ChangaLight = 'Changa-Light';
  static const String Rakkas_Regular = 'Rakkas_Regular';
  static const String BebasNeue_Regular = 'BebasNeue_Regular';
  static const String BreeSerif_Regular = 'BreeSerif_Regular';
  static const String CairoPlay_Black = 'CairoPlay_Black';
  static const String CairoPlay_Bold = 'CairoPlay_Bold';
  static const String DancingScript_Medium = 'DancingScript-Medium';
  static const String MysteryQuest_Regular = 'MysteryQuest-Regular';
  static const String ShadowsIntoLight_Regular = 'ShadowsIntoLight-Regular';
  static const String tejwa1 = 'tejwa1';
  static const String tejw2 = 'tejwa2';
  static const String tejwal3 = 'tejwa3';
  static const String digital = 'digital';
}

class FF {
  static const FontWeight B = FontWeight.bold;
}

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
  static const String tableUserCrcc = 'user_crcc';
  static const String tableUserTop = 'user_top';
  static const String tableUserCm = 'user_cm';
  static const String tableUserProject = 'user_project';
  static const String tableUserOthers = 'user_others';
  static const String tableCallsSignaling = 'calls_signaling';
  static const String tableEvents = 'events';
  static const String tableProjects = 'projects';
  static const String tableSpareCells = 'spare_cells';
  static const String tableCapacitors = 'capacitors';
  static const String tableCategoryItems = 'category_items';
  static const String tableAnnouncingImages = 'announcing_images';
  static const String tableWorldTable = 'world_table';
  static const String tableZone = 'zone';
  static const String tableNetworkFaults = 'network_faults';
  static const String tableReportsConfig = 'reports_config';

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
  static const Color secondaryColor = Color(0xFF03DAC6); // Teal
  static const Color warningColor = Color(0xFFFFB300); // Amber
  static const Color errorColor = Color(0xFFD32F2F); // Red
  static const Color backgroundColor = Color(0xFFFFFFFF); // White
  static const Color gold = Color(0xFFFFD700); // Gold

  static const List<Color> indicatorBackground = [
    Appcolors.primaryColor,
    Appcolors.primaryColor,
    Color(0xFF163C5E),
    Color(0xFF0F2B44),
    Color(0xFF081A2A),
  ];
}

class StationDetailsConstants {
  static const Color secondaryColor = Color.fromARGB(255, 230, 156, 19);
  static const Color textColor = Colors.black;
  static const Color subtitleColor = Color.fromARGB(255, 99, 110, 209);
  static const Color backgroundColor = Color.fromARGB(255, 219, 216, 216);
  static const double horizontalPadding = 13.0;
  static const double verticalPadding = 10.0;
  static const double borderRadius = 15.0;
}

class AppimageString {
  AppimageString._(); // Private constructor to prevent instantiation

  static const String image55 = 'lib/assets/images/g/image55.jpg';
  static const String minisrty = 'lib/assets/images/g/ministry.jpg';
  static const String aaa = 'lib/assets/images/g/aaa.jpg';
  static const String qq = 'lib/assets/images/g/qq.png';
  static const String on1 = 'lib/assets/images/g/on1.jpg';
  static const String on2 = 'lib/assets/images/g/on2.jpg';
  static const String on3 = 'lib/assets/images/g/on3.jpg';
  static const String on4 = 'lib/assets/images/g/on41.jpg';
  static const String on5 = 'lib/assets/images/g/on42.png';
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
      'عرض كامل للاحداث بالشبكة الموحدة من تقارير مهندسى التحكم ';
  static const String boarding3text2 = ' ... ابدأ الان ';
  static const String boarding4text1 = 'اصدار خاص';
  static const String boarding4text2 =
      'الشركة المصرية لنقل الكهرباء  \nبرعاية المهندسه الفاضلة / منى رزق \n رئيسة الشركة المصرية لنقل الكهربـاء';
}

class Appfontstring {
  static const String ChangaLight = 'Changa-Light';
  static const String digital = 'digital';
}

class FF {
  static const FontWeight B = FontWeight.bold;
}

class AppBarText {
  static const String companyName = 'الشـركـة المصريـة لنـقـل الكهـرباء';
  static const String cairo = '(القاهـرة) ';
  static const String regionalControl = 'التحكم الاقليمى';
  static const String userPrefix = 'User : ';
  static const String unknownUser = 'غير معروف';
  static const String loadingFailed = 'فشل التحميل - انقر للمحاولة';

  // Sign Out Dialog
  static const String signOutTitle = 'تاكيد الخروج';
  static const String signOutMessage = 'هل تريد تسجيل الخروج؟';
  static const String signOutButton = 'تسجيل الخروج';
  static const String cancelButton = 'إلغاء';

  // Status Messages
  static const String signOutLoading = 'جاري تسجيل الخروج...';
  static const String signOutError = 'حدث خطأ أثناء تسجيل الخروج';
  static const String retry = 'إعادة المحاولة';
}

class Stringshomenav {
  static const String noCategories = 'No categories available';
  static const String noImages = 'No images available';
  static const String noStationData = 'No station data available';
  static const String noWeatherData = 'No weather data available';
  static const String retry = 'Retry';
  static const String newsHeadline = 'الاخبـار';
  static const String cairoWeatherHeadline = 'طقس القاهرة';
  static const String networkLoadHeadline = 'حمل شبكة القاهرة ';
  static const String exchangeHeadline = 'التبادلات مع التحكمات الاقليمية';
  static const String generationHeadline = 'التوليد';
  static const String seeAll = 'الكـل';
  static const String weatherNow = 'الطقس الآن';
  static const String msgAccessDenied = 'غير مصرح لك بالوصول إلى هذه الفئة';
  static const String msgOtherDepts = 'مخصص لادارات اخرى';
  static const String msgNotReady = 'الفئة غير جاهزة بعد';
}

class OnboardingConstants {
  // Animation durations
  static const fadeDuration = Duration(milliseconds: 1200);
  static const zoomDuration = Duration(milliseconds: 700);
  static const delay200 = Duration(milliseconds: 400);
  static const delay400 = Duration(milliseconds: 500);

  // Layout ratios
  static const double skipButtonTopRatio = 0.02;
  static const double skipButtonRightRatio = 0.044;
  static const double dotsBottomRatio = 0.22;
  static const double dotsLeftRatio = 0.44;
  static const double buttonBottomRatio = 0.04;
  static const double buttonRightRatio = 0.04;
  static const double contentHorizontalRatio = 0.07;
  static const double contentVerticalRatio = 0.07;
  static const double imageTopSpacingRatio = 0.1;
  static const double imageMaxHeightRatio = 0.5;
  static const double imageMaxWidthRatio = 0.8;
  static const double titleSpacingRatio = 0.05;
  static const double subtitleSpacingRatio = 0.015;

  // UI Constants
  static const borderRadius = 24.0;
  static const borderWidth = 0.5;
  static const shadowBlurRadius = 20.0;
  static const shadowSpreadRadius = 1.0;
  static const shadowOpacity = 0.3;
  static const dotSpacing = 5.0;
  static const dotRadius = 8.0;
  static const activeDotWidth = 15.0;
  static const inactiveDotHeight = 4.0;
  static const buttonElevation = 6.0;
  static const buttonPaddingRatio = 0.05;
  static const buttonIconSizeRatio = 15.0;
  static const baseScreenWidth = 375.0;
  static const baseFontSizeTitle = 22.0;
  static const baseFontSizeSubtitle = 12.0;
  static const baseFontSizeButton = 14.0;

  // Colors
  static const Color backgroundColor = Colors.transparent;
  static const Color shadowColor = Colors.blue;
  static const Color inactiveDotColor = Colors.white24;
  static const Color activeDotColor = Colors.blue;
  static const Color buttonBackgroundColor = Colors.white;
  static const Color borderColor = Colors.white24;
  static const Color subtitleColor = Colors.white60;
  static const Color skipButtonBorderColor = Colors.white30;

  // Design Specifics
  static const double glassOpacity = 0.08;
  static const double glassBlur = 25.0;
}

class CacheConstants {
  static const String stationLoadsKey = 'cached_station_loads';
  static const String timestampKey = 'cache_timestamp';
  static const String updateTimestampsKey = 'cached_update_timestamps';
  static const int cacheValidityMinutes = 10;
  static const String hourlyMaxLoadsKey = 'cached_hourly_max_loads';
  static const String intlLoadsKey = 'cached_intl_loads';
  static const String intlCacheTimestampKey = 'intl_cache_timestamp';
}

class WeatherConstants {
  static const String weatherCacheKey = 'cached_weather_data';
}

class StationConstants {
  static const double maxStationLoad = 700.0;
  static const Duration updateInterval = Duration(seconds: 6);
  static const int maxRetries = 5;
}

class IndicatorConstants {
  static const List<String> exchangeStations = [
    'عبور3/عاشر',
    'الكريمات/بنى سويف',
    'قليوب/قناطر',
    'برقاش/ابوغالب',
    'ابو زعبل ق / بلبيس',
  ];
  static const String generationStation = 'الكريمات الشمسية';
}

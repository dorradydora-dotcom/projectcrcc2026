import 'dart:convert';
import 'package:amiraly/app/util/validators/validator_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:amiraly/app/util/constant/constants.dart';

/// معالج رسائل الخلفية (يجب أن يكون top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    await NotificationManager().initialize();

    final String title = message.data['title'] ?? 'تعليمات طارئة';
    final String body = message.data['body'] ?? '';
    final String? route = message.data['route'];

    if (body.isNotEmpty) {
      await NotificationManager()
          .show(title, body, message.messageId, route: route);
    }
  } catch (e, stackTrace) {
    AppLogger.logError('Background message handler failed', e, stackTrace);
  }
}

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        AppConstants.notificationChannelId,
        AppConstants.notificationChannelName,
        description: AppConstants.notificationChannelDescription,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: AndroidInitializationSettings(AppConstants.notificationIcon),
        iOS: DarwinInitializationSettings(),
      );

      await _plugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _handleNotificationTap,
      );

      _isInitialized = true;
      AppLogger.logSuccess('🔔 Local notifications initialized');
    } catch (e, stackTrace) {
      AppLogger.logError(
          'Local notifications initialization failed', e, stackTrace);
      rethrow;
    }
  }

  void _handleNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(response.payload!);
        final String? route = data['route'];
        if (route != null) _navigateToRoute(route);
      } catch (e) {
        if (kDebugMode) {
          AppLogger.logError('Failed to handle notification tap', e);
        }
      }
    }
  }

  void _navigateToRoute(String route) {
    switch (route) {
      case AppConstants.routeService:
        Get.toNamed('/${AppConstants.routeService}');
        break;
      case AppConstants.routeAnnouncement:
        Get.toNamed('/${AppConstants.routeInstructions}');
        break;
      case AppConstants.routeEvents:
        Get.toNamed('/${AppConstants.routeEvents}');
        break;
      default:
        if (kDebugMode) AppLogger.logWarning('Unknown route: $route');
    }
  }

  Future<void> show(
    String title,
    String body,
    String? messageId, {
    String? route,
  }) async {
    if (messageId == null || !_isInitialized) return;

    if (await _isNotificationProcessed(messageId)) {
      if (kDebugMode) AppLogger.logInfo('Duplicate notification skipped');
      return;
    }

    await _markNotificationAsProcessed(messageId);

    try {
      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        AppConstants.notificationChannelId,
        AppConstants.notificationChannelName,
        channelDescription: AppConstants.notificationChannelDescription,
        importance: Importance.max,
        priority: Priority.high,
        icon: AppConstants.notificationIcon,
        largeIcon: DrawableResourceAndroidBitmap(AppConstants.notificationIcon),
        ledOnMs: 1000,
        ledOffMs: 500,
        enableVibration: true,
        fullScreenIntent: true,
        playSound: true,
        showWhen: true,
        styleInformation: BigTextStyleInformation(
          body,
          htmlFormatBigText: false,
          contentTitle: title,
          summaryText: '( تنبيه هام )',
        ),
      );

      await _plugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        NotificationDetails(android: androidDetails),
        payload: jsonEncode({'route': route ?? AppConstants.routeAnnouncement}),
      );

      AppLogger.logSuccess('📨 Notification shown: $title');
    } catch (e, stackTrace) {
      AppLogger.logError('Failed to show notification', e, stackTrace);
    }
  }

  Future<bool> _isNotificationProcessed(String messageId) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> processedList =
          prefs.getStringList(AppConstants.processedNotificationsKey) ?? [];
      return processedList.contains(messageId);
    } catch (e) {
      if (kDebugMode) {
        AppLogger.logError('Failed to check notification status', e);
      }
      return false;
    }
  }

  Future<void> _markNotificationAsProcessed(String messageId) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> processedList =
          prefs.getStringList(AppConstants.processedNotificationsKey) ?? [];
      processedList.add(messageId);
      if (processedList.length > AppConstants.maxProcessedNotifications) {
        processedList.removeAt(0);
      }
      await prefs.setStringList(
          AppConstants.processedNotificationsKey, processedList);
    } catch (e) {
      if (kDebugMode) {
        AppLogger.logError('Failed to mark notification as processed', e);
      }
    }
  }
}

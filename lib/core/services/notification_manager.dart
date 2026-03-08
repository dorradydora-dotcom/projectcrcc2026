import 'dart:convert';
import 'package:amiraly/app/util/validators/validator_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:amiraly/app/util/constant/constants.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    debugPrint('🔥 [Background Message] Received: ${message.messageId}');
    debugPrint('🔥 [Background Message] Data: ${message.data}');

    await Firebase.initializeApp();
    await NotificationManager().initialize();

    final String title =
        message.data['title'] ?? message.notification?.title ?? 'تعليمات طارئة';
    final String body =
        message.data['body'] ?? message.notification?.body ?? '';
    final String? route = message.data['route'];

    if (route == 'call') {
      debugPrint('🔥 [Background Message] Call route detected');
      final status = message.data['status'];
      if (status == 'ended' || status == 'rejected') {
        final callId = message.data['call_id'];
        if (callId != null) {
          await FlutterCallkitIncoming.endCall(callId);
        } else {
          await FlutterCallkitIncoming.endAllCalls();
        }
        return;
      }
      debugPrint('🔥 [Background Message] Showing CallKit');
      await NotificationManager().showCallKit(message.data);
      return;
    }

    if (body.isNotEmpty) {
      await NotificationManager().show(title, body, message.messageId,
          route: route, data: message.data);
    }
  } catch (e, stackTrace) {
    debugPrint('🔥 [Background Message] Error: $e');
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
        if (route != null) _navigateToRoute(route, data: data);
      } catch (e) {
        if (kDebugMode) {
          AppLogger.logError('Failed to handle notification tap', e);
        }
      }
    }
  }

  void _navigateToRoute(String route, {Map<String, dynamic>? data}) {
    switch (route) {
      case AppConstants.routeService:
        Get.toNamed('/${AppConstants.routeService}', arguments: data);
        break;
      case AppConstants.routeAnnouncement:
        Get.toNamed('/${AppConstants.routeInstructions}', arguments: data);
        break;
      case AppConstants.routeEvents:
        Get.toNamed('/${AppConstants.routeEvents}', arguments: data);
        break;
      case 'call':
        // نتوجه لصفحة GoLive مباشرة مع تمرير بيانات المكالمة
        Get.toNamed('Go live', arguments: data);
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
    Map<String, dynamic>? data,
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
        payload: jsonEncode({
          'route': route ?? AppConstants.routeAnnouncement,
          if (data != null) ...data,
        }),
      );

      AppLogger.logSuccess('📨 Notification shown: $title');
    } catch (e, stackTrace) {
      AppLogger.logError('Failed to show notification', e, stackTrace);
    }
  }

  Future<void> showCallKit(Map<String, dynamic> data) async {
    final String? callId = data['call_id'];
    if (callId == null) {
      debugPrint('Cannot show CallKit: missing call_id in data');
      return;
    }
    final callerName = data['caller_name'] ?? 'محطة غير معروفة';
    final channelName = data['channel_name'] ?? 'g-live';

    final params = CallKitParams(
      id: callId,
      nameCaller: callerName,
      appName: 'Amiraly GoLive',
      handle: 'فيديو مباشر',
      type: 1, // 0: Audio, 1: Video
      duration: 30000,
      textAccept: 'رد',
      textDecline: 'رفض',
      missedCallNotification: const NotificationParams(
        showNotification: true,
        isShowCallback: true,
        subtitle: 'مكالمة فائتة',
        callbackText: 'اتصال لاحقاً',
      ),
      extra: <String, dynamic>{
        'route': 'call',
        'call_id': callId,
        'channel_name': channelName,
        'caller_name': callerName,
      },
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: true,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#071624',
        actionColor: '#4CAF50',
        incomingCallNotificationChannelName: "Incoming Call",
        missedCallNotificationChannelName: "Missed Call",
      ),
    );

    await FlutterCallkitIncoming.showCallkitIncoming(params);
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

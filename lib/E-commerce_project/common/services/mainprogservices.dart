// ============================================================================
// NOTIFICATION MANAGER
// ============================================================================

import 'dart:async';
import 'dart:convert';
import 'package:amiraly/E-commerce_project/common/models/appmodels.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:amiraly/E-commerce_project/util/constant/constants.dart';
import 'package:amiraly/E-commerce_project/util/validators/validatorHeper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// مدير الإشعارات المحلية (Singleton)
class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  FlutterLocalNotificationsPlugin get plugin => _plugin;

  bool _isInitialized = false;

  /// تهيئة الإشعارات المحلية
  Future<void> initialize() async {
    if (_isInitialized) {
      AppLogger.logWarning('Notifications already initialized');
      return;
    }

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

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings(AppConstants.notificationIcon);
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings();
      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _plugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          _handleNotificationTap(response);
        },
      );

      _isInitialized = true;
      AppLogger.logSuccess('Local notifications initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.logError(
          'Local notifications initialization failed', e, stackTrace);
      rethrow;
    }
  }

  /// معالجة النقر على الإشعار
  void _handleNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(response.payload!);
        final String? route = data['route'];

        if (route != null) {
          _navigateToRoute(route);
        }
      } catch (e) {
        AppLogger.logError('Failed to handle notification tap', e);
      }
    }
  }

  /// التنقل إلى المسار المحدد
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
        AppLogger.logWarning('Unknown route: $route');
    }
  }

  /// عرض إشعار محلي
  Future<void> show(
    String title,
    String body,
    String? messageId, {
    String? route,
  }) async {
    if (messageId == null) {
      AppLogger.logWarning('Message ID is null, skipping notification');
      return;
    }

    // التحقق من عدم تكرار الإشعار
    if (await _isNotificationProcessed(messageId)) {
      AppLogger.logInfo('Duplicate notification skipped: $messageId');
      return;
    }

    await _markNotificationAsProcessed(messageId);

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

      NotificationDetails platformDetails =
          NotificationDetails(android: androidDetails);

      await _plugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        platformDetails,
        payload: jsonEncode({'route': route ?? AppConstants.routeAnnouncement}),
      );

      AppLogger.logSuccess('Notification shown: $title');
    } catch (e, stackTrace) {
      AppLogger.logError('Failed to show notification', e, stackTrace);
    }
  }

  /// التحقق من معالجة الإشعار مسبقاً
  Future<bool> _isNotificationProcessed(String messageId) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> processedList =
          prefs.getStringList(AppConstants.processedNotificationsKey) ?? [];
      return processedList.contains(messageId);
    } catch (e) {
      AppLogger.logError('Failed to check notification status', e);
      return false;
    }
  }

  /// تحديد الإشعار كمعالج
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
        AppConstants.processedNotificationsKey,
        processedList,
      );
    } catch (e) {
      AppLogger.logError('Failed to mark notification as processed', e);
    }
  }
}

// ============================================================================
// BACKGROUND MESSAGE HANDLER
// ============================================================================

/// معالج الرسائل في الخلفية (Top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    await NotificationManager().initialize();

    final String title = message.data['title'] ?? 'تعليمات طارئة';
    final String body = message.data['body'] ?? '';
    final String? route = message.data['route'];

    if (body.isNotEmpty) {
      await NotificationManager().show(
        title,
        body,
        message.messageId,
        route: route,
      );
    }
  } catch (e, stackTrace) {
    AppLogger.logError('Background message handler failed', e, stackTrace);
  }
}

/// تطبيق الأخطاء
class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'حدث خطأ في تهيئة التطبيق',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  // إعادة تشغيل التطبيق
                },
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// ============================================================================
// NOTIFICATION SERVICE
// ============================================================================

/// خدمة إرسال الإشعارات عبر FCM
class NotificationService {
  /// تحميل بيانات Service Account من .env
  static Future<Map<String, dynamic>> getServiceAccountJson() async {
    final String? jsonString = dotenv.env['SERVICE_ACCOUNT_JSON'];

    if (jsonString == null || jsonString.isEmpty) {
      throw Exception('SERVICE_ACCOUNT_JSON not found in .env');
    }

    try {
      final Map<String, dynamic> parsed = jsonDecode(jsonString);
      if (parsed['private_key'] == null) {
        throw Exception('Invalid SERVICE_ACCOUNT_JSON: private_key is missing');
      }
      return parsed;
    } catch (e, stackTrace) {
      AppLogger.logError('Failed to parse SERVICE_ACCOUNT_JSON', e, stackTrace);
      rethrow;
    }
  }

  /// الحصول على Access Token
  static Future<String> getAccessToken() async {
    try {
      final Map<String, dynamic> serviceAccountJson =
          await getServiceAccountJson();

      List<String> scopes = [
        "https://www.googleapis.com/auth/userinfo.email",
        "https://www.googleapis.com/auth/firebase.database",
        "https://www.googleapis.com/auth/firebase.messaging"
      ];

      http.Client client = await auth.clientViaServiceAccount(
        auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
        scopes,
      );

      auth.AccessCredentials credentials =
          await auth.obtainAccessCredentialsViaServiceAccount(
        auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
        scopes,
        client,
      );

      client.close();
      return credentials.accessToken.data;
    } catch (e, stackTrace) {
      AppLogger.logError('Failed to get access token', e, stackTrace);
      rethrow;
    }
  }

  static String get fcmProjectId =>
      dotenv.env['FCM_PROJECT_ID'] ?? 'crccproject-98fb0';

  static String get fcmEndpoint =>
      dotenv.env['FCM_ENDPOINT'] ??
      'https://fcm.googleapis.com/v1/projects/$fcmProjectId/messages:send';

  /// إرسال إشعار واحد
  static Future<bool> _sendSingleNotification(
    String deviceToken,
    String title,
    String body, {
    String? route,
  }) async {
    try {
      final String accessToken = await getAccessToken();
      final String endpointFCM = fcmEndpoint;

      final Map<String, dynamic> messagePayload = {
        "notification": {
          "title": title,
          "body": body,
        },
        "android": {
          "notification": {
            "channel_id": AppConstants.notificationChannelId,
            "icon": AppConstants.notificationIcon,
          },
        },
        "data": {
          "title": title,
          "body": body,
          if (route != null) "route": route,
        },
        "token": deviceToken,
      };

      final http.Response response = await http.post(
        Uri.parse(endpointFCM),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken'
        },
        body: jsonEncode({"message": messagePayload}),
      );

      if (response.statusCode == 200) {
        AppLogger.logSuccess('Notification sent to $deviceToken');
        return true;
      } else {
        AppLogger.logError(
          'Failed to send notification to $deviceToken',
          'Status: ${response.statusCode}, Body: ${response.body}',
        );
        return false;
      }
    } catch (e, stackTrace) {
      AppLogger.logError(
          'Error sending notification to $deviceToken', e, stackTrace);
      return false;
    }
  }

  /// إرسال إشعارات لجدول معين
  static Future<Map<String, dynamic>> sendNotification(
    String tableName,
    String title,
    String body, {
    String? route,
  }) async {
    if (tableName.isEmpty) {
      return {'success': false, 'message': 'Table name is empty'};
    }

    try {
      final supabase = Supabase.instance.client;
      final data = await supabase.from(tableName).select('user_token');

      if (data.isEmpty) {
        AppLogger.logWarning('No device tokens found in table: $tableName');
        return {'success': false, 'message': 'No tokens found', 'sent': 0};
      }

      // إرسال متوازي لتحسين الأداء
      final futures = data.map((row) {
        String? deviceToken = row['user_token'];
        if (deviceToken != null && deviceToken.isNotEmpty) {
          return _sendSingleNotification(deviceToken, title, body,
              route: route);
        }
        return Future.value(false);
      });

      final results = await Future.wait(futures);
      final successCount = results.where((result) => result).length;

      AppLogger.logSuccess('Notifications sent: $successCount/${data.length}');
      return {
        'success': true,
        'sent': successCount,
        'total': data.length,
      };
    } catch (e, stackTrace) {
      AppLogger.logError('Supabase query error', e, stackTrace);
      return {'success': false, 'message': e.toString()};
    }
  }
}
// ============================================================================
// SUPABASE SERVICE
// ============================================================================

/// خدمة Supabase لإدارة المحطات
class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  /// جلب أحمال المحطات
  Future<List<StationLoad>> fetchStationLoads({
    int limit = AppConstants.defaultFetchLimit,
  }) async {
    try {
      final response = await _client
          .from(AppConstants.tableStation)
          .select()
          .limit(limit)
          .timeout(AppConstants.timeoutDuration);

      return (response as List<dynamic>)
          .map((json) => StationLoad.fromJson(json))
          .toList();
    } on TimeoutException {
      AppLogger.logError('Request timed out');
      throw Exception('انتهت مهلة الطلب. تحقق من اتصالك بالإنترنت');
    } on PostgrestException catch (e) {
      AppLogger.logError('Database error', e);
      throw Exception('خطأ في قاعدة البيانات: ${e.message}');
    } catch (e, stackTrace) {
      AppLogger.logError('Failed to fetch station loads', e, stackTrace);
      throw Exception('فشل في جلب بيانات المحطات');
    }
  }

  /// جلب محطات محددة
  Future<Map<String, String>> fetchSpecificStations() async {
    try {
      final response = await _client
          .from(AppConstants.tableStationsAuth)
          .select('st_name, st_email');

      final Map<String, String> specificStations = {};
      for (final row in response) {
        final stName = row['st_name'] as String;
        final stEmail = row['st_email'] as String;
        specificStations[stName] = stEmail;
      }

      return specificStations;
    } catch (e, stackTrace) {
      AppLogger.logError('Failed to fetch specific stations', e, stackTrace);
      return {};
    }
  }

  /// تحديث حمل المحطة
  Future<void> updateStationLoad(String stationName, double newLoad) async {
    final now = DateTime.now();
    final hourStr = 'hour_${now.hour.toString().padLeft(2, '0')}';

    try {
      await _client
          .from(AppConstants.tableStation)
          .update({
            'station_load': newLoad,
            hourStr: newLoad,
          })
          .eq('station_name', stationName)
          .timeout(AppConstants.timeoutDuration);

      AppLogger.logSuccess('Station load updated: $stationName = $newLoad');
    } on PostgrestException catch (e) {
      AppLogger.logError('Database error while updating station', e);
      throw Exception('خطأ في قاعدة البيانات: ${e.message}');
    } catch (e, stackTrace) {
      AppLogger.logError('Failed to update station load', e, stackTrace);
      throw Exception('فشل في تحديث حمل المحطة');
    }
  }

  /// إضافة/تحديث الحمل الأقصى للساعة
  Future<void> upsertHourlyMaxLoad(
    int hour,
    DateTime date,
    double maxLoad,
  ) async {
    try {
      final formattedDate = date.toIso8601String().split('T')[0];
      await _client.from(AppConstants.tableHourlyMaxLoads).upsert({
        'hour': hour,
        'date': formattedDate,
        'max_load': maxLoad,
      }, onConflict: 'hour,date').timeout(AppConstants.timeoutDuration);

      AppLogger.logSuccess('Hourly max load upserted: Hour $hour = $maxLoad');
    } on PostgrestException catch (e) {
      AppLogger.logError('Database error while upserting', e);
      throw Exception('خطأ في قاعدة البيانات: ${e.message}');
    } catch (e, stackTrace) {
      AppLogger.logError('Failed to upsert hourly max load', e, stackTrace);
      throw Exception('فشل في تحديث الحمل الأقصى للساعة');
    }
  }

  /// جلب الأحمال الأقصى للساعات
  Future<List<Map<String, dynamic>>> fetchHourlyMaxLoads(DateTime date) async {
    try {
      final formattedDate = date.toIso8601String().split('T')[0];
      return await _client
          .from(AppConstants.tableHourlyMaxLoads)
          .select()
          .eq('date', formattedDate)
          .order('hour', ascending: true)
          .timeout(AppConstants.timeoutDuration);
    } on PostgrestException catch (e) {
      AppLogger.logError('Database error while fetching hourly loads', e);
      throw Exception('خطأ في قاعدة البيانات: ${e.message}');
    } catch (e, stackTrace) {
      AppLogger.logError('Failed to fetch hourly max loads', e, stackTrace);
      throw Exception('فشل في جلب الأحمال الأقصى للساعات');
    }
  }
}

// ============================================================================
// SUPABASE SERVICE HOURLY
// ============================================================================

/// خدمة Supabase للأحمال الساعية
class SupabaseServiceHourly {
  final SupabaseClient _client = Supabase.instance.client;

  /// جلب الأحمال الساعية للمحطات
  Future<List<StationHourlyLoad>> fetchStationHourlyLoads({
    int limit = AppConstants.hourlyFetchLimit,
  }) async {
    try {
      final response = await _client
          .from(AppConstants.tableStation)
          .select(
            'station_name, hour_00, hour_01, hour_02, hour_03, hour_04, '
            'hour_05, hour_06, hour_07, hour_08, hour_09, hour_10, hour_11, '
            'hour_12, hour_13, hour_14, hour_15, hour_16, hour_17, hour_18, '
            'hour_19, hour_20, hour_21, hour_22, hour_23',
          )
          .limit(limit)
          .timeout(AppConstants.timeoutDuration);

      return (response as List<dynamic>)
          .map((json) => StationHourlyLoad.fromJson(json))
          .toList();
    } on TimeoutException {
      AppLogger.logError('Request timed out');
      throw Exception('انتهت مهلة الطلب. تحقق من اتصالك بالإنترنت');
    } on PostgrestException catch (e) {
      AppLogger.logError('Database error', e);
      throw Exception('خطأ في قاعدة البيانات: ${e.message}');
    } catch (e, stackTrace) {
      AppLogger.logError('Failed to fetch station hourly loads', e, stackTrace);
      throw Exception('فشل في جلب الأحمال الساعية للمحطات');
    }
  }
}

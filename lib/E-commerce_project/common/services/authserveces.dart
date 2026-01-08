// ============================================================================
// AUTH SERVICE
// ============================================================================

import 'dart:async';

import 'package:amiraly/E-commerce_project/common/services/mainprogservices.dart';
import 'package:amiraly/E-commerce_project/features/auth/login/loginscreen.dart';
import 'package:amiraly/E-commerce_project/util/constant/constants.dart';
import 'package:amiraly/E-commerce_project/util/validators/validatorHeper.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// خدمة المصادقة والتفويض (Singleton)
///
/// توفر وظائف:
/// - تسجيل الدخول والخروج
/// - إدارة المستخدمين
/// - Firebase Messaging
/// - Supabase Authentication
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  late final SupabaseClient _supabase;
  String? userName;
  String? userEmail;

  // FCM Subscriptions
  StreamSubscription<RemoteMessage>? _onMessageSubscription;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSubscription;

  void _showSnackbar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            message,
            style: TextStyle(fontFamily: Appfontstring.ChangaLight),
          ),
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: AppConstants.snackbarDuration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static String get supabaseUrl {
    final url = dotenv.env['SUPABASE_URL'];
    if (url == null || url.isEmpty) {
      throw Exception('SUPABASE_URL not found in .env');
    }
    return url;
  }

  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY']!;

  /// تهيئة Firebase
  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp();
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
      AppLogger.logSuccess('Firebase initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.logError('Firebase initialization failed', e, stackTrace);
      rethrow;
    }
  }

  /// تهيئة Supabase
  Future<void> _initializeSupabase() async {
    try {
      String url = dotenv.env['SUPABASE_URL'] ?? supabaseUrl;
      String key = dotenv.env['SUPABASE_ANON_KEY'] ?? supabaseAnonKey;

      await Supabase.initialize(url: url, anonKey: key);
      _supabase = Supabase.instance.client;

      AppLogger.logSuccess('Supabase initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.logError('Supabase initialization failed', e, stackTrace);
      rethrow;
    }
  }

  /// طلب صلاحيات الإشعارات
  Future<void> _requestNotificationPermission() async {
    try {
      NotificationSettings settings =
          await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        AppLogger.logSuccess('Notification permission granted');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        AppLogger.logInfo('Notification permission provisional');
      } else {
        AppLogger.logWarning('Notification permission denied');
      }
    } catch (e, stackTrace) {
      AppLogger.logError(
          'Error requesting notification permission', e, stackTrace);
    }
  }

  /// الحصول على Firebase Token
  Future<void> _retrieveFirebaseToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        AppLogger.logInfo('Firebase Token: $token');
      } else {
        AppLogger.logWarning('Failed to retrieve Firebase token');
      }
    } catch (e, stackTrace) {
      AppLogger.logError('Error retrieving Firebase token', e, stackTrace);
    }
  }

  /// إعداد مستمعي FCM
  void _setupFCMListeners() {
    // الرسائل أثناء تشغيل التطبيق
    _onMessageSubscription =
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      AppLogger.logInfo('Message received: ${message.data}');

      final String title = message.data['title'] ?? 'تعليمات طارئة';
      final String body = message.data['body'] ?? '';
      final String? route = message.data['route'];

      if (body.isNotEmpty) {
        NotificationManager()
            .show(title, body, message.messageId, route: route);
      }
    });

    // فتح التطبيق من الإشعار
    _onMessageOpenedAppSubscription =
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      AppLogger.logInfo('Message opened app: ${message.data}');
      _handleMessageRoute(message.data['route']);
    });

    // التطبيق مغلق تماماً
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? initialMessage) {
      if (initialMessage != null) {
        AppLogger.logInfo('Initial message: ${initialMessage.data}');
        _handleMessageRoute(initialMessage.data['route']);
      }
    });
  }

  /// معالجة التوجيه من الإشعار
  void _handleMessageRoute(String? route) {
    if (route == null) return;

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

  /// تهيئة جميع خدمات التطبيق
  Future<void> initializeAppServices() async {
    try {
      await _initializeFirebase();
      await _initializeSupabase();
      await _requestNotificationPermission();
      await _retrieveFirebaseToken();
      await NotificationManager().initialize();

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      _setupFCMListeners();

      AppLogger.logSuccess('All app services initialized');
    } catch (e, stackTrace) {
      AppLogger.logError('Failed to initialize app services', e, stackTrace);
      rethrow;
    }
  }

  /// إدراج بيانات في جدول
  Future<void> insertData(String tableName, String email, String name) async {
    try {
      await _supabase.from(tableName).insert({
        'user_email': email.trim(),
        'user_name': name.trim(),
      });
      AppLogger.logSuccess('Data inserted successfully');
    } catch (e, stackTrace) {
      AppLogger.logError('Failed to insert data', e, stackTrace);
      rethrow;
    }
  }

  /// تحديث بيانات في جدول
  Future<void> updateData(String tableName, String name) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from(tableName)
          .update({'user_name': name}).eq('user_id', userId);

      AppLogger.logSuccess('Data updated successfully');
    } catch (e, stackTrace) {
      AppLogger.logError('Failed to update data', e, stackTrace);
      rethrow;
    }
  }

  /// تسجيل الدخول
  Future<Session?> login({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (context.mounted) {
        _showSnackbar(context, 'تم تسجيل الدخول بنجاح!');
      }

      AppLogger.logSuccess('User logged in: $email');
      return response.session;
    } on AuthException catch (e) {
      AppLogger.logError('Login failed - AuthException', e);
      if (context.mounted) {
        _showSnackbar(
          context,
          'خطأ في تسجيل الدخول: ${e.message}',
          isError: true,
        );
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.logError('Login failed - Unknown error', e, stackTrace);
      if (context.mounted) {
        _showSnackbar(context, 'حدث خطأ غير متوقع', isError: true);
      }
      return null;
    }
  }

  /// تسجيل الخروج
  Future<void> signOut({required BuildContext context}) async {
    try {
      // إلغاء الاشتراكات أولاً
      _onMessageSubscription?.cancel();
      _onMessageOpenedAppSubscription?.cancel();
      _onMessageSubscription = null;
      _onMessageOpenedAppSubscription = null;
      Get.delete<AuthService>();
      await _supabase.auth.signOut();

      if (context.mounted) {
        Get.offAll(() => const LoginScreen());
        _showSnackbar(context, 'تم تسجيل الخروج!', isError: true);
      }

      AppLogger.logSuccess('User signed out');
    } catch (e, stackTrace) {
      AppLogger.logError('Sign out failed', e, stackTrace);
      if (context.mounted) {
        _showSnackbar(context, 'فشل تسجيل الخروج', isError: true);
      }
    }
  }

  /// الحصول على تفاصيل المستخدم
  Future<Map<String, String>> getUserDetails() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        userName = user.userMetadata?['name']?.toString() ?? 'User';
        userEmail = user.email ?? 'No email';
        return {'name': userName!, 'email': userEmail!};
      }
      return {'name': 'Guest', 'email': 'No email'};
    } catch (e, stackTrace) {
      AppLogger.logError('Failed to fetch user details', e, stackTrace);
      return {'name': 'Error', 'email': 'Error'};
    }
  }

  /// الحصول على المستخدم الحالي
  User? getCurrentUser() => _supabase.auth.currentUser;

  /// الحصول على بريد المستخدم الحالي
  String? getCurrentUserEmail() {
    final user = _supabase.auth.currentUser;
    return user?.email;
  }

  /// التحقق من صلاحية تحديث المحطة
  Future<bool> canUpdateStation(String stationName, String userEmail) async {
    try {
      final response = await _supabase
          .from(AppConstants.tableUserStations)
          .select('station_name')
          .eq('user_email', userEmail)
          .eq('station_name', stationName);

      return response.isNotEmpty;
    } catch (e, stackTrace) {
      AppLogger.logError(
          'Failed to check station update permission', e, stackTrace);
      return false;
    }
  }

  /// تنظيف الموارد
  void dispose() {
    _onMessageSubscription?.cancel();
    _onMessageOpenedAppSubscription?.cancel();
    AppLogger.logInfo('AuthService disposed');
  }
}

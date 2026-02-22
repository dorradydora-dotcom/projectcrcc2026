import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:amiraly/app/util/constant/constants.dart';
import 'package:amiraly/app/util/validators/validatorHeper.dart';
import 'package:amiraly/app/features/auth/login/loginscreen.dart';
import 'package:amiraly/core/services/notification_manager.dart';

class AuthService extends GetxController {
  static AuthService get instance => Get.find<AuthService>();

  SupabaseClient? _supabase;
  String? userName;
  String? userEmail;

  final List<StreamSubscription> _subscriptions = [];
  final Map<String, dynamic> _cache = {};
  SharedPreferences? _prefs;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  SupabaseClient? get supabase => _supabase;

  SupabaseClient get supabaseRequired {
    if (_supabase == null) {
      throw Exception(
          'Supabase not initialized. Call initializeServices() first.');
    }
    return _supabase!;
  }

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  void _showSnackbar(BuildContext context, String message,
      {bool isError = false}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Directionality(
          textDirection: TextDirection.rtl,
          child: Text(message,
              style: TextStyle(fontFamily: Appfontstring.ChangaLight)),
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: AppConstants.snackbarDuration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> initializeServices() async {
    if (_isInitialized) return;
    try {
      AppLogger.logInfo('🔄 Initializing AuthService...');
      try {
        _supabase = Supabase.instance.client;
        AppLogger.logSuccess('✅ Supabase obtained from instance');
      } catch (e) {
        AppLogger.logWarning(
            'Supabase.instance not available, trying initialization...');
        String url = dotenv.env['SUPABASE_URL'] ?? '';
        String key = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
        if (url.isEmpty || key.isEmpty) {
          throw Exception('Supabase credentials not found in .env');
        }
        await Supabase.initialize(url: url, anonKey: key);
        _supabase = Supabase.instance.client;
        AppLogger.logSuccess('✅ Supabase initialized successfully');
      }

      _setupFCMListeners();
      await _loadUserDataIfLoggedIn();
      _isInitialized = true;
      AppLogger.logSuccess('✅ AuthService initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.logError('❌ AuthService initialization failed', e, stackTrace);
      rethrow;
    }
  }

  Future<void> _loadUserDataIfLoggedIn() async {
    try {
      if (_supabase == null) return;
      final user = _supabase!.auth.currentUser;
      if (user != null) {
        userName = user.userMetadata?['name']?.toString() ?? 'User';
        userEmail = user.email ?? 'No email';
        _cache['user_details'] = {'name': userName!, 'email': userEmail!};
        AppLogger.logInfo('👤 User data loaded: $userName');
      }
    } catch (e) {
      AppLogger.logError('Failed to load user data', e);
    }
  }

  void _setupFCMListeners() {
    try {
      _subscriptions
          .add(FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) AppLogger.logInfo('📨 Message received');
        final String title = message.data['title'] ?? 'تعليمات طارئة';
        final String body = message.data['body'] ?? '';
        final String? route = message.data['route'];
        if (body.isNotEmpty) {
          NotificationManager()
              .show(title, body, message.messageId, route: route);
        }
      }));

      _subscriptions.add(
          FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (kDebugMode) AppLogger.logInfo('📨 Message opened app');
        _handleMessageRoute(message.data['route']);
      }));

      FirebaseMessaging.instance
          .getInitialMessage()
          .then((RemoteMessage? initialMessage) {
        if (initialMessage != null) {
          _handleMessageRoute(initialMessage.data['route']);
        }
      });

      AppLogger.logSuccess('🔔 FCM listeners setup completed');
    } catch (e, stackTrace) {
      AppLogger.logError('Failed to setup FCM listeners', e, stackTrace);
    }
  }

  void _handleMessageRoute(String? route) {
    if (route == null) return;
    try {
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
    } catch (e) {
      AppLogger.logError('Failed to handle message route', e);
    }
  }

  Future<void> insertData(String tableName, String email, String name) async {
    try {
      if (_supabase == null) await initializeServices();
      await _supabase!.from(tableName).insert({
        'user_email': email.trim(),
        'user_name': name.trim(),
      });
      AppLogger.logSuccess('✅ Data inserted successfully');
    } catch (e, stackTrace) {
      AppLogger.logError('Failed to insert data', e, stackTrace);
      rethrow;
    }
  }

  Future<void> updateData(String tableName, String name) async {
    try {
      if (_supabase == null) await initializeServices();
      final userId = _supabase!.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');
      await _supabase!
          .from(tableName)
          .update({'user_name': name}).eq('user_id', userId);
      AppLogger.logSuccess('✅ Data updated successfully');
    } catch (e, stackTrace) {
      AppLogger.logError('Failed to update data', e, stackTrace);
      rethrow;
    }
  }

  Future<Session?> login({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    try {
      if (!_isInitialized || _supabase == null) await initializeServices();
      AppLogger.logInfo('🔑 Attempting login for: $email');
      final response = await _supabase!.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      if (context.mounted) _showSnackbar(context, 'تم تسجيل الدخول بنجاح!');
      AppLogger.logSuccess('✅ User logged in: $email');
      return response.session;
    } on AuthException catch (e) {
      AppLogger.logError('Login failed - AuthException', e);
      if (context.mounted) {
        _showSnackbar(context, 'خطأ في تسجيل الدخول: ${e.message}',
            isError: true);
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.logError('Login failed - Unknown error', e, stackTrace);
      if (context.mounted)
        _showSnackbar(context, 'حدث خطأ غير متوقع', isError: true);
      return null;
    }
  }

  Future<void> signOut({required BuildContext context}) async {
    try {
      AppLogger.logInfo('🚪 Attempting sign out...');
      for (var subscription in _subscriptions) {
        await subscription.cancel();
      }
      _subscriptions.clear();
      _cache.clear();
      _prefs = null;
      if (_supabase != null) await _supabase!.auth.signOut();
      if (context.mounted) {
        Get.offAll(() => const LoginScreen());
        _showSnackbar(context, 'تم تسجيل الخروج بنجاح!');
      }
      AppLogger.logSuccess('✅ User signed out successfully');
    } catch (e, stackTrace) {
      AppLogger.logError('Sign out failed', e, stackTrace);
      if (context.mounted)
        _showSnackbar(context, 'فشل تسجيل الخروج', isError: true);
    }
  }

  Future<Map<String, String>> getUserDetails() async {
    if (_cache.containsKey('user_details')) {
      return _cache['user_details'];
    }
    try {
      if (_supabase == null) return {'name': 'Guest', 'email': 'No email'};
      final user = _supabase!.auth.currentUser;
      if (user != null) {
        userName = user.userMetadata?['name']?.toString() ?? 'User';
        userEmail = user.email ?? 'No email';
        final details = {'name': userName!, 'email': userEmail!};
        _cache['user_details'] = details;
        return details;
      }
      return {'name': 'Guest', 'email': 'No email'};
    } catch (e, stackTrace) {
      AppLogger.logError('Failed to fetch user details', e, stackTrace);
      return {'name': 'Error', 'email': 'Error'};
    }
  }

  String? getCurrentUserEmail() {
    final user = Supabase.instance.client.auth.currentUser;
    return user?.email?.trim().toLowerCase();
  }

  User? getCurrentUser() => Supabase.instance.client.auth.currentUser;

  Future<String?> getCurrentUserEmailSafe() async {
    try {
      if (!_isInitialized || _supabase == null) await initializeServices();
      return _supabase?.auth.currentUser?.email;
    } catch (e, stackTrace) {
      AppLogger.logError(
          'Failed to get current user email safely', e, stackTrace);
      return null;
    }
  }

  Future<bool> canUpdateStation(String stationName, String userEmail) async {
    try {
      if (_supabase == null) await initializeServices();
      final response = await _supabase!
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

  @override
  void onClose() {
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    _cache.clear();
    _prefs = null;
    AppLogger.logInfo('🗑️ AuthService disposed');
    super.onClose();
  }
}

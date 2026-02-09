import 'package:amiraly/E-commerce_project/common/models/appmodels.dart';
import 'package:amiraly/E-commerce_project/features/mainprog/screen/navscreens/favorites_controller.dart';
import 'package:amiraly/E-commerce_project/util/validators/validatorHeper.dart';
import 'package:carousel_slider/carousel_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:amiraly/E-commerce_project/features/auth/login/loginscreen.dart';
import 'package:amiraly/E-commerce_project/util/constant/constants.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:amiraly/E-commerce_project/features/auth/homepage/homepage.dart';
import 'package:amiraly/E-commerce_project/features/auth/onboarding/onboardingscreen.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:amiraly/E-commerce_project/features/mainprog/screen/navscreens/station_load_controller.dart';

// 🔧 إضافة متغيرات تتبع حالة التهيئة
bool _isServicesInitialized = false;
Completer<void> _servicesInitializedCompleter = Completer<void>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar', null);

  try {
    // 1. التهيئة الأساسية فقط
    await dotenv.load(fileName: ".env");

    // 2. تهيئة Firebase أولاً (ضروري للبدء)
    await Firebase.initializeApp();

    // 3. تشغيل التطبيق فوراً
    runApp(const MyApp());

    // 4. تهيئة WebView في الخلفية (للتطوير فقط)
    if (!kReleaseMode) {
      Future.microtask(() async {
        try {
          await InAppWebViewController.setWebContentsDebuggingEnabled(true);
        } catch (e) {
          AppLogger.logWarning('WebView debugging setup failed');
        }
      });
    }

    // 5. تهيئة الخدمات الثقيلة في الخلفية
    Future.microtask(() => _initializeHeavyServicesInBackground());
  } catch (e, stackTrace) {
    AppLogger.logError('Initialization failed', e, stackTrace);
    runApp(const ErrorApp());
  }
}

/// تهيئة الخدمات الثقيلة في الخلفية
Future<void> _initializeHeavyServicesInBackground() async {
  try {
    AppLogger.logInfo('🔄 Starting background services initialization...');

    // 1. تهيئة Supabase
    await _initializeSupabaseInBackground();

    // 2. إعداد الإشعارات
    await _setupNotificationsInBackground();

    // 3. تحديث حالة التهيئة
    _isServicesInitialized = true;
    _servicesInitializedCompleter.complete();

    AppLogger.logSuccess('✅ All background services initialized');
  } catch (e, stackTrace) {
    AppLogger.logError('❌ Background initialization failed', e, stackTrace);
    _servicesInitializedCompleter.completeError(e);
  }
}

/// تهيئة Supabase في الخلفية
Future<void> _initializeSupabaseInBackground() async {
  try {
    String url = dotenv.env['SUPABASE_URL'] ?? '';
    String key = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

    if (url.isEmpty || key.isEmpty) {
      throw Exception('Supabase URL or Key is empty');
    }

    await Supabase.initialize(url: url, anonKey: key);
    AppLogger.logSuccess('✅ Supabase initialized in background');
  } catch (e, stackTrace) {
    AppLogger.logError('❌ Supabase initialization failed', e, stackTrace);
    rethrow;
  }
}

/// إعداد الإشعارات في الخلفية
Future<void> _setupNotificationsInBackground() async {
  try {
    // طلب صلاحيات الإشعارات
    NotificationSettings settings =
        await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // الحصول على التوكن (في production لا نسجله)
      if (kDebugMode) {
        String? token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          AppLogger.logInfo('ℹ️ FCM Token retrieved successfully');
        }
      }

      // تهيئة الإشعارات المحلية
      await NotificationManager().initialize();
      AppLogger.logSuccess('✅ Notifications setup completed');
    } else {
      AppLogger.logWarning('⚠️ Notification permission not granted');
    }
  } catch (e, stackTrace) {
    AppLogger.logError('❌ Notifications setup failed', e, stackTrace);
  }
}

/// التحقق من اكتمال تهيئة الخدمات
Future<void> ensureServicesInitialized() async {
  if (_isServicesInitialized) return;
  await _servicesInitializedCompleter.future;
}

/// Bindings للتطبيق
class AppBindings implements Bindings {
  @override
  void dependencies() {
    // تهيئة AuthService فوراً (ضروري)
    Get.put(AuthService(), permanent: true);

    // تهيئة الـ controllers الأخرى عند الحاجة فقط
    Get.lazyPut(() => StationLoadController());
    Get.lazyPut(() => FavoritesController());
    Get.lazyPut(() => CarouselSliderController());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          initialBinding: AppBindings(),
          title: 'CRCC App',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
            fontFamily: Appfontstring.ChangaLight,
          ),
          home: const AuthWrapper(),
          routes: pageRoutes,
        );
      },
    );
  }
}

/// AuthWrapper مُحسّن مع تحقق من الخدمات
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isCheckingServices = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkServices();
  }

  Future<void> _checkServices() async {
    try {
      // التحقق من اكتمال تهيئة الخدمات
      await ensureServicesInitialized();

      // التحقق من أن AuthService مهيأ
      final authService = Get.find<AuthService>();
      if (!authService.isInitialized) {
        await authService.initializeServices();
      }

      if (mounted) {
        setState(() {
          _isCheckingServices = false;
        });
      }
    } catch (e, stackTrace) {
      AppLogger.logError('Service check failed', e, stackTrace);
      if (mounted) {
        setState(() {
          _isCheckingServices = false;
          _errorMessage = 'فشل في تهيئة الخدمات';
        });
      }
    }
  }

  Future<bool> _isOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(AppConstants.onboardingKey) ?? false;
    } catch (e) {
      AppLogger.logError('Failed to check onboarding status', e);
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingServices) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 20),
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _checkServices,
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    return FutureBuilder<bool>(
      future: _isOnboardingCompleted(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'حدث خطأ في تحميل التطبيق',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          );
        }

        final isOnboardingCompleted = snapshot.data ?? false;
        if (!isOnboardingCompleted) {
          return const OnboardingScreen();
        }

        final supabase = Supabase.instance.client;
        final user = supabase.auth.currentUser;
        return user != null ? const HomePage() : const LoginScreen();
      },
    );
  }
}

// ============================================================================
// AUTH SERVICE - مُصلّح
// ============================================================================

// ============================================================================
// AUTH SERVICE - مُصلّح بالكامل
// ============================================================================

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

  // 🔥 **الحل: تعديل getter supabase ليكون nullable**
  SupabaseClient? get supabase => _supabase;

  // 🔥 **إضافة getter آمن مع throw فوري**
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

  /// تهيئة الخدمات
  Future<void> initializeServices() async {
    if (_isInitialized) return;

    try {
      AppLogger.logInfo('🔄 Initializing AuthService...');

      // 🔥 **الحل: تهيئة Supabase من المثيل العالمي**
      try {
        _supabase = Supabase.instance.client;
        if (_supabase == null) {
          throw Exception('Supabase.instance.client is null');
        }
        AppLogger.logSuccess('✅ Supabase obtained from instance');
      } catch (e) {
        AppLogger.logWarning(
            'Supabase.instance not available, trying initialization...');

        // إذا فشل، حاول إعادة التهيئة
        String url = dotenv.env['SUPABASE_URL'] ?? '';
        String key = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

        if (url.isEmpty || key.isEmpty) {
          throw Exception('Supabase credentials not found in .env');
        }

        await Supabase.initialize(url: url, anonKey: key);
        _supabase = Supabase.instance.client;
        AppLogger.logSuccess('✅ Supabase initialized successfully');
      }

      // إعداد مستمعات FCM
      _setupFCMListeners();

      // تحميل بيانات المستخدم إذا كان مسجلاً
      await _loadUserDataIfLoggedIn();

      _isInitialized = true;
      AppLogger.logSuccess('✅ AuthService initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.logError('❌ AuthService initialization failed', e, stackTrace);
      rethrow;
    }
  }

  /// 🔥 **الحل: تحميل بيانات المستخدم باستخدام _supabase مباشرة**
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
        if (kDebugMode) {
          AppLogger.logInfo('📨 Message received');
        }

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
        if (kDebugMode) {
          AppLogger.logInfo('📨 Message opened app');
        }
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
          if (kDebugMode) {
            AppLogger.logWarning('Unknown route: $route');
          }
      }
    } catch (e) {
      AppLogger.logError('Failed to handle message route', e);
    }
  }

  /// 🔥 **الحل: تعديل insertData لاستخدام _supabase مباشرة**
  Future<void> insertData(String tableName, String email, String name) async {
    try {
      if (_supabase == null) {
        await initializeServices();
      }

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

  /// 🔥 **الحل: تعديل updateData لاستخدام _supabase مباشرة**
  Future<void> updateData(String tableName, String name) async {
    try {
      if (_supabase == null) {
        await initializeServices();
      }

      final userId = _supabase!.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _supabase!
          .from(tableName)
          .update({'user_name': name}).eq('user_id', userId);

      AppLogger.logSuccess('✅ Data updated successfully');
    } catch (e, stackTrace) {
      AppLogger.logError('Failed to update data', e, stackTrace);
      rethrow;
    }
  }

  /// 🔥 **الحل: تعديل login لاستخدام _supabase مباشرة**
  Future<Session?> login({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    try {
      // التحقق من التهيئة قبل الاستخدام
      if (!_isInitialized || _supabase == null) {
        await initializeServices();
      }

      AppLogger.logInfo('🔑 Attempting login for: $email');

      final response = await _supabase!.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (context.mounted) {
        _showSnackbar(context, 'تم تسجيل الدخول بنجاح!');
      }

      AppLogger.logSuccess('✅ User logged in: $email');
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

  /// 🔥 **الحل: تعديل signOut لاستخدام _supabase مباشرة**
  Future<void> signOut({required BuildContext context}) async {
    try {
      AppLogger.logInfo('🚪 Attempting sign out...');

      // إلغاء جميع الاشتراكات
      for (var subscription in _subscriptions) {
        await subscription.cancel();
      }
      _subscriptions.clear();

      // مسح الـ cache
      _cache.clear();

      // مسح SharedPreferences reference
      _prefs = null;

      if (_supabase != null) {
        await _supabase!.auth.signOut();
      }

      if (context.mounted) {
        Get.offAll(() => const LoginScreen());
        _showSnackbar(context, 'تم تسجيل الخروج بنجاح!');
      }

      AppLogger.logSuccess('✅ User signed out successfully');
    } catch (e, stackTrace) {
      AppLogger.logError('Sign out failed', e, stackTrace);
      if (context.mounted) {
        _showSnackbar(context, 'فشل تسجيل الخروج', isError: true);
      }
    }
  }

  /// 🔥 **الحل: تعديل getUserDetails لاستخدام _supabase مباشرة**
  Future<Map<String, String>> getUserDetails() async {
    // تحقق من الـ cache أولاً
    if (_cache.containsKey('user_details')) {
      return _cache['user_details'];
    }

    try {
      if (_supabase == null) {
        return {'name': 'Guest', 'email': 'No email'};
      }

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

  /// 🔥 **الحل: تعديل getCurrentUserEmail لاستخدام _supabase مباشرة**

  String? getCurrentUserEmail() {
    final user = Supabase.instance.client.auth.currentUser;
    return user?.email?.trim().toLowerCase();
  }

  // أو أفضل: إرجاع كائن المستخدم كاملاً إذا احتجت بيانات أكثر
  User? getCurrentUser() {
    return Supabase.instance.client.auth.currentUser;
  }

  /// 🔥 **الحل: إضافة دالة آمنة للحصول على البريد**
  Future<String?> getCurrentUserEmailSafe() async {
    try {
      if (!_isInitialized || _supabase == null) {
        await initializeServices();
      }

      return _supabase?.auth.currentUser?.email;
    } catch (e, stackTrace) {
      AppLogger.logError(
          'Failed to get current user email safely', e, stackTrace);
      return null;
    }
  }

  /// 🔥 **الحل: تعديل canUpdateStation لاستخدام _supabase مباشرة**
  Future<bool> canUpdateStation(String stationName, String userEmail) async {
    try {
      if (_supabase == null) {
        await initializeServices();
      }

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
    // تنظيف جميع الاشتراكات
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

// ============================================================================
// NOTIFICATION MANAGER
// ============================================================================

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// تهيئة الإشعارات المحلية
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

        if (route != null) {
          _navigateToRoute(route);
        }
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
        if (kDebugMode) {
          AppLogger.logWarning('Unknown route: $route');
        }
    }
  }

  /// عرض إشعار محلي
  Future<void> show(
    String title,
    String body,
    String? messageId, {
    String? route,
  }) async {
    if (messageId == null || !_isInitialized) return;

    // التحقق من عدم تكرار الإشعار
    if (await _isNotificationProcessed(messageId)) {
      if (kDebugMode) {
        AppLogger.logInfo('Duplicate notification skipped');
      }
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

      AppLogger.logSuccess('📨 Notification shown: $title');
    } catch (e, stackTrace) {
      AppLogger.logError('Failed to show notification', e, stackTrace);
    }
  }

  Future<bool> _isNotificationProcessed(String messageId) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> processedList =
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
        AppConstants.processedNotificationsKey,
        processedList,
      );
    } catch (e) {
      if (kDebugMode) {
        AppLogger.logError('Failed to mark notification as processed', e);
      }
    }
  }
}

// ============================================================================
// BACKGROUND MESSAGE HANDLER
// ============================================================================

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
      debugShowCheckedModeBanner: false,
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
                  // يمكن إعادة تشغيل التطبيق هنا
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

class NotificationService {
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
        AppLogger.logSuccess('Notification sent');
        return true;
      } else {
        AppLogger.logError(
          'Failed to send notification',
          'Status: ${response.statusCode}',
        );
        return false;
      }
    } catch (e, stackTrace) {
      AppLogger.logError('Error sending notification', e, stackTrace);
      return false;
    }
  }

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

      AppLogger.logSuccess(
          '📨 Notifications sent: $successCount/${data.length}');
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

class SupabaseService {
  SupabaseClient get _client => Supabase.instance.client;

  final Map<String, CachedData> _cache = {};
  static const Duration cacheDuration = Duration(minutes: 5);

  Future<List<StationLoad>> fetchStationLoads({
    int limit = AppConstants.defaultFetchLimit,
    bool forceRefresh = false,
  }) async {
    const cacheKey = 'station_loads';

    if (!forceRefresh && _cache.containsKey(cacheKey)) {
      final cached = _cache[cacheKey]!;
      if (!cached.isExpired) {
        AppLogger.logInfo('📦 Returning cached data');
        return cached.data as List<StationLoad>;
      }
    }

    try {
      final response = await _client
          .from(AppConstants.tableStation)
          .select()
          .order('station_name', ascending: true)
          .limit(limit)
          .timeout(AppConstants.timeoutDuration);

      final stations = (response as List<dynamic>)
          .map((json) => StationLoad.fromJson(json))
          .toList();

      _cache[cacheKey] = CachedData(
        data: stations,
        timestamp: DateTime.now(),
      );

      AppLogger.logSuccess('✅ Data fetched and cached');
      return stations;
    } on TimeoutException {
      if (_cache.containsKey(cacheKey)) {
        AppLogger.logWarning('⚠️ Timeout - using old cache');
        return _cache[cacheKey]!.data as List<StationLoad>;
      }
      throw Exception('انتهت مهلة الطلب. تحقق من اتصالك بالإنترنت');
    } catch (e, stackTrace) {
      AppLogger.logError('Failed to fetch station loads', e, stackTrace);

      if (_cache.containsKey(cacheKey)) {
        AppLogger.logWarning('Using cached data due to error');
        return _cache[cacheKey]!.data as List<StationLoad>;
      }
      throw Exception('فشل في جلب بيانات المحطات');
    }
  }

  Future<Map<String, String>> fetchSpecificStations() async {
    const cacheKey = 'specific_stations';

    if (_cache.containsKey(cacheKey)) {
      final cached = _cache[cacheKey]!;
      if (!cached.isExpired) {
        AppLogger.logInfo('📦 Returning cached specific stations');
        return cached.data as Map<String, String>;
      }
    }

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

      _cache[cacheKey] = CachedData(
        data: specificStations,
        timestamp: DateTime.now(),
      );

      return specificStations;
    } catch (e, stackTrace) {
      AppLogger.logError('Failed to fetch specific stations', e, stackTrace);

      if (_cache.containsKey(cacheKey)) {
        return _cache[cacheKey]!.data as Map<String, String>;
      }
      return {};
    }
  }

  void clearCacheKey(String key) {
    _cache.remove(key);
    AppLogger.logInfo('🗑️ Cache key cleared: $key');
  }

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
      _cache.remove('station_loads');

      AppLogger.logSuccess('✅ Station load updated: $stationName = $newLoad');
    } on PostgrestException catch (e) {
      AppLogger.logError('Database error while updating station', e);
      throw Exception('خطأ في قاعدة البيانات: ${e.message}');
    } catch (e, stackTrace) {
      AppLogger.logError('Failed to update station load', e, stackTrace);
      throw Exception('فشل في تحديث حمل المحطة');
    }
  }

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

      AppLogger.logSuccess('✅ Hourly max load upserted: Hour $hour = $maxLoad');
    } on PostgrestException catch (e) {
      AppLogger.logError('Database error while upserting', e);
      throw Exception('خطأ في قاعدة البيانات: ${e.message}');
    } catch (e, stackTrace) {
      AppLogger.logError('Failed to upsert hourly max load', e, stackTrace);
      throw Exception('فشل في تحديث الحمل الأقصى للساعة');
    }
  }

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

  Future<void> clearCache() async {
    _cache.clear();
    AppLogger.logInfo('🗑️ Cache cleared');
  }
}

// ============================================================================
// SUPABASE SERVICE HOURLY
// ============================================================================

class SupabaseServiceHourly {
  SupabaseClient get _client => Supabase.instance.client;

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

class CachedData {
  final dynamic data;
  final DateTime timestamp;

  CachedData({required this.data, required this.timestamp});

  bool get isExpired =>
      DateTime.now().difference(timestamp) > SupabaseService.cacheDuration;
}

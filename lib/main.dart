import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:carousel_slider/carousel_controller.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:amiraly/app/util/constant/constants.dart';
import 'package:amiraly/core/services/heartbeat_service.dart';
import 'package:amiraly/app/util/validators/validator_helper.dart';
import 'package:amiraly/app/features/mainprog/screen/navscreens/favorites_controller.dart';
import 'package:amiraly/app/features/mainprog/screen/navscreens/station_load_controller.dart';
import 'package:amiraly/app/common/routes/app_routes.dart';
import 'package:amiraly/core/services/auth_service.dart';
import 'package:amiraly/core/services/notification_manager.dart';
import 'package:amiraly/app/features/mainprog/screen/catogriesScreens/golive.dart';
import 'package:amiraly/app/features/splash/splash_screen.dart';
import 'package:amiraly/core/widgets/error_app.dart';

// 🔧 متغيرات تتبع حالة التهيئة
bool _isServicesInitialized = false;
Completer<void> _servicesInitializedCompleter = Completer<void>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar', null);

  try {
    await dotenv.load(fileName: ".env");
    await Firebase.initializeApp();

    // تسجيل معالج رسائل الخلفية
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    runApp(const MyApp());

    // تهيئة WebView في الخلفية (للتطوير فقط)
    if (!kReleaseMode) {
      Future.microtask(() async {
        try {
          await InAppWebViewController.setWebContentsDebuggingEnabled(true);
        } catch (e) {
          AppLogger.logWarning('WebView debugging setup failed');
        }
      });
    }

    // تهيئة الخدمات الثقيلة في الخلفية
    Future.microtask(() => _initializeHeavyServicesInBackground());
  } catch (e, stackTrace) {
    AppLogger.logError('Initialization failed', e, stackTrace);
    runApp(const ErrorApp());
  }
}

Future<void> _initializeHeavyServicesInBackground() async {
  try {
    AppLogger.logInfo('🔄 Starting background services initialization...');
    await _initializeSupabaseInBackground();
    await _setupNotificationsInBackground();
    _isServicesInitialized = true;
    _servicesInitializedCompleter.complete();
    AppLogger.logSuccess('✅ All background services initialized');
  } catch (e, stackTrace) {
    AppLogger.logError('❌ Background initialization failed', e, stackTrace);
    _servicesInitializedCompleter.completeError(e);
  }
}

Future<void> _initializeSupabaseInBackground() async {
  try {
    final String url = dotenv.env['SUPABASE_URL'] ?? '';
    final String key = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
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

Future<void> _setupNotificationsInBackground() async {
  try {
    final NotificationSettings settings =
        await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) await FirebaseMessaging.instance.getToken();
      await NotificationManager().initialize();
      AppLogger.logSuccess('✅ Notifications setup completed');
    } else {
      AppLogger.logWarning('⚠️ Notification permission not granted');
    }
  } catch (e, stackTrace) {
    AppLogger.logError('❌ Notifications setup failed', e, stackTrace);
  }
}

Future<void> ensureServicesInitialized() async {
  if (_isServicesInitialized) return;
  await _servicesInitializedCompleter.future;
}

// ============================================================================
// APP BINDINGS
// ============================================================================

class AppBindings implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AuthService(), fenix: true);
    Get.lazyPut(() => HeartbeatService(), fenix: true);
    Get.lazyPut(() => GlobalCallService(), fenix: true);
    Get.lazyPut(() => StationLoadController(), fenix: true);
    Get.lazyPut(() => FavoritesController(), fenix: true);
    Get.lazyPut(() => CarouselSliderController(), fenix: true);
  }
}

// ============================================================================
// MY APP
// ============================================================================

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
          useInheritedMediaQuery: true,
          debugShowCheckedModeBanner: false,
          initialBinding: AppBindings(),
          title: 'CRCC App',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
            fontFamily: Appfontstring.ChangaLight,
          ),
          home: const SplashScreen(),
          routes: pageRoutes,
        );
      },
    );
  }
}

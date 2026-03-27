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
import 'package:amiraly/core/services/supabase_service.dart';
import 'package:amiraly/app/util/validators/validator_helper.dart';
import 'package:amiraly/app/features/mainprog/screen/navscreens/favorites_controller.dart';
import 'package:amiraly/app/features/mainprog/screen/navscreens/station_load_controller.dart';
import 'package:amiraly/app/common/routes/app_routes.dart';
import 'package:amiraly/core/services/auth_service.dart';
import 'package:amiraly/core/services/notification_manager.dart';
import 'package:amiraly/app/features/mainprog/screen/catogriesScreens/golive.dart';
import 'package:amiraly/app/features/splash/splash_screen.dart';

// 🔧 متغيرات تتبع حالة التهيئة
bool _isServicesInitialized = false;
Completer<void> _servicesInitializedCompleter = Completer<void>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تشغيل التطبيق فوراً لتقليل ظهور الشاشة السادة (Native Launch Screen)
  runApp(const MyApp());

  // تهيئة الخدمات الثقيلة في الخلفية بعد عرض الفريم الأول
  Future.delayed(const Duration(milliseconds: 100), () => _initializeHeavyServicesInBackground());
}

Future<void> _initializeHeavyServicesInBackground() async {
  try {
    AppLogger.logInfo('🔄 Starting background services initialization...');

    // 1. تشغيل المهام المستقلة بالتوازي
    await Future.wait([
      dotenv.load(fileName: ".env"),
      initializeDateFormatting('ar', null),
    ]);
    
    // 2. تهيئة Firebase بعد تحميل الـ .env
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 3. تهيئة الخدمات التي تعتمد على بعضها بالتتابع ولكن مع فواصل Frames
    await _initializeSupabaseInBackground();
    await _setupNotificationsInBackground();

    // 4. تهيئة WebView في الخلفية (للتطوير فقط)
    if (!kReleaseMode) {
      await InAppWebViewController.setWebContentsDebuggingEnabled(true);
      AppLogger.logInfo('✅ WebView debugging setup completed in background');
    }

    // 5. تهيئة خدمة المكالمات بعد التأكد من جاهزية Supabase
    Get.put(GlobalCallService(), permanent: true);
    AppLogger.logSuccess('✅ GlobalCallService initialized after Supabase');

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
    // AuthService كـ permanent singleton — يُنشأ مرة واحدة فقط طوال عمر التطبيق
    Get.put(AuthService(), permanent: true);
    Get.lazyPut(() => SupabaseService(), fenix: true);
    Get.lazyPut(() => HeartbeatService(), fenix: true);
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

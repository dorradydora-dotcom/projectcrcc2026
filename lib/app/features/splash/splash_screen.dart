import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:amiraly/app/util/constant/constants.dart';
import 'package:amiraly/app/features/auth/login/loginscreen.dart';
import 'package:amiraly/app/features/auth/homepage/homepage.dart';
import 'package:amiraly/app/features/auth/onboarding/onboardingscreen.dart';
import 'package:amiraly/core/services/auth_service.dart';
import 'package:amiraly/app/util/validators/validator_helper.dart';
import 'package:amiraly/main.dart' show ensureServicesInitialized;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _hasError = false;
  String _errorMessage = '';
  // ✅ ValueNotifier بدل setState - بس الـ ProgressBar هو اللي بيتحدث
  final ValueNotifier<double> _progress = ValueNotifier(0.0);
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _startAppProcess();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _progress.dispose();
    super.dispose();
  }

  Future<void> _startAppProcess() async {
    if (_hasError) {
      setState(() {
        _hasError = false;
        _errorMessage = '';
      });
    }
    _progress.value = 0.0;
    _progressTimer?.cancel();

    // بدء تهيئة الخدمات في الخلفية
    final servicesFuture = ensureServicesInitialized();

    // تايمر مدته 3 ثوانٍ بالضبط (0.01 كل 30 ملي ثانية)
    _progressTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      // زيادة التقدم
      if (_progress.value < 1.0) {
        _progress.value = (_progress.value + 0.01).clamp(0.0, 1.0);
      }
      
      // عند الوصول إلى 100% بعد 3 ثوانٍ
      if (_progress.value >= 1.0) {
        timer.cancel();
        
        try {
          // ننتظر الخدمات لتأكيد انتهائها (عادةً ستكون قد انتهت أصلاً)
          await servicesFuture;
          if (!mounted) return;
          _completeProcess();
        } catch (e) {
          if (!mounted) return;
          AppLogger.logError('App initialization failed', e);
          setState(() {
            _hasError = true;
            _errorMessage = 'حدث خطأ تقني أثناء تهيئة الخدمات الأساسية.';
          });
        }
      }
    });
  }

  Future<void> _completeProcess() async {
    try {
      // تهيئة خدمات المصادقة لتحديد الوجهة
      final authService = Get.find<AuthService>();
      if (!authService.isInitialized) {
        await authService.initializeServices();
      }

      final prefs = await SharedPreferences.getInstance();
      final isOnboardingCompleted = prefs.getBool(AppConstants.onboardingKey) ?? false;

      // فحص الاتصال بالإنترنت
      final List<ConnectivityResult> connectivityResult =
          await (Connectivity().checkConnectivity());

      if (connectivityResult.contains(ConnectivityResult.none)) {
        setState(() {
          _hasError = true;
          _errorMessage =
              'نعتذر، لا يوجد اتصال بالإنترنت حالياً.\nيرجى التأكد من اتصالك بالشبكة.';
        });
      } else {
        _navigateToNext(isOnboardingCompleted);
      }
    } catch (e) {
      AppLogger.logError('App completion process failed', e);
      setState(() {
        _hasError = true;
        _errorMessage = 'حدث خطأ تقني أثناء محاولة تهيئة التطبيق.';
      });
    }
  }

  void _navigateToNext(bool isOnboardingCompleted) {
    Widget nextScreen;
    if (!isOnboardingCompleted) {
      nextScreen = const OnboardingScreen();
    } else {
      final user = Supabase.instance.client.auth.currentUser;
      nextScreen = user != null ? const HomePage() : const LoginScreen();
    }

    final args = Get.arguments;
    final bool isCall = (args is Map && args['route'] == 'call');

    if (isCall) {
       debugPrint('SplashScreen: Call detected in arguments, navigating to Next with Get.offAll');
       Get.offAll(() => nextScreen, arguments: args, transition: Transition.noTransition);
    } else {
       Get.offAll(() => nextScreen, transition: Transition.noTransition);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // خلفية سوداء متجانسة
          Container(color: Colors.black),

          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),

                  // اللوجو (ثابت وبسيط)
                  FadeIn(
                    duration: const Duration(seconds: 1),
                    child: Hero(
                      tag: 'app_logo',
                      child: Image.asset(
                        AppimageString.on5,
                        height: 180,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // اسم الشركة
                  FadeInUp(
                    duration: const Duration(milliseconds: 1500),
                    delay: const Duration(milliseconds: 200),
                    child: Column(
                      children: [
                        Text(
                          AppBarText.companyName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16, // تصغير حجم الخط
                            fontWeight: FontWeight.w800,
                            fontFamily: Appfontstring.ChangaLight,
                            letterSpacing: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${AppBarText.regionalControl} ${AppBarText.cairo}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontFamily: Appfontstring.ChangaLight,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 2),

                  // ✅ ValueListenableBuilder - بس الـ ProgressBar بيتحدث، مش كل الشاشة
                  if (!_hasError)
                    FadeIn(
                      duration: const Duration(seconds: 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 80),
                        child: ValueListenableBuilder<double>(
                          valueListenable: _progress,
                          builder: (context, value, _) {
                            return Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: value,
                                    backgroundColor: Colors.white10,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                            Colors.orange),
                                    minHeight: 6,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '${(value * 100).toInt()}%',
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: Appfontstring.digital,
                                    fontFamilyFallback: [Appfontstring.ChangaLight],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'جاري تهيئة النظام...',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    fontSize: 11,
                                    fontFamily: Appfontstring.ChangaLight,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),

                  // عرض الخطأ فقط عند الحاجة بصندوق زجاجي
                  if (_hasError) _buildGlassStatus(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassStatus() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 300,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: _buildErrorWidget(),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded,
              color: Colors.orangeAccent, size: 40),
          const SizedBox(height: 12),
          Text(
            _errorMessage,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontFamily: Appfontstring.ChangaLight,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: _startAppProcess,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: const Text('إعادة المحاولة'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.blue.withValues(alpha: 0.2),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

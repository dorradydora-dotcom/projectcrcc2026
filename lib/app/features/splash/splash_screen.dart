import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import 'package:amiraly/app/util/constant/constants.dart';
import 'package:amiraly/core/widgets/auth_wrapper.dart';
import 'package:amiraly/app/util/validators/validator_helper.dart';
import 'package:amiraly/main.dart' show ensureServicesInitialized;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  bool _hasError = false;
  String _errorMessage = '';
  late AnimationController _bgAnimationController;
  double _progress = 0.0;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
    _startAppProcess();
  }

  @override
  void dispose() {
    _bgAnimationController.dispose();
    _progressTimer?.cancel();
    super.dispose();
  }

  Future<void> _startAppProcess() async {
    setState(() {
      _hasError = false;
      _progress = 0.0;
    });

    // بدء تهيئة الخدمات في الخلفية فور دخول الشاشة لمسابق الزمن
    final servicesFuture = ensureServicesInitialized();

    _progressTimer?.cancel();
    _progressTimer =
        Timer.periodic(const Duration(milliseconds: 50), (timer) async {
      if (mounted) {
        setState(() {
          _progress += 0.01;
          if (_progress >= 1.0) {
            _progress = 1.0;
            timer.cancel();
            _completeProcess(servicesFuture); // الانتقال فور الوصول لـ 100%
          }
        });
      }
    });
  }

  Future<void> _completeProcess(Future<void> servicesFuture) async {
    try {
      // التأكد من اكتمال كافة الخدمات الحيوية قبل الانتقال الفعلي
      await servicesFuture;

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
        _navigateToNext();
      }
    } catch (e) {
      AppLogger.logError('App completion process failed', e);
      setState(() {
        _hasError = true;
        _errorMessage = 'حدث خطأ تقني أثناء محاولة تهيئة التطبيق.';
      });
    }
  }

  void _navigateToNext() {
    // If we have call arguments, we might be already navigating or need to pass them
    final args = Get.arguments;
    if (args is Map && args['route'] == 'call') {
      debugPrint(
          'SplashScreen: Detected call arguments, using Get.to to preserve flow');
      Get.to(() => const AuthWrapper(),
          arguments: args,
          transition: Transition.fade,
          duration: const Duration(seconds: 2));
    } else {
      Get.offAll(() => const AuthWrapper(),
          transition: Transition.fade, duration: const Duration(seconds: 2));
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

                  // شريط وكاونتر التحميل البرتقالي بناءً على طلب المستخدم
                  if (!_hasError)
                    FadeIn(
                      duration: const Duration(seconds: 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 80), // تقصير الشريط بزيادة الـ padding
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: _progress,
                                backgroundColor: Colors.white10,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    Colors.orange),
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${(_progress * 100).toInt()}%',
                              style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: Appfontstring.digital,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'جاري تهيئة النظام...',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.3),
                                fontSize: 11,
                                fontFamily: Appfontstring.ChangaLight,
                              ),
                            ),
                          ],
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
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
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
              backgroundColor: Colors.blue.withOpacity(0.2),
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

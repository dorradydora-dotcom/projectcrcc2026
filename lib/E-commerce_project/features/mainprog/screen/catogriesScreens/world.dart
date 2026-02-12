import 'dart:ui';
import 'package:amiraly/E-commerce_project/common/widgets/appbar.dart';
import 'package:amiraly/E-commerce_project/util/constant/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'world_controller.dart';

class WorldScreen extends StatefulWidget {
  const WorldScreen({super.key});

  @override
  State<WorldScreen> createState() => _WorldScreenState();
}

class _WorldScreenState extends State<WorldScreen>
    with TickerProviderStateMixin {
  final WorldController controller = Get.put(WorldController());
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: const CustomAppBar(),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          children: [
            _buildWebView(),
            _buildGradientOverlay(),
            _buildLoadingStatus(),
            _buildErrorState(),
          ],
        ),
      ),
      floatingActionButton: _buildRefreshFAB(),
    );
  }

  Widget _buildWebView() {
    return Obx(() {
      if (controller.initialUrlworld.value.isEmpty &&
          controller.isLoading.value) {
        return const SizedBox.shrink();
      }
      return InAppWebView(
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          useOnLoadResource: true,
          allowFileAccessFromFileURLs: true,
          allowUniversalAccessFromFileURLs: true,
          useHybridComposition: true,
          allowsInlineMediaPlayback: true,
        ),
        onWebViewCreated: controller.onWebViewCreated,
        onLoadStop: (ctrl, url) => controller.onLoadStop(),
        onLoadError: (ctrl, url, code, message) => controller.onLoadError(),
        onProgressChanged: (ctrl, p) => controller.onProgressChanged(p),
      );
    });
  }

  Widget _buildGradientOverlay() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 80.h,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF0F172A).withOpacity(0.9),
                const Color(0xFF0F172A).withOpacity(0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingStatus() {
    return Obx(() {
      if (!controller.isLoading.value) return const SizedBox.shrink();
      return Positioned.fill(
        child: Container(
          color: const Color(0xFF0F172A).withOpacity(0.8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SpinKitPulse(
                color: const Color(0xFF38BDF8),
                size: 80.sp,
              ),
              SizedBox(height: 24.h),
              Text(
                'جاري تحميل خريطة الشبكة...',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: Appfontstring.ChangaLight,
                  fontSize: 14.sp,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 16.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 60.w),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child: LinearProgressIndicator(
                    value: controller.progress.value,
                    backgroundColor: Colors.white10,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                    minHeight: 4.h,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildErrorState() {
    return Obx(() {
      if (!controller.hasError.value) return const SizedBox.shrink();
      return Container(
        color: const Color(0xFF0F172A),
        child: Center(
          child: FadeTransition(
            opacity: _fadeController,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.redAccent.withOpacity(0.1),
                    border: Border.all(
                        color: Colors.redAccent.withOpacity(0.2), width: 2),
                  ),
                  child: Icon(Icons.wifi_off_rounded,
                      size: 60.sp, color: Colors.redAccent),
                ),
                SizedBox(height: 24.h),
                Text(
                  'فشل الاتصال بالشبكة التفاعلية',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: Appfontstring.ChangaBold,
                    fontSize: 18.sp,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  'يرجى التأكد من اتصال الإنترنت والمحاولة مرة أخرى',
                  style: TextStyle(
                    color: Colors.white60,
                    fontFamily: Appfontstring.ChangaLight,
                    fontSize: 12.sp,
                  ),
                ),
                SizedBox(height: 40.h),
                ElevatedButton.icon(
                  onPressed: controller.fetchUrl,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('إعادة المحاولة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38BDF8),
                    foregroundColor: Colors.white,
                    padding:
                        EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.r)),
                    elevation: 10,
                    shadowColor: const Color(0xFF38BDF8).withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildRefreshFAB() {
    return Obx(() {
      if (controller.isLoading.value) return const SizedBox.shrink();
      return FloatingActionButton(
        onPressed: controller.fetchUrl,
        backgroundColor: const Color(0xFF38BDF8),
        child: const Icon(Icons.refresh, color: Colors.white),
      );
    });
  }
}

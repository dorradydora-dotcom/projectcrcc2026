import 'dart:ui';
import 'package:amiraly/E-commerce_project/common/widgets/appbar.dart';
import 'package:amiraly/E-commerce_project/features/mainprog/screen/catogriesScreens/map_controller.dart';
import 'package:amiraly/E-commerce_project/util/constant/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';

class Mapscreen extends StatelessWidget {
  const Mapscreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject Controller
    final controller = Get.put(MapController());

    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: const Color(0xFF0F172A), // Dark background base
      appBar: const CustomAppBar(),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Appcolors.primaryColor,
                Color(0xFF163C5E),
                Color(0xFF0F2B44),
                Color(0xFF081A2A)
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              SizedBox(height: 10.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                child: _buildExplanationCard(),
              ),
              SizedBox(height: 6.h),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.w)
                      .copyWith(bottom: 10.h),
                  child: _buildMapContainer(controller),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExplanationCard() {
    return FadeInDown(
      duration: const Duration(milliseconds: 600),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: C.black, size: 17.5.sp),
                    SizedBox(width: 8.w),
                    Text(
                      'بيانات الخريطة :',
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        color: C.black,
                        fontFamily: Appfontstring.ChangaLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 7.h),
                _buildBulletPoint(
                    Icons.bolt, 'مسارات خطوط الطاقة على جميع مستويات الجهد'),
                _buildBulletPoint(Icons.link, 'محطات الربط بجميع الدول'),
                _buildBulletPoint(Icons.warning_amber_rounded,
                    'تداخلات الخطوط بين التضاريس المختلفة'),
                SizedBox(height: 3.5.h),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.satellite_alt,
                          size: 12.sp, color: Colors.redAccent),
                      SizedBox(width: 6.w),
                      Text(
                        'تحديث دوري بالأقمار الصناعية (كل 3 شهور)',
                        style: TextStyle(
                          fontSize: 9.sp,
                          color: Colors.redAccent,
                          fontFamily: Appfontstring.ChangaLight,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBulletPoint(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 3.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(5.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white70,
              size: 12.sp,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 10.5.sp,
                color: Colors.white.withOpacity(0.9),
                fontFamily: Appfontstring.ChangaLight,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapContainer(MapController controller) {
    return FadeInUp(
      duration: const Duration(milliseconds: 700),
      child: Container(
        // height removed to fill Expanded space
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: Stack(
            children: [
              // WebView
              Obx(() {
                if (controller.hasError.value &&
                    controller.initialUrl.value == null) {
                  return _buildErrorState(controller);
                }
                return InAppWebView(
                  initialUrlRequest: controller.initialUrl.value != null
                      ? URLRequest(url: WebUri(controller.initialUrl.value!))
                      : null,
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    cacheEnabled: true,
                    allowsBackForwardNavigationGestures: true,
                    useShouldOverrideUrlLoading: true,
                    transparentBackground: true,
                    supportZoom: false,
                  ),
                  pullToRefreshController: controller
                      .pullToRefreshController ??= PullToRefreshController(
                    settings: PullToRefreshSettings(
                      color: Appcolors.primaryColor,
                    ),
                    onRefresh: () async {
                      controller.reload();
                    },
                  ),
                  onWebViewCreated: controller.onWebViewCreated,
                  onLoadStop: (webController, url) {
                    controller.isLoading.value = false;
                    controller.pullToRefreshController?.endRefreshing();
                  },
                  onLoadError: (webController, url, code, message) {
                    controller.isLoading.value = false;
                    controller.hasError.value = true;
                    controller.pullToRefreshController?.endRefreshing();
                  },
                  onProgressChanged: (webController, progress) {
                    controller.updateProgress(progress / 100);
                  },
                );
              }),

              // Loading Overlay (Glassmorphism)
              Obx(() {
                if (controller.isLoading.value) {
                  return Container(
                    color: Colors.black.withOpacity(0.6),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SpinKitCubeGrid(
                            color: C.blue,
                            size: 40.sp,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            "جاري تحميل الخريطة...",
                            style: TextStyle(
                              color: Colors.white70,
                              fontFamily: Appfontstring.ChangaLight,
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),

              // Progress Bar
              Obx(() => controller.progress.value > 0 &&
                      controller.progress.value < 1.0
                  ? Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        value: controller.progress.value,
                        backgroundColor: Colors.transparent,
                        color: C.blue,
                        minHeight: 3,
                      ),
                    )
                  : const SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(MapController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, size: 40.sp, color: Colors.white38),
          SizedBox(height: 10.h),
          Text(
            "تعذر تحميل الخريطة",
            style: TextStyle(
              color: Colors.white60,
              fontSize: 12.sp,
              fontFamily: Appfontstring.ChangaLight,
            ),
          ),
          SizedBox(height: 15.h),
          ElevatedButton.icon(
            onPressed: controller.fetchUrl,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text("إعادة المحاولة"),
            style: ElevatedButton.styleFrom(
              backgroundColor: C.blue.withOpacity(0.8),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              textStyle: TextStyle(
                  fontFamily: Appfontstring.ChangaLight, fontSize: 12.sp),
            ),
          )
        ],
      ),
    );
  }
}

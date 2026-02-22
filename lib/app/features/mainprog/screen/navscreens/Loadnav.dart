import 'package:amiraly/app/common/models/appmodels.dart';
import 'package:amiraly/app/features/mainprog/screen/navscreens/loadnav_controller.dart';
import 'package:amiraly/app/features/mainprog/screen/navscreens/station_load_controller.dart';
import 'package:amiraly/app/util/constant/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'package:get/get.dart';

class LoadnavScreen extends StatefulWidget {
  const LoadnavScreen({super.key});

  @override
  State<LoadnavScreen> createState() => _LoadnavScreenState();
}

class _LoadnavScreenState extends State<LoadnavScreen> {
  late final LoadnavController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(LoadnavController());
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        floatingActionButton: _buildFAB(),
        body: Container(
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
          child: RefreshIndicator(
            color: Colors.orangeAccent,
            backgroundColor: Colors.white,
            onRefresh: () async {
              await controller.fetchStationLoads();
// Removed migrated data fetches
            },
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Total Load Display
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 30.h),
                    child: Obx(() => LoadDisplayWidget(
                          totalLoad: controller.totalStationLoad,
                          isLoading: controller.isLoadingStations.value &&
                              controller.stationLoads.isEmpty,
                          isFromCache: controller.isStationFromCache.value,
                        )),
                  ),
                ),

                SliverToBoxAdapter(child: SizedBox(height: 8.h)),

// Removed migrated UI components

                // Station Cards Header
                SliverToBoxAdapter(
                  child: Container(
                    margin: EdgeInsets.only(left: 10.w, right: 10.w, top: 6.h),
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(16.r)),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.flash_on,
                            color: Colors.orangeAccent, size: 16),
                        SizedBox(width: 8.w),
                        Text(
                          'محطات شبكه القاهرة',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontFamily: Appfontstring.ChangaLight,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        const Icon(Icons.flash_on,
                            color: Colors.orangeAccent, size: 16),
                      ],
                    ),
                  ),
                ),

                // Station Cards Grid Area
                Obx(() {
                  // Ensure visibility changes when permissions load
                  final _ = Get.find<StationLoadController>().isCrccUser.value;

                  if (controller.stnError.value &&
                      controller.stationLoads.isEmpty) {
                    return SliverToBoxAdapter(child: _buildErrorWidget());
                  } else if (controller.isLoadingStations.value &&
                      controller.stationLoads.isEmpty) {
                    return const ShimmerLoadingGrid();
                  } else {
                    return SliverToBoxAdapter(
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 10.w),
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(16.r)),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final w = constraints.maxWidth;
                            final crossCount = w < 360
                                ? 2
                                : w > 600
                                    ? 4
                                    : 3;
                            final aspectRatio = w < 360
                                ? 2.5
                                : w > 600
                                    ? 2.0
                                    : 2.2;
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossCount,
                                childAspectRatio: aspectRatio,
                                crossAxisSpacing: 4.w,
                                mainAxisSpacing: 4.h,
                              ),
                              itemCount: controller.stationLoads.length,
                              itemBuilder: (context, index) {
                                final station = controller.stationLoads[index];
                                return StationCard(
                                  index: index,
                                  station: station,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    );
                  }
                }),

                SliverToBoxAdapter(child: SizedBox(height: 80.h)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h, left: 10.w),
      child: FloatingActionButton(
        heroTag: 'load_pdf_fab',
        onPressed: () {
          controller.generateAndSharePDF(context);
        },
        backgroundColor: Colors.orangeAccent,
        child: Obx(() => controller.isGeneratingPdf.value
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                    color: Colors.black, strokeWidth: 2),
              )
            : const Icon(Icons.picture_as_pdf, color: Colors.black)),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
          SizedBox(height: 16.h),
          Obx(() => Text(
                controller.errorMessage.value.isEmpty
                    ? 'حدث خطأ غير متوقع'
                    : controller.errorMessage.value,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              )),
          ElevatedButton(
            onPressed: () => controller.fetchStationLoads(),
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// COMPONENTS
// ---------------------------------------------------------------------------

// LOAD DISPLAY WIDGET
class LoadDisplayWidget extends StatelessWidget {
  final double totalLoad;
  final bool isLoading;
  final bool isFromCache;

  const LoadDisplayWidget({
    super.key,
    required this.totalLoad,
    required this.isLoading,
    this.isFromCache = false,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LoadnavController>();

    return Container(
      height: 135.h,
      margin: EdgeInsets.only(left: 8.w, right: 8.w, top: 1.h, bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF2C2C2C), const Color(0xFF000000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'الحمل الكلي للشبكة',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 11.sp,
                    fontFamily: Appfontstring.ChangaLight,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                if (isFromCache) ...[
                  SizedBox(width: 6.w),
                  Icon(Icons.offline_bolt,
                      color: Colors.orangeAccent, size: 11.sp),
                ],
              ],
            ),
          ),
          SizedBox(height: 2.h),
          isLoading
              ? Shimmer.fromColors(
                  baseColor: Colors.red.withOpacity(0.3),
                  highlightColor: Colors.red.withOpacity(0.7),
                  child: Text(
                    '---',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 38.sp,
                      fontFamily: Appfontstring.digital,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: totalLoad),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeOutQuart,
                  builder: (context, value, child) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                (value >= 0 ? '+' : '') +
                                    value.toStringAsFixed(0),
                                style: TextStyle(
                                  color:
                                      value < 0 ? Colors.red : Colors.redAccent,
                                  fontSize: 38.sp,
                                  fontFamily: Appfontstring.digital,
                                  shadows: [
                                    Shadow(
                                      color: (value < 0
                                              ? Colors.red
                                              : Colors.redAccent)
                                          .withOpacity(0.5),
                                      blurRadius: 15,
                                    ),
                                  ],
                                ),
                                textDirection: TextDirection.rtl,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'ميجا واط',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 11.sp,
                            fontFamily: Appfontstring.ChangaLight,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ],
                    );
                  },
                ),
          SizedBox(height: 4.h),
          Container(
            padding: EdgeInsets.all(2.h),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
            ),
            child: Obx(() => RichText(
                  textDirection: TextDirection.rtl,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'أقصى حمل في الساعة الأخيرة: ',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10.sp,
                          fontFamily: Appfontstring.ChangaLight,
                        ),
                      ),
                      TextSpan(
                        text: controller.maxLoadInLastHour.value
                            .toStringAsFixed(0),
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 12.sp,
                          fontFamily: Appfontstring.ChangaLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: ' م.و',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10.sp,
                          fontFamily: Appfontstring.ChangaLight,
                        ),
                      ),
                    ],
                  ),
                )),
          ),
        ],
      ),
    );
  }
}

// Removed RealCapitalLoadCards and HourlyMaxLoadTable definitions (migrated to indicators.dart)

// STATION CARD
class StationCard extends StatefulWidget {
  final int index;
  final StationLoad station;

  const StationCard({
    super.key,
    required this.index,
    required this.station,
  });

  @override
  State<StationCard> createState() => _StationCardState();
}

class _StationCardState extends State<StationCard> {
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 2.w, vertical: 2.h),
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 2.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.08),
              Colors.white.withOpacity(0.03),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.blueAccent.withOpacity(0.6),
                    Colors.blue.withOpacity(0.4)
                  ],
                ),
              ),
              child: Center(
                child: Text(
                  '${widget.index + 1}',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: Appfontstring.ChangaLight,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.station.stationName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: Appfontstring.ChangaLight,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  SizedBox(height: 2.h),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: 0,
                      end: widget.station.isPositive
                          ? widget.station.load
                          : -widget.station.load,
                    ),
                    duration: const Duration(seconds: 1),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      final isPositive = value >= 0;
                      return RichText(
                        textDirection: TextDirection.rtl,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text:
                                  '${isPositive ? '+' : ''}${value.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 13.sp, // Reduced from 14.sp
                                fontWeight: FontWeight.bold,
                                fontFamily: Appfontstring.digital,
                                color: isPositive
                                    ? Colors.greenAccent
                                    : Colors.redAccent,
                              ),
                            ),
                            TextSpan(
                              text: ' م.و',
                              style: TextStyle(
                                fontSize: 9.sp,
                                fontFamily: Appfontstring.ChangaLight,
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// SHIMMER LOADING GRID
class ShimmerLoadingGrid extends StatelessWidget {
  const ShimmerLoadingGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 2.2,
          crossAxisSpacing: 4.w,
          mainAxisSpacing: 4.h,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return Shimmer.fromColors(
              baseColor: Colors.white.withOpacity(0.05),
              highlightColor: Colors.white.withOpacity(0.15),
              child: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.15),
                    width: 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 80.w,
                      height: 10.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Container(
                      width: 50.w,
                      height: 14.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          childCount: 8,
        ),
      ),
    );
  }
}

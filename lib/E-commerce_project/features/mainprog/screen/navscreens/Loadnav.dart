import 'dart:math';
import 'package:amiraly/E-commerce_project/common/models/appmodels.dart';
import 'package:amiraly/E-commerce_project/features/mainprog/screen/navscreens/loadnav_controller.dart';
import 'package:amiraly/E-commerce_project/util/constant/constants.dart';
import 'package:fl_chart/fl_chart.dart';
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
              controller.fetchAllIntlData();
              await controller.fetchFreshHourlyData();
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

                // Real Capital Load Cards
                const SliverToBoxAdapter(
                  child: RealCapitalLoadCards(),
                ),

                SliverToBoxAdapter(child: SizedBox(height: 8.h)),

                // Hourly Chart
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    child: const HourlyMaxLoadTable(),
                  ),
                ),

                SliverToBoxAdapter(child: SizedBox(height: 8.h)),

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

                // Station Cards Grid
                Obx(() {
                  if (controller.stnError.value &&
                      controller.stationLoads.isEmpty) {
                    return SliverToBoxAdapter(child: _buildErrorWidget());
                  } else if (controller.isLoadingStations.value &&
                      controller.stationLoads.isEmpty) {
                    return const SliverToBoxAdapter(
                        child: ShimmerLoadingGrid());
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
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 2.2,
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
                controller.errorMessage.value ?? 'حدث خطأ غير متوقع',
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
      height: 115.h,
      margin: EdgeInsets.only(left: 40.w, right: 40.w, top: 1.h, bottom: 8.h),
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
        mainAxisSize:
            min(4, 4).toDouble() > 0 ? MainAxisSize.min : MainAxisSize.min,
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
                        SizedBox(
                          width: 110.w,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              value.toStringAsFixed(0),
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 38.sp,
                                fontFamily: Appfontstring.digital,
                                shadows: [
                                  Shadow(
                                    color: Colors.redAccent.withOpacity(0.5),
                                    blurRadius: 15,
                                  ),
                                ],
                              ),
                              textDirection: TextDirection.rtl,
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

// REAL CAPITAL LOAD CARDS
class RealCapitalLoadCards extends StatelessWidget {
  const RealCapitalLoadCards({super.key});

  @override
  Widget build(BuildContext context) {
    final LoadnavController controller = Get.find<LoadnavController>();

    return Obx(() {
      final List<Map<String, dynamic>> cardItems = [
        {
          'city': 'الـقـاهـرة',
          'country': 'مصر',
          'load': controller.intlLoads['القاهرة'],
          'color': Colors.redAccent,
          'update': 'اليوم',
          'flag': '🇪🇬',
        },
        {
          'city': 'طوكيو',
          'country': 'اليابان',
          'load': controller.intlLoads['طوكيو'],
          'color': Colors.orangeAccent,
          'update': controller.intlLastUpdate['طوكيو'] ?? 'يومي',
          'flag': '🇯🇵',
        },
        {
          'city': 'المانيا',
          'country': 'ألمانيا',
          'load': controller.intlLoads['المانيا'],
          'color': Colors.blueAccent,
          'update': controller.intlLastUpdate['المانيا'] ?? 'يومي',
          'flag': '🇩🇪',
        },
        {
          'city': 'فرنسا',
          'country': 'فرنسا',
          'load': controller.intlLoads['فرنسا'],
          'color': const Color.fromARGB(255, 145, 21, 234),
          'update': controller.intlLastUpdate['فرنسا'] ?? 'يومي',
          'flag': '🇫🇷',
        },
        {
          'city': 'السعودية',
          'country': 'السعودية',
          'load': controller.intlLoads['السعودية'],
          'color': Colors.greenAccent,
          'update': controller.intlLastUpdate['السعودية'] ?? 'تقرير شهري',
          'flag': '🇸🇦',
        },
      ];

      return Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 3.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'أحمال عالمية مسجلة',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 10.sp,
                        fontFamily: Appfontstring.ChangaLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (controller.intlError.value) ...[
                      SizedBox(width: 8.w),
                      GestureDetector(
                        onTap: controller.fetchAllIntlData,
                        child: Icon(Icons.refresh,
                            color: Colors.orangeAccent, size: 14.sp),
                      ),
                    ],
                  ],
                ),
                Icon(Icons.public,
                    color: Colors.blueAccent.withOpacity(0.4), size: 10.sp),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.06),
                    Colors.white.withOpacity(0.01),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                  width: 0.8,
                ),
              ),
              child: Column(
                children: cardItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isLast = index == cardItems.length - 1;
                  final cityKey =
                      item['city'] == 'الـقـاهـرة' ? 'القاهرة' : item['city'];
                  final isFromCache =
                      controller.intlFromCache.contains(cityKey);

                  return Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 1.h),
                        child: Row(
                          children: [
                            Text(item['flag'],
                                style: TextStyle(fontSize: 10.sp)),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['city'],
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 10.sp,
                                      fontFamily: Appfontstring.ChangaLight,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        item['country'],
                                        style: TextStyle(
                                          color: Colors.white38,
                                          fontSize: 7.sp,
                                          fontFamily: Appfontstring.ChangaLight,
                                        ),
                                      ),
                                      if (isFromCache) ...[
                                        SizedBox(width: 4.w),
                                        Text(
                                          '(من الذاكرة)',
                                          style: TextStyle(
                                            color: Colors.orangeAccent
                                                .withOpacity(0.6),
                                            fontSize: 6.sp,
                                            fontFamily:
                                                Appfontstring.ChangaLight,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                item['load'] == null
                                    ? SizedBox(
                                        width: 15.w,
                                        height: 10.h,
                                        child: Shimmer.fromColors(
                                          baseColor: Colors.white10,
                                          highlightColor: Colors.white24,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(2.r),
                                            ),
                                          ),
                                        ),
                                      )
                                    : Opacity(
                                        opacity: isFromCache ? 0.35 : 1.0,
                                        child: Row(
                                          textDirection: TextDirection.ltr,
                                          children: [
                                            Text(
                                              (item['load'] as double)
                                                  .toStringAsFixed(0),
                                              style: TextStyle(
                                                color: item['color'],
                                                fontSize: 16.sp,
                                                fontFamily:
                                                    Appfontstring.digital,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(width: 2.w),
                                            Text(
                                              'م.و',
                                              style: TextStyle(
                                                color: item['color'],
                                                fontSize: 8.sp,
                                                fontFamily:
                                                    Appfontstring.ChangaLight,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                Text(
                                  item['update'],
                                  style: TextStyle(
                                    color: Colors.white24,
                                    fontSize: 8.sp,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (!isLast)
                        Divider(
                          color: Colors.white.withOpacity(0.03),
                          height: 1,
                          thickness: 0.5,
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      );
    });
  }
}

// HOURLY MAX LOAD TABLE
class HourlyMaxLoadTable extends StatelessWidget {
  const HourlyMaxLoadTable({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LoadnavController>();

    return Obx(() {
      if (controller.isLoadingHourly.value &&
          controller.hourlyMaxLoadsToday.isEmpty) {
        return Center(
            child: CircularProgressIndicator(color: Colors.orangeAccent));
      }
      if (controller.hourlyError.value != null &&
          controller.hourlyMaxLoadsToday.isEmpty) {
        return Text(controller.hourlyError.value!,
            style: TextStyle(color: Colors.red));
      }

      final primaryColor = Colors.orangeAccent;

      return Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Text(
              'أقصى حمل لكل ساعة (اليوم vs الأمس)',
              style: TextStyle(
                  fontFamily: Appfontstring.ChangaLight,
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12.h),
            _buildChart(primaryColor, controller),
          ],
        ),
      );
    });
  }

  Widget _buildChart(Color primary, LoadnavController controller) {
    return Container(
      height: 144.h,
      padding: EdgeInsets.only(right: 10.w),
      child: LineChart(LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (controller.maxHourlyLoad.value ?? 0) > 0
                ? controller.maxHourlyLoad.value! / 4
                : 500,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Colors.white12, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
              rightTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40.w,
                      getTitlesWidget: (value, meta) => Text(
                            value.toInt().toString(),
                            style: TextStyle(
                                color: Colors.white54, fontSize: 11.sp),
                          ))),
              bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                      showTitles: true,
                      interval: 4,
                      getTitlesWidget: (value, meta) => Text(
                            "${value.toInt()}:00",
                            style: TextStyle(
                                color: Colors.white54, fontSize: 11.sp),
                          )))),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: 23,
          minY: 0,
          maxY: ((controller.maxHourlyLoad.value ?? 0) > 0
                  ? controller.maxHourlyLoad.value!
                  : 100) *
              1.1,
          lineBarsData: [
            _buildLineData(controller.hourlyMaxLoadsYesterday, Colors.white30),
            _buildLineData(controller.hourlyMaxLoadsToday, primary),
          ])),
    );
  }

  LineChartBarData _buildLineData(
      List<Map<String, dynamic>> data, Color color) {
    List<FlSpot> spots = List.generate(24, (index) {
      final item = data.firstWhere((e) => e['hour'] == index,
          orElse: () => {'max_load': 0});
      return FlSpot(
          index.toDouble(), (item['max_load'] as num?)?.toDouble() ?? 0.0);
    });

    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 2,
      dotData: FlDotData(show: false),
      belowBarData: BarAreaData(show: true, color: color.withOpacity(0.1)),
    );
  }
}

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
                      end: widget.station.load,
                    ),
                    duration: const Duration(seconds: 1),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return RichText(
                        textDirection: TextDirection.rtl,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: value.toStringAsFixed(0),
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                fontFamily: Appfontstring.digital,
                                color: Colors.greenAccent,
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
    return Shimmer.fromColors(
      baseColor: Colors.white.withOpacity(0.05),
      highlightColor: Colors.white.withOpacity(0.15),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 2.2,
          crossAxisSpacing: 4.w,
          mainAxisSpacing: 4.h,
        ),
        itemCount: 8,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(bottom: 6.h),
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
          );
        },
      ),
    );
  }
}

import 'package:amiraly/app/common/widgets/appbar.dart';
import 'package:amiraly/app/features/mainprog/screen/catogriesScreens/indicators_controller.dart';
import 'package:amiraly/app/util/constant/constants.dart';
import 'package:amiraly/core/widgets/electric_loading_indicator.dart';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

class IndicatorsScreen extends GetView<IndicatorsController> {
  const IndicatorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(IndicatorsController()); // Ensure controller is initialized
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: Colors.transparent,
      appBar: const CustomAppBar(),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: Appcolors.indicatorBackground,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Obx(() {
            if (controller.isLoadingStations.value &&
                controller.stations.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const ElectricLoadingIndicator(
                      color: Colors.orangeAccent,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'جاري تحميل البيانات...',
                      style: TextStyle(
                        fontFamily: Appfontstring.ChangaLight,
                        color: Colors.white70,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                await controller.fetchStationIndicatorData();
                controller.fetchAllIntlData();
                await controller.fetchFreshHourlyData();
              },
              color: Colors.orangeAccent,
              child: FadeTransition(
                opacity: controller.fadeAnimation,
                child: SafeArea(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(isSmallScreen ? 8.0.w : 16.0.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- International Loads Section ---
                        _buildSectionTitle(
                          'أحمال عالمية مسجلة',
                          isSmallScreen,
                          icon: Icons.public,
                        ),
                        SizedBox(height: 16.h),
                        const RealCapitalLoadCards(),
                        SizedBox(height: 24.h),

                        // --- Hourly Max Loads Section ---
                        _buildSectionTitle(
                          'أقصى حمل لكل ساعة',
                          isSmallScreen,
                          icon: Icons.access_time_filled,
                        ),
                        SizedBox(height: 16.h),
                        const HourlyMaxLoadTable(),
                        SizedBox(height: 24.h),

                        Divider(
                            color: Colors.white.withOpacity(0.1),
                            thickness: 1,
                            height: 30.h),

                        // --- Station Charts Section ---
                        _buildSectionTitle(
                          'احمال المحطات على مدار اليوم ',
                          isSmallScreen,
                          icon: Icons.analytics,
                        ),
                        SizedBox(height: 16.h),
                        _buildStationSelector(isSmallScreen),
                        SizedBox(height: 16.h),
                        _buildLineChartContainer(isSmallScreen),
                        SizedBox(height: 16.h),
                        _buildLineChartLegend(isSmallScreen),
                        SizedBox(height: 24.h),

                        Divider(
                            color: Colors.white.withOpacity(0.1),
                            thickness: 1,
                            height: 30.h),

                        // --- Pie Chart Section ---
                        _buildSectionTitle(
                          'تحليل نسب احمال المحطات والتوليد والتبادلات',
                          isSmallScreen,
                          icon: Icons.pie_chart,
                        ),
                        SizedBox(height: 16.h),
                        _buildPieChartContainer(isSmallScreen),
                        SizedBox(height: 16.h),
                        _buildPieChartLegend(isSmallScreen),
                        SizedBox(height: 80.h)
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isSmallScreen,
      {IconData? icon}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon,
                color: Colors.orangeAccent, size: (isSmallScreen ? 16 : 18).sp),
            SizedBox(width: 8.w),
          ],
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: (isSmallScreen ? 12 : 14).sp,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: Appfontstring.ChangaLight,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStationSelector(bool isSmallScreen) {
    return Obx(() {
      if (controller.stations.isEmpty) {
        return _buildEmptyCard(
          'لا توجد محطات متاحة',
          isSmallScreen,
        );
      }

      return Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Row(
            children: controller.stations.asMap().entries.map((entry) {
              final index = entry.key;
              final isSelected = controller.selectedStations.contains(index);
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 3.0.w),
                child: GestureDetector(
                  onTap: () =>
                      controller.toggleStationSelection(index, !isSelected),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.orangeAccent
                          : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: isSelected
                            ? Colors.orangeAccent
                            : Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      controller.stations[index],
                      style: TextStyle(
                        fontSize: (isSmallScreen ? 10 : 12).sp,
                        fontFamily: Appfontstring.ChangaLight,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      );
    });
  }

  Widget _buildEmptyCard(String message, bool isSmallScreen) {
    return Container(
      height: (isSmallScreen ? 60 : 80).h,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.sp,
              fontFamily: Appfontstring.ChangaLight,
              color: Colors.white54,
              height: 1.3,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLineChartContainer(bool isSmallScreen) {
    return Obx(() {
      if (controller.selectedStations.isEmpty) {
        return _buildEmptyCard('اختر محطة لعرض البيانات', isSmallScreen);
      }

      final chartHeight = isSmallScreen ? 240.h : 320.h;

      return Container(
          height: chartHeight,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Padding(
              padding: EdgeInsets.all(8.w),
              child: AspectRatio(
                aspectRatio: 1.5,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      horizontalInterval: 50,
                      verticalInterval: 4,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.white.withOpacity(0.1),
                        strokeWidth: 1,
                      ),
                      getDrawingVerticalLine: (value) => FlLine(
                        color: Colors.white.withOpacity(0.1),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32.w,
                          interval: 50,
                          getTitlesWidget: (value, meta) => Padding(
                            padding: EdgeInsets.only(right: 4.w),
                            child: Text(
                              value.toInt().toString(),
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: Colors.white54,
                                fontFamily: Appfontstring.digital,
                              ),
                            ),
                          ),
                        ),
                        axisNameWidget: Container(
                          padding: EdgeInsets.only(bottom: 4.h),
                          child: Text(
                            'Load (Units)',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                              fontFamily: Appfontstring.ChangaLight,
                            ),
                          ),
                        ),
                        axisNameSize: 32.h,
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 24.h,
                          interval: 4,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() % 4 == 0) {
                              return Padding(
                                padding: EdgeInsets.only(top: 4.h),
                                child: Text(
                                  '${value.toInt()}:00',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: Colors.white54,
                                    fontFamily: Appfontstring.digital,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                        axisNameWidget: Container(
                          padding: EdgeInsets.only(top: 4.h),
                          child: Text(
                            'Time (Hours)',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                              fontFamily: Appfontstring.ChangaLight,
                            ),
                          ),
                        ),
                        axisNameSize: 32.h,
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    minX: 0,
                    maxX: 23,
                    minY: 0,
                    maxY: 700,
                    lineBarsData:
                        controller.selectedStations.map((stationIndex) {
                      final color = AppConstants.indicatorstationColors[
                          stationIndex % AppConstants.maxStations];
                      return LineChartBarData(
                          spots: controller.stationLoads[stationIndex]
                              .asMap()
                              .entries
                              .map((e) => FlSpot(e.key.toDouble(), e.value))
                              .toList(),
                          isCurved: true,
                          color: color,
                          barWidth: 3,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) =>
                                FlDotCirclePainter(
                                    radius: 3, strokeColor: Colors.white),
                          ),
                          belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    color.withOpacity(0.3),
                                    color.withOpacity(0)
                                  ])));
                    }).toList(),
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        tooltipRoundedRadius: 8.r,
                        tooltipPadding: EdgeInsets.all(8.w),
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            return LineTooltipItem(
                              'محطة ${controller.stations[controller.selectedStations[spot.barIndex]]}\n${spot.y.toStringAsFixed(1)} م.و',
                              TextStyle(
                                color: Colors.white,
                                fontSize: 11.sp,
                                fontFamily: Appfontstring.ChangaLight,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                ),
              )));
    });
  }

  Widget _buildLineChartLegend(bool isSmallScreen) {
    return Obx(() => Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          constraints: BoxConstraints(maxHeight: 100.h),
          child: Wrap(
            spacing: 12.0.w,
            runSpacing: 8.0.h,
            alignment: WrapAlignment.start,
            children: controller.selectedStations.map((index) {
              return Indicator(
                color: AppConstants.indicatorstationColors[
                    index % AppConstants.indicatorstationColors.length],
                text: 'محطة ${controller.stations[index]}',
                isSquare: false,
                size: isSmallScreen ? 10 : 12,
              );
            }).toList(),
          ),
        ));
  }

  Widget _buildPieChartContainer(bool isSmallScreen) {
    return Obx(() {
      if (!controller.hasPieData.value) {
        return _buildEmptyCard('لا توجد بيانات لعرض النسب', isSmallScreen);
      }

      final chartHeight = isSmallScreen ? 220.h : 300.h;

      final double stationsPct =
          (controller.sumStations.value.abs() / controller.totalDynamic.value) *
              100.0;
      final double generationPct = (controller.sumGeneration.value.abs() /
              controller.totalDynamic.value) *
          100.0;
      final double exchangesPct = (controller.sumExchanges.value.abs() /
              controller.totalDynamic.value) *
          100.0;

      return Center(
        child: Container(
          height: chartHeight,
          width: chartHeight * 1.2, // Maintain aspect ratio within centered box
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      controller.touchedPieIndex.value = -1;
                      return;
                    }
                    controller.touchedPieIndex.value =
                        pieTouchResponse.touchedSection!.touchedSectionIndex;
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 2,
                centerSpaceRadius: (isSmallScreen ? 32 : 48).r,
                sections: _buildPieChartSections(
                  isSmallScreen,
                  stationsPct,
                  generationPct,
                  exchangesPct,
                ),
              ),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            ),
          ),
        ),
      );
    });
  }

  List<PieChartSectionData> _buildPieChartSections(
    bool isSmallScreen,
    double stationsPct,
    double generationPct,
    double exchangesPct,
  ) {
    final pieData = [
      {'title': 'المحطات', 'pct': stationsPct},
      {'title': 'التوليد', 'pct': generationPct},
      {'title': 'التبادلات', 'pct': exchangesPct},
    ];

    return List.generate(pieData.length, (i) {
      final radius = (isSmallScreen ? (45.0) : (55.0)).r;
      const shadows = [Shadow(color: Colors.black26, blurRadius: 2)];

      final data = pieData[i];
      final percentage = (data['pct'] as double).toStringAsFixed(1);
      final sectionTitle = data['title'] as String;

      return PieChartSectionData(
        color: AppConstants.indicatorstationColors[
            i % AppConstants.indicatorstationColors.length],
        value: data['pct'] as double,
        title: '',
        radius: radius,
        titleStyle: const TextStyle(),
        badgeWidget: Container(
          padding: EdgeInsets.all(isSmallScreen ? 6.w : 8.w),
          decoration: BoxDecoration(
            color: AppConstants.indicatorstationColors[i].withOpacity(0.85),
            borderRadius: BorderRadius.circular(6.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: (isSmallScreen ? 11 : 13).sp,
                  color: Colors.white,
                  fontFamily: Appfontstring.digital,
                  fontWeight: FontWeight.bold,
                  shadows: shadows,
                  height: 1.1,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                sectionTitle,
                style: TextStyle(
                  fontSize: (isSmallScreen ? 9 : 11).sp,
                  color: Colors.white,
                  fontFamily: Appfontstring.ChangaLight,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        badgePositionPercentageOffset: 1.25,
      );
    });
  }

  Widget _buildPieChartLegend(bool isSmallScreen) {
    return Obx(() {
      final double stationsPct = controller.totalDynamic.value > 0
          ? (controller.sumStations.value / controller.totalDynamic.value) * 100
          : 0.0;
      final double generationPct = controller.totalDynamic.value > 0
          ? (controller.sumGeneration.value / controller.totalDynamic.value) *
              100
          : 0.0;
      final double exchangesPct = controller.totalDynamic.value > 0
          ? (controller.sumExchanges.value / controller.totalDynamic.value) *
              100
          : 0.0;

      final pieLabels = ['المحطات', 'التوليد', 'التبادلات'];
      final pcts = [stationsPct, generationPct, exchangesPct];
      final sums = [
        controller.sumStations.value,
        controller.sumGeneration.value,
        controller.sumExchanges.value
      ];

      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          children: List.generate(pieLabels.length, (index) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 4.h),
              child: Indicator(
                color: AppConstants.indicatorstationColors[index],
                isSquare: true,
                size: isSmallScreen ? 12 : 14,
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontFamily: Appfontstring.ChangaLight,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                    children: [
                      TextSpan(text: '${pieLabels[index]}: '),
                      TextSpan(
                        text: '${pcts[index].toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.yellow,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                          text: ' (${sums[index].toStringAsFixed(0)} م.و)'),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      );
    });
  }
}

class Indicator extends StatelessWidget {
  final Color color;
  final String? text;
  final Widget? child;
  final bool isSquare;
  final double size;
  final Color textColor;

  const Indicator({
    super.key,
    required this.color,
    this.text,
    this.child,
    this.isSquare = false,
    this.size = 16,
    this.textColor = Colors.white70,
  }) : assert(text != null || child != null);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size.w,
          height: size.h,
          decoration: BoxDecoration(
            shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
            color: color,
            border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
        SizedBox(width: 8.w),
        Flexible(
          child: child ??
              Text(
                text!,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontFamily: Appfontstring.ChangaLight,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
        ),
      ],
    );
  }
}

// ==============================================================================
// MIGRATED COMPONENTS (Adapted for Indicators Screen)
// ==============================================================================

// REAL CAPITAL LOAD CARDS
class RealCapitalLoadCards extends GetView<IndicatorsController> {
  const RealCapitalLoadCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final List<Map<String, dynamic>> cardItems = [
        {
          'city': 'الـقـاهـرة',
          'country': 'مصر',
          'load': controller.intlLoads['القاهرة'],
          'color': Colors.orangeAccent,
          'update': 'الان',
          'flag': '🇪🇬',
        },
        {
          'city': 'طوكيو',
          'country': 'اليابان',
          'load': controller.intlLoads['طوكيو'],
          'color': Colors.redAccent,
          'update': controller.intlLastUpdate['طوكيو'] ?? 'يومي',
          'flag': '🇯🇵',
        },
        {
          'city': 'المانيا',
          'country': 'ألمانيا',
          'load': controller.intlLoads['المانيا'],
          'color': Colors.greenAccent,
          'update': controller.intlLastUpdate['المانيا'] ?? 'يومي',
          'flag': '🇩🇪',
        },
        {
          'city': 'فرنسا',
          'country': 'فرنسا',
          'load': controller.intlLoads['فرنسا'],
          'color': const Color.fromARGB(255, 228, 211, 240),
          'update': controller.intlLastUpdate['فرنسا'] ?? 'يومي',
          'flag': '🇫🇷',
        },
        {
          'city': 'السعودية',
          'country': 'السعودية',
          'load': controller.intlLoads['السعودية'],
          'color': Colors.yellow,
          'update': controller.intlLastUpdate['السعودية'] ?? 'تقرير شهري',
          'flag': '🇸🇦',
        },
      ];

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
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
              final isFromCache = controller.intlFromCache.contains(cityKey);

              return Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                    child: Row(
                      children: [
                        Text(item['flag'], style: TextStyle(fontSize: 16.sp)),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['city'],
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 12.sp,
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
                                      fontSize: 10.sp,
                                      fontFamily: Appfontstring.ChangaLight,
                                    ),
                                  ),
                                  if (isFromCache) ...[
                                    SizedBox(width: 6.w),
                                    Text(
                                      '(من الذاكرة)',
                                      style: TextStyle(
                                        color: Colors.orangeAccent
                                            .withOpacity(0.6),
                                        fontSize: 8.sp,
                                        fontFamily: Appfontstring.ChangaLight,
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
                                            fontSize: 19.sp,
                                            fontFamily:
                                                Appfontstring.ChangaLight,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(width: 4.w),
                                        Text(
                                          'م.و',
                                          style: TextStyle(
                                            color: item['color'],
                                            fontSize: 10.sp,
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
                                fontSize: 9.sp,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      color: Colors.white.withOpacity(0.05),
                      height: 12.h,
                      thickness: 0.5,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      );
    });
  }
}

// HOURLY MAX LOAD TABLE
class HourlyMaxLoadTable extends GetView<IndicatorsController> {
  const HourlyMaxLoadTable({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingHourly.value &&
          controller.hourlyMaxLoadsToday.isEmpty) {
        return Center(
            child: const ElectricLoadingIndicator(color: Colors.orangeAccent));
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
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(
                'اليوم vs الأمس',
                style: TextStyle(
                    fontFamily: Appfontstring.ChangaLight,
                    color: Colors.white38,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold),
              ),
              Row(children: [
                Container(
                    width: 10.w, height: 10.w, color: Colors.orangeAccent),
                SizedBox(width: 4.w),
                Text("اليوم",
                    style: TextStyle(color: Colors.white54, fontSize: 10.sp)),
                SizedBox(width: 12.w),
                Container(width: 10.w, height: 10.w, color: Colors.white30),
                SizedBox(width: 4.w),
                Text("الأمس",
                    style: TextStyle(color: Colors.white54, fontSize: 10.sp)),
              ])
            ]),
            SizedBox(height: 12.h),
            _buildChart(primaryColor, controller),
          ],
        ),
      );
    });
  }

  Widget _buildChart(Color primary, IndicatorsController controller) {
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

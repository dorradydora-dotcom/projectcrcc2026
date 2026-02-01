import 'package:amiraly/E-commerce_project/common/widgets/appbar.dart';
import 'package:amiraly/E-commerce_project/util/constant/constants.dart';
import 'package:amiraly/main.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class IndicatorsScreen extends StatefulWidget {
  const IndicatorsScreen({super.key});

  @override
  State<IndicatorsScreen> createState() => _IndicatorsScreenState();
}

class _IndicatorsScreenState extends State<IndicatorsScreen>
    with TickerProviderStateMixin {
  List<String> stations = [];
  List<int> selectedStations = [];
  late List<List<double>> stationLoads;
  int touchedPieIndex = -1;
  bool isLoading = true;
  double sumStations = 0.0;
  double sumGeneration = 0.0;
  double sumExchanges = 0.0;
  double totalDynamic = 0.0;
  bool hasPieData = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final SupabaseServiceHourly _supabaseService = SupabaseServiceHourly();

  @override
  void initState() {
    super.initState();
    stationLoads = [];
    sumStations = 0.0;
    sumGeneration = 0.0;
    sumExchanges = 0.0;
    totalDynamic = 0.0;
    hasPieData = false;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        isLoading = true;
      });
      _animationController.reset();
      final hourlyLoads = await _supabaseService.fetchStationHourlyLoads();

      final List<String> newStations =
          hourlyLoads.map((e) => e.stationName).toList();
      final List<List<double>> newStationLoads =
          hourlyLoads.map((e) => e.loads).toList();

      double newSumStations = 0.0;
      double newSumGeneration = 0.0;
      double newSumExchanges = 0.0;

      final List<String> exchangeStations = [
        'عبور3/عاشر',
        'الكريمات/بنى سويف',
        'قليوب/قناطر',
        'برقاش/ابوغالب',
        'ابو زعبل ق / بلبيس',
      ];
      final String generationStation = 'الكريمات الشمسية';

      for (int i = 0; i < newStations.length; i++) {
        final String stationName = newStations[i];
        final List<double> loads = newStationLoads[i];
        final double stationSum =
            loads.fold(0.0, (double a, double b) => a + b);

        if (stationName == generationStation) {
          newSumGeneration += stationSum;
        } else if (exchangeStations.contains(stationName)) {
          newSumExchanges += stationSum;
        } else {
          newSumStations += stationSum;
        }
      }

      final double newTotalDynamic =
          newSumStations + newSumGeneration + newSumExchanges;
      final bool newHasPieData = newTotalDynamic > 0.0;

      setState(() {
        stations = newStations;
        stationLoads = newStationLoads;
        selectedStations = newStations.isNotEmpty ? [0] : [];
        sumStations = newSumStations;
        sumGeneration = newSumGeneration;
        sumExchanges = newSumExchanges;
        totalDynamic = newTotalDynamic;
        hasPieData = newHasPieData;
        isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        stations = [];
        stationLoads = [];
        selectedStations = [];
        sumStations = 0.0;
        sumGeneration = 0.0;
        sumExchanges = 0.0;
        totalDynamic = 0.0;
        hasPieData = false;
        isLoading = false;
      });
      _animationController.forward();
    }
  }

  void _showMaxStationsSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                'يمكنك اختيار ${AppConstants.maxStations} محطات كحد أقصى',
                style: TextStyle(
                  fontFamily: Appfontstring.Almarai_Bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: IndicatorAppColors.secondaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const CustomAppBar(),
      body: Container(
        decoration: BoxDecoration(
          color: IndicatorAppColors.backgroundColor,
          boxShadow: [
            BoxShadow(
              color: IndicatorAppColors.shadowColor.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          IndicatorAppColors.primaryColor),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'جاري تحميل البيانات...',
                      style: TextStyle(
                        fontFamily: Appfontstring.Almarai_Bold,
                        color: IndicatorAppColors.subTextColor,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadData,
                color: IndicatorAppColors.primaryColor,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SafeArea(
                    child: Padding(
                      padding: EdgeInsets.all(isSmallScreen ? 8.0.w : 16.0.w),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle(
                              'احمال المحطات على مدار اليوم ',
                              isSmallScreen,
                            ),
                            SizedBox(height: 16.h),
                            _buildStationSelector(isSmallScreen),
                            SizedBox(height: 16.h),
                            _buildLineChartContainer(isSmallScreen),
                            SizedBox(height: 16.h),
                            _buildLineChartLegend(isSmallScreen),
                            SizedBox(height: 8.h),
                            Divider(
                                color: IndicatorAppColors.borderColor,
                                thickness: 1,
                                height: 16.h),
                            SizedBox(height: 16.h),
                            _buildSectionTitle(
                              'تحليل نسب احمال المحطات والتوليد والتبادلات',
                              isSmallScreen,
                            ),
                            SizedBox(height: 16.h),
                            _buildPieChartContainer(isSmallScreen),
                            SizedBox(height: 16.h),
                            _buildPieChartLegend(isSmallScreen),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isSmallScreen) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: IndicatorAppColors.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12.r),
        border:
            Border.all(color: IndicatorAppColors.primaryColor.withOpacity(0.2)),
      ),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: (isSmallScreen ? 12 : 14).sp,
          color: IndicatorAppColors.primaryColor,
          fontWeight: FontWeight.bold,
          fontFamily: Appfontstring.Almarai_Bold,
          height: 1.1,
        ),
      ),
    );
  }

  Widget _buildStationSelector(bool isSmallScreen) {
    if (stations.isEmpty) {
      return _buildEmptyCard(
        'لا توجد محطات متاحة',
        isSmallScreen,
      );
    }

    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: IndicatorAppColors.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: IndicatorAppColors.borderColor),
        boxShadow: [
          BoxShadow(
            color: IndicatorAppColors.shadowColor.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        child: Row(
          children: stations.asMap().entries.map((entry) {
            final index = entry.key;
            final isSelected = selectedStations.contains(index);
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 2.0.w),
              child: FilterChip(
                label: Text(
                  stations[index],
                  style: TextStyle(
                    fontSize: (isSmallScreen ? 10 : 12).sp,
                    fontFamily: Appfontstring.Almarai_Bold,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : IndicatorAppColors.textColor,
                  ),
                ),
                selected: isSelected,
                selectedColor: IndicatorAppColors.primaryColor,
                checkmarkColor: Colors.white,
                backgroundColor: Colors.grey.shade100,
                elevation: isSelected ? 4 : 2,
                shadowColor: IndicatorAppColors.shadowColor.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                onSelected: (selected) {
                  setState(() {
                    if (selected &&
                        selectedStations.length < AppConstants.maxStations) {
                      selectedStations.add(index);
                    } else if (selected) {
                      _showMaxStationsSnackBar();
                    } else {
                      selectedStations.remove(index);
                    }
                  });
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyCard(String message, bool isSmallScreen) {
    return Container(
      height: (isSmallScreen ? 60 : 80).h,
      decoration: BoxDecoration(
        color: IndicatorAppColors.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: IndicatorAppColors.borderColor),
        boxShadow: [
          BoxShadow(
            color: IndicatorAppColors.shadowColor.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.sp,
              fontFamily: Appfontstring.Almarai_Bold,
              color: IndicatorAppColors.subTextColor,
              height: 1.3,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLineChartContainer(bool isSmallScreen) {
    if (selectedStations.isEmpty) {
      return _buildEmptyCard('اختر محطة لعرض البيانات', isSmallScreen);
    }

    final chartHeight = isSmallScreen ? 240.h : 320.h;

    return Container(
        height: chartHeight,
        decoration: BoxDecoration(
          color: IndicatorAppColors.cardColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: IndicatorAppColors.borderColor),
          boxShadow: [
            BoxShadow(
              color: IndicatorAppColors.shadowColor.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
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
                      color: IndicatorAppColors.borderColor.withOpacity(0.3),
                      strokeWidth: 1,
                    ),
                    getDrawingVerticalLine: (value) => FlLine(
                      color: IndicatorAppColors.borderColor.withOpacity(0.3),
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
                              color: IndicatorAppColors.subTextColor,
                              fontFamily: Appfontstring.Almarai_Bold,
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
                            color: IndicatorAppColors.textColor,
                            fontFamily: Appfontstring.Almarai_Bold,
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
                                  color: IndicatorAppColors.subTextColor,
                                  fontFamily: Appfontstring.Almarai_Bold,
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
                            color: IndicatorAppColors.textColor,
                            fontFamily: Appfontstring.Almarai_Bold,
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
                    border: Border.all(color: IndicatorAppColors.borderColor),
                  ),
                  minX: 0,
                  maxX: 23,
                  minY: 0,
                  maxY: 700,
                  lineBarsData: selectedStations.map((stationIndex) {
                    final color = AppConstants.indicatorstationColors[
                        stationIndex % AppConstants.maxStations];
                    return LineChartBarData(
                        spots: stationLoads[stationIndex]
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
                                  radius: 3,
                                  color: color,
                                  strokeWidth: 1,
                                  strokeColor: Colors.white),
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
                            'محطة ${stations[selectedStations[spot.barIndex]]}\n${spot.y.toStringAsFixed(1)} م.و',
                            TextStyle(
                              color: Colors.white,
                              fontSize: 11.sp,
                              fontFamily: Appfontstring.Almarai_Bold,
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
  }

  Widget _buildLineChartLegend(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
          color: IndicatorAppColors.cardColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: IndicatorAppColors.borderColor),
          boxShadow: [
            BoxShadow(
                color: IndicatorAppColors.shadowColor.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ]),
      constraints: BoxConstraints(maxHeight: 100.h),
      child: Wrap(
        spacing: 12.0.w,
        runSpacing: 8.0.h,
        alignment: WrapAlignment.start,
        children: selectedStations.map((index) {
          return Indicator(
            color: AppConstants.indicatorstationColors[
                index % AppConstants.indicatorstationColors.length],
            text: 'محطة ${stations[index]}',
            isSquare: false,
            size: isSmallScreen ? 10 : 12,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPieChartContainer(bool isSmallScreen) {
    if (!hasPieData) {
      return _buildEmptyCard('لا توجد بيانات لعرض النسب', isSmallScreen);
    }

    final chartHeight = isSmallScreen ? 220.h : 300.h;

    final double stationsPct = (sumStations / totalDynamic) * 100.0;
    final double generationPct = (sumGeneration / totalDynamic) * 100.0;
    final double exchangesPct = (sumExchanges / totalDynamic) * 100.0;

    return Container(
      height: chartHeight,
      decoration: BoxDecoration(
        color: IndicatorAppColors.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: IndicatorAppColors.borderColor),
        boxShadow: [
          BoxShadow(
            color: IndicatorAppColors.shadowColor.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: AspectRatio(
          aspectRatio: 1.2,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      touchedPieIndex = -1;
                      return;
                    }
                    touchedPieIndex =
                        pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
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
        color: AppConstants.indicatorpieChartColors[
            i % AppConstants.indicatorpieChartColors.length],
        value: data['pct'] as double,
        title: '',
        radius: radius,
        titleStyle: const TextStyle(),
        badgeWidget: Container(
          padding: EdgeInsets.all(isSmallScreen ? 6.w : 8.w),
          decoration: BoxDecoration(
            color: AppConstants.indicatorpieChartColors[i].withOpacity(0.85),
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
                  fontFamily: Appfontstring.Almarai_Bold,
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
                  fontFamily: Appfontstring.Almarai_Bold,
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
    final double stationsPct =
        totalDynamic > 0 ? (sumStations / totalDynamic) * 100 : 0.0;
    final double generationPct =
        totalDynamic > 0 ? (sumGeneration / totalDynamic) * 100 : 0.0;
    final double exchangesPct =
        totalDynamic > 0 ? (sumExchanges / totalDynamic) * 100 : 0.0;

    final pieLabels = ['المحطات', 'التوليد', 'التبادلات'];
    final pcts = [stationsPct, generationPct, exchangesPct];
    final sums = [sumStations, sumGeneration, sumExchanges];

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: IndicatorAppColors.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: IndicatorAppColors.borderColor),
        boxShadow: [
          BoxShadow(
            color: IndicatorAppColors.shadowColor.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Wrap(
        spacing: 16.0.w,
        runSpacing: 8.0.h,
        alignment: WrapAlignment.start,
        children: List.generate(pieLabels.length, (index) {
          return Indicator(
            color: AppConstants.indicatorpieChartColors[index],
            text:
                '${pieLabels[index]}: ${pcts[index].toStringAsFixed(1)}% (${sums[index].toStringAsFixed(0)} م.و)',
            isSquare: true,
            size: isSmallScreen ? 10 : 12,
          );
        }),
      ),
    );
  }
}

class Indicator extends StatelessWidget {
  final Color color;
  final String text;
  final bool isSquare;
  final double size;
  final Color textColor;

  const Indicator({
    super.key,
    required this.color,
    required this.text,
    this.isSquare = false,
    this.size = 16,
    this.textColor = IndicatorAppColors.textColor,
  });

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
            border: Border.all(color: Colors.white, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
        SizedBox(width: 8.w),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.sp,
              fontFamily: Appfontstring.Almarai_Bold,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

import 'dart:async';
import 'dart:ui';
import 'package:amiraly/E-commerce_project/common/models/appmodels.dart';
import 'package:amiraly/E-commerce_project/common/widgets/appbar.dart';
import 'package:amiraly/E-commerce_project/util/constant/constants.dart';
import 'package:amiraly/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:amiraly/E-commerce_project/features/mainprog/screen/navscreens/station_load_controller.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';

class Cairoscreen extends StatefulWidget {
  const Cairoscreen({super.key});

  @override
  State<Cairoscreen> createState() => _CairoscreenState();
}

class _CairoscreenState extends State<Cairoscreen> {
  double get screenWidth => MediaQuery.of(context).size.width;
  double get screenHeight => MediaQuery.of(context).size.height;
  final SupabaseService supabaseService = SupabaseService();
  List<StationLoad> stationLoads = [];
  bool isLoading = true;
  String? errorMessage;
  final GlobalKey<LiquidPullToRefreshState> refreshIndicatorKey =
      GlobalKey<LiquidPullToRefreshState>();
  final StationLoadController _controller = Get.find<StationLoadController>();

  @override
  void initState() {
    super.initState();
    // Use the central controller's data
  }

  Future<void> fetchData() async {
    await _controller.fetchData();
  }

  double _getTotalLoad() {
    return _controller.totalLoad;
  }

  String _getStationLoad(String stationName) {
    try {
      final station = _controller.stationLoads
          .firstWhere((s) => s.stationName == stationName);
      double absLoad = station.load.abs();
      bool isPositive = _controller.directions[stationName] ?? true;
      double signedLoad = isPositive ? absLoad : -absLoad;
      return '${signedLoad >= 0 ? '+' : ''}${signedLoad.toStringAsFixed(0)}';
    } catch (_) {
      return '0';
    }
  }

  void _flipDirection(String stationName) async {
    await _controller.toggleDirection(stationName);
    setState(() {});
  }

  void updateLoads() async {
    // Controller handles this via its timer
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Appcolors.primaryColor,
                Appcolors.primaryColor,
                Color(0xFF081A2A)
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: LiquidPullToRefresh(
            key: refreshIndicatorKey,
            onRefresh: fetchData,
            height: 50.h,
            showChildOpacityTransition: false,
            borderWidth: 2,
            color: Colors.white,
            backgroundColor: Appcolors.primaryColor,
            animSpeedFactor: 2,
            child: SafeArea(
              child: Obx(() {
                final isWide = screenWidth > 600;
                final totalLoad = _getTotalLoad();

                if (_controller.hasError.value) {
                  return _buildErrorView(isWide);
                }

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.w),
                        child: Column(
                          children: [
                            SizedBox(height: 2.h),
                            TotalLoadCard(
                              totalLoad: totalLoad,
                              isLoading: _controller.isLoading.value,
                              isWide: isWide,
                            ),
                            SizedBox(height: 8.h),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: 0.h, bottom: 0.h),
                        child: Text(
                          'تحديث تلقائي كل 60 ثانية',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white24,
                            fontSize: 7.sp,
                            fontFamily: Appfontstring.ChangaLight,
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      sliver: _buildSliverSectionHeader(
                          'التبادلات خارج القاهرة', Icons.swap_horiz),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      sliver: _buildStationsGrid(isWide),
                    ),
                    SliverToBoxAdapter(child: SizedBox(height: 4.h)),
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      sliver: _buildSliverSectionHeader('التوليد', Icons.bolt),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      sliver: SliverToBoxAdapter(
                        child: StationGaugeCard(
                          title: 'الكريمات الشمسية',
                          subtitle: '',
                          value: _getStationLoad('الكريمات الشمسية'),
                          min: 0,
                          max: 120,
                          isWide: isWide,
                          isToggleable: false,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(child: SizedBox(height: 4.h)),
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      sliver: SliverToBoxAdapter(
                          child: _buildNotesExpansion(isWide)),
                    ),
                    SliverToBoxAdapter(child: SizedBox(height: 10.h)),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(bool isWide) {
    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWideError = constraints.maxWidth > 600;
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(isWideError ? 26.w : 14.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: isWideError ? 80.sp : 64.sp, color: Colors.red),
                  SizedBox(height: 16.h),
                  Text(errorMessage!,
                      style: TextStyle(
                        fontSize: isWideError ? 18.sp : 16.sp,
                        fontFamily: Appfontstring.ChangaLight,
                        color: Colors.red,
                      ),
                      textAlign: TextAlign.center),
                  SizedBox(height: 16.h),
                  ElevatedButton.icon(
                    onPressed: fetchData,
                    icon: const Icon(Icons.refresh),
                    label: Text(
                      'إعادة المحاولة',
                      style: TextStyle(
                        fontSize: isWideError ? 16.sp : 14.sp,
                        fontFamily: Appfontstring.ChangaLight,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88E5),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: isWideError ? 32.w : 24.w,
                        vertical: 12.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSliverSectionHeader(String title, IconData icon) {
    return SliverToBoxAdapter(
      child: Padding(
        padding:
            EdgeInsetsDirectional.only(bottom: 12.h, start: 8.w, top: 16.h),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 14.h,
              color: const Color(0xFF00E5FF),
            ),
            SizedBox(width: 8.w),
            Text(
              title.toUpperCase(),
              style: TextStyle(
                fontFamily: Appfontstring.ChangaBold,
                fontSize: 11.sp,
                color: Colors.white70,
                letterSpacing: 2,
              ),
            ),
            const Spacer(),
            Text(
              'SEC_ID: 0x${title.hashCode.toRadixString(16).toUpperCase().substring(0, 4)}',
              style: TextStyle(
                fontFamily: Appfontstring.ChangaLight,
                fontSize: 7.sp,
                color: const Color(0xFF00E5FF).withOpacity(0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStationsGrid(bool isWide) {
    final stations = [
      {
        'title': 'عبور 3 / العاشر',
        'subtitle': 'تحكم القناة',
        'key': 'عبور3/عاشر',
        'min': 0,
        'max': 130,
      },
      {
        'title': 'القناطر',
        'subtitle': 'تحكم طلخا',
        'key': 'قليوب/قناطر',
        'min': 0,
        'max': 110,
      },
      {
        'title': 'ابوزعبل ق /بلبيس',
        'subtitle': 'تحكم القناة',
        'key': 'ابو زعبل ق / بلبيس',
        'min': 0,
        'max': 120,
      },
      {
        'title': 'برقاش / ابوغالب',
        'subtitle': 'تحكم غرب الدلتا',
        'key': 'برقاش/ابوغالب',
        'min': 0,
        'max': 120,
      },
      {
        'title': 'الكريمات /بنى سويف شرق',
        'subtitle': 'تحكم سمالوط',
        'key': 'الكريمات/بنى سويف',
        'min': 0,
        'max': 180,
      },
    ];

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWide ? 2 : 1,
        mainAxisSpacing: 2.h, // Reduced from 4.h
        crossAxisSpacing: 8.w,
        childAspectRatio:
            isWide ? 3.0 : 3.8, // Adjusted from 4.2 : 5.8 to fix overflow
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final station = stations[index];
          return StationGaugeCard(
            title: station['title'] as String,
            subtitle: station['subtitle'] as String,
            value: _getStationLoad(station['key'] as String),
            min: station['min'] as int,
            max: station['max'] as int,
            isWide: isWide,
            onFlip: () => _flipDirection(station['key'] as String),
          );
        },
        childCount: stations.length,
      ),
    );
  }

  Widget _buildNotesExpansion(bool isWide) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.amber.withOpacity(0.2)),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              collapsedIconColor: Colors.amber,
              iconColor: Colors.amber,
              leading:
                  Icon(Icons.info_outline, color: Colors.amber, size: 20.sp),
              title: Text(
                'ملاحظات هامة',
                style: TextStyle(
                  fontFamily: Appfontstring.ChangaBold,
                  fontSize: isWide ? 13.sp : 11.sp,
                  color: Colors.white,
                ),
              ),
              children: [
                Padding(
                  padding: EdgeInsets.all(isWide ? 10.w : 6.w),
                  child: Column(
                    children: [
                      _buildNoteItem(
                          'جميع البيانات محدثة بشكل تلقائى من محطات المنطقه كل ساعة'),
                      _buildNoteItem(
                          'الحمل الكلى يمثل مجموع احمال المحطات والتبادلات (صادر و وارد) و حمل التوليد'),
                      _buildNoteItem(
                          'عند وجود مشكلة لتحديث البيانات من المحطات يتم تحديثها من التحكم'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoteItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 5.h),
            child: Icon(Icons.circle, size: 5.sp, color: Colors.amber),
          ),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: Appfontstring.ChangaLight,
                fontSize: 10.sp,
                color: Colors.white70,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Refactored Widgets
// -----------------------------------------------------------------------------

class TotalLoadCard extends StatelessWidget {
  final double totalLoad;
  final bool isLoading;
  final bool isWide;

  const TotalLoadCard({
    super.key,
    required this.totalLoad,
    required this.isLoading,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    final Color tacticalCyan = const Color(0xFF00E5FF);
    final Color alertRed = const Color(0xFFFF1744);

    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        margin: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: tacticalCyan.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            // Corner Accents (Always Cyan)
            Positioned(
                top: 4,
                left: 4,
                child: _HUDCorner(tacticalCyan, isTop: true, isLeft: true)),
            Positioned(
                top: 4,
                right: 4,
                child: _HUDCorner(tacticalCyan, isTop: true, isLeft: false)),
            Positioned(
                bottom: 4,
                left: 4,
                child: _HUDCorner(tacticalCyan, isTop: false, isLeft: true)),
            Positioned(
                bottom: 4,
                right: 4,
                child: _HUDCorner(tacticalCyan, isTop: false, isLeft: false)),

            Padding(
              padding: EdgeInsets.all(8.w),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _HUDLabel('SYSTEM_Load_MONITOR', tacticalCyan),
                      _HUDLabel('CORE_TEMP: OPTIMAL', Colors.greenAccent),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        isLoading ? 'SCANNING' : totalLoad.toStringAsFixed(0),
                        style: TextStyle(
                          color: (totalLoad < 0) ? alertRed : Colors.white,
                          fontSize: 48.sp,
                          fontFamily: Appfontstring.BebasNeue_Regular,
                          letterSpacing: 2,
                          shadows: [
                            Shadow(
                                color: (totalLoad < 0 ? alertRed : tacticalCyan)
                                    .withOpacity(0.8),
                                blurRadius: 10),
                          ],
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'MW',
                        style: TextStyle(
                          color: tacticalCyan.withOpacity(0.5),
                          fontSize: 16.sp,
                          fontFamily: Appfontstring.BebasNeue_Regular,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Divider(color: tacticalCyan.withOpacity(0.1), thickness: 0.5),
                  SizedBox(height: 4.h),
                  Text(
                    'CAIRO GRID REAL-TIME DATA',
                    style: TextStyle(
                      color: const Color.fromARGB(119, 255, 255, 255),
                      fontSize: 8.sp,
                      letterSpacing: 2,
                      fontFamily: Appfontstring.ChangaLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _HUDLabel(String text, Color color) {
    return Row(
      children: [
        Container(width: 3, height: 3, color: color),
        SizedBox(width: 4.w),
        Text(
          text,
          style: TextStyle(
            color: color.withOpacity(0.6),
            fontSize: 7.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _HUDCorner(Color color, {required bool isTop, required bool isLeft}) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? BorderSide(color: color, width: 2) : BorderSide.none,
          bottom: !isTop ? BorderSide(color: color, width: 2) : BorderSide.none,
          left: isLeft ? BorderSide(color: color, width: 2) : BorderSide.none,
          right: !isLeft ? BorderSide(color: color, width: 2) : BorderSide.none,
        ),
      ),
    );
  }
}

class StationGaugeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final int min;
  final int max;
  final bool isWide;
  final VoidCallback? onFlip;
  final bool isToggleable;

  const StationGaugeCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    required this.isWide,
    this.onFlip,
    this.isToggleable = true,
  });

  @override
  Widget build(BuildContext context) {
    final double numValue =
        double.tryParse(value.replaceAll('+', ''))?.abs() ?? 0.0;
    final double progress = (numValue / max).clamp(0.0, 1.0);
    final bool isNegative = value.startsWith('-');
    final Color tacticalCyan = const Color(0xFF00E5FF);
    final Color alertRed = const Color(0xFFFF1744);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: IntrinsicHeight(
          child: Column(
            children: [
              // Top Bar (Always Cyan)
              Container(
                height: 3,
                width: double.infinity,
                color: tacticalCyan.withOpacity(0.3),
              ),
              Expanded(
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                                fontFamily: Appfontstring.ChangaBold,
                                color: Colors.white70,
                                letterSpacing: 1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (onFlip != null && isToggleable)
                            GestureDetector(
                              onTap: onFlip,
                              child: Icon(Icons.swap_horiz,
                                  size: 18.sp, color: Colors.yellowAccent),
                            ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            value,
                            style: TextStyle(
                              color: isNegative ? alertRed : Colors.white,
                              fontFamily: Appfontstring.BebasNeue_Regular,
                              fontSize: 24.sp,
                              letterSpacing: 1,
                              shadows: isNegative
                                  ? [
                                      Shadow(
                                          color: alertRed.withOpacity(0.5),
                                          blurRadius: 5)
                                    ]
                                  : null,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'MW',
                            style: TextStyle(
                              color: tacticalCyan.withOpacity(0.4),
                              fontSize: 10.sp,
                              fontFamily: Appfontstring.BebasNeue_Regular,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      // HUD Style Multi-Bar Progress
                      _buildHUDProgressBar(progress, tacticalCyan),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHUDProgressBar(double progress, Color color) {
    return Row(
      children: List.generate(15, (index) {
        final isActive = (index / 15) < progress;
        return Expanded(
          child: Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: isActive ? color : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        );
      }),
    );
  }
}

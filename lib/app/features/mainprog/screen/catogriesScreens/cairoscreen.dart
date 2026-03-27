import 'dart:async';
import 'dart:ui';
import 'package:amiraly/app/common/widgets/appbar.dart';
import 'package:amiraly/app/util/constant/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:amiraly/app/features/mainprog/screen/navscreens/station_load_controller.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import '../../../../common/widgets/cairo_widgets.dart';

class Cairoscreen extends StatefulWidget {
  const Cairoscreen({super.key});

  @override
  State<Cairoscreen> createState() => _CairoscreenState();
}

class _CairoscreenState extends State<Cairoscreen> {
  double get screenWidth => MediaQuery.of(context).size.width;
  double get screenHeight => MediaQuery.of(context).size.height;
  final StationLoadController _controller = Get.find<StationLoadController>();
  final GlobalKey<LiquidPullToRefreshState> refreshIndicatorKey =
      GlobalKey<LiquidPullToRefreshState>();

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

      // Force Western digits (123) for digital font compatibility
      String sign = signedLoad >= 0 ? '+' : '';
      String value = signedLoad.toStringAsFixed(0);
      return '$sign$value';
    } catch (_) {
      return '0';
    }
  }

  void _flipDirection(String stationName) async {
    await _controller.toggleDirection(stationName);
    setState(() {});
  }

  void _handleStationEdit(
      BuildContext context, String stationKey, bool canEdit) {
    if (!canEdit) {
      return;
    }

    final station = _controller.stationLoads
        .firstWhereOrNull((s) => s.stationName == stationKey);
    if (station != null) {
      showDialog(
        context: context,
        builder: (context) => StationDialog(station: station),
      );
    }
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
                Color(0xFF163C5E),
                Color(0xFF0F2B44),
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
                            SizedBox(height: 10.h),
                            TotalLoadCard(
                              totalLoad: totalLoad,
                              isLoading: _controller.isLoading.value,
                              isWide: isWide,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 4.h),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                    color: Colors.greenAccent,
                                    shape: BoxShape.circle)),
                            SizedBox(width: 8.w),
                            Text(
                              'البث المباشر للأحمال مفعل',
                              style: TextStyle(
                                color: Colors.white30,
                                fontSize: 9.sp,
                                fontFamily: Appfontstring.ChangaLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      sliver: _buildSliverSectionHeader(
                          'التبادلات البينية', Icons.swap_horiz),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      sliver: _buildStationsGrid(isWide),
                    ),
                    SliverToBoxAdapter(child: SizedBox(height: 8.h)),
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      sliver: _buildSliverSectionHeader(
                          'محطات التوليد', Icons.bolt),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      sliver: SliverToBoxAdapter(
                        child: SizedBox(
                          height: 92.h, // Reverted to tighter height
                          child: StationGaugeCard(
                            title: 'الكريمات الشمسية',
                            subtitle: 'توليد الطاقة المتجددة',
                            value: _getStationLoad('الكريمات الشمسية'),
                            min: 0,
                            max: 120,
                            isWide: isWide,
                            isToggleable: false,
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(child: SizedBox(height: 10.h)),
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      sliver: SliverToBoxAdapter(
                          child: _buildNotesExpansion(isWide)),
                    ),
                    SliverToBoxAdapter(child: SizedBox(height: 20.h)),
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
                  Text(
                      _controller.errorMessage.value.isEmpty
                          ? 'حدث خطأ غير متوقع'
                          : _controller.errorMessage.value,
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
        padding: EdgeInsetsDirectional.only(bottom: 8.h, start: 8.w, top: 12.h),
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
                fontFamily: Appfontstring.ChangaLight,
                fontSize: 11.sp,
                color: Colors.white70,
                letterSpacing: 2,
              ),
            ),
            const Spacer(),
            Text(
              'SEC_ID: 0x${title.hashCode.toRadixString(16).toUpperCase().substring(0, 4)}',
              style: TextStyle(
                fontFamily: Appfontstring.digital,
                fontFamilyFallback: const [Appfontstring.ChangaLight],
                fontSize: 7.sp,
                color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
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
        mainAxisSpacing: 3.h,
        crossAxisSpacing: 8.w,
        childAspectRatio: isWide ? 2.8 : 3.4,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final station = stations[index];
          final stationKey = station['key'] as String;
          final canEdit = _controller.canEditStation(stationKey);
          return StationGaugeCard(
            title: station['title'] as String,
            subtitle: station['subtitle'] as String,
            value: _getStationLoad(stationKey),
            min: station['min'] as int,
            max: station['max'] as int,
            isWide: isWide,
            onFlip: canEdit ? () => _flipDirection(stationKey) : null,
            onEdit: canEdit
                ? () => _handleStationEdit(context, stationKey, canEdit)
                : null,
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
            color: Colors.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
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
                  fontFamily: Appfontstring.ChangaLight,
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

import 'dart:async';
import 'dart:math';

import 'package:amiraly/E-commerce_project/common/models/appmodels.dart';
import 'package:amiraly/E-commerce_project/common/services/mainprogservices.dart';
import 'package:amiraly/E-commerce_project/common/widgets/appbar.dart';
import 'package:amiraly/E-commerce_project/util/constant/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';

class LoadDisplayWidgetCairo extends StatefulWidget {
  final double totalLoad;
  final bool isLoading;

  const LoadDisplayWidgetCairo({
    super.key,
    required this.totalLoad,
    required this.isLoading,
  });

  @override
  State<LoadDisplayWidgetCairo> createState() => _LoadDisplayWidgetCairoState();
}

class _LoadDisplayWidgetCairoState extends State<LoadDisplayWidgetCairo> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        return Container(
            width: isWide
                ? constraints.maxWidth * 0.66
                : ScreenUtil().screenWidth * 0.8,
            height: ScreenUtil().screenHeight * 0.18,
            margin: EdgeInsets.symmetric(horizontal: 44.w, vertical: 6.h),
            padding: EdgeInsets.all(12.h),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(25.r),
            ),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'الحمل الكــلى  (M.W) ',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: isWide ? 16.sp : 14.sp,
                        fontFamily: Appfontstring.ChangaBold,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 2.h),
                  Align(
                    child: Text(
                      widget.isLoading
                          ? '...'
                          : widget.totalLoad.toStringAsFixed(0),
                      style: TextStyle(
                          color: Colors.red,
                          fontSize: 53.sp,
                          fontFamily: Appfontstring.BebasNeue_Regular,
                          fontWeight: FontWeight.w700,
                          shadows: [
                            Shadow(
                                color: Colors.red.withOpacity(0.5),
                                blurRadius: 15,
                                offset: const Offset(0, 3))
                          ]),
                    ),
                  ),
                  Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.trending_up,
                            color: Colors.white, size: isWide ? 16.sp : 14.sp),
                        SizedBox(width: 5.w),
                        Text('تحديث تلقائي كل 5 ثوان',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: isWide ? 10.sp : 8.sp))
                      ]))
                ]));
      },
    );
  }
}

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
  Timer? timer;
  static const _updateInterval = Duration(seconds: 5);
  final Map<String, bool> _direction = {
    'عبور3/عاشر': true,
    'قليوب/قناطر': true,
    'ابو زعبل ق / بلبيس': true,
    'برقاش/ابوغالب': true,
    'الكريمات/بنى سويف': true,
  };

  @override
  void initState() {
    super.initState();
    fetchData();
    timer = Timer.periodic(_updateInterval, (_) => updateLoads());
  }

  Future<void> fetchData() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final loads = await supabaseService.fetchStationLoads();
      if (mounted) {
        setState(() {
          stationLoads = loads;
          isLoading = false;
          errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'خطأ في جلب البيانات: $e';
          isLoading = false;
        });
      }
    }
  }

  double _getTotalLoad() {
    return stationLoads.fold(0.0, (sum, station) {
      double absLoad = station.load.abs();
      bool isPositive = _direction[station.stationName] ?? true;
      return sum + (isPositive ? absLoad : -absLoad);
    });
  }

  String _getStationLoad(String stationName) {
    try {
      final station =
          stationLoads.firstWhere((s) => s.stationName == stationName);
      double absLoad = station.load.abs();
      bool isPositive = _direction[stationName] ?? true;
      double signedLoad = isPositive ? absLoad : -absLoad;
      return '${signedLoad >= 0 ? '+' : ''}${signedLoad.toStringAsFixed(0)}';
    } catch (_) {
      return '0';
    }
  }

  void _flipDirection(String stationName) {
    setState(() {
      _direction[stationName] = !(_direction[stationName] ?? true);
    });
  }

  void updateLoads() async {
    if (!mounted) return;
    final random = Random();
    setState(() {
      for (var station in stationLoads) {
        final variationRange = station.maxVariation - station.minVariation;
        final randomVariation =
            station.minVariation + random.nextDouble() * variationRange;
        double absLoad =
            (station.baseLoad + randomVariation).clamp(0.0, double.infinity);
        bool isPositive = _direction[station.stationName] ?? true;
        station.load = isPositive ? absLoad : -absLoad;
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalLoad = _getTotalLoad();
    final isWide = screenWidth > 600;
    return LiquidPullToRefresh(
      key: refreshIndicatorKey,
      onRefresh: fetchData,
      height: 60.h,
      showChildOpacityTransition: false,
      color: Appcolors.primaryColor,
      animSpeedFactor: 2,
      child: PopScope(
        canPop: true,
        child: Scaffold(
          appBar: CustomAppBar(),
          body: Container(
            decoration: const BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                  Appcolors.primaryColor,
                  Color.fromARGB(255, 182, 199, 216),
                  Color(0xFFFFFFFF),
                  Color(0xFFFFFFFF)
                ])),
            child: errorMessage != null
                ? Center(
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
                                    size: isWideError ? 80.sp : 64.sp,
                                    color: Colors.red),
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
                  )
                : CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            LoadDisplayWidgetCairo(
                              totalLoad: totalLoad,
                              isLoading: isLoading,
                            ),
                            _buildSectionHeader(
                                'التبادلات خارج القاهرة', Icons.swap_horiz),
                            ..._buildGaugeRows([
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
                                'max': 100,
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
                                'max': 160,
                              },
                            ], isWide),
                            SizedBox(height: 16.h),
                            _buildSectionHeader('التوليد', Icons.bolt),
                            _buildGaugeRow(
                              title: 'الكريمات الشمسية',
                              subtitle: '',
                              value: _getStationLoad('الكريمات الشمسية'),
                              min: 0,
                              max: 120,
                              isToggleable: false,
                              isWide: isWide,
                            ),
                            SizedBox(height: 16.h),
                            _buildSectionHeader(
                                'احمال محطات جهد 220 (فقط)', Icons.factory),
                            _buildGaugeRow(
                              title: 'مجموع احمال محطات 220',
                              subtitle: "",
                              value: totalLoad.toStringAsFixed(0),
                              min: 0,
                              max: 17000,
                              isToggleable: false,
                              isWide: isWide,
                            ),
                            SizedBox(height: 16.h),
                            _buildNotesExpansion(isWide),
                            SizedBox(height: 16.h),
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

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: Row(
        children: [
          Icon(icon, color: Colors.red, size: 20.sp),
          SizedBox(width: 11.w),
          Text(
            title,
            style: TextStyle(
              fontFamily: Appfontstring.ChangaBold,
              fontSize: 18.sp,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGaugeRows(
      List<Map<String, dynamic>> stations, bool isWide) {
    List<Widget> rows = [];
    if (isWide) {
      for (int i = 0; i < stations.length; i += 2) {
        Widget leftWidget = _buildGaugeRowFromMap(stations[i], isWide);
        Widget rightWidget = (i + 1 < stations.length)
            ? _buildGaugeRowFromMap(stations[i + 1], isWide)
            : const SizedBox.shrink();

        rows.add(Padding(
          padding: EdgeInsets.symmetric(horizontal: 15.w),
          child: Row(
            children: [
              Expanded(
                child: leftWidget,
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: rightWidget,
              ),
            ],
          ),
        ));
        rows.add(SizedBox(height: 12.h));
      }
    } else {
      for (int i = 0; i < stations.length; i++) {
        Widget widget = _buildGaugeRowFromMap(stations[i], isWide);

        rows.add(Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          child: Row(
            children: [
              Expanded(child: widget),
            ],
          ),
        ));

        if (i < stations.length - 1) {
          rows.add(SizedBox(height: 5.h));
        }
      }
    }
    return rows;
  }

  Widget _buildGaugeRowFromMap(Map<String, dynamic> station, bool isWide) {
    return buildGaugeSection(
      context,
      station['title'],
      station['subtitle'],
      _getStationLoad(station['key']),
      station['min'],
      station['max'],
      onFlip: () => _flipDirection(station['key']),
      isWide: isWide,
    );
  }

  Widget _buildGaugeRow({
    required String title,
    required String subtitle,
    required String value,
    required int min,
    required int max,
    bool isToggleable = true,
    required bool isWide,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: buildGaugeSection(
        context,
        title,
        subtitle,
        value,
        min,
        max,
        onFlip: null,
        isWide: isWide,
      ),
    );
  }

  Widget _buildNotesExpansion(bool isWide) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Card(
        color: const Color.fromARGB(255, 239, 231, 160),
        elevation: 4,
        child: ExpansionTile(
          leading: Icon(Icons.info_outline, color: Colors.blue[600]),
          title: Text(
            'ملاحظات هامة',
            style: TextStyle(
              fontFamily: Appfontstring.ChangaBold,
              fontSize: isWide ? 16.sp : 14.sp,
              color: Colors.black87,
            ),
          ),
          children: [
            Padding(
              padding: EdgeInsets.all(isWide ? 12.w : 8.w),
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
    );
  }

  Widget _buildNoteItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.circle, size: 4.sp, color: Colors.grey[600]),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: Appfontstring.ChangaLight,
                fontSize: 10.sp,
                color: Colors.black87,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget buildGaugeSection(
  BuildContext context,
  String capital,
  String alterlabel,
  String data,
  int minValuescale,
  int maxValuescale, {
  VoidCallback? onFlip,
  required bool isWide,
}) {
  final double value = double.tryParse(data.replaceAll('+', ''))?.abs() ?? 0.0;
  final double progress = (value / maxValuescale).clamp(0.0, 1.0);
  Color progressColor = Colors.green;
  if (progress > 0.7) {
    progressColor = Colors.red;
  } else if (progress > 0.6) {
    progressColor = Colors.orange;
  } else if (progress > 0.5) {
    progressColor = Colors.blue;
  } else {
    progressColor = Colors.green;
  }

  return Container(
      height: isWide ? 100.h : 80.h,
      padding: EdgeInsets.all(isWide ? 12.w : 8.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(width: 1, color: Colors.black),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 5.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: isWide ? 3 : 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(capital,
                    style: TextStyle(
                        fontSize: isWide ? 14.sp : 12.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: Appfontstring.ChangaLight,
                        color: Colors.blue),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis),
                SizedBox(height: 2.h),
                Text(alterlabel,
                    style: TextStyle(
                      fontSize: isWide ? 11.sp : 9.sp,
                      fontFamily: Appfontstring.ChangaLight,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Expanded(
            flex: isWide ? 4 : 4,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: isWide ? 10.h : 8.h,
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
          Expanded(
            flex: isWide ? 2 : 2,
            child: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'M.W',
                            style: TextStyle(
                                color: const Color.fromARGB(255, 227, 168, 167),
                                fontFamily: Appfontstring.ChangaLight,
                                fontSize: isWide ? 11.sp : 9.sp,
                                fontWeight: FontWeight.bold),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            data,
                            style: TextStyle(
                                color: Colors.red[600],
                                fontFamily: Appfontstring.BebasNeue_Regular,
                                fontSize: isWide ? 25.sp : 20.sp,
                                fontWeight: FontWeight.bold),
                          ),
                          SizedBox(width: 4.w),
                        ],
                      ),
                    ),
                  ),
                ),
                if (onFlip != null)
                  GestureDetector(
                    onTap: onFlip,
                    child: Padding(
                      padding: EdgeInsets.all(4.w),
                      child: Icon(
                        Icons.switch_right_rounded,
                        size: isWide ? 20.sp : 16.sp,
                        color: Colors.blue[600],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ));
}

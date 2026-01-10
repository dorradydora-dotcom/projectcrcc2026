import 'dart:async';
import 'dart:math';
import 'package:amiraly/E-commerce_project/common/models/appmodels.dart';
import 'package:amiraly/E-commerce_project/features/mainprog/screen/navscreens/stationloadnav.dart';
import 'package:amiraly/E-commerce_project/util/constant/constants.dart';
import 'package:amiraly/main.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoadnavScreen extends StatefulWidget {
  const LoadnavScreen({super.key});

  @override
  State<LoadnavScreen> createState() => _LoadnavScreenState();
}

class _LoadnavScreenState extends State<LoadnavScreen> {
  static const _updateInterval = Duration(seconds: 5);

  final SupabaseService _supabaseService = SupabaseService();
  List<StationLoad> _stationLoads = [];
  bool _isLoading = true;
  String? _errorMessage;
  final GlobalKey<LiquidPullToRefreshState> _refreshIndicatorKey =
      GlobalKey<LiquidPullToRefreshState>();
  final GlobalKey<_HourlyMaxLoadTableState> _hourlyKey =
      GlobalKey<_HourlyMaxLoadTableState>();
  Timer? _timer;
  Map<String, double> previousLoads = {};
  Map<String, bool> isIncreasing = {};
  double _previousTotalLoad = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _timer = Timer.periodic(_updateInterval, (_) => _updateLoads());
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final loads = await _supabaseService.fetchStationLoads();
      setState(() {
        _stationLoads = loads;
        _isLoading = false;
        _errorMessage = null;
        previousLoads.clear();
        for (final station in _stationLoads) {
          previousLoads[station.stationName] = station.load;
        }
        _previousTotalLoad = _getTotalLoad();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'خطأ في جلب بيانات المحطات: $e';
        _isLoading = false;
      });
    }
    // Refresh hourly data independently
    if (_hourlyKey.currentState != null) {
      await _hourlyKey.currentState!._fetchData();
    }
  }

  void _updateLoads() {
    if (!mounted || _stationLoads.isEmpty) return;

    final random = Random();
    bool anyChange = false;
    final Map<String, double> newPreviousLoads =
        Map<String, double>.from(previousLoads);
    final Map<String, bool> newIsIncreasing = <String, bool>{};

    for (final station in _stationLoads) {
      final prevLoad = previousLoads[station.stationName] ?? station.load;
      final variationRange = station.maxVariation - station.minVariation;
      final randomVariation =
          station.minVariation + random.nextDouble() * variationRange;
      final newLoad =
          (station.baseLoad + randomVariation).clamp(0.0, double.infinity);
      if (newLoad != prevLoad) {
        anyChange = true;
      }
      newIsIncreasing[station.stationName] = newLoad > prevLoad;
      station.load = newLoad;
      newPreviousLoads[station.stationName] = newLoad;
    }

    final newTotalLoad = _getTotalLoad();
    final totalChanged = newTotalLoad != _previousTotalLoad;

    if (anyChange || totalChanged) {
      setState(() {
        previousLoads = newPreviousLoads;
        isIncreasing = newIsIncreasing;
        _previousTotalLoad = newTotalLoad;
      });
    }
  }

  double _getTotalLoad() =>
      _stationLoads.fold(0.0, (sum, station) => sum + station.load);

  Color _getHeaderColor() =>
      const Color.fromARGB(255, 119, 235, 166).withOpacity(0.15);

  Widget _buildHeaderCell(String text, double width) {
    return SizedBox(
        width: width,
        child: Container(
            height: 36.h,
            decoration: BoxDecoration(
                color: _getHeaderColor(),
                border: Border.all(
                    color: Colors.black.withOpacity(0.2), width: 0.5),
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8), topRight: Radius.circular(8))),
            alignment: Alignment.center,
            child: Text(text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: Appfontstring.ChangaLight,
                    color: Color(0xFF0D47A1)),
                textDirection: TextDirection.rtl)));
  }

  Widget _buildLoadCell(StationLoad station, Color bgColor) {
    final bool hasChange = isIncreasing.containsKey(station.stationName);
    final Color loadColor = hasChange
        ? (isIncreasing[station.stationName]! ? Colors.green : Colors.red)
        : const Color(0xFF0D47A1);

    return SizedBox(
      width: 70.w,
      child: Container(
        height: 32.h,
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: Colors.black.withOpacity(0.2), width: 0.5),
        ),
        alignment: Alignment.center,
        child: Text(
          station.load.toStringAsFixed(0),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            fontFamily: Appfontstring.ChangaLight,
            color: loadColor,
          ),
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }

  Widget _buildNameCell(String stationName, Color bgColor) {
    return SizedBox(
      width: 100.w,
      child: Container(
        height: 32.h,
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: Colors.black.withOpacity(0.2), width: 0.5),
        ),
        alignment: Alignment.center,
        child: Text(
          stationName,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            fontFamily: Appfontstring.ChangaLight,
            color: Color(0xFF0D47A1),
          ),
          textDirection: TextDirection.rtl,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildEmptyCell(double width, Color bgColor) {
    return SizedBox(
      width: width,
      child: Container(
        height: 32.h,
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: Colors.black.withOpacity(0.2), width: 0.5),
        ),
      ),
    );
  }

  Widget _buildStationTable() {
    if (_stationLoads.isEmpty) {
      return const SizedBox.shrink();
    }

    final headerRow = Row(
      children: [
        _buildHeaderCell('الحمل\n(م.و)', 70.w),
        _buildHeaderCell('المحطة', 100.w),
        const SizedBox(width: 3),
        _buildHeaderCell('الحمل\n(م.و)', 70.w),
        _buildHeaderCell('المحطة', 100.w),
      ],
    );

    List<Widget> dataRows = [];
    for (int i = 0; i < _stationLoads.length; i += 2) {
      final pairIndex = i ~/ 2;
      final rowColor = pairIndex % 2 == 0
          ? Colors.white
          : const Color(0xFFE3F2FD).withOpacity(0.1);

      List<Widget> pairChildren = [
        _buildLoadCell(_stationLoads[i], rowColor),
        _buildNameCell(_stationLoads[i].stationName, rowColor),
      ];

      if (i + 1 < _stationLoads.length) {
        pairChildren.add(const SizedBox(width: 3));
        pairChildren.add(_buildLoadCell(_stationLoads[i + 1], rowColor));
        pairChildren
            .add(_buildNameCell(_stationLoads[i + 1].stationName, rowColor));
      } else {
        pairChildren.add(const SizedBox(width: 3));
        pairChildren.add(_buildEmptyCell(70.w, rowColor));
        pairChildren.add(_buildEmptyCell(100.w, rowColor));
      }

      dataRows.add(
        Row(
          children: pairChildren,
        ),
      );
    }

    return Column(
      children: [
        SizedBox(height: 20.h),
        const Center(
          child: Text('احمال محطات الربط و التبادلات',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: Appfontstring.ChangaLight,
                color: Colors.blueAccent,
              ),
              textDirection: TextDirection.rtl),
        ),
        SizedBox(height: 20.h),
        headerRow,
        ...dataRows,
      ],
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LiquidPullToRefresh(
      key: _refreshIndicatorKey,
      color: const Color(0xFF1E88E5),
      backgroundColor: Colors.white,
      height: 60.h,
      showChildOpacityTransition: false,
      onRefresh: _fetchData,
      child: WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          body: Container(
            decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [
              Appcolors.primaryColor,
              Colors.white,
              Colors.white
            ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  LoadDisplayWidget(
                      totalLoad: _getTotalLoad(), isLoading: _isLoading),
                  SizedBox(height: 16.h),
                  HourlyMaxLoadTable(
                    key: _hourlyKey,
                    tableName: AppConstants.tableHourlyMaxLoads,
                  ),
                  SizedBox(height: 16.h),
                  if (_errorMessage != null)
                    Container(
                        margin: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 12.h),
                        padding: EdgeInsets.all(16.h),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.r),
                          border:
                              Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Column(children: [
                          Text(
                            _errorMessage!,
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: Appfontstring.ChangaLight,
                              color: Colors.redAccent,
                            ),
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                          ),
                          SizedBox(height: 12.h),
                          ElevatedButton(
                              onPressed: _fetchData,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E88E5),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24.w,
                                  vertical: 12.h,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                              ),
                              child: const Text('إعادة المحاولة',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: Appfontstring.ChangaLight,
                                  )))
                        ]))
                  else
                    Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 12,
                                offset: const Offset(0, 4))
                          ]),
                      child: _isLoading
                          ? SizedBox(
                              height: 200.h,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF1E88E5),
                                ),
                              ),
                            )
                          : RepaintBoundary(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: _buildStationTable(),
                              ),
                            ),
                    ),
                  SizedBox(height: 60.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HourlyMaxLoadTable extends StatefulWidget {
  final String? tableName;
  final Key? key;

  const HourlyMaxLoadTable({
    this.key,
    this.tableName,
  }) : super(key: key);

  @override
  State<HourlyMaxLoadTable> createState() => _HourlyMaxLoadTableState();
}

class _HourlyMaxLoadTableState extends State<HourlyMaxLoadTable> {
  late final SupabaseClient _supabase;
  List<Map<String, dynamic>> _hourlyMaxLoadsToday = [];
  List<Map<String, dynamic>> _hourlyMaxLoadsYesterday = [];
  bool _isLoading = false;
  String? _error;
  double? _maxLoadValue;
  final bool _sortAscending = true;
  DateTime? _lastFetchTime;

  @override
  void initState() {
    super.initState();
    _supabase = Supabase.instance.client;
    _fetchData();
  }

  Future<void> _fetchData() async {
    final now = DateTime.now();
    if (_lastFetchTime != null &&
        now.difference(_lastFetchTime!).inMinutes < 1) {
      return;
    }
    _lastFetchTime = now;

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final table = widget.tableName ?? 'hourly_max_loads';
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final todayFormatted = today.toIso8601String().split('T')[0];
      final yesterdayFormatted = yesterday.toIso8601String().split('T')[0];

      final todayResponse = await _supabase
          .from(table)
          .select('hour, max_load')
          .eq('date', todayFormatted)
          .order('hour', ascending: _sortAscending)
          .timeout(const Duration(seconds: 10));

      final yesterdayResponse = await _supabase
          .from(table)
          .select('hour, max_load')
          .eq('date', yesterdayFormatted)
          .order('hour', ascending: _sortAscending)
          .timeout(const Duration(seconds: 10));

      if (mounted) {
        setState(() {
          _hourlyMaxLoadsToday = List<Map<String, dynamic>>.from(todayResponse);
          _hourlyMaxLoadsYesterday = List<Map<String, dynamic>>.from(
            yesterdayResponse,
          );
          _maxLoadValue =
              [..._hourlyMaxLoadsToday, ..._hourlyMaxLoadsYesterday].isNotEmpty
                  ? [..._hourlyMaxLoadsToday, ..._hourlyMaxLoadsYesterday]
                      .map((e) => (e['max_load'] as num?)?.toDouble() ?? 0.0)
                      .reduce((a, b) => a > b ? a : b)
                  : 0.0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _getErrorMessage(e);
          _isLoading = false;
        });
      }
    }
  }

  String _getErrorMessage(dynamic e) {
    if (e is TimeoutException) {
      return 'Request timed out. Please check your connection.';
    }
    return 'Error fetching data';
  }

  String _formatNumber(dynamic value) {
    if (value == null) return '0';
    final doubleNumber = (value as num?)?.toDouble() ?? 0.0;
    return doubleNumber == doubleNumber.roundToDouble()
        ? doubleNumber.toInt().toString()
        : doubleNumber.toStringAsFixed(1);
  }

  Widget _buildHourlyHeaderCell(
      String text, double width, Color primaryColor, double height) {
    return SizedBox(
      width: width,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.25),
          border: Border.all(color: Colors.black.withOpacity(0.2), width: 0.5),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            fontFamily: Appfontstring.ChangaLight,
            color: primaryColor,
          ),
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }

  Widget _buildHourlyLoadCell(String text, double width, Color primaryColor,
      bool isPeak, Color rowColor, double height) {
    final fontSize = height == 40.h ? 13.sp : 11.sp;
    return SizedBox(
      width: width,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: rowColor,
          border: Border.all(color: Colors.black.withOpacity(0.2), width: 0.5),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isPeak)
              const Icon(
                Icons.electric_bolt_sharp,
                size: 14,
                color: Colors.red,
              ),
            if (isPeak) SizedBox(width: 4.w),
            Flexible(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: isPeak ? FontWeight.w800 : FontWeight.w600,
                  fontFamily: Appfontstring.ChangaLight,
                  color: isPeak ? Colors.red : primaryColor,
                ),
                textDirection: TextDirection.rtl,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHourlyTimeCell(String text, double width, Color rowColor,
      Color primaryColor, double height) {
    final fontSize = height == 40.h ? 13.sp : 11.sp;
    return SizedBox(
      width: width,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: rowColor,
          border: Border.all(color: Colors.black.withOpacity(0.2), width: 0.5),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            fontFamily: Appfontstring.ChangaLight,
            color: primaryColor,
          ),
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.blue[900]!;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        image: DecorationImage(
            image: AssetImage(AppimageString.rtop),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
                const Color.fromARGB(39, 0, 0, 0).withOpacity(0.9),
                BlendMode.xor)),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isLargeScreen = constraints.maxWidth > 600.w;
          final isLandscape =
              MediaQuery.of(context).orientation == Orientation.landscape;

          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isLargeScreen ? 20.w : 16.w,
              vertical: isLargeScreen ? 16.h : 12.h,
            ),
            child: isLargeScreen && isLandscape
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: _buildTableSection(context, primaryColor),
                      ),
                      SizedBox(width: 7.w),
                      Expanded(
                        flex: 2,
                        child: _buildChartSection(context, primaryColor),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildTableSection(context, primaryColor),
                      SizedBox(height: isLargeScreen ? 28.h : 20.h),
                      _buildChartSection(context, primaryColor),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildTableSection(BuildContext context, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildTableHeader(context),
        SizedBox(height: 12.h),
        RepaintBoundary(
          child: _buildDataTable(context, primaryColor: primaryColor),
        ),
      ],
    );
  }

  Widget _buildTableHeader(BuildContext context) {
    return const Center(
      child: Text(
        'أقصى حمل لكل ساعة (اليوم)',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          fontFamily: Appfontstring.ChangaLight,
          color: Colors.black87,
        ),
        textDirection: TextDirection.rtl,
      ),
    );
  }

  Widget _buildDataTable(BuildContext context, {required Color primaryColor}) {
    final isLargeScreen = ScreenUtil().screenWidth > 600.w;

    final loadWidth = isLargeScreen ? 90.w : 80.w;
    final timeWidth = isLargeScreen ? 80.w : 70.w;
    final gap = const SizedBox(width: 12);
    final headingHeight = isLargeScreen ? 40.h : 36.h;
    final dataHeight = isLargeScreen ? 40.h : 36.h;

    if (_isLoading) {
      return SizedBox(
        height: isLargeScreen ? 320.h : 280.h,
        child: Center(
          child: CircularProgressIndicator(
            color: primaryColor,
            strokeWidth: 2.w,
          ),
        ),
      );
    }

    if (_error != null) {
      return SizedBox(
        height: isLargeScreen ? 320.h : 280.h,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error!,
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: isLargeScreen ? 16.sp : 14.sp,
                  fontFamily: Appfontstring.ChangaLight,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),
              ElevatedButton(
                onPressed: _fetchData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: EdgeInsets.symmetric(
                    horizontal: isLargeScreen ? 24.w : 20.w,
                    vertical: isLargeScreen ? 12.h : 10.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                child: Text(
                  'إعادة المحاولة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isLargeScreen ? 14.sp : 12.sp,
                    fontFamily: Appfontstring.ChangaLight,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_hourlyMaxLoadsToday.isEmpty) {
      return SizedBox(
        height: isLargeScreen ? 320.h : 280.h,
        child: Center(
          child: Text(
            'لا توجد بيانات متاحة',
            style: TextStyle(
              fontSize: isLargeScreen ? 16.sp : 14.sp,
              fontFamily: Appfontstring.ChangaLight,
              color: primaryColor,
            ),
            textDirection: TextDirection.rtl,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: primaryColor.withOpacity(0.3), width: 1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          children: [
            // Header
            Row(
              children: [
                _buildHourlyHeaderCell(
                    'أقصى حمل\n(م.و)', loadWidth, primaryColor, headingHeight),
                _buildHourlyHeaderCell(
                    'الساعة', timeWidth, primaryColor, headingHeight),
                gap,
                _buildHourlyHeaderCell(
                    'أقصى حمل\n(م.و)', loadWidth, primaryColor, headingHeight),
                _buildHourlyHeaderCell(
                    'الساعة', timeWidth, primaryColor, headingHeight),
              ],
            ),
            // Data rows
            ...List.generate(12, (pairIndex) {
              final i = pairIndex * 2;
              final hour1 = i;
              final hourData1 = _hourlyMaxLoadsToday.firstWhere(
                (data) => data['hour'] == hour1,
                orElse: () => {'hour': hour1, 'max_load': 0.0},
              );
              final isPeak1 = _maxLoadValue != null &&
                  hourData1['max_load'] != null &&
                  (hourData1['max_load'] as num).toDouble() >=
                      _maxLoadValue! * 0.95;

              final hour2 = i + 1;
              final hourData2 = _hourlyMaxLoadsToday.firstWhere(
                (data) => data['hour'] == hour2,
                orElse: () => {'hour': hour2, 'max_load': 0.0},
              );
              final isPeak2 = _maxLoadValue != null &&
                  hourData2['max_load'] != null &&
                  (hourData2['max_load'] as num).toDouble() >=
                      _maxLoadValue! * 0.95;

              final baseRowColor = pairIndex % 2 == 0
                  ? Colors.transparent
                  : primaryColor.withOpacity(0.08);
              final hasPeak = isPeak1 || isPeak2;
              final rowColor =
                  hasPeak ? primaryColor.withOpacity(0.2) : baseRowColor;

              return Row(
                children: [
                  _buildHourlyLoadCell(
                    _formatNumber(hourData1['max_load']),
                    loadWidth,
                    primaryColor,
                    isPeak1,
                    rowColor,
                    dataHeight,
                  ),
                  _buildHourlyTimeCell(
                    _formatHour(hour1),
                    timeWidth,
                    rowColor,
                    primaryColor,
                    dataHeight,
                  ),
                  gap,
                  _buildHourlyLoadCell(
                    _formatNumber(hourData2['max_load']),
                    loadWidth,
                    primaryColor,
                    isPeak2,
                    rowColor,
                    dataHeight,
                  ),
                  _buildHourlyTimeCell(
                    _formatHour(hour2),
                    timeWidth,
                    rowColor,
                    primaryColor,
                    dataHeight,
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatHour(int hour) {
    return '${hour.toString().padLeft(2, '0')}:00';
  }

  Widget _buildChartSection(BuildContext context, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RepaintBoundary(
          child: _buildLineChart(context, primaryColor),
        ),
      ],
    );
  }

  Widget _buildLineChart(BuildContext context, Color primaryColor) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isLargeScreen = ScreenUtil().screenWidth > 600.w;
    final todayColor = primaryColor;
    final yesterdayColor = Colors.greenAccent;

    final todaySpots = List.generate(24, (index) {
      final hourData = _hourlyMaxLoadsToday.firstWhere(
        (data) => data['hour'] == index,
        orElse: () => {'hour': index, 'max_load': 0.0},
      );
      return FlSpot(
        index.toDouble(),
        (hourData['max_load'] as num?)?.toDouble() ?? 0.0,
      );
    });

    final yesterdaySpots = List.generate(24, (index) {
      final hourData = _hourlyMaxLoadsYesterday.firstWhere(
        (data) => data['hour'] == index,
        orElse: () => {'hour': index, 'max_load': 0.0},
      );
      return FlSpot(
        index.toDouble(),
        (hourData['max_load'] as num?)?.toDouble() ?? 0.0,
      );
    });

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isLargeScreen ? 8.w : 4.w,
        vertical: isLargeScreen ? 12.h : 8.h,
      ),
      padding: EdgeInsets.all(isLargeScreen ? 20.w : 16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [Colors.grey[900]!, Colors.grey[800]!]
              : [Colors.white, Colors.blueGrey[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Center(
            child: Text('الحمل الأقصى لكل ساعة (اليوم مقابل الأمس)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: Appfontstring.ChangaLight,
                  color: Colors.blue,
                ),
                textDirection: TextDirection.rtl),
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('اليوم', todayColor),
              SizedBox(width: isLargeScreen ? 28.w : 20.w),
              _buildLegendItem('الأمس', yesterdayColor),
            ],
          ),
          SizedBox(height: 16.h),
          SizedBox(
            height: isLargeScreen ? 300.h : 260.h,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval:
                      _maxLoadValue != null ? _maxLoadValue! / 5 : 1.0,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                    strokeWidth: 1,
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: isLargeScreen ? 52.w : 44.w,
                      interval:
                          _maxLoadValue != null ? _maxLoadValue! / 5 : 1.0,
                      getTitlesWidget: (value, meta) => Text(
                        _formatNumber(value),
                        style: TextStyle(
                          fontSize: isLargeScreen ? 12.sp : 11.sp,
                          fontFamily: Appfontstring.ChangaLight,
                          color: isDarkMode ? Colors.white70 : Colors.black87,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: isLargeScreen ? 36.h : 32.h,
                      interval: isLargeScreen ? 3 : 4,
                      getTitlesWidget: (value, meta) {
                        final hour = value.toInt();
                        return Text(
                          _formatHour(hour),
                          style: TextStyle(
                            fontSize: isLargeScreen ? 12.sp : 11.sp,
                            fontFamily: Appfontstring.ChangaLight,
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                          textDirection: TextDirection.rtl,
                        );
                      },
                    ),
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
                  border: Border.all(
                    color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                    width: 1.5,
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: yesterdaySpots,
                    isCurved: true,
                    color: yesterdayColor,
                    barWidth: isLargeScreen ? 3 : 2,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: yesterdayColor.withOpacity(0.2),
                    ),
                  ),
                  LineChartBarData(
                    spots: todaySpots,
                    isCurved: true,
                    color: todayColor,
                    barWidth: isLargeScreen ? 3 : 2,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: todayColor.withOpacity(0.2),
                    ),
                  ),
                ],
                minX: 0,
                maxX: 23,
                minY: 0,
                maxY: _maxLoadValue != null ? _maxLoadValue! * 1.1 : 100.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    final isLargeScreen = ScreenUtil().screenWidth > 600.w;
    return Row(
      children: [
        Container(
          width: isLargeScreen ? 18.w : 14.w,
          height: isLargeScreen ? 18.h : 14.h,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 8.w),
        Text(
          label,
          style: TextStyle(
            fontSize: isLargeScreen ? 15.sp : 13.sp,
            fontFamily: Appfontstring.ChangaLight,
            color: color,
            fontWeight: FontWeight.w600,
          ),
          textDirection: TextDirection.rtl,
        ),
      ],
    );
  }
}

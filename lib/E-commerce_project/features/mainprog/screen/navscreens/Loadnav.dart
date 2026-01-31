import 'dart:async';
import 'dart:math';
import 'package:amiraly/E-commerce_project/common/models/appmodels.dart';
import 'package:amiraly/E-commerce_project/services/cache_service.dart';
import 'package:amiraly/E-commerce_project/util/constant/constants.dart';
import 'package:amiraly/main.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoadnavScreen extends StatefulWidget {
  const LoadnavScreen({super.key});

  @override
  State<LoadnavScreen> createState() => _LoadnavScreenState();
}

class _LoadnavScreenState extends State<LoadnavScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final CacheService _cacheService = CacheService();

  List<StationLoad> _stationLoads = [];
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _timer;
  Timer? _simulationTimer;

  @override
  void initState() {
    super.initState();
    _loadData(); // Will fetch fresh first
    // Auto-refresh from API
    _timer = Timer.periodic(
        const Duration(seconds: 60), (_) => _fetchFromApi(showLoading: false));
    // Simulation timer
    _simulationTimer = Timer.periodic(
        const Duration(seconds: 6), (_) => _simulateLoadChanges());
  }

  Future<void> _loadData() async {
    // Directly fetch fresh data. Cache will be used as fallback inside _fetchFromApi on failure.
    await _fetchFromApi(showLoading: true);
  }

  Future<void> _fetchFromApi({bool showLoading = true}) async {
    // Only show loading if we have NO data
    if (showLoading && mounted && _stationLoads.isEmpty) {
      // Corrected !mounted to mounted
      setState(() => _isLoading = true);
    }
    try {
      final loads = await _supabaseService.fetchStationLoads();
      if (mounted) {
        setState(() {
          _stationLoads = loads;
          _isLoading = false;
          _errorMessage = null;
        });
        _cacheService.saveStationLoads(loads);
      }
    } catch (e) {
      // Cache fallback removed. Only show fresh data.

      if (mounted && showLoading) {
        setState(() {
          if (_stationLoads.isEmpty) {
            _errorMessage = 'خطأ في جلب بيانات المحطات: $e';
          }
          _isLoading = false;
        });
      }
    }
  }

  void _simulateLoadChanges() {
    if (_stationLoads.isEmpty) return;

    final random = Random();
    setState(() {
      for (var station in _stationLoads) {
        final variationRange = station.maxVariation - station.minVariation;
        final randomVariation =
            station.minVariation + random.nextDouble() * variationRange;
        station.load =
            (station.baseLoad + randomVariation).clamp(0.0, double.infinity);
      }
    });
  }

  double _getTotalLoad() =>
      _stationLoads.fold(0.0, (sum, station) => sum + station.load);

  @override
  void dispose() {
    _timer?.cancel();
    _simulationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalLoad = _getTotalLoad();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
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
              await _fetchFromApi();
            },
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Total Load Display (Replaced with LoadDisplayWidget)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40.h), // reduced top padding
                    child: LoadDisplayWidget(
                      totalLoad: totalLoad,
                      isLoading: _isLoading && _stationLoads.isEmpty,
                      isFromCache: false,
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                    child: SizedBox(height: 12.h)), // reduced spacing

                // Hourly Chart
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    child: HourlyMaxLoadTable(
                      tableName: AppConstants.tableHourlyMaxLoads,
                    ),
                  ),
                ),

                SliverToBoxAdapter(child: SizedBox(height: 12.h)),

                // Station Cards Grid
                if (_errorMessage != null && _stationLoads.isEmpty)
                  SliverToBoxAdapter(child: _buildErrorWidget())
                else if (_isLoading && _stationLoads.isEmpty)
                  const SliverToBoxAdapter(child: ShimmerLoadingGrid())
                else
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3, // Changed to 3
                        childAspectRatio: 2.2, // Adjusted for narrower cards
                        crossAxisSpacing: 4.w,
                        mainAxisSpacing: 4.h,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final station = _stationLoads[index];
                          return StationCard(
                            index: index,
                            station: station,
                          );
                        },
                        childCount: _stationLoads.length,
                      ),
                    ),
                  ),

                SliverToBoxAdapter(child: SizedBox(height: 80.h)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Column(
      children: [
        Text(
          _errorMessage!,
          style: TextStyle(
              color: Colors.redAccent, fontFamily: Appfontstring.ChangaLight),
          textAlign: TextAlign.center,
        ),
        TextButton(
          onPressed: _fetchFromApi,
          child: Text('إعادة المحاولة',
              style: TextStyle(
                  fontFamily: Appfontstring.ChangaLight,
                  color: Colors.blueAccent)),
        )
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// COMPONENTS COPIED FROM STATIONLOADNAV
// ---------------------------------------------------------------------------

// LOAD DISPLAY WIDGET
class LoadDisplayWidget extends StatefulWidget {
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
  State<LoadDisplayWidget> createState() => _LoadDisplayWidgetState();
}

class _LoadDisplayWidgetState extends State<LoadDisplayWidget> {
  static const _updateInterval = Duration(seconds: 6);
  static const _historyRetentionMinutes = 60;

  double maxLoadInLastHour = 0.0;
  double _hourlyMax = 0.0;
  int? _trackedHour;
  DateTime? _trackedDate;
  final SupabaseService _supabaseService = SupabaseService();
  final List<Map<String, dynamic>> _loadHistory = [];
  Timer? timer;

  @override
  void initState() {
    super.initState();
    initializeHourlyMax();
    timer = Timer.periodic(_updateInterval, (_) => updateLoadHistory());
  }

  Future<void> initializeHourlyMax() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisHour = now.hour;
    try {
      final hourlyData = await _supabaseService.fetchHourlyMaxLoads(today);
      final Map<String, dynamic>? currentEntry = hourlyData.firstWhere(
        (e) => e['hour'] == thisHour,
        orElse: () => <String, dynamic>{},
      );
      _hourlyMax = currentEntry != null && currentEntry['max_load'] != null
          ? (currentEntry['max_load'] as num).toDouble()
          : 0.0;
    } catch (e) {
      _hourlyMax = 0.0;
    }
    _trackedHour = thisHour;
    _trackedDate = today;
  }

  Future<void> updateLoadHistory() async {
    if (!mounted) return;
    final now = DateTime.now();
    _loadHistory.add({'timestamp': now, 'totalLoad': widget.totalLoad});
    _loadHistory.removeWhere(
      (entry) =>
          now.difference(entry['timestamp'] as DateTime).inMinutes >
          _historyRetentionMinutes,
    );
    setState(() {
      maxLoadInLastHour = _loadHistory.isNotEmpty
          ? _loadHistory.map((e) => e['totalLoad'] as double).reduce(max)
          : widget.totalLoad;
    });

    if (_trackedHour == null || _trackedDate == null) return;

    final today = DateTime(now.year, now.month, now.day);
    final thisHour = now.hour;
    final dateChanged = now.year != _trackedDate!.year ||
        now.month != _trackedDate!.month ||
        now.day != _trackedDate!.day;
    final hourChanged = _trackedHour != thisHour || dateChanged;

    if (hourChanged) {
      // (Simplified logic for read-only view, we probably don't want to UPSERT from here if it's a viewer page,
      // but sticking to original code logic for consistency)
      _trackedHour = thisHour;
      _trackedDate = today;
      _hourlyMax = widget.totalLoad;
    } else if (widget.totalLoad > _hourlyMax) {
      _hourlyMax = widget.totalLoad;
      // Assuming we shouldn't write to DB from this view?
      // Sticking to local display update.
    }
  }

  @override
  void didUpdateWidget(LoadDisplayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.totalLoad != oldWidget.totalLoad) updateLoadHistory();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120.h, // Further Reduced from 140.h
      margin: EdgeInsets.only(left: 45.w, right: 45.w, top: 1.h, bottom: 10.h),
      padding: EdgeInsets.symmetric(
          horizontal: 10.w, vertical: 4.h), // Further Reduced padding
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2C2C2C),
            const Color(0xFF000000),
          ],
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
            padding:
                EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h), // Reduced
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
                    fontSize: 11.sp, // Reduced font size (was 13)
                    fontFamily: Appfontstring.ChangaLight,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                if (widget.isFromCache) ...[
                  SizedBox(width: 6.w),
                  Icon(
                    Icons.offline_bolt,
                    color: Colors.orangeAccent,
                    size: 12.sp, // Reduced icon size
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 2.h),
          widget.isLoading
              ? Shimmer.fromColors(
                  baseColor: Colors.red.withOpacity(0.3),
                  highlightColor: Colors.red.withOpacity(0.7),
                  child: Text(
                    '---',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 40.sp, // Reduced from 50
                      fontFamily: Appfontstring.digital,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: widget.totalLoad),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeOutQuart,
                  builder: (context, value, child) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        SizedBox(
                          width: 120.w, // Reduced width
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              value.toStringAsFixed(0),
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 40.sp, // Reduced font size (was 50)
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
                            fontSize: 10.sp, // Reduced
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
            padding: EdgeInsets.all(2.h), // Reduced
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: Colors.blueAccent.withOpacity(0.2),
              ),
            ),
            child: RichText(
              textDirection: TextDirection.rtl,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'أقصى حمل في الساعة الأخيرة: ',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 9.sp, // Reduced
                      fontFamily: Appfontstring.ChangaLight,
                    ),
                  ),
                  TextSpan(
                    text: maxLoadInLastHour.toStringAsFixed(0),
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 13.sp, // Reduced
                      fontFamily: Appfontstring.ChangaLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: ' م.و',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 9.sp, // Reduced
                      fontFamily: Appfontstring.ChangaLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
          borderRadius: BorderRadius.circular(10.r), // Reduced radius
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
            width: 0.8, // Reduced border width
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4, // Reduced blur
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Station Number Badge
            Container(
              width: 20.w, // Reduced badge size
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
                    fontSize: 10.sp, // Reduced font
                    fontWeight: FontWeight.bold,
                    fontFamily: Appfontstring.ChangaLight,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(width: 4.w), // Reduced spacing

            // Station Info
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.station.stationName,
                    maxLines: 1, // Ensure single line
                    overflow: TextOverflow.ellipsis, // Handle overflow
                    style: TextStyle(
                      fontSize: 9.sp, // Reduced font
                      fontWeight: FontWeight.bold,
                      fontFamily: Appfontstring.ChangaLight,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  SizedBox(height: 2.h),

                  // Animated Load Value
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
                                fontSize: 13.sp, // Reduced font
                                fontWeight: FontWeight.bold,
                                fontFamily: Appfontstring.digital,
                                color: Colors.greenAccent,
                              ),
                            ),
                            TextSpan(
                              text: ' م.و',
                              style: TextStyle(
                                fontSize: 8.sp, // Reduced
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

// SHIMMER LOADING
class ShimmerLoadingGrid extends StatelessWidget {
  const ShimmerLoadingGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.white.withOpacity(0.05),
      highlightColor: Colors.white.withOpacity(0.15),
      child: GridView.builder(
        // Changed to GridView from original ListView to match layout
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // Changed to 3
          childAspectRatio: 2.2, // Adjusted for narrower cards
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

// ---------------------------------------------------------------------------
// KEEPING THE HOURLY CHART LOGIC (As it was part of Loadnav features)
// ---------------------------------------------------------------------------

class HourlyMaxLoadTable extends StatefulWidget {
  final String? tableName;

  const HourlyMaxLoadTable({
    super.key,
    this.tableName,
  });

  @override
  State<HourlyMaxLoadTable> createState() => _HourlyMaxLoadTableState();
}

class _HourlyMaxLoadTableState extends State<HourlyMaxLoadTable> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final CacheService _cacheService = CacheService();

  List<Map<String, dynamic>> _hourlyMaxLoadsToday = [];
  List<Map<String, dynamic>> _hourlyMaxLoadsYesterday = [];

  bool _isLoading = false;
  String? _error;
  double? _maxLoadValue;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // 1. Load from Cache
    final cached = await _cacheService.getHourlyMaxLoads();
    if (cached != null && mounted) {
      setState(() {
        _hourlyMaxLoadsToday = cached['today']!;
        _hourlyMaxLoadsYesterday = cached['yesterday']!;
        _calculateMaxLoad();
      });
    }

    // 2. Fetch Fresh
    await _fetchFromApi();
  }

  Future<void> _fetchFromApi() async {
    if (!mounted) return;
    if (_hourlyMaxLoadsToday.isEmpty) setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final table = widget.tableName ?? 'hourly_max_loads';
      final todayFormatted = DateTime(now.year, now.month, now.day)
          .toIso8601String()
          .split('T')[0];
      final yesterdayFormatted = DateTime(now.year, now.month, now.day - 1)
          .toIso8601String()
          .split('T')[0];

      final todayResponse = await _supabase
          .from(table)
          .select('hour, max_load')
          .eq('date', todayFormatted)
          .order('hour', ascending: true);

      final yesterdayResponse = await _supabase
          .from(table)
          .select('hour, max_load')
          .eq('date', yesterdayFormatted)
          .order('hour', ascending: true);

      if (mounted) {
        List<Map<String, dynamic>> todayList =
            List<Map<String, dynamic>>.from(todayResponse);
        List<Map<String, dynamic>> yesterdayList =
            List<Map<String, dynamic>>.from(yesterdayResponse);

        setState(() {
          _hourlyMaxLoadsToday = todayList;
          _hourlyMaxLoadsYesterday = yesterdayList;
          _calculateMaxLoad();
          _isLoading = false;
          _error = null;
        });

        _cacheService.saveHourlyMaxLoads(todayList, yesterdayList);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (_hourlyMaxLoadsToday.isEmpty) _error = 'Error fetching data: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _calculateMaxLoad() {
    final all = [..._hourlyMaxLoadsToday, ..._hourlyMaxLoadsYesterday];
    if (all.isNotEmpty) {
      _maxLoadValue = all
          .map((e) => (e['max_load'] as num?)?.toDouble() ?? 0.0)
          .reduce(max);
    } else {
      _maxLoadValue = 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return Center(
          child: CircularProgressIndicator(color: Colors.orangeAccent));
    if (_error != null)
      return Text(_error!, style: TextStyle(color: Colors.red));

    final primaryColor = Colors.orangeAccent;

    return Container(
      padding: EdgeInsets.all(16.w),
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
          SizedBox(height: 16.h),
          _buildChart(primaryColor),
        ],
      ),
    );
  }

  Widget _buildChart(Color primary) {
    return Container(
      height: 200.h,
      padding: EdgeInsets.only(right: 10.w),
      child: LineChart(LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval:
                _maxLoadValue != null ? _maxLoadValue! / 4 : 500,
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
                                color: Colors.white54, fontSize: 10.sp),
                          ))),
              bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                      showTitles: true,
                      interval: 4,
                      getTitlesWidget: (value, meta) => Text(
                            "${value.toInt()}:00",
                            style: TextStyle(
                                color: Colors.white54, fontSize: 10.sp),
                          )))),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: 23,
          minY: 0,
          maxY: (_maxLoadValue ?? 100) * 1.1,
          lineBarsData: [
            _buildLineData(_hourlyMaxLoadsYesterday, Colors.white30),
            _buildLineData(_hourlyMaxLoadsToday, primary),
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

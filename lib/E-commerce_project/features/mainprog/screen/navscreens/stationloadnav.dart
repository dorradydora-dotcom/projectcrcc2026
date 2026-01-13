import 'dart:async';
import 'dart:math';
import 'package:amiraly/E-commerce_project/common/models/appmodels.dart';
import 'package:amiraly/E-commerce_project/util/constant/constants.dart';
import 'package:amiraly/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoadDisplayWidget extends StatefulWidget {
  final double totalLoad;
  final bool isLoading;

  const LoadDisplayWidget({
    super.key,
    required this.totalLoad,
    required this.isLoading,
  });

  @override
  State<LoadDisplayWidget> createState() => _LoadDisplayWidgetState();
}

class _LoadDisplayWidgetState extends State<LoadDisplayWidget> {
  static const _updateInterval = Duration(seconds: 5);
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
      _hourlyMax = currentEntry != null
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
      try {
        final hourlyData = await _supabaseService.fetchHourlyMaxLoads(today);
        final Map<String, dynamic>? currentEntry = hourlyData.firstWhere(
          (e) => e['hour'] == thisHour,
          orElse: () => <String, dynamic>{},
        );
        final existingMax = currentEntry != null
            ? (currentEntry['max_load'] as num).toDouble()
            : 0.0;
        final newMax = max(existingMax, widget.totalLoad);
        _hourlyMax = newMax;
        if (widget.totalLoad > existingMax) {
          await _supabaseService.upsertHourlyMaxLoad(thisHour, today, newMax);
        }
      } catch (e) {
        _hourlyMax = widget.totalLoad;
        await _supabaseService.upsertHourlyMaxLoad(thisHour, today, _hourlyMax);
      }
      _trackedHour = thisHour;
      _trackedDate = today;
    } else if (widget.totalLoad > _hourlyMax) {
      _hourlyMax = widget.totalLoad;
      _supabaseService
          .upsertHourlyMaxLoad(thisHour, today, _hourlyMax)
          .catchError((e) {});
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
      width: 1.sw,
      margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      padding: EdgeInsets.all(12.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF06141C), Color(0xFF2C3D49)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10.r,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Total Electrical Load',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
            textDirection: TextDirection.rtl,
          ),
          SizedBox(height: 2.h),
          Text(
            widget.isLoading ? '...' : widget.totalLoad.toStringAsFixed(0),
            style: TextStyle(
              color: Colors.redAccent,
              fontSize: 44.sp,
              fontFamily: Appfontstring.tejwa1,
              fontWeight: FontWeight.w600,
              shadows: const [Shadow(color: Colors.red, blurRadius: 10)],
            ),
            textDirection: TextDirection.rtl,
          ),
          SizedBox(height: 2.h),
          RichText(
            textDirection: TextDirection.rtl,
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'القيمة القصوى في الساعة الأخيرة: ',
                  style: TextStyle(
                    color: const Color(0xDBF0E769),
                    fontSize: 12.sp,
                    fontFamily: Appfontstring.ChangaLight,
                  ),
                ),
                TextSpan(
                  text: maxLoadInLastHour.toStringAsFixed(0),
                  style: TextStyle(
                    color: const Color(0xFF03C6D0),
                    fontSize: 20.sp,
                    fontFamily: Appfontstring.ChangaLight,
                  ),
                ),
                TextSpan(
                  text: ' م.و',
                  style: TextStyle(
                    color: const Color(0xDBF0E769),
                    fontSize: 12.sp,
                    fontFamily: Appfontstring.ChangaLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CustomActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;

  const CustomActionButton({
    super.key,
    required this.onPressed,
    this.icon = Icons.settings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(4.w),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.all(8.w),
          backgroundColor: const Color(0xFF1E88E5),
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: Icon(icon, size: 16.sp),
      ),
    );
  }
}

class StationloadnavScreen extends StatefulWidget {
  const StationloadnavScreen({super.key});

  @override
  State<StationloadnavScreen> createState() => _StationloadnavScreenState();
}

class _StationloadnavScreenState extends State<StationloadnavScreen> {
  static const _updateInterval = Duration(seconds: 4);
  Map<String, String> specificStations = {};

  final SupabaseService _supabaseService = SupabaseService();
  List<StationLoad> _stationLoads = [];
  bool _isLoading = true;
  String? _errorMessage;
  final GlobalKey<LiquidPullToRefreshState> _refreshIndicatorKey =
      GlobalKey<LiquidPullToRefreshState>();
  Timer? _timer;
  List<String> adminEmails = [];
  String? userEmail;

  @override
  void initState() {
    super.initState();
    userEmail = Supabase.instance.client.auth.currentUser?.email;
    _fetchData();
    _timer = Timer.periodic(_updateInterval, (_) => _updateLoads());
  }

  Future<void> _fetchData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final loads = await _supabaseService.fetchStationLoads();
      if (!mounted) return; // التحقق بعد أول await

      specificStations = await _supabaseService.fetchSpecificStations();
      if (!mounted) return; // التحقق بعد ثاني await

      setState(() {
        _stationLoads = loads;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return; // التحقق قبل setState في حالة الخطأ

      setState(() {
        _errorMessage = 'خطأ في جلب البيانات: $e';
        _isLoading = false;
      });
    }
  }

  void _updateLoads() {
    if (!mounted) return;
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

  Future<void> _handleStationAction(
      BuildContext context, StationLoad station) async {
    final currentUserEmail = Supabase.instance.client.auth.currentUser?.email;
    final requiredEmail = specificStations[station.stationName];

    bool isCrccUser = false;
    try {
      final response =
          await Supabase.instance.client.from('user_crcc').select('user_email');
      final crccEmails =
          response.map((e) => e['user_email'] as String).toList();
      isCrccUser = crccEmails.contains(currentUserEmail);
    } catch (e) {
      debugPrint('Error checking user_crcc table');
    }

    if (isCrccUser) {
      showDialog(
        context: context,
        builder: (context) => StationDialog(
          station: station,
          onUpdate: () {
            setState(() {});
            _refreshIndicatorKey.currentState?.show();
          },
        ),
      );
      return;
    }

    if (requiredEmail != null && currentUserEmail != requiredEmail) {
      _showErrorSnackBar(
          context, 'غير مصرح لك بتعديل حمل محطة ${station.stationName}');
      return;
    }

    if (adminEmails.contains(currentUserEmail) ||
        requiredEmail == currentUserEmail) {
      showDialog(
        context: context,
        builder: (context) => StationDialog(
          station: station,
          onUpdate: () {
            setState(() {});
            _refreshIndicatorKey.currentState?.show();
          },
        ),
      );
    } else {
      _showErrorSnackBar(context, 'غير مصرح لك بتحديث بيانات المحطة');
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textDirection: TextDirection.rtl),
        backgroundColor: Colors.red,
      ),
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
          body: _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontFamily: Appfontstring.ChangaLight,
                          color: Colors.red,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      SizedBox(height: 16.h),
                      ElevatedButton(
                        onPressed: _fetchData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E88E5),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 20.w, vertical: 10.h),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r)),
                        ),
                        child: Text(
                          'إعادة المحاولة',
                          style: TextStyle(
                              fontSize: 14.sp,
                              fontFamily: Appfontstring.ChangaLight),
                        ),
                      ),
                    ],
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Appcolors.primaryColor,
                        const Color.fromARGB(177, 255, 255, 255)
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: LoadDisplayWidget(
                          totalLoad: _getTotalLoad(),
                          isLoading: _isLoading,
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Container(
                          margin: EdgeInsets.symmetric(
                              horizontal: 7.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(169, 255, 255, 255),
                            borderRadius: BorderRadius.circular(12.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10.r,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: DataTable(
                            columnSpacing: 9.w,
                            dividerThickness: 0.9,
                            headingRowHeight: 40.h,
                            dataRowHeight: 36.h,
                            headingRowColor: WidgetStateProperty.all(
                              const Color(0xFF1E88E5).withOpacity(0.1),
                            ),
                            columns: [
                              DataColumn(
                                label: SizedBox(
                                  width: 60.w,
                                  child: Text(
                                    'الإجراء',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: Appfontstring.ChangaLight,
                                      color: const Color(0xFF0D47A1),
                                    ),
                                    textDirection: TextDirection.rtl,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: SizedBox(
                                  width: 80.w,
                                  child: Text(
                                    'الحمل\n(م.و)',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: Appfontstring.ChangaLight,
                                      color: const Color(0xFF0D47A1),
                                    ),
                                    textDirection: TextDirection.rtl,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: SizedBox(
                                  width: 120.w,
                                  child: Text(
                                    'المحطة',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: Appfontstring.ChangaLight,
                                      color: const Color(0xFF0D47A1),
                                    ),
                                    textDirection: TextDirection.rtl,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: SizedBox(
                                  width: 40.w,
                                  child: Text(
                                    'رقم',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: Appfontstring.ChangaLight,
                                      color: const Color(0xFF0D47A1),
                                    ),
                                    textDirection: TextDirection.rtl,
                                  ),
                                ),
                              ),
                            ],
                            rows: _stationLoads.asMap().entries.map((entry) {
                              final index = entry.key;
                              final station = entry.value;
                              final showUpdateButton =
                                  station.load >= 0 && station.load <= 700;
                              final requiredEmail =
                                  specificStations[station.stationName];
                              final isUserAssigned = userEmail != null &&
                                  requiredEmail != null &&
                                  userEmail == requiredEmail;
                              return DataRow(
                                color: WidgetStateProperty.all(
                                  index % 2 == 0
                                      ? Colors.white
                                      : const Color(0xFFE3F2FD)
                                          .withOpacity(0.05),
                                ),
                                cells: [
                                  DataCell(
                                    Center(
                                      child: showUpdateButton
                                          ? CustomActionButton(
                                              onPressed: () =>
                                                  _handleStationAction(
                                                      context, station),
                                              icon: Icons.settings,
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 80.w,
                                      child: Text(
                                        _isLoading
                                            ? '...'
                                            : station.load.toStringAsFixed(2),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize:
                                              isUserAssigned ? 13.sp : 12.sp,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: Appfontstring.ChangaLight,
                                          color: isUserAssigned
                                              ? Colors.red
                                              : const Color(0xFF0D47A1),
                                        ),
                                        textDirection: TextDirection.rtl,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 120.w,
                                      child: Text(
                                        station.stationName,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize:
                                              isUserAssigned ? 13.sp : 12.sp,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: Appfontstring.ChangaLight,
                                          color: isUserAssigned
                                              ? Colors.red
                                              : const Color(0xFF0D47A1),
                                        ),
                                        textDirection: TextDirection.rtl,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 40.w,
                                      child: Text(
                                        '${index + 1}',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize:
                                              isUserAssigned ? 13.sp : 12.sp,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: Appfontstring.ChangaLight,
                                          color: isUserAssigned
                                              ? Colors.red
                                              : const Color(0xFF0D47A1),
                                        ),
                                        textDirection: TextDirection.rtl,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class StationDialog extends StatefulWidget {
  final StationLoad station;
  final VoidCallback onUpdate;

  const StationDialog({
    super.key,
    required this.station,
    required this.onUpdate,
  });

  @override
  State<StationDialog> createState() => StationDialogState();
}

class StationDialogState extends State<StationDialog> {
  final TextEditingController _loadController = TextEditingController();
  final SupabaseService _supabaseService = SupabaseService();
  String? _errorText;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadController.text = widget.station.load.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _loadController.dispose();
    super.dispose();
  }

  Future<void> _updateLoad(double newLoad) async {
    setState(() => _isUpdating = true);
    try {
      await _supabaseService.updateStationLoad(
          widget.station.stationName, newLoad);
      setState(() => widget.station.load = newLoad);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم تحديث ${widget.station.stationName} بنجاح',
              textDirection: TextDirection.rtl,
            ),
            backgroundColor: Colors.green,
          ),
        );
        widget.onUpdate();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ في التحديث: $e',
              textDirection: TextDirection.rtl,
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _validateAndUpdate() {
    final input =
        _loadController.text.trim().replaceAll('٫', '.').replaceAll(',', '.');
    final newLoad = double.tryParse(input);
    if (newLoad == null || newLoad < 0 || newLoad > 700) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال قيمة صحيحة بين 0 و 700',
              textDirection: TextDirection.rtl),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    _updateLoad(newLoad);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      title: Text(
        'تحديث المحطة',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
          fontFamily: Appfontstring.ChangaLight,
          color: const Color(0xFF0D47A1),
        ),
        textDirection: TextDirection.rtl,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'اسم المحطة: ${widget.station.stationName}',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                fontFamily: Appfontstring.ChangaLight,
              ),
              textDirection: TextDirection.rtl,
            ),
            SizedBox(height: 8.h),
            Text(
              'الحمل الحالي: ${widget.station.load.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                fontFamily: Appfontstring.ChangaLight,
              ),
              textDirection: TextDirection.rtl,
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: _loadController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: 'أدخل الحمل الجديد',
                hintStyle: TextStyle(
                  fontSize: 14.sp,
                  fontFamily: Appfontstring.ChangaLight,
                  color: Colors.grey,
                ),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: const BorderSide(color: Color(0xFF1E88E5)),
                ),
                errorText: _errorText,
                errorMaxLines: 2,
              ),
              textDirection: TextDirection.rtl,
              onChanged: (value) {
                final input =
                    value.trim().replaceAll('٫', '.').replaceAll(',', '.');
                setState(() {
                  if (input.isEmpty) {
                    _errorText = 'يرجى إدخال قيمة الحمل';
                  } else {
                    final parsed = double.tryParse(input);
                    if (parsed == null || parsed < 0 || parsed > 700) {
                      _errorText = 'يرجى إدخال رقم صحيح بين 0 و 700';
                    } else {
                      _errorText = null;
                    }
                  }
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              onPressed: (_errorText != null || _isUpdating)
                  ? null
                  : _validateAndUpdate,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r)),
              ),
              child: _isUpdating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'تحديث',
                      style: TextStyle(
                          fontSize: 14.sp,
                          fontFamily: Appfontstring.ChangaLight),
                    ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'إلغاء',
                style: TextStyle(
                  color: Colors.red,
                  fontFamily: Appfontstring.ChangaLight,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

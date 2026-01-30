import 'dart:async';
import 'dart:math';
import 'package:amiraly/E-commerce_project/common/models/appmodels.dart';
import 'package:amiraly/E-commerce_project/util/constant/constants.dart';
import 'package:amiraly/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const double _maxStationLoad = 700.0;

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
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 2.h),
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.03),
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
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Text(
              'الحمل الكلي للشبكة',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 15.sp,
                fontFamily: Appfontstring.ChangaLight,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
          SizedBox(height: 7.h),
          Container(
            child: widget.isLoading
                ? Text(
                    '......',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 42.sp,
                      fontFamily: Appfontstring.tejwa1,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: widget.totalLoad),
                    duration: const Duration(seconds: 1),
                    curve: Curves.easeOutQuart,
                    builder: (context, value, child) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            value.toStringAsFixed(0),
                            style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 50.sp,
                                fontFamily: Appfontstring.digital),
                            textDirection: TextDirection.rtl,
                          ),
                          Text(
                            'ميجا واط',
                            style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 10.sp,
                                fontFamily: Appfontstring.ChangaLight),
                            textDirection: TextDirection.rtl,
                          ),
                        ],
                      );
                    },
                  ),
          ),
          SizedBox(height: 6.h),
          Container(
            padding: EdgeInsets.all(5.h),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10.r),
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
                      fontSize: 12.sp,
                      fontFamily: Appfontstring.ChangaLight,
                    ),
                  ),
                  TextSpan(
                    text: maxLoadInLastHour.toStringAsFixed(0),
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 18.sp,
                      fontFamily: Appfontstring.ChangaLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: ' م.و',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12.sp,
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
        margin: EdgeInsets.all(3.w),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8.r)),
        child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
                padding: EdgeInsets.all(5.w),
                backgroundColor: const Color.fromARGB(255, 228, 178, 124),
                foregroundColor: Colors.white,
                elevation: 3),
            child: Icon(icon, size: 17.sp)));
  }
}

class StationloadnavScreen extends StatefulWidget {
  const StationloadnavScreen({super.key});

  @override
  State<StationloadnavScreen> createState() => _StationloadnavScreenState();
}

class _StationloadnavScreenState extends State<StationloadnavScreen> {
  static const _updateInterval = Duration(seconds: 6);
  Map<String, String> specificStations = {};

  final SupabaseService _supabaseService = SupabaseService();
  List<StationLoad> _stationLoads = [];
  bool _isLoading = true;
  String? _errorMessage;

  Timer? _timer;
  String? userEmail;
  bool _isCrccUser = false;

  @override
  void initState() {
    super.initState();
    userEmail = Supabase.instance.client.auth.currentUser?.email;
    _checkPermissions();
    _fetchData();
    _timer = Timer.periodic(_updateInterval, (_) => _updateLoads());
  }

  Future<void> _checkPermissions() async {
    if (userEmail == null) return;
    try {
      final response =
          await Supabase.instance.client.from('user_crcc').select('user_email');
      final crccEmails =
          response.map((e) => e['user_email'] as String).toList();
      if (mounted) {
        setState(() {
          _isCrccUser = crccEmails.contains(userEmail);
        });
      }
    } catch (e) {
      debugPrint('Error checking permissions: $e');
    }
  }

  Future<void> _fetchData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final loads = await _supabaseService.fetchStationLoads();
      if (!mounted) return;

      specificStations = await _supabaseService.fetchSpecificStations();
      if (!mounted) return;

      setState(() {
        _stationLoads = loads;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'خطأ في جلب البيانات';
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

  void _handleStationAction(BuildContext context, StationLoad station) async {
    final requiredEmail = specificStations[station.stationName];
    bool authorized = false;

    if (_isCrccUser) {
      authorized = true;
    } else if (requiredEmail != null && userEmail == requiredEmail) {
      authorized = true;
    }

    if (authorized) {
      final shouldRefresh = await showDialog<bool>(
        context: context,
        builder: (context) => StationDialog(
          station: station,
          onUpdate: () {
            // Callback passed but handle reload centrally after pop
          },
        ),
      );

      if (shouldRefresh == true) {
        // Trigger explicit refresh logic here
        // Set loading to true immediately for visual feedback
        setState(() => _isLoading = true);
        await _fetchData();
      }
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
    return WillPopScope(
      onWillPop: () async => false,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          extendBodyBehindAppBar: true,
          floatingActionButton: SizedBox(
              height: 38.h,
              width: 38.w,
              child: FloatingActionButton(
                  onPressed: () => _fetchData(),
                  backgroundColor: const Color.fromARGB(109, 3, 218, 197),
                  child: const Icon(Icons.refresh,
                      color: Colors.white, size: 19))),
          body: _errorMessage != null
              ? Container(
                  color: const Color(0xFF0F172A),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _errorMessage!,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontFamily: Appfontstring.ChangaLight,
                            color: Colors.redAccent,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        SizedBox(height: 16.h),
                        ElevatedButton(
                          onPressed: _fetchData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                horizontal: 24.w, vertical: 12.h),
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
                  ),
                )
              : Container(
                  color: const Color(0xFF0F172A),
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: LoadDisplayWidget(
                          totalLoad: _getTotalLoad(),
                          isLoading: _isLoading,
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Container(
                          margin: EdgeInsets.fromLTRB(12.w, 2.h, 12.w, 20.h),
                          decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.08),
                                  Colors.white.withOpacity(0.03),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.15),
                                width: 1.5,
                              )),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16.r),
                            child: DataTable(
                              columnSpacing: 8.w,
                              dividerThickness: 0.5,
                              headingRowHeight: 40.h,
                              headingRowColor: WidgetStateProperty.all(
                                Colors.blueAccent.withOpacity(0.1),
                              ),
                              columns: [
                                DataColumn(
                                  label: SizedBox(
                                    width: 35.w,
                                    child: Text(
                                      'رقم',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: Appfontstring.ChangaLight,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: SizedBox(
                                    width: 100.w,
                                    child: Text(
                                      'المحطة',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: Appfontstring.ChangaLight,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: SizedBox(
                                    width: 70.w,
                                    child: Text(
                                      'الحمل',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: Appfontstring.ChangaLight,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: SizedBox(
                                    width: 50.w,
                                    child: Text(
                                      'تعديل',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: Appfontstring.ChangaLight,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              rows: _stationLoads.asMap().entries.map((entry) {
                                final index = entry.key;
                                final station = entry.value;
                                final showUpdateButton = station.load >= 0 &&
                                    station.load <= _maxStationLoad;
                                final requiredEmail =
                                    specificStations[station.stationName];
                                final isUserAssigned = userEmail != null &&
                                    requiredEmail != null &&
                                    userEmail == requiredEmail;

                                return DataRow(
                                  color: WidgetStateProperty.resolveWith(
                                    (states) {
                                      if (index % 2 == 0) {
                                        return Colors.white.withOpacity(0.02);
                                      }
                                      return Colors.white.withOpacity(0.05);
                                    },
                                  ),
                                  cells: [
                                    DataCell(
                                      Container(
                                        width: 35.w,
                                        alignment: Alignment.center,
                                        child: Text(
                                          '${index + 1}',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize:
                                                isUserAssigned ? 13.sp : 12.sp,
                                            fontWeight: FontWeight.w600,
                                            fontFamily:
                                                Appfontstring.ChangaLight,
                                            color: isUserAssigned
                                                ? Colors.orangeAccent
                                                : Colors.white54,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Container(
                                        width: 100.w,
                                        alignment: Alignment.center,
                                        padding: EdgeInsets.symmetric(
                                            vertical: 4.h, horizontal: 8.w),
                                        decoration: isUserAssigned
                                            ? BoxDecoration(
                                                color: Colors.orangeAccent
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8.r),
                                                border: Border.all(
                                                  color: Colors.orangeAccent
                                                      .withOpacity(0.3),
                                                ),
                                              )
                                            : null,
                                        child: Text(
                                          station.stationName,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize:
                                                isUserAssigned ? 13.sp : 12.sp,
                                            fontWeight: FontWeight.w600,
                                            fontFamily:
                                                Appfontstring.ChangaLight,
                                            color: isUserAssigned
                                                ? Colors.orangeAccent
                                                : Colors.white70,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Container(
                                        width: 70.w,
                                        alignment: Alignment.center,
                                        child: Text(
                                          _isLoading
                                              ? '...'
                                              : station.load.toStringAsFixed(2),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize:
                                                isUserAssigned ? 13.sp : 12.sp,
                                            fontWeight: FontWeight.bold,
                                            fontFamily:
                                                Appfontstring.ChangaLight,
                                            color: isUserAssigned
                                                ? Colors.orangeAccent
                                                : Colors.greenAccent,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Center(
                                        child: showUpdateButton
                                            ? CustomActionButton(
                                                onPressed: () =>
                                                    _handleStationAction(
                                                        context, station),
                                                icon: Icons.edit,
                                              )
                                            : const SizedBox.shrink(),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
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
        Navigator.of(context).pop(true);
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
    if (newLoad == null || newLoad < 0 || newLoad > _maxStationLoad) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال قيمة صحيحة بين 0 و $_maxStationLoad',
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
      backgroundColor: const Color(0xFF163C5E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      title: Text(
        'تحديث بيانات المحطة',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 17.sp,
          fontWeight: FontWeight.bold,
          fontFamily: Appfontstring.ChangaLight,
          color: Colors.white,
        ),
        textDirection: TextDirection.rtl,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'اسم المحطة: ${widget.station.stationName}',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
                fontFamily: Appfontstring.ChangaLight,
              ),
              textDirection: TextDirection.rtl,
            ),
            SizedBox(height: 3.h),
            Text(
              'الحمل الحالي: ${widget.station.load.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
                fontFamily: Appfontstring.ChangaLight,
              ),
              textDirection: TextDirection.rtl,
            ),
            SizedBox(height: 10.h),
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
                    if (parsed == null ||
                        parsed < 0 ||
                        parsed > _maxStationLoad) {
                      _errorText =
                          'يرجى إدخال رقم صحيح بين 0 و $_maxStationLoad';
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
                backgroundColor: const Color.fromARGB(255, 198, 223, 246),
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
                        color: Colors.green,
                        fontFamily: Appfontstring.ChangaLight,
                        fontSize: 14.sp,
                      ),
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

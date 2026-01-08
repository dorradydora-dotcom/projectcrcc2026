import 'dart:async';
import 'dart:math';

import 'package:amiraly/E-commerce_project/common/services/mainprogservices.dart';
import 'package:amiraly/E-commerce_project/util/constant/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
  double _previousMaxLoadInLastHour = 0.0;
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

  @override
  void dispose() {
    timer?.cancel();
    timer = null;
    super.dispose();
  }

  Future<void> initializeHourlyMax() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisHour = now.hour;
    try {
      final hourlyData = await _supabaseService.fetchHourlyMaxLoads(today);
      final Map<String, dynamic> currentEntry = hourlyData.firstWhere(
        (e) => e['hour'] == thisHour,
        orElse: () => <String, dynamic>{},
      );
      _hourlyMax = (currentEntry['max_load'] as num).toDouble();
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
    final newMaxLoadInLastHour = _loadHistory.isNotEmpty
        ? _loadHistory.map((e) => e['totalLoad'] as double).reduce(max)
        : widget.totalLoad;

    bool needsRebuild = newMaxLoadInLastHour != _previousMaxLoadInLastHour;

    if (_trackedHour == null || _trackedDate == null) {
      if (needsRebuild & mounted) {
        setState(() {
          maxLoadInLastHour = newMaxLoadInLastHour;
          _previousMaxLoadInLastHour = newMaxLoadInLastHour;
        });
      }
      return;
    }

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
        final newHourlyMax = max(existingMax, widget.totalLoad);
        final hourlyMaxChanged = newHourlyMax != _hourlyMax;
        _hourlyMax = newHourlyMax;
        if (widget.totalLoad > existingMax) {
          await _supabaseService.upsertHourlyMaxLoad(
            thisHour,
            today,
            newHourlyMax,
          );
        }
        needsRebuild = needsRebuild || hourlyMaxChanged;
      } catch (e) {
        final newHourlyMax = widget.totalLoad;
        final hourlyMaxChanged = newHourlyMax != _hourlyMax;
        _hourlyMax = newHourlyMax;
        await _supabaseService.upsertHourlyMaxLoad(
          thisHour,
          today,
          _hourlyMax,
        );
        needsRebuild = needsRebuild || hourlyMaxChanged;
      }
      _trackedHour = thisHour;
      _trackedDate = today;
    } else {
      if (widget.totalLoad > _hourlyMax) {
        final oldHourlyMax = _hourlyMax;
        _hourlyMax = widget.totalLoad;
        _supabaseService
            .upsertHourlyMaxLoad(
              thisHour,
              today,
              _hourlyMax,
            )
            .catchError((e) {});
        needsRebuild = needsRebuild || (_hourlyMax != oldHourlyMax);
      }
    }

    if (mounted) {
      setState(() {
        maxLoadInLastHour = newMaxLoadInLastHour;
        _previousMaxLoadInLastHour = newMaxLoadInLastHour;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
            width: double.infinity * 0.8,
            constraints:
                BoxConstraints(maxWidth: ScreenUtil().screenWidth * 0.9),
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            padding: EdgeInsets.all(20.h),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20.r),
                border:
                    Border.all(color: Colors.white.withOpacity(0.3), width: 2)),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Total Electrical Load',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    widget.isLoading
                        ? '...'
                        : widget.totalLoad.toStringAsFixed(0),
                    style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 52,
                        fontFamily: Appfontstring.digital,
                        fontWeight: FontWeight.w700,
                        shadows: const [
                          Shadow(color: Colors.red, blurRadius: 12)
                        ]),
                    textDirection: TextDirection.rtl,
                  ),
                  SizedBox(height: 8.h),
                  RichText(
                      textDirection: TextDirection.rtl,
                      text: TextSpan(children: [
                        const TextSpan(
                          text: 'القيمة القصوى في الساعة الأخيرة: ',
                          style: TextStyle(
                              fontSize: 12,
                              fontFamily: Appfontstring.ChangaLight,
                              color: Color.fromARGB(214, 255, 255, 255)),
                        ),
                        TextSpan(
                          text: maxLoadInLastHour.toStringAsFixed(0),
                          style: TextStyle(
                            color: Color.fromARGB(255, 238, 225, 42),
                            fontSize: 22,
                            fontFamily: Appfontstring.digital,
                          ),
                        ),
                        const TextSpan(
                            text: ' م.و',
                            style: TextStyle(
                                color: Color.fromARGB(255, 240, 231, 105),
                                fontSize: 14,
                                fontFamily: Appfontstring.ChangaLight))
                      ]))
                ])));
  }
}

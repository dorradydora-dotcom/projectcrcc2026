import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:amiraly/app/util/constant/constants.dart';
import 'package:amiraly/app/common/models/appmodels.dart';
import 'package:amiraly/app/features/mainprog/screen/navscreens/station_load_controller.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'dart:math';
import 'package:shimmer/shimmer.dart';
import 'package:amiraly/core/services/heartbeat_service.dart';
import 'package:amiraly/core/widgets/electric_loading_indicator.dart';


// ============================================================================
// TOTAL LOAD CARD - MATCHING STATIONLOADNAV DESIGN
// ============================================================================

class TotalLoadCard extends StatefulWidget {
  final double totalLoad;
  final bool isLoading;
  final bool isWide;
  final bool isFromCache;

  const TotalLoadCard({
    super.key,
    required this.totalLoad,
    required this.isLoading,
    required this.isWide,
    this.isFromCache = false,
  });

  @override
  State<TotalLoadCard> createState() => _TotalLoadCardState();
}

class _TotalLoadCardState extends State<TotalLoadCard> {
  static const _historyRetentionMinutes = 60;
  double maxLoadInLastHour = 0.0;
  final List<Map<String, dynamic>> _loadHistory = [];
  StreamSubscription? _heartbeatSubscription;

  @override
  void initState() {
    super.initState();
    maxLoadInLastHour = widget.totalLoad;

    // Subscribe to central heartbeat for history updates every 6 seconds
    _heartbeatSubscription = HeartbeatService.instance.onTick.listen((tick) {
      if (tick % 6 == 0) {
        _updateLoadHistory();
      }
    });
  }

  void _updateLoadHistory() {
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
  }

  @override
  void didUpdateWidget(TotalLoadCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.totalLoad != oldWidget.totalLoad) {
      _updateLoadHistory();
    }
  }

  @override
  void dispose() {
    _heartbeatSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160.h,
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C2C2C), Color(0xFF000000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
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
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'الحمل الكلي لمنطقة القاهرة',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13.sp,
                    fontFamily: Appfontstring.ChangaLight,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                if (widget.isFromCache) ...[
                  SizedBox(width: 6.w),
                  Icon(Icons.offline_bolt,
                      color: Colors.orangeAccent, size: 14.sp),
                ],
              ],
            ),
          ),
          SizedBox(height: 2.h),
          widget.isLoading
              ? Shimmer.fromColors(
                  baseColor: Colors.red.withValues(alpha: 0.3),
                  highlightColor: Colors.red.withValues(alpha: 0.7),
                  child: Text(
                    '---',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 50.sp,
                      fontFamily: Appfontstring.digital,
                      fontFamilyFallback: const [Appfontstring.ChangaLight],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: widget.totalLoad),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeOutQuart,
                  builder: (context, value, child) {
                    final isNegative = value < 0;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              value.toStringAsFixed(0),
                              style: TextStyle(
                                color:
                                    isNegative ? Colors.red : Colors.redAccent,
                                fontSize: 50.sp,
                                fontFamily: Appfontstring.digital,
                                fontFamilyFallback: const [Appfontstring.ChangaLight],
                                shadows: [
                                  Shadow(
                                    color: (isNegative
                                            ? Colors.red
                                            : Colors.redAccent)
                                        .withValues(alpha: 0.5),
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
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12.sp,
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
            padding: EdgeInsets.all(3.h),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8.r),
              border:
                  Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
            ),
            child: RichText(
              textDirection: TextDirection.rtl,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'أقصى حمل في الساعة الأخيرة: ',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10.sp,
                      fontFamily: Appfontstring.ChangaLight,
                    ),
                  ),
                  TextSpan(
                    text: maxLoadInLastHour.toStringAsFixed(0),
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 15.sp,
                      fontFamily: Appfontstring.digital,
                      fontFamilyFallback: const [Appfontstring.ChangaLight],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: ' م.و',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10.sp,
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

// ============================================================================
// STATION CARD - REFINED DESIGN SYSTEM
// ============================================================================

class StationGaugeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final int min;
  final int max;
  final bool isWide;
  final VoidCallback? onFlip;
  final VoidCallback? onEdit;
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
    this.onEdit,
    this.isToggleable = true,
  });

  @override
  Widget build(BuildContext context) {
    final double numValue =
        double.tryParse(value.replaceAll('+', '').replaceAll('-', '')) ?? 0.0;
    final bool isNegative = value.startsWith('-');
    final double progress = (numValue / (max > 0 ? max : 1)).clamp(0.0, 1.0);

    return Container(
      margin: EdgeInsets.symmetric(vertical: 2.h),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 11.sp,
                    fontFamily: Appfontstring.ChangaLight,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.rtl,
                ),
                SizedBox(height: 2.h),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                      begin: 0, end: isNegative ? -numValue : numValue),
                  duration: const Duration(seconds: 1),
                  curve: Curves.easeOutQuart,
                  builder: (context, animValue, child) {
                    final color =
                        animValue >= 0 ? Colors.greenAccent : Colors.redAccent;
                    return Row(
                      children: [
                        Text(
                          '${animValue >= 0 ? '+' : ''}${animValue.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: color,
                            fontSize: 18.sp,
                            fontFamily: Appfontstring.digital,
                            fontFamilyFallback: const [Appfontstring.ChangaLight],
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'م.و',
                          style: TextStyle(
                              color: Colors.white60,
                              fontSize: 9.sp,
                              fontFamily: Appfontstring.ChangaLight),
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(height: 4.h),
                HudProgressBar(
                    progress: progress,
                    color: isNegative ? Colors.redAccent : Colors.greenAccent),
              ],
            ),
          ),
          if (isToggleable && (onFlip != null || onEdit != null))
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onEdit != null)
                  _CircleAction(
                      icon: Icons.edit,
                      color: Colors.blueAccent,
                      onTap: onEdit!),
                if (onFlip != null) ...[
                  SizedBox(height: 8.h),
                  _CircleAction(
                      icon: Icons.swap_horiz,
                      color: Colors.yellowAccent,
                      onTap: onFlip!),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CircleAction(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
        ),
        child: Icon(icon, color: color, size: 14.sp),
      ),
    );
  }
}

class HudProgressBar extends StatelessWidget {
  final double progress;
  final Color color;

  const HudProgressBar(
      {super.key, required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(15, (index) {
        final isActive = (index / 15) < progress;
        return Expanded(
          child: Container(
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: isActive ? color : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        );
      }),
    );
  }
}

// ============================================================================
// COMPATIBILITY DIALOG
// ============================================================================

class StationDialog extends StatefulWidget {
  final StationLoad station;
  const StationDialog({super.key, required this.station});

  @override
  State<StationDialog> createState() => _StationDialogState();
}

class _StationDialogState extends State<StationDialog> {
  final _controller = TextEditingController();
  final stationController = Get.find<StationLoadController>();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.station.load.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
      title: Text('تحديث ${widget.station.stationName}',
          style: TextStyle(
              fontFamily: Appfontstring.ChangaLight,
              fontSize: 14.sp,
              color: Colors.white)),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: BorderSide.none),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.red))),
        ElevatedButton(
          onPressed: _loading
              ? null
              : () async {
                  final val = double.tryParse(_controller.text);
                  if (val != null) {
                    setState(() => _loading = true);
                    await stationController.updateStationLoad(
                        widget.station.stationName, val);
                    if (mounted) {
                      Navigator.of(this.context).pop();
                    }
                  }
                },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          child: _loading
              ? const ElectricLoadingIndicator(size: 20)
              : const Text('حفظ'),
        ),
      ],
    );
  }
}

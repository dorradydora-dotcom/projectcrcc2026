import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:amiraly/app/util/constant/constants.dart';
import 'package:amiraly/app/common/models/appmodels.dart';
import 'package:amiraly/app/features/mainprog/screen/navscreens/station_load_controller.dart';
import 'package:get/get.dart';

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
    const Color tacticalCyan = Color(0xFF00E5FF);
    const Color alertRed = Color(0xFFFF1744);

    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        margin: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: tacticalCyan.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
                top: 4,
                left: 4,
                child: HudCorner(tacticalCyan, isTop: true, isLeft: true)),
            Positioned(
                top: 4,
                right: 4,
                child: HudCorner(tacticalCyan, isTop: true, isLeft: false)),
            Positioned(
                bottom: 4,
                left: 4,
                child: HudCorner(tacticalCyan, isTop: false, isLeft: true)),
            Positioned(
                bottom: 4,
                right: 4,
                child: HudCorner(tacticalCyan, isTop: false, isLeft: false)),
            Padding(
              padding: EdgeInsets.all(8.w),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      HudLabel(
                          text: 'SYSTEM_Load_MONITOR', color: tacticalCyan),
                      HudLabel(
                          text: 'CORE_TEMP: OPTIMAL',
                          color: Colors.greenAccent),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            isLoading
                                ? 'SCANNING'
                                : totalLoad.toStringAsFixed(0),
                            style: TextStyle(
                              color: (totalLoad < 0) ? alertRed : Colors.white,
                              fontSize: 48.sp,
                              fontFamily: Appfontstring.BebasNeue_Regular,
                              letterSpacing: 2,
                              shadows: [
                                Shadow(
                                    color: (totalLoad < 0
                                            ? alertRed
                                            : tacticalCyan)
                                        .withValues(alpha: 0.8),
                                    blurRadius: 10),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'MW',
                        style: TextStyle(
                          color: tacticalCyan.withValues(alpha: 0.5),
                          fontSize: 16.sp,
                          fontFamily: Appfontstring.BebasNeue_Regular,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Divider(
                      color: tacticalCyan.withValues(alpha: 0.1),
                      thickness: 0.5),
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
}

class HudLabel extends StatelessWidget {
  final String text;
  final Color color;

  const HudLabel({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 3, color: color),
        SizedBox(width: 4.w),
        Text(
          text,
          style: TextStyle(
            color: color.withValues(alpha: 0.6),
            fontSize: 7.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class HudCorner extends StatelessWidget {
  final Color color;
  final bool isTop;
  final bool isLeft;

  const HudCorner(this.color,
      {super.key, required this.isTop, required this.isLeft});

  @override
  Widget build(BuildContext context) {
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
        double.tryParse(value.replaceAll('+', ''))?.abs() ?? 0.0;
    final double progress = (numValue / max).clamp(0.0, 1.0);
    final bool isNegative = value.startsWith('-');
    const Color tacticalCyan = Color(0xFF00E5FF);
    const Color alertRed = Color(0xFFFF1744);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: IntrinsicHeight(
          child: Column(
            children: [
              Container(
                height: 3,
                width: double.infinity,
                color: tacticalCyan.withValues(alpha: 0.3),
              ),
              Expanded(
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
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
                          if (isToggleable) ...[
                            if (onEdit != null)
                              GestureDetector(
                                onTap: onEdit,
                                child: Icon(Icons.edit,
                                    size: 18.sp, color: Colors.blueAccent),
                              ),
                            if (onEdit != null && onFlip != null)
                              SizedBox(width: 8.w),
                            if (onFlip != null)
                              GestureDetector(
                                onTap: onFlip,
                                child: Icon(Icons.swap_horiz,
                                    size: 18.sp, color: Colors.yellowAccent),
                              ),
                          ],
                        ],
                      ),
                      const Spacer(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                value,
                                style: TextStyle(
                                  color: isNegative ? alertRed : Colors.white,
                                  fontFamily: Appfontstring.BebasNeue_Regular,
                                  fontSize: 24.sp,
                                  letterSpacing: 1,
                                  shadows: isNegative
                                      ? [
                                          Shadow(
                                              color: alertRed.withValues(
                                                  alpha: 0.5),
                                              blurRadius: 5)
                                        ]
                                      : null,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'MW',
                            style: TextStyle(
                              color: tacticalCyan.withValues(alpha: 0.4),
                              fontSize: 10.sp,
                              fontFamily: Appfontstring.BebasNeue_Regular,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      HudProgressBar(progress: progress, color: tacticalCyan),
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
            height: 4,
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

class StationDialog extends StatefulWidget {
  final StationLoad station;

  const StationDialog({
    super.key,
    required this.station,
  });

  @override
  State<StationDialog> createState() => StationDialogState();
}

class StationDialogState extends State<StationDialog> {
  final TextEditingController _loadController = TextEditingController();
  final controller = Get.find<StationLoadController>();
  String? _errorText;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadController.text = widget.station.load.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _loadController.dispose();
    super.dispose();
  }

  Future<void> _updateLoad(double newLoad) async {
    setState(() => _isUpdating = true);

    final success = await controller.updateStationLoad(
      widget.station.stationName,
      newLoad,
    );

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم تحديث ${widget.station.stationName} بنجاح',
              textDirection: TextDirection.rtl,
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'فشل التحديث، يرجى المحاولة مرة أخرى',
              textDirection: TextDirection.rtl,
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        );
      }
      setState(() => _isUpdating = false);
    }
  }

  void _validateAndUpdate() {
    final input =
        _loadController.text.trim().replaceAll('٫', '.').replaceAll(',', '.');
    final newLoad = double.tryParse(input);
    if (newLoad == null || newLoad < 0 || newLoad > 1000) {
      setState(() {
        _errorText = 'يرجى إدخال قيمة صحيحة';
      });
      return;
    }
    _updateLoad(newLoad);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF163C5E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      title: Text(
        'تحديث بيانات المحطة',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 18.sp,
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
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                widget.station.stationName,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.orangeAccent,
                  fontFamily: Appfontstring.ChangaLight,
                ),
                textDirection: TextDirection.rtl,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'الحمل الحالي: ${widget.station.load.toStringAsFixed(0)} م.و',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
                fontFamily: Appfontstring.ChangaLight,
              ),
              textDirection: TextDirection.rtl,
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: _loadController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontFamily: Appfontstring.ChangaLight,
              ),
              decoration: InputDecoration(
                hintText: 'أدخل الحمل الجديد',
                hintStyle: TextStyle(
                  fontSize: 14.sp,
                  fontFamily: Appfontstring.ChangaLight,
                  color: Colors.grey,
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
                errorText: _errorText,
              ),
              textDirection: TextDirection.ltr,
            ),
          ],
        ),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _isUpdating ? null : _validateAndUpdate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: _isUpdating
                    ? SizedBox(
                        width: 20.w,
                        height: 20.h,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('تحديث'),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    side: const BorderSide(color: Colors.red, width: 1),
                  ),
                ),
                child: const Text('إلغاء', style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

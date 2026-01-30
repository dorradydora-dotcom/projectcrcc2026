import 'dart:async';
import 'dart:math';
import 'package:amiraly/E-commerce_project/common/models/appmodels.dart';
import 'package:amiraly/E-commerce_project/util/constant/constants.dart';
import 'package:amiraly/E-commerce_project/features/mainprog/screen/navscreens/station_load_controller.dart';
import 'package:amiraly/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

const double _maxStationLoad = 700.0;

// ============================================================================
// LOAD DISPLAY WIDGET WITH ANIMATIONS
// ============================================================================

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
      height: 160.h,
      margin: EdgeInsets.only(
          left: 45.w,
          right: 45.w,
          top: 1.h,
          bottom: 20.h), // Added bottom margin for spacing
      padding: EdgeInsets.symmetric(
          horizontal: 10.w, vertical: 8.h), // Reduced vertical padding
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2C2C2C), // Lighter black for shine
            const Color(0xFF000000), // Pure black
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
            padding: EdgeInsets.symmetric(
                horizontal: 8.w, vertical: 3.h), // Reduced vertical padding
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
                    fontSize: 13.sp,
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
                    size: 14.sp,
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 2.h), // Reduced spacing
          widget.isLoading
              ? Shimmer.fromColors(
                  baseColor: Colors.red.withOpacity(0.3),
                  highlightColor: Colors.red.withOpacity(0.7),
                  child: Text(
                    '---',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 50.sp,
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
                        // Fixed width container to prevent shaking
                        SizedBox(
                          width: 140.w, // Fixed width for number
                          child: Align(
                            alignment: Alignment
                                .centerLeft, // Push number towards 'MW'
                            child: Text(
                              value.toStringAsFixed(0),
                              style: TextStyle(
                                color: Colors.redAccent, // Red Color
                                fontSize: 50.sp,
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
                      fontSize: 10.sp,
                      fontFamily: Appfontstring.ChangaLight,
                    ),
                  ),
                  TextSpan(
                    text: maxLoadInLastHour.toStringAsFixed(0),
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 15.sp,
                      fontFamily: Appfontstring.ChangaLight,
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
// SHIMMER LOADING SKELETON
// ============================================================================

class ShimmerLoadingGrid extends StatelessWidget {
  const ShimmerLoadingGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 8,
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.white.withOpacity(0.05),
          highlightColor: Colors.white.withOpacity(0.15),
          child: Container(
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
                  width: 100.w,
                  height: 14.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                ),
                SizedBox(height: 5.h),
                Container(
                  width: 65.w,
                  height: 20.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// STATION CARD WIDGET WITH ANIMATIONS
// ============================================================================

class StationCard extends StatefulWidget {
  final int index;
  final StationLoad station;
  final bool isUserAssigned;
  final bool canEdit;
  final VoidCallback onEditTap;

  const StationCard({
    super.key,
    required this.index,
    required this.station,
    required this.isUserAssigned,
    required this.canEdit,
    required this.onEditTap,
    this.isUpdatedRecently = false,
  });

  final bool isUpdatedRecently;

  @override
  State<StationCard> createState() => _StationCardState();
}

class _StationCardState extends State<StationCard> {
  @override
  Widget build(BuildContext context) {
    final showUpdateButton =
        widget.station.load >= 0 && widget.station.load <= _maxStationLoad;

    return RepaintBoundary(
      child: Container(
        margin: EdgeInsets.symmetric(
            horizontal: 2.w, vertical: 2.h), // Minimal margin
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              widget.isUserAssigned
                  ? Colors.orange.withOpacity(0.12)
                  : Colors.white.withOpacity(0.08),
              widget.isUserAssigned
                  ? Colors.orange.withOpacity(0.05)
                  : Colors.white.withOpacity(0.03),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: widget.isUserAssigned
                ? Colors.orangeAccent.withOpacity(0.3)
                : Colors.white.withOpacity(0.15),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.isUserAssigned
                  ? Colors.orange.withOpacity(0.1)
                  : Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Station Number Badge
            Container(
              width: 26.w, // Smaller badge
              height: 26.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: widget.isUpdatedRecently
                      ? [Colors.greenAccent, Colors.green]
                      : widget.isUserAssigned
                          ? [Colors.orangeAccent, Colors.orange]
                          : [
                              Colors.blueAccent.withOpacity(0.6),
                              Colors.blue.withOpacity(0.4)
                            ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.isUpdatedRecently
                        ? Colors.green.withOpacity(0.3)
                        : widget.isUserAssigned
                            ? Colors.orange.withOpacity(0.3)
                            : Colors.blue.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '${widget.index + 1}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: Appfontstring.ChangaLight,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),

            // Station Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.station.stationName,
                    style: TextStyle(
                      fontSize: widget.isUserAssigned ? 13.sp : 12.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: Appfontstring.ChangaLight,
                      color: widget.isUserAssigned
                          ? Colors.orangeAccent
                          : Colors.white.withOpacity(0.9),
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  SizedBox(height: 4.h),

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
                                fontSize: 17.sp,
                                fontWeight: FontWeight.bold,
                                fontFamily: Appfontstring.digital,
                                color: widget.isUserAssigned
                                    ? Colors.orangeAccent
                                    : Colors.greenAccent,
                              ),
                            ),
                            TextSpan(
                              text: ' م.و',
                              style: TextStyle(
                                fontSize: 10.sp,
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

            // Edit Button
            if (showUpdateButton)
              CustomActionButton(
                onPressed: widget.onEditTap,
                icon: Icons.edit_outlined,
                isHighlighted: widget.isUserAssigned,
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// CUSTOM ACTION BUTTON
// ============================================================================

class CustomActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final bool isHighlighted;

  const CustomActionButton({
    super.key,
    required this.onPressed,
    this.icon = Icons.settings,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isHighlighted
                  ? [Colors.orangeAccent, Colors.orange]
                  : [
                      const Color.fromARGB(255, 228, 178, 124),
                      const Color.fromARGB(255, 200, 150, 100)
                    ],
            ),
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: isHighlighted
                    ? Colors.orange.withOpacity(0.3)
                    : Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 18.sp,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// ERROR RETRY WIDGET
// ============================================================================

class ErrorRetryWidget extends StatelessWidget {
  final String errorMessage;
  final int retryCountdown;
  final VoidCallback onRetry;
  final bool hasCachedData;
  final VoidCallback? onUseCached;

  const ErrorRetryWidget({
    super.key,
    required this.errorMessage,
    required this.retryCountdown,
    required this.onRetry,
    this.hasCachedData = false,
    this.onUseCached,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.withOpacity(0.1),
            Colors.red.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.redAccent.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.redAccent,
            size: 40.sp,
          ),
          SizedBox(height: 12.h),
          Text(
            errorMessage,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontSize: 14.sp,
              fontFamily: Appfontstring.ChangaLight,
              color: Colors.white.withOpacity(0.9),
              height: 1.5,
            ),
          ),
          if (retryCountdown > 0) ...[
            SizedBox(height: 16.h),
            Text(
              'المحاولة التالية خلال: $retryCountdown ثانية',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: 14.sp,
                fontFamily: Appfontstring.ChangaLight,
                color: Colors.white60,
              ),
            ),
          ],
          SizedBox(height: 16.h),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: Text(
              'إعادة المحاولة الآن',
              style: TextStyle(
                fontSize: 15.sp,
                fontFamily: Appfontstring.ChangaLight,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
          if (hasCachedData && onUseCached != null) ...[
            SizedBox(height: 12.h),
            TextButton.icon(
              onPressed: onUseCached,
              icon: Icon(Icons.offline_bolt,
                  color: Colors.orangeAccent, size: 20.sp),
              label: Text(
                'استخدام البيانات المحفوظة',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontFamily: Appfontstring.ChangaLight,
                  color: Colors.orangeAccent,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// MAIN SCREEN WITH GETX
// ============================================================================

class StationloadnavScreen extends StatelessWidget {
  const StationloadnavScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize controller
    final controller = Get.put(StationLoadController());

    return WillPopScope(
      onWillPop: () async => false,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          extendBodyBehindAppBar: true,
          // floatingActionButton removed as per request for pull-to-refresh
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
            child: Obx(() {
              // Error State
              if (controller.hasError.value &&
                  controller.stationLoads.isEmpty) {
                return Center(
                  child: ErrorRetryWidget(
                    errorMessage: controller.errorMessage.value,
                    retryCountdown: controller.retryCountdown.value,
                    onRetry: () => controller.fetchData(),
                  ),
                );
              }

              // Main Content
              // Main Content
              return RefreshIndicator(
                color: Colors.orangeAccent,
                backgroundColor: Colors.white,
                onRefresh: () async {
                  await controller.fetchData();
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics()),
                  slivers: [
                    // Total Load Display
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          Obx(
                            () => LoadDisplayWidget(
                              totalLoad: controller.totalLoad,
                              isLoading: controller.isLoading.value,
                              isFromCache: controller.isFromCache.value,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(bottom: 10.h),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.keyboard_arrow_down,
                                    color: Colors.white54, size: 14.sp),
                                SizedBox(width: 4.w),
                                Text(
                                  "اسحب الشاشة لاسفل للتحديث",
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 10.sp,
                                    fontFamily: Appfontstring.ChangaLight,
                                  ),
                                ),
                                SizedBox(width: 4.w),
                                Icon(Icons.keyboard_arrow_down,
                                    color: Colors.white54, size: 14.sp),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Loading State or Station Cards
                    Obx(() {
                      if (controller.isLoading.value &&
                          controller.stationLoads.isEmpty) {
                        return const SliverToBoxAdapter(
                          child: ShimmerLoadingGrid(),
                        );
                      }

                      return SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio:
                              3.5, // Increased ratio to reduce height further
                          crossAxisSpacing: 2.w, // Minimized horizontal spacing
                          mainAxisSpacing: 2.h, // Minimized vertical spacing
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final station = controller.stationLoads[index];
                            final isUserAssigned = controller
                                .isUserAssignedToStation(station.stationName);
                            final canEdit =
                                controller.canEditStation(station.stationName);

                            return StationCard(
                              index: index,
                              station: station,
                              isUserAssigned: isUserAssigned,
                              canEdit: canEdit,
                              isUpdatedRecently: controller
                                  .wasUpdatedThisHour(station.stationName),
                              onEditTap: () =>
                                  _handleStationEdit(context, station, canEdit),
                            );
                          },
                          childCount: controller.stationLoads.length,
                        ),
                      );
                    }),

                    // Bottom Padding
                    SliverToBoxAdapter(
                      child: SizedBox(height: 60.h),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  void _handleStationEdit(
      BuildContext context, StationLoad station, bool canEdit) {
    if (!canEdit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'غير مصرح لك بتحديث بيانات المحطة',
            textDirection: TextDirection.rtl,
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => StationDialog(station: station),
    );
  }
}

// ============================================================================
// STATION EDIT DIALOG
// ============================================================================

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
    if (newLoad == null || newLoad < 0 || newLoad > _maxStationLoad) {
      setState(() {
        _errorText = 'يرجى إدخال قيمة صحيحة بين 0 و $_maxStationLoad';
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
                color: Colors.white.withOpacity(0.1),
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
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
                errorText: _errorText,
                errorMaxLines: 2,
                errorStyle: TextStyle(
                  fontFamily: Appfontstring.ChangaLight,
                  fontSize: 12.sp,
                ),
              ),
              textDirection: TextDirection.ltr,
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
            Expanded(
              child: ElevatedButton(
                onPressed: (_errorText != null || _isUpdating)
                    ? null
                    : _validateAndUpdate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey,
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
                    : Text(
                        'تحديث',
                        style: TextStyle(
                          fontFamily: Appfontstring.ChangaLight,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                child: Text(
                  'إلغاء',
                  style: TextStyle(
                    color: Colors.red,
                    fontFamily: Appfontstring.ChangaLight,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

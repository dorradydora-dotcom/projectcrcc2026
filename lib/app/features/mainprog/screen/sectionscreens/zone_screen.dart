import 'package:amiraly/app/features/mainprog/screen/sectionscreens/zone_controller.dart';
import 'package:amiraly/app/util/constant/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shimmer/shimmer.dart';

class ZoneScreen extends StatefulWidget {
  final String zoneName;
  final String displayName;

  const ZoneScreen({
    super.key,
    required this.zoneName,
    required this.displayName,
  });

  @override
  State<ZoneScreen> createState() => _ZoneScreenState();
}

class _ZoneScreenState extends State<ZoneScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  late final ZoneController _controller;
  final TransformationController _transformationController =
      TransformationController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(ZoneController());
    _controller.fetchZonePhoto(widget.zoneName);
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _zoomController?.dispose();
    super.dispose();
  }

  AnimationController? _zoomController;
  TapDownDetails? _doubleTapDetails;

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap() {
    final position = _doubleTapDetails!.localPosition;
    // Current scale
    final double scale = _transformationController.value.getMaxScaleOnAxis();

    // Target scale
    double targetScale = 3.0;
    if (scale >= 3.0) {
      targetScale = 1.0;
    }

    final Matrix4 endMatrix = Matrix4.identity();
    endMatrix.setTranslationRaw(-position.dx * (targetScale - 1),
        -position.dy * (targetScale - 1), 0.0);
    endMatrix.setEntry(0, 0, targetScale);
    endMatrix.setEntry(1, 1, targetScale);
    endMatrix.setEntry(2, 2, 1.0);

    _animateToMatrix(endMatrix);
  }

  void _resetZoom() {
    _animateToMatrix(Matrix4.identity());
  }

  void _animateToMatrix(Matrix4 endMatrix) {
    _zoomController?.dispose();
    _zoomController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));

    final animation = Matrix4Tween(
      begin: _transformationController.value,
      end: endMatrix,
    ).animate(CurvedAnimation(
      parent: _zoomController!,
      curve: Curves.easeInOut,
    ));

    animation.addListener(() {
      _transformationController.value = animation.value;
    });

    _zoomController!.forward();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Container(
      color: const Color(0xFF0F172A),
      child: Stack(
        children: [
          // Background Gradient to add depth
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.5,
                  colors: [
                    const Color(0xFF1E293B),
                    const Color(0xFF0F172A),
                  ],
                ),
              ),
            ),
          ),
          // Background Image with InteractiveViewer wrapped in GestureDetector for double tap
          GestureDetector(
            onDoubleTapDown: (details) => _handleDoubleTapDown(details),
            onDoubleTap: _handleDoubleTap,
            child: InteractiveViewer(
              transformationController: _transformationController,
              panEnabled: true,
              scaleEnabled: true,
              boundaryMargin: const EdgeInsets.all(
                  500), // Increased margin for better panning
              minScale: 0.5,
              maxScale: 10.0, // Increased max scale
              child: Center(
                child: Obx(() {
                  final isLoading = _controller.isLoading[widget.zoneName] ??
                      (_controller.zonePhotos[widget.zoneName] == null);
                  final error = _controller.zoneErrors[widget.zoneName];
                  final photoUrl = _controller.zonePhotos[widget.zoneName];

                  if (isLoading && (photoUrl == null || photoUrl.isEmpty)) {
                    return _buildShimmer();
                  }

                  if (error != null && (photoUrl == null || photoUrl.isEmpty)) {
                    return _buildErrorState(error);
                  }

                  if (photoUrl == null || photoUrl.isEmpty) {
                    return _buildEmptyState();
                  }

                  return CachedNetworkImage(
                    imageUrl: photoUrl,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => _buildShimmer(),
                    errorWidget: (context, url, error) =>
                        _buildErrorState(error.toString()),
                    fadeInDuration: const Duration(milliseconds: 400),
                  );
                }),
              ),
            ),
          ),

          // Floating Reset Button (appears when zoomed)
          Positioned(
            bottom: 90.h,
            right: 24.w,
            child: ValueListenableBuilder<Matrix4>(
              valueListenable: _transformationController,
              builder: (context, value, child) {
                final scale = value.storage[0];
                if (scale <= 1.05) {
                  return const SizedBox.shrink();
                }

                return FloatingActionButton.small(
                  heroTag: 'reset_zoom_${widget.zoneName}',
                  backgroundColor:
                      Appcolors.primaryColor.withValues(alpha: 0.9),
                  elevation: 6,
                  onPressed: _resetZoom,
                  child: const Icon(Iconsax.refresh, color: Colors.white),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[850]!,
      highlightColor: Colors.grey[700]!,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.danger, color: Appcolors.errorColor, size: 80.sp),
            SizedBox(height: 20.h),
            Text(
              'فشل تحميل الخريطة',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                fontFamily: Appfontstring.ChangaLight,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14.sp,
                fontFamily: Appfontstring.ChangaLight,
              ),
            ),
            SizedBox(height: 32.h),
            ElevatedButton.icon(
              onPressed: () => _controller.fetchZonePhoto(widget.zoneName),
              icon: const Icon(Iconsax.refresh, color: Colors.white),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Appcolors.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Iconsax.image,
            color: Colors.white.withValues(alpha: 0.3),
            size: 120.sp,
          ),
          SizedBox(height: 24.h),
          Text(
            '${widget.displayName}\n(لا توجد خريطة متوفرة حالياً)',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18.sp,
              height: 1.4,
              fontFamily: Appfontstring.ChangaLight,
            ),
          ),
        ],
      ),
    );
  }
}

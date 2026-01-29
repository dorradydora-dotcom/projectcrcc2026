import 'package:amiraly/E-commerce_project/features/mainprog/screen/sectionscreens/zone_controller.dart';
import 'package:amiraly/E-commerce_project/util/constant/constants.dart';
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
    with AutomaticKeepAliveClientMixin {
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
    super.dispose();
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
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
          // Background Image with InteractiveViewer
          InteractiveViewer(
            transformationController: _transformationController,
            panEnabled: true,
            scaleEnabled: true,
            boundaryMargin: const EdgeInsets.all(100),
            minScale: 0.6,
            maxScale: 4.5,
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

          // Floating Reset Button (appears when zoomed)
          Positioned(
            bottom: 90.h,
            right: 24.w,
            child: ValueListenableBuilder<Matrix4>(
              valueListenable: _transformationController,
              builder: (context, value, child) {
                final scale = value.storage[0];
                if (scale <= 1.05) return const SizedBox.shrink();

                return FloatingActionButton.small(
                  heroTag: 'reset_zoom_${widget.zoneName}',
                  backgroundColor: Appcolors.primaryColor.withOpacity(0.9),
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
            color: Colors.white.withOpacity(0.3),
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

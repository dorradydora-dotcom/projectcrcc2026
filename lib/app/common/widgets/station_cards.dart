import 'dart:ui';
import 'package:amiraly/app/common/models/appmodels.dart';
import 'package:amiraly/app/features/mainprog/screen/navscreens/favorites_controller.dart';
import 'package:amiraly/app/util/constant/constants.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class VerticalStationCard extends StatelessWidget {
  const VerticalStationCard({
    super.key,
    required this.station,
    required this.onTap,
  });

  final StationDetialesModel station;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FadeInRight(
      duration: const Duration(milliseconds: 500),
      child: Container(
        width: 155.w,
        margin: EdgeInsets.symmetric(vertical: 4.h, horizontal: 4.w),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: -8,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Stack(
              children: [
                // Main Card Tap Area
                GestureDetector(
                  onTap: onTap,
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Image Section
                      Expanded(
                        flex: 11,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: HeaderVerticalProduct(station: station),
                            ),
                            // Soft Overlay Gradient
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.5),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Status Badge
                            Positioned(
                              top: 12.h,
                              left: 12.w,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 5.w, vertical: 3.h),
                                decoration: BoxDecoration(
                                  color: (station.image.isNotEmpty
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFF59E0B))
                                      .withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Text(
                                  station.image.isNotEmpty ? 'نشطة' : 'صيانة',
                                  style: TextStyle(
                                    fontSize: 8.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Content Section
                      Expanded(
                        flex: 6,
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 4.h),
                          child: BodyVerticalProduct(station: station),
                        ),
                      ),
                    ],
                  ),
                ),
                // Independent Heart Button Area
                Positioned(
                  top: 1.h,
                  right: 1.w,
                  child: HeartVContainer(station: station),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HeaderVerticalProduct extends StatelessWidget {
  const HeaderVerticalProduct({super.key, required this.station});

  final StationDetialesModel station;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18.r),
        child: CachedNetworkImage(
          imageUrl: station.image.isNotEmpty
              ? station.image
              : 'https://via.placeholder.com/150',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorWidget: (context, url, error) => Container(
            color: Colors.white.withOpacity(0.05),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image_not_supported_outlined,
                    color: Colors.white24, size: 24.sp),
                SizedBox(height: 4.h),
                Text(
                  'خطأ في التحميل',
                  style: TextStyle(
                      color: Colors.white24,
                      fontSize: 8.sp,
                      fontFamily: Appfontstring.ChangaLight),
                ),
              ],
            ),
          ),
          placeholder: (context, url) => Container(
            color: Colors.white.withOpacity(0.05),
            child: Center(
                child: CircularProgressIndicator(
              strokeWidth: 2.sp,
              color: Colors.white24,
            )),
          ),
        ),
      ),
    );
  }
}

class HeartVContainer extends StatelessWidget {
  const HeartVContainer({super.key, required this.station});

  final StationDetialesModel station;

  @override
  Widget build(BuildContext context) {
    final favoritesController = Get.find<FavoritesController>();
    return Obx(
      () => IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        onPressed: () => favoritesController.toggleFavorite(station),
        icon: Icon(
          favoritesController.isFavorite(station)
              ? Iconsax.heart5
              : Iconsax.heart,
          key: ValueKey(favoritesController.isFavorite(station)),
          color: Colors.redAccent,
          size: 18.sp,
        ),
      ),
    );
  }
}

class BodyVerticalProduct extends StatelessWidget {
  const BodyVerticalProduct({super.key, required this.station});

  final StationDetialesModel station;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        TxtName(station: station),
        SizedBox(height: 6.h),
        TxtDescription(station: station),
      ],
    );
  }
}

class TxtName extends StatelessWidget {
  const TxtName({super.key, required this.station});

  final StationDetialesModel station;

  @override
  Widget build(BuildContext context) {
    return Text(
      station.name,
      style: TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w700,
        color: Colors.white.withOpacity(0.95),
        fontFamily: Appfontstring.ChangaLight,
        letterSpacing: 0.3,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.right,
    );
  }
}

class TxtDescription extends StatelessWidget {
  const TxtDescription({super.key, required this.station});

  final StationDetialesModel station;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Iconsax.location, color: const Color(0xFF0ED2D2), size: 10.sp),
        SizedBox(width: 4.w),
        Flexible(
          child: Text(
            station.zone,
            style: TextStyle(
              fontSize: 10.sp,
              fontFamily: Appfontstring.ChangaLight,
              color: Colors.white.withOpacity(0.55),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

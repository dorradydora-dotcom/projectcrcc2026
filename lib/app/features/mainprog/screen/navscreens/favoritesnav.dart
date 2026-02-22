import 'package:amiraly/app/common/widgets/station_cards.dart';
import 'package:amiraly/app/features/mainprog/screen/navscreens/favorites_controller.dart';
import 'package:amiraly/app/features/mainprog/screen/stationdetailes/stationdetailes.dart';
import 'package:amiraly/app/util/constant/constants.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class FavoritesNav extends StatelessWidget {
  const FavoritesNav({super.key});

  @override
  Widget build(BuildContext context) {
    final favoritesController = Get.put(FavoritesController());
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Stack(
          children: [
            // Background Elements
            Positioned(
              top: -50.h,
              right: -30.w,
              child: Icon(Iconsax.heart5,
                  size: 200.sp, color: Colors.white.withOpacity(0.04)),
            ),
            Obx(
              () => Directionality(
                textDirection: TextDirection.rtl,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    buildSliverAppBar(favoritesController),
                    if (favoritesController.favorites.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyState(context),
                      )
                    else ...[
                      _buildGridLayout(context, favoritesController),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSliverAppBar(FavoritesController controller) {
    return SliverAppBar(
      expandedHeight: 140.h,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF0F172A),
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Glassy Background
            Container(
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
            ),
            Positioned(
              bottom: 20.h,
              left: 20.w,
              right: 20.w,
              child: FadeInDown(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المفضلات',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24.sp,
                        fontFamily: Appfontstring.ChangaLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20.r),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${controller.favorites.length} محطة محفوظة',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.white70,
                              fontFamily: Appfontstring.ChangaLight,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Icon(Iconsax.heart5,
                              color: Colors.redAccent, size: 14.sp),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w),
        child: FadeInUp(
          child: Container(
            padding: EdgeInsets.all(30.r),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(30.r),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Iconsax.heart,
                        size: 80.sp, color: Colors.white.withOpacity(0.05)),
                    Icon(Iconsax.heart5, size: 50.sp, color: Colors.white12),
                  ],
                ),
                SizedBox(height: 24.h),
                Text(
                  'قائمة المفضلات فارغة',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontFamily: Appfontstring.ChangaLight,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  'أضف محطاتك المفضلة لتتمكن من الوصول إليها بسرعة من هنا في أي وقت.',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontFamily: Appfontstring.ChangaLight,
                    color: Colors.white54,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridLayout(
    BuildContext context,
    FavoritesController controller,
  ) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 30.h),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10.h,
          crossAxisSpacing: 10.w,
          childAspectRatio: 0.82,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final delay = (index * 80).clamp(0, 500);
            return FadeInUp(
              delay: Duration(milliseconds: delay),
              child: VerticalStationCard(
                station: controller.favorites[index],
                onTap: () => Get.to(
                  () => StationDetailsPage(
                    station: controller.favorites[index],
                  ),
                ),
              ),
            );
          },
          childCount: controller.favorites.length,
        ),
      ),
    );
  }
}

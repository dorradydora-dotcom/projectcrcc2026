import 'package:amiraly/E-commerce_project/features/mainprog/screen/sectionscreens/northscreen.dart';
import 'package:amiraly/E-commerce_project/features/mainprog/screen/sectionscreens/eastscreen.dart';
import 'package:amiraly/E-commerce_project/features/mainprog/screen/sectionscreens/southscreen.dart';
import 'package:amiraly/E-commerce_project/features/mainprog/screen/sectionscreens/westscreen.dart';
import 'package:amiraly/E-commerce_project/features/mainprog/screen/stationdetailes/stationdetailes.dart';
import 'package:amiraly/E-commerce_project/util/constant/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:ui';
import 'package:amiraly/E-commerce_project/features/mainprog/screen/navscreens/areanav_controller.dart';
import 'package:animate_do/animate_do.dart';
import 'package:amiraly/E-commerce_project/common/widgets/station_cards.dart';

class Areanav extends StatefulWidget {
  const Areanav({super.key});

  @override
  State<Areanav> createState() => _AreanavState();
}

class _AreanavState extends State<Areanav> {
  @override
  void initState() {
    super.initState();
    Get.put(AreaNavController(), permanent: true);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: DefaultTabController(
        length: 4,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            floatingActionButton: SizedBox(
                height: 38.h,
                width: 38.w,
                child: FloatingActionButton(
                    onPressed: () => Get.find<AreaNavController>()
                        .fetchStations(refresh: true),
                    backgroundColor: const Color.fromARGB(109, 3, 218, 197),
                    child: const Icon(Icons.refresh,
                        color: Colors.white, size: 19))),
            body: NestedScrollView(
              headerSliverBuilder: (_, innerBoxIsScrolled) => [
                buildSliverAppBar(),
              ],
              body: const TabBarView(
                children: [
                  NorthScreen(),
                  EastScreen(),
                  SouthScreen(),
                  WestScreen(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  SliverAppBar buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 0.55 * ScreenUtil().screenHeight,
      floating: false,
      pinned: true,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: buildFlexibleSpace(),
      bottom: buildTabBar(),
    );
  }

  Widget buildFlexibleSpace() {
    return FlexibleSpaceBar(
      background: Container(
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
        child: Stack(
          children: [
            Positioned(
              left: -20.w,
              bottom: 80.h,
              child: Icon(Iconsax.flash5,
                  size: 120.sp, color: Colors.white.withOpacity(0.04)),
            ),
            Column(children: [
              SizedBox(height: 15.h), // Reduced margin
              FadeInDown(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                  child: buildDashboardSummary(),
                ),
              ),
              SizedBox(height: 5.h), // Reduced spacing
              // Search Bar
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: buildSearchBar(),
                ),
              ),
              SizedBox(height: 12.h), // Reduced spacing
              // Horizontal List Header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Scroll Indicator (Animated Arrow)
                    FadeInLeft(
                      delay: const Duration(milliseconds: 800),
                      child: Row(
                        children: [
                          Icon(Iconsax.arrow_left_2,
                              color: const Color(0xFF0ED2D2), size: 14.sp),
                          SizedBox(width: 4.w),
                          Text(
                            'اسحب لرؤية المزيد',
                            style: TextStyle(
                              fontFamily: Appfontstring.ChangaLight,
                              fontSize: 9.sp,
                              color: Colors.white.withOpacity(0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    FadeInLeft(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 9.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          'أحدث المحطات المضافة',
                          style: TextStyle(
                            fontFamily: Appfontstring.ChangaLight,
                            fontSize: 10.sp, // Reduced font size
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 2.h), // Reduced spacing
              buildStationContent()
            ]),
          ],
        ),
      ),
    );
  }

  Widget buildSearchBar() {
    final controller = Get.find<AreaNavController>();
    return Container(
      height: 54.h,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: TextField(
            onChanged: (value) => controller.searchQuery.value = value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontFamily: Appfontstring.ChangaLight,
            ),
            decoration: InputDecoration(
              hintText: 'ابحث عن محطة أو منطقة...',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.25),
                fontSize: 13.sp,
                fontFamily: Appfontstring.ChangaLight,
              ),
              prefixIcon: Container(
                padding: EdgeInsets.all(12.r),
                child: Icon(Iconsax.search_normal,
                    color: const Color(0xFF0ED2D2), size: 22.sp),
              ),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildDashboardSummary() {
    final controller = Get.find<AreaNavController>();
    return Obx(() => Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(28.r),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 25,
                spreadRadius: -8,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                        'الإجمالي',
                        controller.totalStations.toString(),
                        Iconsax.buildings,
                        const Color(0xFF60A5FA)),
                    _buildVerticalDivider(),
                    _buildStatItem('نشطة', controller.activeStations.toString(),
                        Iconsax.flash, const Color(0xFF34D399)),
                    _buildVerticalDivider(),
                    _buildStatItem(
                        'صيانة',
                        controller.maintenanceStations.toString(),
                        Iconsax.setting_2,
                        const Color(0xFFFBBF24)),
                  ],
                ),
              ),
            ),
          ),
        ));
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 30.h,
      width: 1,
      color: Colors.white.withOpacity(0.1),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16.sp),
          ),
          SizedBox(height: 7.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: Appfontstring.ChangaLight,
              letterSpacing: 1,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 8.sp,
              color: Colors.white.withOpacity(0.65),
              fontFamily: Appfontstring.ChangaLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildStationContent() {
    return Obx(() {
      final controller = Get.find<AreaNavController>();
      if (controller.isLoading.value) {
        return Center(
            child: CircularProgressIndicator(
                strokeWidth: 2.sp, color: Colors.white70));
      }

      final filteredList = controller.filteredStations;

      if (filteredList.isEmpty) {
        return Center(
          child: Text(
            'لا توجد نتائج للبحث',
            style: TextStyle(
                fontSize: 14.sp,
                color: Colors.white54,
                fontFamily: Appfontstring.ChangaLight),
          ),
        );
      }
      return SizedBox(
        height: 170.h,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 3.w),
          itemCount: filteredList.length,
          itemBuilder: (context, index) {
            final station = filteredList[index];
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 3.w),
              child: VerticalStationCard(
                station: station,
                onTap: () {
                  Get.to(() => StationDetailsPage(station: station));
                },
              ),
            );
          },
        ),
      );
    });
  }

  PreferredSizeWidget buildTabBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(36.h),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: TabBar(
          labelStyle: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.bold,
            fontFamily: Appfontstring.ChangaLight,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 10.sp,
            fontFamily: Appfontstring.ChangaLight,
          ),
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            gradient: LinearGradient(
              colors: [
                const Color(0xFF0ED2D2).withOpacity(0.8),
                const Color(0xFF1E293B).withOpacity(0.4),
              ],
            ),
          ),
          dividerColor: Colors.transparent,
          isScrollable: false,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(text: 'الشمالية'),
            Tab(text: 'الشرقية'),
            Tab(text: 'الجنوبية'),
            Tab(text: 'الغربية'),
          ],
        ),
      ),
    );
  }
}

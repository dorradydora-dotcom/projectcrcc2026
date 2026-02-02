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
  late final AreaNavController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(AreaNavController(), permanent: true);
  }

  @override
  void dispose() {
    super.dispose();
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
            backgroundColor: const Color(0xFF0F172A),
            floatingActionButton: SizedBox(
                height: 38.h,
                width: 38.w,
                child: FloatingActionButton(
                    heroTag: 'area_refresh_fab',
                    onPressed: () => Get.find<AreaNavController>()
                        .fetchStations(refresh: true),
                    backgroundColor: const Color.fromARGB(109, 3, 218, 197),
                    child: const Icon(Icons.refresh,
                        color: Colors.white, size: 19))),
            body: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                buildSliverAppBar(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 15.h, 16.w, 5.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [_buildSectionLabel('المناطـق')],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                  sliver: _buildSectionGrid(),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(height: 10.h),
                ),
              ],
              body: Obx(() {
                final index = _controller.selectedIndex.value;
                return Container(
                  color: const Color(0xFF0F172A),
                  child: FadeInUp(
                    key: ValueKey(index),
                    duration: const Duration(milliseconds: 400),
                    child: _buildActiveSection(index),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  SliverAppBar buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 0.39 * ScreenUtil().screenHeight,
      floating: false,
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: const Color(0xFF0F172A),
      automaticallyImplyLeading: false,
      flexibleSpace: buildFlexibleSpace(),
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
              Color(0xFF0F172A),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // Floating background icons for depth
            Positioned(
              left: -10.w,
              top: 50.h,
              child: FadeInLeft(
                duration: const Duration(seconds: 2),
                child: Icon(Iconsax.flash5,
                    size: 140.sp, color: Colors.white.withOpacity(0.03)),
              ),
            ),
            Positioned(
              right: 20.w,
              bottom: 100.h,
              child: FadeInRight(
                duration: const Duration(seconds: 3),
                child: Icon(Iconsax.building_35,
                    size: 80.sp, color: Colors.white.withOpacity(0.02)),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  SizedBox(height: 12.h),
                  // Dashboard
                  FadeInDown(
                    duration: const Duration(milliseconds: 800),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: buildDashboardSummary(),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  // Search Section
                  FadeInUp(
                    delay: const Duration(milliseconds: 200),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Row(
                        children: [
                          Expanded(child: buildSearchBar()),
                          SizedBox(width: 10.w),
                          _buildFilterButton(),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  // Auto-scrolling Ticker
                  buildStationContent(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return FadeInLeft(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: const Color(0xFF0ED2D2).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: const Color(0xFF0ED2D2).withOpacity(0.2)),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: Appfontstring.ChangaLight,
            fontSize: 10.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0ED2D2),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton() {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.white.withOpacity(0.1))),
      child: Icon(Iconsax.filter_edit,
          color: const Color(0xFF0ED2D2), size: 20.sp),
    );
  }

  Widget buildSearchBar() {
    final controller = Get.find<AreaNavController>();
    return Container(
      height: 48.h, // Slightly more compact
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: TextField(
            onChanged: (value) => controller.searchQuery.value = value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13.sp,
              fontFamily: Appfontstring.ChangaLight,
            ),
            decoration: InputDecoration(
              hintText: 'ابحث عن محطة...',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.2),
                fontSize: 12.sp,
                fontFamily: Appfontstring.ChangaLight,
              ),
              prefixIcon: Icon(Iconsax.search_normal_1,
                  color: const Color(0xFF0ED2D2).withOpacity(0.8), size: 18.sp),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 12.h),
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
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                child: Row(
                  children: [
                    _buildStatBlock(
                      'الإجمالي',
                      controller.totalStations.toString(),
                      Iconsax.buildings,
                      const Color(0xFF60A5FA),
                    ),
                    _buildLiteDivider(),
                    _buildStatBlock(
                      'نشـطة',
                      controller.activeStations.toString(),
                      Iconsax.flash,
                      const Color(0xFF34D399),
                    ),
                    _buildLiteDivider(),
                    _buildStatBlock(
                      'صـيانة',
                      controller.maintenanceStations.toString(),
                      Iconsax.setting_2,
                      const Color(0xFFFBBF24),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ));
  }

  Widget _buildLiteDivider() {
    return Container(
      height: 25.h,
      width: 1,
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      color: Colors.white.withOpacity(0.1),
    );
  }

  Widget _buildStatBlock(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 13.sp),
              SizedBox(width: 6.w),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: Appfontstring.BebasNeue_Regular,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 8.sp,
              color: Colors.white.withOpacity(0.4),
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
      if (_controller.isLoading.value) {
        return Center(
            child: CircularProgressIndicator(
                strokeWidth: 2.sp, color: Colors.white70));
      }

      final filteredList = _controller.filteredStations;

      if (_controller.hasNoSearchResults) {
        return _buildEmptySearchState();
      }

      if (filteredList.isEmpty && !_controller.isSearchActive) {
        return const SizedBox.shrink();
      }

      return SizedBox(
        height: 145.h,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 2.w),
          itemCount: filteredList.length,
          itemBuilder: (context, index) {
            final station = filteredList[index];
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 2.w),
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

  Widget _buildEmptySearchState() {
    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Container(
        height: 145.h,
        margin: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.search_status,
                size: 40.sp, color: Colors.white.withOpacity(0.15)),
            SizedBox(height: 12.h),
            Text(
              'لا يوجد نتائج للبحث',
              style: TextStyle(
                fontFamily: Appfontstring.ChangaLight,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'جرب البحث بكلمات أخرى أو مناطق مختلفة',
              style: TextStyle(
                fontFamily: Appfontstring.ChangaLight,
                fontSize: 10.sp,
                color: Colors.white38,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionGrid() {
    final sections = [
      {
        'name': 'الشمالية',
        'icon': Iconsax.gps,
        'color': const Color(0xFF60A5FA)
      },
      {
        'name': 'الشرقية',
        'icon': Iconsax.direct_right,
        'color': const Color(0xFF34D399)
      },
      {
        'name': 'الجنوبية',
        'icon': Iconsax.location,
        'color': const Color(0xFFFBBF24)
      },
      {
        'name': 'الغربية',
        'icon': Iconsax.direct_left,
        'color': const Color(0xFFF87171)
      },
    ];

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8.h,
        crossAxisSpacing: 8.w,
        childAspectRatio: 0.9,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return Obx(() {
            final isSelected = _controller.selectedIndex.value == index;
            final section = sections[index];
            return GestureDetector(
              onTap: () => _controller.selectedIndex.value = index,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (section['color'] as Color).withOpacity(0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isSelected
                        ? (section['color'] as Color).withOpacity(0.4)
                        : Colors.white.withOpacity(0.06),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      section['icon'] as IconData,
                      color: isSelected
                          ? (section['color'] as Color)
                          : Colors.white30,
                      size: 16.sp,
                    ),
                    SizedBox(height: 4.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2.w),
                      child: SizedBox(
                        width: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            section['name'] as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: Appfontstring.ChangaLight,
                              fontSize: 10.sp,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected ? Colors.white : Colors.white54,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          });
        },
        childCount: sections.length,
      ),
    );
  }

  Widget _buildActiveSection(int index) {
    switch (index) {
      case 0:
        return const NorthScreen();
      case 1:
        return const EastScreen();
      case 2:
        return const SouthScreen();
      case 3:
        return const WestScreen();
      default:
        return const SizedBox.shrink();
    }
  }
}

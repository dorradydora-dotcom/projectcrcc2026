import 'package:amiraly/E-commerce_project/common/models/appmodels.dart';
import 'package:amiraly/E-commerce_project/features/mainprog/screen/navscreens/favoritesnav.dart';
import 'package:amiraly/E-commerce_project/features/mainprog/screen/sectionscreens/NonthScreen.dart';
import 'package:amiraly/E-commerce_project/features/mainprog/screen/sectionscreens/eastscreen.dart';
import 'package:amiraly/E-commerce_project/features/mainprog/screen/sectionscreens/southscreen.dart';
import 'package:amiraly/E-commerce_project/features/mainprog/screen/sectionscreens/westscreen.dart';
import 'package:amiraly/E-commerce_project/features/mainprog/screen/stationdetailes/stationdetailes.dart';
import 'package:amiraly/E-commerce_project/util/constant/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class Areanav extends StatefulWidget {
  const Areanav({super.key});

  @override
  State<Areanav> createState() => _AreanavState();
}

class _AreanavState extends State<Areanav> {
  @override
  void initState() {
    super.initState();
    Get.put(AreaNavController());
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
          body: LiquidPullToRefresh(
            height: 2.h,
            showChildOpacityTransition: false,
            onRefresh: () async {
              await Get.find<AreaNavController>().fetchStations();
            },
            child: NestedScrollView(
              headerSliverBuilder: (_, innerBoxIsScrolled) => [
                buildSliverAppBar(),
              ],
              body: const TabBarView(
                children: [
                  NonthScreen(),
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
      expandedHeight: 0.36 * ScreenUtil().screenHeight,
      floating: false,
      pinned: true,
      automaticallyImplyLeading: false,
      flexibleSpace: buildFlexibleSpace(),
      bottom: buildTabBar(),
    );
  }

  Widget buildFlexibleSpace() {
    return FlexibleSpaceBar(
      background: Container(
        padding: EdgeInsets.only(right: 4.w, bottom: 4.h),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Appcolors.primaryColor,
              Color.fromARGB(255, 49, 107, 152),
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'محـطات جهد 220 كف',
              style: TextStyle(
                fontFamily: Appfontstring.ChangaLight,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 11.h),
            buildStationContent(),
          ],
        ),
      ),
    );
  }

  Widget buildStationContent() {
    return Obx(() {
      final controller = Get.find<AreaNavController>();
      if (controller.isLoading.value) {
        return Center(child: CircularProgressIndicator(strokeWidth: 2.sp));
      }
      if (controller.stations.isEmpty) {
        return Text(
          'لا توجد محطات متاحة',
          style: TextStyle(fontSize: 16.sp, color: Colors.grey),
        );
      }
      return SizedBox(
        height: 190.h,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: Row(
            children: controller.stations.map((station) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: VerticalStationCard(
                  station: station,
                  onTap: () {
                    Get.to(() => StationDetailsPage(station: station));
                  },
                ),
              );
            }).toList(),
          ),
        ),
      );
    });
  }

  PreferredSizeWidget buildTabBar() {
    return TabBar(
      labelStyle: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        fontFamily: Appfontstring.ChangaLight,
      ),
      indicatorColor: AreapageColors.kSecondaryColor,
      isScrollable: true,
      labelColor: AreapageColors.kSecondaryColor,
      unselectedLabelColor: AreapageColors.kSubtitleColor,
      tabs: const [
        Tab(text: 'الشمالية'),
        Tab(text: 'الشرقية'),
        Tab(text: 'الجنوبية'),
        Tab(text: 'الغربية'),
      ],
    );
  }
}

class AreaNavController extends GetxController {
  final RxList<StationDetialesModel> stations = <StationDetialesModel>[].obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchStations();
  }

  Future<void> fetchStations() async {
    try {
      isLoading.value = true;
      final response = await Supabase.instance.client
          .from('station_table')
          .select()
          .timeout(const Duration(seconds: 30));

      stations.value = response.map((json) {
        return StationDetialesModel.fromJson(json);
      }).toList();
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في جلب المحطات',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      stations.clear();
    } finally {
      isLoading.value = false;
    }
  }
}

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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 0.38 * ScreenUtil().screenWidth,
        height: 200.h,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 240, 240, 194),
          border: Border.all(color: Colors.black, width: 1.3),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              flex: 3,
              child: HeaderVerticalProduct(station: station),
            ),
            Expanded(
              flex: 1,
              child: BodyVerticalProduct(station: station),
            ),
          ],
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
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: Colors.black, width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14.r), // Consistent radius
            child: Image.network(
              station.image.isNotEmpty
                  ? station.image
                  : 'https://via.placeholder.com/150',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) => Center(
                child: Icon(Icons.error, color: Colors.red, size: 40.sp),
              ),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                    child: CircularProgressIndicator(strokeWidth: 2.sp));
              },
            ),
          ),
        ),
        HeartVContainer(station: station),
      ],
    );
  }
}

class HeartVContainer extends StatelessWidget {
  const HeartVContainer({super.key, required this.station});

  final StationDetialesModel station;

  @override
  Widget build(BuildContext context) {
    final favoritesController = Get.find<FavoritesController>();
    return Positioned(
      top: 0,
      right: 0,
      child: Obx(
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
      ),
    );
  }
}

class BodyVerticalProduct extends StatelessWidget {
  const BodyVerticalProduct({super.key, required this.station});

  final StationDetialesModel station;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          TxtName(station: station),
          SizedBox(height: 4.h),
          TxtDescription(station: station),
        ],
      ),
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
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
        color: Colors.black,
        fontFamily: Appfontstring.ChangaLight,
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
    return Text(
      'المنطقة : ${station.zone}',
      style: TextStyle(
        fontSize: 12.sp,
        fontFamily: Appfontstring.ChangaLight,
        color: AreapageColors.kSubtitleColor.withOpacity(0.7),
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.right,
    );
  }
}

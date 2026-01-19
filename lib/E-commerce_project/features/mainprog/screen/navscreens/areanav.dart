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
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'dart:ui';
import 'package:animate_do/animate_do.dart';

class Areanav extends StatefulWidget {
  const Areanav({super.key});

  @override
  State<Areanav> createState() => _AreanavState();
}

class _AreanavState extends State<Areanav> {
  @override
  void initState() {
    super.initState();
    // استخدام permanent: true لضمان بقاء الـ Controller والبيانات حتى غلق التطبيق
    Get.put(AreaNavController(), permanent: true);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
          floatingActionButton: SizedBox(
            height: 25.h,
            width: 25.w,
            child: FloatingActionButton(
              onPressed: () =>
                  Get.find<AreaNavController>().fetchStations(refresh: true),
              backgroundColor: Appcolors.primaryColor,
              child: const Icon(Icons.refresh, color: Colors.white),
            ),
          ),
          body: NestedScrollView(
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
    );
  }

  SliverAppBar buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 0.60 * ScreenUtil().screenHeight,
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Appcolors.primaryColor,
              Color.fromARGB(255, 30, 80, 120), // أغمق قليلاً للعمق
              Color.fromARGB(255, 10, 30, 50), // نهاية داكنة فخمة
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // Background Pattern (Subtle flashes)
            Positioned(
              right: -20.w,
              top: 50.h,
              child: Icon(Iconsax.flash5,
                  size: 200.sp, color: Colors.white.withOpacity(0.05)),
            ),
            Positioned(
              left: -30.w,
              bottom: 100.h,
              child: Icon(Iconsax.flash5,
                  size: 150.sp, color: Colors.white.withOpacity(0.03)),
            ),
            Column(
              children: [
                SizedBox(height: 66.h), // مسافة علوية أقل قليلاً لتوفير مساحة
                // Dashboard Summary
                FadeInDown(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: buildDashboardSummary(),
                  ),
                ),
                SizedBox(height: 15.h), // تقليل المسافة
                // Search Bar
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: buildSearchBar(),
                  ),
                ),
                SizedBox(height: 16.h),
                // Horizontal List Header
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      FadeInLeft(
                        child: Text(
                          'أحدث المحطات',
                          style: TextStyle(
                            fontFamily: Appfontstring.ChangaLight,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8.h),
                buildStationContent(), // إزالة Expanded لتجنب أخطاء الأبعاد
                SizedBox(height: 10.h),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSearchBar() {
    final controller = Get.find<AreaNavController>();
    return Container(
      height: 45.h,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: TextField(
            onChanged: (value) => controller.searchQuery.value = value,
            textAlign: TextAlign.right,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'ابحث عن محطة أو منطقة...',
              hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.5), fontSize: 12.sp),
              prefixIcon: Icon(Iconsax.search_normal,
                  color: Colors.white.withOpacity(0.7), size: 18.sp),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildDashboardSummary() {
    final controller = Get.find<AreaNavController>();
    return Obx(() => Container(
          padding: EdgeInsets.symmetric(
              horizontal: 12.w, vertical: 14.h), // حواف أكثر رشاقة
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                      'إجمالي المحطات',
                      controller.totalStations.toString(),
                      Iconsax.buildings,
                      Colors.white),
                  _buildStatItem('نشط', controller.activeStations.toString(),
                      Iconsax.flash, Colors.greenAccent),
                  _buildStatItem(
                      'تحت الصيانة',
                      controller.maintenanceStations.toString(),
                      Iconsax.setting_2,
                      Colors.orangeAccent),
                ],
              ),
            ),
          ),
        ));
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min, // تصغير المساحة المستهلكة
      children: [
        Icon(icon, color: color, size: 22.sp),
        SizedBox(height: 6.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: Appfontstring.ChangaLight,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            color: Colors.white.withOpacity(0.8),
            fontFamily: Appfontstring.ChangaLight,
          ),
        ),
      ],
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
        height: 190.h,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: Row(
            children: filteredList.map((station) {
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
        fontSize: 13.sp,
        fontWeight: FontWeight.bold,
        fontFamily: Appfontstring.ChangaLight,
      ),
      indicatorColor: AreapageColors.kSecondaryColor,
      indicatorWeight: 3,
      isScrollable: false,
      labelColor: AreapageColors.kSecondaryColor,
      unselectedLabelColor: Colors.white70,
      tabs: const [
        Tab(text: 'الشمالية', icon: Icon(Iconsax.map_1, size: 20)),
        Tab(text: 'الشرقية', icon: Icon(Iconsax.sun_1, size: 20)),
        Tab(text: 'الجنوبية', icon: Icon(Iconsax.location_add, size: 20)),
        Tab(text: 'الغربية', icon: Icon(Iconsax.wind_2, size: 20)),
      ],
    );
  }
}

class AreaNavController extends GetxController {
  final RxList<StationDetialesModel> stations = <StationDetialesModel>[].obs;
  final RxBool isLoading = true.obs;

  // متغير للبحث
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchStations();
  }

  /// تصفية المحطات بناءً على البحث
  List<StationDetialesModel> get filteredStations {
    if (searchQuery.isEmpty) return stations;
    return stations
        .where((s) =>
            s.name.contains(searchQuery.value) ||
            s.zone.contains(searchQuery.value))
        .toList();
  }

  /// إحصائيات للمحطات (للدراسة والعرض في الـ Dashboard)
  int get totalStations => stations.length;
  int get activeStations => stations.where((s) => s.image.isNotEmpty).length;
  int get maintenanceStations => stations.where((s) => s.image.isEmpty).length;

  /// جلب جميع المحطات مع خاصية الـ Caching
  /// يتم الجلب مرة واحدة فقط وتخزين البيانات حتى غلق التطبيق
  Future<void> fetchStations({bool refresh = false}) async {
    // التحقق مما إذا كانت البيانات موجودة بالفعل لمنع الاستدعاء المتكرر
    if (stations.isNotEmpty && !refresh) return;

    try {
      isLoading.value = true;

      // جلب جميع المحطات من الجدول بدون قيود
      final response = await Supabase.instance.client
          .from('station_table')
          .select()
          .timeout(const Duration(seconds: 10));

      final fetchedData = response.map((json) {
        return StationDetialesModel.fromJson(json);
      }).toList();

      stations.assignAll(fetchedData);
    } catch (e) {
      // تسجيل الخطأ في الـ Console للمساعدة في التصحيح
      debugPrint('Error fetching stations: $e');

      Get.snackbar(
        'خطأ في الاتصال',
        'فشل في جلب بيانات المحطات. يرجى التأكد من اتصالك بالإنترنت والمحاولة مرة أخرى.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        mainButton: TextButton(
          onPressed: () {
            if (Get.isSnackbarOpen) Get.back();
            fetchStations(refresh: true);
          },
          child: const Text(
            'إعادة المحاولة',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
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
    return FadeInRight(
      duration: const Duration(milliseconds: 500),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 140.w,
          margin: EdgeInsets.symmetric(vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Image & Status
                  Expanded(
                    flex: 3,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: HeaderVerticalProduct(station: station),
                        ),
                        // Status Indicator
                        Positioned(
                          top: 8.h,
                          left: 8.w,
                          child: Container(
                            width: 8.w,
                            height: 8.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: station.image.isNotEmpty
                                  ? Colors.greenAccent
                                  : Colors.orangeAccent,
                              boxShadow: [
                                BoxShadow(
                                  color: (station.image.isNotEmpty
                                          ? Colors.greenAccent
                                          : Colors.orangeAccent)
                                      .withOpacity(0.6),
                                  blurRadius: 6,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Name & Zone
                  Expanded(
                    flex: 1,
                    child: BodyVerticalProduct(station: station),
                  ),
                ],
              ),
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
        fontSize: 12.sp,
        fontWeight: FontWeight.bold,
        color: Colors.white,
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
        fontSize: 10.sp,
        fontFamily: Appfontstring.ChangaLight,
        color: Colors.white.withOpacity(0.7),
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.right,
    );
  }
}

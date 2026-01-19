import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:amiraly/E-commerce_project/common/models/appmodels.dart';
import 'package:amiraly/E-commerce_project/common/widgets/headlinetext.dart';
import 'package:amiraly/E-commerce_project/features/mainprog/screen/catogriesScreens/cairoscreen.dart';
import 'package:amiraly/E-commerce_project/features/mainprog/screen/catogriesScreens/cmscreen.dart';
import 'package:amiraly/E-commerce_project/util/constant/constants.dart';
import 'package:amiraly/main.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

// ============================================================================
// HOME NAVIGATION SCREEN
// ============================================================================
class HomeNav extends StatefulWidget {
  const HomeNav({super.key});

  @override
  State<HomeNav> createState() => _HomeNavState();
}

class _HomeNavState extends State<HomeNav> {
  late final HomenavcontrollerImp _controller;
  late final CarouselSliderController _carouselController;
  Timer? _loadTimer;
  late Future<void> _initialDataFuture;

  // Local UI State
  String? _selectedCategory;
  final RxInt _currentCarouselIndex = 0.obs;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(HomenavcontrollerImp());
    _carouselController = CarouselSliderController();
    _startLoadVariationTimer();
    _initialDataFuture = _initializeData();
  }

  Future<void> _initializeData() async {
    await Future.wait([
      _controller.checkUserGroup(),
      _controller.fetchCategories(),
      _controller.fetchAnnouncImages(),
      _controller.fetchCairoWeather(),
      _controller.fetchStationLoads(),
    ]);
    if (mounted) setState(() {});
  }

  void _reloadPage() {
    setState(() {
      _initialDataFuture = _initializeData();
    });
  }

  void _startLoadVariationTimer() {
    _loadTimer?.cancel();
    _loadTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _controller.updateStationVariations();
    });
  }

  @override
  void dispose() {
    _loadTimer?.cancel();
    // No need to delete controller if it is used elsewhere or managed by bindings,
    // otherwise: Get.delete<HomenavcontrollerImp>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (context, child) {
        return WillPopScope(
          onWillPop: () async => Navigator.canPop(context),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              floatingActionButton: SizedBox(
                height: 25.h,
                width: 25.w,
                child: FloatingActionButton(
                  onPressed: _reloadPage,
                  backgroundColor: Appcolors.primaryColor,
                  child: const Icon(Icons.refresh, color: Colors.white),
                ),
              ),
              body: Obx(() {
                if (_controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                return FutureBuilder<void>(
                  future: _initialDataFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.hasError) {
                      return _buildErrorWidget(
                        error: snapshot.error.toString(),
                        onRetry: _reloadPage,
                      );
                    }
                    return CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(child: _buildHeaderSection()),
                        SliverToBoxAdapter(child: _buildContentSection()),
                      ],
                    );
                  },
                );
              }),
            ),
          ),
        );
      },
    );
  }

  // --- Header Section ---

  Widget _buildHeaderSection() {
    return ClipPath(
      clipper: CustomClipPathWidget(),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: Appcolors.buttonGradient2,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        height: 140.h,
        child: Stack(
          children: [
            Positioned(
              top: 8.h,
              left: 0,
              right: 0,
              child: _buildCategoryList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList() {
    final categories = _controller.categories;
    if (categories.isEmpty) {
      return SizedBox(
        height: 147.h,
        child: const Center(child: Text(Stringshomenav.noCategories)),
      );
    }

    // Initialize selection if needed
    _selectedCategory ??= categories.first.name;

    return SizedBox(
      height: 147.h,
      child: ListView.builder(
        shrinkWrap: false,
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemExtent: 75.w,
        itemBuilder: (_, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category.name;
          return Padding(
            padding: const EdgeInsets.only(right: 1.0),
            child: GestureDetector(
              onTap: () => _onCategoryTap(category),
              child: CategoryItem(
                category: category,
                isSelected: isSelected,
              ),
            ),
          );
        },
      ),
    );
  }

  void _onCategoryTap(MainCatogoryModel category) {
    // Logic delegated to controller
    _controller.handleCategoryTap(context, category);
  }

  // --- Content Section ---

  Widget _buildContentSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.75.w),
      child: Column(
        children: [
          HeadlineText(
            fontfamily: Appfontstring.ChangaLight,
            fontSize: 18.75.sp,
            headlineText: Stringshomenav.newsHeadline,
            buttomheadlineText: '- - -',
            color: Colors.black87,
            isSeeAllVisible: true,
            screenHeight: 230.h,
            screenWidth: 375.w,
          ),
          SizedBox(height: 5.h),
          _buildCarousel(),
          SizedBox(height: 5.h),
          HeadlineText(
            fontfamily: Appfontstring.ChangaLight,
            fontSize: 18.75.sp,
            headlineText: Stringshomenav.cairoWeatherHeadline,
            buttomheadlineText: '- - -',
            color: Colors.black87,
            screenHeight: 230.h,
            screenWidth: 375.w,
            isSeeAllVisible: true,
          ),
          SizedBox(height: 5.h),
          _buildWeatherSection(),
          SizedBox(height: 5.h),
          Obx(() => _buildStationSections()),
        ],
      ),
    );
  }

  Widget _buildCarousel() {
    final announcImages = _controller.announcImages;
    if (announcImages.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(7.5),
        child: Center(child: Text(Stringshomenav.noImages)),
      );
    }

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8.r,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16.r),
            child: CarouselSlider(
              carouselController: _carouselController,
              options: CarouselOptions(
                autoPlayCurve: Curves.linear,
                enlargeCenterPage: true,
                enlargeStrategy: CenterPageEnlargeStrategy.height,
                height: 191.h,
                enlargeFactor: 0.4,
                viewportFraction: 0.7,
                reverse: true,
                enableInfiniteScroll: true,
                initialPage: 0,
                autoPlay: true,
                autoPlayAnimationDuration: const Duration(milliseconds: 800),
                onPageChanged: (index, reason) =>
                    _currentCarouselIndex.value = index,
              ),
              items: announcImages.map((photo) {
                return Builder(
                  builder: (BuildContext context) {
                    return Container(
                      width: 330.5.w,
                      margin: EdgeInsets.symmetric(horizontal: 5.w),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.black, width: 1),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: CachedNetworkImage(
                          maxHeightDiskCache: 400,
                          maxWidthDiskCache: 400,
                          memCacheHeight: 400,
                          memCacheWidth: 400,
                          imageUrl: photo.imageUrl,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Center(
                            child: Icon(
                              Icons.error,
                              color: Colors.redAccent,
                              size: 40.sp,
                            ),
                          ),
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 16.h),
          Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                announcImages.length,
                (i) => Circularcontainer(
                  padding: 0,
                  height: 5.h,
                  width: _currentCarouselIndex.value == i ? 20.w : 10.w,
                  backgroundColor: _currentCarouselIndex.value == i
                      ? Colors.blueAccent
                      : Colors.grey.shade300,
                  radius: 50.r,
                  margin: EdgeInsets.symmetric(horizontal: 2.w),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherSection() {
    final weatherData = _controller.weatherData;
    if (weatherData.isEmpty) {
      return _buildErrorWidget(
        error: Stringshomenav.noWeatherData,
        onRetry: _controller.refreshWeather,
      );
    }

    final currentWeather = weatherData.firstWhere(
      (weather) => weather.isCurrent,
      orElse: () => WeatherData(
        dayName: Stringshomenav.weatherNow,
        maxTemp: 0,
        minTemp: 0,
        description: 'Unknown',
        icon: '🌤️',
        isToday: false,
        isCurrent: true,
        date: DateTime.now(),
      ),
    );
    final forecast =
        weatherData.where((weather) => !weather.isCurrent).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 3.5.w),
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: _buildWeatherCard(currentWeather, 85.w, true),
          ),
          ...forecast.asMap().entries.take(4).map((entry) {
            final weather = entry.value;
            return Padding(
              padding: EdgeInsets.only(right: 7.w),
              child: _buildWeatherCard(weather, 72.w, false),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildWeatherCard(WeatherData weather, double width, bool isCurrent) {
    return Container(
      width: width,
      height: 100.h,
      padding: EdgeInsets.all(3.75.w),
      decoration: BoxDecoration(
        color: isCurrent
            ? const Color.fromARGB(199, 166, 228, 223)
            : const Color.fromARGB(255, 247, 248, 216),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(width: 1, color: Appcolors.textPrimary),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6.r,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            weather.dayName,
            style: TextStyle(
              fontSize: 12.125.sp,
              fontFamily: Appfontstring.ChangaLight,
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 5.h),
          Text(
            weather.icon,
            style: TextStyle(
              fontSize: isCurrent ? 22.sp : 20.sp,
              fontFamily: Appfontstring.ChangaLight,
            ),
          ),
          SizedBox(height: 5.h),
          Text(
            isCurrent
                ? '${weather.maxTemp}°'
                : '${weather.minTemp}°/${weather.maxTemp}°',
            style: TextStyle(
              fontSize: 13.25.sp,
              fontFamily: Appfontstring.ChangaLight,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStationSections() {
    final stationData = _controller.stationLoads;
    if (stationData.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(7.5),
        child: Center(child: Text(Stringshomenav.noStationData)),
      );
    }

    final Map<String, bool> direction = {
      for (final s in stationData) s.stationName: true
    };

    double getStationLoad(String stationName) {
      try {
        final station =
            stationData.firstWhere((s) => s.stationName == stationName);
        final absLoad = station.load.abs();
        final isPositive = direction[stationName] ?? true;
        return isPositive ? absLoad : -absLoad;
      } catch (e) {
        return 0.0;
      }
    }

    double getTotalLoad() {
      return stationData.fold(0.0, (sum, station) {
        final absLoad = station.load.abs();
        final isPositive = direction[station.stationName] ?? true;
        return sum + (isPositive ? absLoad : -absLoad);
      });
    }

    return Column(
      children: [
        HeadlineText(
          fontfamily: Appfontstring.ChangaLight,
          fontSize: 18.75.sp,
          headlineText: Stringshomenav.networkLoadHeadline,
          buttomheadlineText: Stringshomenav.seeAll,
          color: Colors.black,
          screenHeight: 243.h,
          screenWidth: 375.w,
          isSeeAllVisible: true,
          onSeeAllPressed: _controller.gotocairoscreen,
        ),
        SizedBox(height: 6.h),
        buildGaugeSection(
          context,
          'حمل الشبكة',
          0,
          17000,
          getTotalLoad(),
        ),
        SizedBox(height: 6.h),
        HeadlineText(
          fontfamily: Appfontstring.ChangaLight,
          fontSize: 18.75.sp,
          headlineText: Stringshomenav.exchangeHeadline,
          buttomheadlineText: Stringshomenav.seeAll,
          color: Colors.black,
          screenHeight: 243.h,
          screenWidth: 375.w,
          isSeeAllVisible: true,
          onSeeAllPressed: _controller.gotocairoscreen,
        ),
        buildGaugeSection(
          context,
          'عبور3/عاشر',
          0,
          130,
          getStationLoad('عبور3/عاشر'),
        ),
        buildGaugeSection(
          context,
          'القناطر',
          0,
          70,
          getStationLoad('قليوب/قناطر'),
        ),
        SizedBox(height: 6.h),
        HeadlineText(
          fontfamily: Appfontstring.ChangaLight,
          fontSize: 18.75.sp,
          headlineText: Stringshomenav.generationHeadline,
          buttomheadlineText: Stringshomenav.seeAll,
          color: Colors.black,
          isSeeAllVisible: true,
          screenHeight: 243.h,
          screenWidth: 375.w,
          onSeeAllPressed: _controller.gotocairoscreen,
        ),
        buildGaugeSection(
          context,
          'الكريمات الشمسية',
          0,
          110,
          getStationLoad('الكريمات الشمسية'),
        ),
      ],
    );
  }

  Widget _buildErrorWidget({
    required String error,
    required VoidCallback onRetry,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Failed to load: $error',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: const Text(Stringshomenav.retry),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// WIDGET HELPERS
// ============================================================================

class CategoryItem extends StatelessWidget {
  final MainCatogoryModel category;
  final bool isSelected;

  const CategoryItem({
    super.key,
    required this.category,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final truncatedText = category.name.length > 8
        ? '${category.name.substring(0, 8)}...'
        : category.name;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          alignment: Alignment.center,
          width: 60.w,
          height: 60.h,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black87, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6.r,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(
            child: CachedNetworkImage(
              imageUrl: category.image,
              width: 60.w,
              height: 60.h,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => Center(
                child: Icon(
                  Icons.error,
                  color: Colors.redAccent,
                  size: 33.75.sp,
                ),
              ),
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        SizedBox(
          width: 75.w,
          child: Text(
            truncatedText,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: 12.125.sp,
              fontFamily: Appfontstring.ChangaLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class Circularcontainer extends StatelessWidget {
  final double height;
  final double width;
  final Color backgroundColor;
  final double radius;
  final EdgeInsets margin;
  final double padding;

  const Circularcontainer({
    super.key,
    required this.height,
    required this.width,
    required this.backgroundColor,
    required this.radius,
    required this.margin,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height.h,
      width: width.w,
      margin: margin,
      padding: EdgeInsets.all(padding.w),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(radius.r),
      ),
    );
  }
}

class CustomClipPathWidget extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.8);
    path.lineTo(size.width * 0.4, size.height * 0.7);
    path.lineTo(size.width * 0.3, size.height * 0.8);
    path.lineTo(size.width * 0.6, size.height * 0.85);
    path.lineTo(size.width * 0.5, size.height * 0.95);
    path.lineTo(size.width * 0.8, size.height * 0.9);
    path.lineTo(size.width * 0.7, size.height * 0.75);
    path.lineTo(size.width, size.height * 0.8);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

Widget buildGaugeSection(
  BuildContext context,
  String capital,
  int minValuescale,
  int maxValuescale,
  double currentValue,
) {
  return Container(
    width: 356.25.w,
    height: 80.h,
    padding: EdgeInsets.only(left: 10.75.w, right: 10.75.w, top: 8.w),
    margin: EdgeInsets.symmetric(horizontal: 6.5.w),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16.r),
      border: Border.all(width: 1, color: Appcolors.secondaryColor),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 6.r,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: MyGaugeWidget(
      label: 'M.W',
      minValuescale: minValuescale,
      maxValuescale: maxValuescale,
      capital: capital,
      currentValue: currentValue,
    ),
  );
}

class MyGaugeWidget extends StatelessWidget {
  const MyGaugeWidget({
    super.key,
    required this.minValuescale,
    required this.maxValuescale,
    required this.label,
    required this.capital,
    required this.currentValue,
  });

  final int minValuescale;
  final int maxValuescale;
  final String label;
  final String capital;
  final double currentValue;

  @override
  Widget build(BuildContext context) {
    final range = maxValuescale - minValuescale;
    final segmentSize = range / 4.0;

    final gaugeRanges = [
      GaugeRange(
        startValue: minValuescale.toDouble(),
        endValue: (minValuescale + segmentSize).clamp(
          minValuescale.toDouble(),
          maxValuescale.toDouble(),
        ),
        color: Colors.green.shade200,
      ),
      GaugeRange(
        startValue: (minValuescale + segmentSize).clamp(
          minValuescale.toDouble(),
          maxValuescale.toDouble(),
        ),
        endValue: (minValuescale + 2 * segmentSize).clamp(
          minValuescale.toDouble(),
          maxValuescale.toDouble(),
        ),
        color: Colors.blue.shade200,
      ),
      GaugeRange(
        startValue: (minValuescale + 2 * segmentSize).clamp(
          minValuescale.toDouble(),
          maxValuescale.toDouble(),
        ),
        endValue: (minValuescale + 3 * segmentSize).clamp(
          minValuescale.toDouble(),
          maxValuescale.toDouble(),
        ),
        color: Colors.orange.shade200,
      ),
      GaugeRange(
        startValue: (minValuescale + 3 * segmentSize).clamp(
          minValuescale.toDouble(),
          maxValuescale.toDouble(),
        ),
        endValue: maxValuescale.toDouble(),
        color: Colors.red.shade400,
      ),
    ];

    final clampedValue = currentValue.clamp(
      minValuescale.toDouble(),
      maxValuescale.toDouble(),
    );

    final formattedValue = clampedValue.toStringAsFixed(0);

    return IntrinsicHeight(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.only(top: 20.h),
              child: Text(
                capital,
                style: TextStyle(
                  fontSize: 11.75.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: Appfontstring.ChangaLight,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 60.h,
              child: SfRadialGauge(
                axes: [
                  RadialAxis(
                    minimum: minValuescale.toDouble(),
                    maximum: maxValuescale.toDouble(),
                    startAngle: 160,
                    endAngle: 10,
                    radiusFactor: 1,
                    showLabels: false,
                    showTicks: true,
                    axisLineStyle: const AxisLineStyle(
                      thickness: 0.03,
                      color: Colors.transparent,
                    ),
                    pointers: [
                      NeedlePointer(
                        value: clampedValue,
                        needleLength: 0.8,
                        needleStartWidth: 0.5,
                        needleEndWidth: 1,
                        knobStyle: const KnobStyle(
                          knobRadius: 0.08,
                          color: Colors.black,
                        ),
                      ),
                    ],
                    ranges: gaugeRanges,
                  ),
                ],
                animationDuration: 800,
                enableLoadingAnimation: true,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'M.W',
                  style: TextStyle(
                    color: Colors.red,
                    fontFamily: Appfontstring.Almarai_Bold,
                    fontSize: 13.25.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 6.w),
                Text(
                  formattedValue,
                  style: TextStyle(
                    color: Colors.black87,
                    fontFamily: Appfontstring.BebasNeue_Regular,
                    fontSize: 30.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// CONTROLLER
// ============================================================================

abstract class Homenavcontroller extends GetxController {
  void gotocairoscreen();
  void gotonewsscreen();
  Future<void> refreshWeather();
  List<MainCatogoryModel> get categories;
  List<AnnouncImagesModel> get announcImages;
  List<WeatherData> get weatherData;
  RxList<StationLoad> get stationLoads;
  String get userGroup;

  Future<void> fetchCategories();
  Future<void> fetchAnnouncImages();
  Future<void> fetchCairoWeather();
  Future<void> fetchStationLoads();
  Future<void> checkUserGroup();
  void updateStationVariations();
  void handleCategoryTap(BuildContext context, MainCatogoryModel category);
}

class HomenavcontrollerImp extends Homenavcontroller {
  final RxList<MainCatogoryModel> _categories = <MainCatogoryModel>[].obs;
  final RxList<AnnouncImagesModel> _announcImages = <AnnouncImagesModel>[].obs;
  final RxList<WeatherData> _weatherData = <WeatherData>[].obs;
  final RxList<StationLoad> _stationLoads = <StationLoad>[].obs;
  final RxString _userGroup = 'none'.obs;
  final isLoading = false.obs;

  @override
  List<MainCatogoryModel> get categories => _categories;
  @override
  List<AnnouncImagesModel> get announcImages => _announcImages;
  @override
  List<WeatherData> get weatherData => _weatherData;
  @override
  RxList<StationLoad> get stationLoads => _stationLoads;
  @override
  String get userGroup => _userGroup.value;

  @override
  void gotocairoscreen() {
    Get.to(() => const Cairoscreen());
  }

  @override
  void gotonewsscreen() {
    Get.to(() => const Cmscreen());
  }

  @override
  Future<void> checkUserGroup() async {
    final email = Get.find<AuthService>().getCurrentUserEmail();
    if (email == null) {
      _userGroup.value = 'none';
      return;
    }

    try {
      final client = Supabase.instance.client;

      // Parallel execution of queries for better performance
      final results = await Future.wait([
        client.from('user_cm').select().eq('user_email', email).limit(1),
        client.from('user_stations').select().eq('user_email', email).limit(1),
        client.from('user_top').select().eq('user_email', email).limit(1),
        client.from('user_crcc').select().eq('user_email', email).limit(1),
      ]);

      if (results[0].isNotEmpty)
        _userGroup.value = 'cm';
      else if (results[1].isNotEmpty)
        _userGroup.value = 'stations';
      else if (results[2].isNotEmpty)
        _userGroup.value = 'top';
      else if (results[3].isNotEmpty)
        _userGroup.value = 'crcc';
      else
        _userGroup.value = 'none';
    } catch (e) {
      _userGroup.value = 'none';
      debugPrint('Error checking user group: $e');
    }
  }

  @override
  void handleCategoryTap(BuildContext context, MainCatogoryModel category) {
    if (Get.find<AuthService>().getCurrentUserEmail() == null) {
      _showSnackBar(context, Stringshomenav.msgOtherDepts);
      return;
    }

    // Check permissions logic moved here
    final normalizedCategoryName = category.name.trim();
    bool isAllowed = false;
    List<String> allowedCategories = [];

    switch (userGroup) {
      case 'cm':
        allowedCategories = ['العالم', 'القاهرة', 'مؤشرات', 'الازمات', 'خريطة'];
        break;
      case 'stations':
        allowedCategories = ['العالم', 'القاهرة', 'مؤشرات', 'خريطة'];
        break;
      case 'top':
      case 'crcc':
        isAllowed = true;
        break;
      case 'none':
        allowedCategories = [];
        break;
    }

    if (!isAllowed && !allowedCategories.contains(normalizedCategoryName)) {
      _showSnackBar(context, Stringshomenav.msgAccessDenied);
      return;
    }

    if (category.pageroute.isNotEmpty) {
      try {
        Get.toNamed(category.pageroute);
      } catch (e) {
        _showSnackBar(context, 'خطأ في التنقل: $e');
      }
    } else {
      _showSnackBar(context, Stringshomenav.msgNotReady);
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Future<void> fetchCategories() async {
    try {
      final response = await Supabase.instance.client
          .from('category_items')
          .select()
          .timeout(const Duration(seconds: 10));
      _categories.value = (response as List<dynamic>)
          .map((json) =>
              MainCatogoryModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _categories.value = [];
    }
  }

  @override
  Future<void> fetchAnnouncImages() async {
    try {
      final response = await Supabase.instance.client
          .from('announcing_images')
          .select()
          .timeout(const Duration(seconds: 10));
      _announcImages.value = (response as List<dynamic>)
          .map((json) =>
              AnnouncImagesModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _announcImages.value = [];
    }
  }

  @override
  Future<void> fetchStationLoads() async {
    try {
      final loads = await SupabaseService().fetchStationLoads();
      updateStationLoads(loads);
    } catch (e) {
      _stationLoads.value = [];
    }
  }

  @override
  Future<void> fetchCairoWeather() async {
    const apiUrl =
        'https://api.open-meteo.com/v1/forecast?latitude=30.0444&longitude=31.2357&daily=weathercode,temperature_2m_max,temperature_2m_min&current_weather=true&timezone=auto&forecast_days=5';

    try {
      final response = await http
          .get(Uri.parse(apiUrl))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // ... (Parsing logic similar to previous implementation, kept concise)
        if (data['daily'] != null && data['current_weather'] != null) {
          _parseWeatherData(data);
        }
      }
    } catch (e) {
      _weatherData.value = [];
    }
  }

  void _parseWeatherData(Map<String, dynamic> data) {
    final daily = data['daily'];
    final current = data['current_weather'];

    final currentWeather = WeatherData(
      dayName: Stringshomenav.weatherNow,
      maxTemp: (current['temperature'] as num?)?.toInt() ?? 0,
      minTemp: (current['temperature'] as num?)?.toInt() ?? 0,
      description: _getWeatherDescription(
        (current['weathercode'] as num?)?.toInt() ?? 0,
      ),
      icon: _getWeatherIcon(
        _getWeatherDescription(
          (current['weathercode'] as num?)?.toInt() ?? 0,
        ),
      ),
      isToday: false,
      isCurrent: true,
      date: DateTime.now(),
    );

    final forecast = List.generate(
      (daily['time'] as List<dynamic>).length - 1,
      (i) {
        final index = i + 1;
        return WeatherData(
          dayName: _getDayName(DateTime.parse(daily['time'][index])),
          maxTemp: (daily['temperature_2m_max'][index] as num?)?.toInt() ?? 0,
          minTemp: (daily['temperature_2m_min'][index] as num?)?.toInt() ?? 0,
          description: _getWeatherDescription(
            (daily['weathercode'][index] as num?)?.toInt() ?? 0,
          ),
          icon: _getWeatherIcon(
            _getWeatherDescription(
              (daily['weathercode'][index] as num?)?.toInt() ?? 0,
            ),
          ),
          isToday: false,
          isCurrent: false,
          date: DateTime.parse(daily['time'][index]),
        );
      },
    ).take(4).toList();

    _weatherData.value = [currentWeather, ...forecast];
  }

  @override
  Future<void> refreshWeather() async {
    await fetchCairoWeather();
  }

  void updateStationLoads(List<StationLoad> loads) {
    _stationLoads.value = loads;
  }

  @override
  void updateStationVariations() {
    final random = Random();
    for (final station in _stationLoads) {
      final delta = station.maxVariation - station.minVariation;
      final variation = random.nextDouble() * delta + station.minVariation;
      station.load = station.baseLoad + variation;
    }
    _stationLoads.refresh();
  }

  String _getDayName(DateTime date) {
    return [
      '',
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ][date.weekday];
  }

  String _getWeatherDescription(int code) {
    return switch (code) {
      0 => 'Clear sky',
      1 || 2 || 3 => 'Mainly clear with few clouds',
      45 || 48 => 'Dense fog',
      51 || 53 || 55 => 'Light drizzle',
      61 || 63 || 65 => 'Rainfall',
      71 || 73 || 75 => 'Snowfall',
      80 || 81 || 82 => 'Intermittent rain showers',
      95 || 96 || 99 => 'Thunderstorms',
      _ => 'Unknown',
    };
  }

  String _getWeatherIcon(String desc) {
    final icons = {
      'clear sky': '☀️',
      'mainly clear with few clouds': '⛅',
      'dense fog': '🌫️',
      'light drizzle': '🌦️',
      'rainfall': '🌧️',
      'snowfall': '❄️',
      'intermittent rain showers': '🌦️',
      'thunderstorms': '⛈️',
      'unknown': '🌤️',
    };
    return icons[desc.toLowerCase()] ?? '🌤️';
  }
}

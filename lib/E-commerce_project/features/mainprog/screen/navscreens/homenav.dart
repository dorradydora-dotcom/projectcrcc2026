import 'package:amiraly/E-commerce_project/common/models/appmodels.dart';
import 'package:amiraly/E-commerce_project/common/widgets/headlinetext.dart';
import 'package:amiraly/E-commerce_project/util/constant/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:ui';
import 'package:amiraly/E-commerce_project/features/mainprog/screen/navscreens/homenav_controller.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class HomeNav extends StatefulWidget {
  const HomeNav({super.key});

  @override
  State<HomeNav> createState() => _HomeNavState();
}

class _HomeNavState extends State<HomeNav> {
  late final HomenavcontrollerImp _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(HomenavcontrollerImp());
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: const Color(0xFF0F172A),
            floatingActionButton: SizedBox(
                height: 28.h,
                width: 28.w,
                child: Pulse(
                    infinite: false,
                    duration: const Duration(seconds: 7),
                    child: FloatingActionButton(
                        onPressed: () => _controller.refreshWeather(),
                        backgroundColor: Appcolors.primaryColor,
                        child: const Icon(Icons.refresh,
                            color: Colors.white, size: 14)))),
            body: Obx(() {
              if (_controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Colors.blueAccent,
                    strokeWidth: 2,
                  ),
                );
              }
              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildHeaderSection()),
                  if (_controller.isOffline.value)
                    SliverToBoxAdapter(
                      child: Container(
                        color: Colors.redAccent.withOpacity(0.1),
                        padding: EdgeInsets.symmetric(vertical: 4.h),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.signal_wifi_off,
                                size: 14.sp, color: Colors.red),
                            SizedBox(width: 8.w),
                            Text(
                              "تعذر الاتصال",
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: Colors.red,
                                fontFamily: Appfontstring.ChangaLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(child: _buildContentSection()),
                ],
              );
            }),
          ),
        );
      },
    );
  }

  // --- Header Section ---

  Widget _buildHeaderSection() {
    return Container(
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
      height: 170.h,
      child: Stack(
        children: [
          // Decorative background icon
          Positioned(
            right: 10.w,
            top: 40.h,
            child: Icon(
              Iconsax.flash5,
              size: 100.sp,
              color: Colors.white.withOpacity(0.09),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 2.h),
                _buildGreetingRow(),
                SizedBox(height: 15.h),
                _buildCategoryList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingRow() {
    return FadeInDown(
        duration: const Duration(milliseconds: 600),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'أهــلاً بك 👋',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 13.sp,
                  fontFamily: Appfontstring.ChangaLight,
                ),
              ),
              Obx(() => Text(_controller.userEmail.value.split('@')[0],
                  style: TextStyle(
                      color: C.green,
                      fontSize: 11.sp,
                      fontFamily: Appfontstring.tejw2)))
            ],
          ),
          Obx(() => Container(
              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.white10),
              ),
              child: Text(_controller.currentDate.value,
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 8.sp,
                      fontFamily: Appfontstring.ChangaLight))))
        ]));
  }

  Widget _buildCategoryList() {
    final categories = _controller.categories;
    if (categories.isEmpty) {
      return SizedBox(
        height: 110.h,
        child: const Center(child: Text(Stringshomenav.noCategories)),
      );
    }

    return SizedBox(
      height: 90.h,
      child: ListView.builder(
        shrinkWrap: false,
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemExtent: 60.w,
        itemBuilder: (_, index) {
          final category = categories[index];
          final isSelected = false;
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
    _controller.handleCategoryTap(context, category);
  }

  Widget _buildContentSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5.00.w),
      child: Column(
        children: [
          FadeInDown(
            child: HeadlineText(
              fontfamily: Appfontstring.ChangaLight,
              fontSize: 15.00.sp,
              headlineText: Stringshomenav.newsHeadline,
              buttomheadlineText: '...',
              color1: Colors.white70,
              color2: Colors.white70,
              isSeeAllVisible: true,
              screenHeight: 230.h,
              screenWidth: 375.w,
            ),
          ),
          SizedBox(height: 5.h),
          _buildCarousel(),
          SizedBox(height: 5.h),
          FadeInUp(
            child: HeadlineText(
              fontfamily: Appfontstring.ChangaLight,
              fontSize: 15.00.sp,
              headlineText: Stringshomenav.cairoWeatherHeadline,
              buttomheadlineText: '...',
              color1: Colors.white70,
              color2: Colors.white70,
              screenHeight: 230.h,
              screenWidth: 375.w,
              isSeeAllVisible: true,
            ),
          ),
          SizedBox(height: 5.h),
          _buildWeatherSection(),
          SizedBox(height: 7.h),
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: BackdropFilter(
        filter: ImageFilter.dilate(),
        child: Container(
          padding:
              EdgeInsets.only(top: 10.h, bottom: 10.h, left: 2.w, right: 2.w),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              color: Colors.white.withOpacity(0.1),
              border: Border.all(color: Colors.white.withOpacity(0.12))),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: CarouselSlider(
                  carouselController: _controller.carouselController,
                  options: CarouselOptions(
                    autoPlayCurve: Curves.linear,
                    enlargeCenterPage: true,
                    enlargeStrategy: CenterPageEnlargeStrategy.height,
                    height: 170.h,
                    enlargeFactor: 0.4,
                    viewportFraction: 0.7,
                    reverse: true,
                    enableInfiniteScroll: true,
                    initialPage: 0,
                    autoPlay: true,
                    autoPlayAnimationDuration:
                        const Duration(milliseconds: 800),
                    onPageChanged: (index, reason) =>
                        _controller.currentCarouselIndex.value = index,
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
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 10.h),
              Obx(
                () => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    announcImages.length,
                    (i) => Circularcontainer(
                      padding: 0,
                      height: 4.h,
                      width: _controller.currentCarouselIndex.value == i
                          ? 16.w
                          : 8.w,
                      backgroundColor:
                          _controller.currentCarouselIndex.value == i
                              ? Colors.blueAccent
                              : Colors.white.withOpacity(0.3),
                      radius: 50.r,
                      margin: EdgeInsets.symmetric(horizontal: 2.w),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
      padding: EdgeInsets.symmetric(horizontal: 3.w),
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.only(right: 5.w),
            child: _buildWeatherCard(currentWeather, 70.w, true),
          ),
          ...forecast.asMap().entries.take(4).map((entry) {
            final weather = entry.value;
            return Padding(
              padding: EdgeInsets.only(right: 7.w),
              child: _buildWeatherCard(weather, 60.w, false),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWeatherCard(WeatherData weather, double width, bool isCurrent) {
    return ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
                width: width,
                height: 75.h,
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? const Color(0xFF1E293B).withOpacity(0.6)
                      : Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    width: 1,
                    color: C.orange.withOpacity(0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 5.r,
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
                          fontSize: 10.sp,
                          fontFamily: Appfontstring.ChangaLight,
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        weather.icon,
                        style: TextStyle(
                          fontSize: isCurrent ? 16.sp : 14.sp,
                          fontFamily: Appfontstring.ChangaLight,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                          isCurrent
                              ? '${weather.maxTemp}°'
                              : '${weather.minTemp}° / ${weather.maxTemp}°',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontFamily: Appfontstring.ChangaLight,
                            color: Colors.blue,
                          ))
                    ]))));
  }

  Widget _buildStationSections() {
    final stationData = _controller.stationLoads;
    if (stationData.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(5.5),
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
        FadeInLeft(
          child: HeadlineText(
            fontfamily: Appfontstring.ChangaLight,
            fontSize: 14.sp,
            headlineText: Stringshomenav.networkLoadHeadline,
            buttomheadlineText: Stringshomenav.seeAll,
            color1: Colors.white70,
            color2: Colors.white70,
            screenHeight: 243.h,
            screenWidth: 375.w,
            isSeeAllVisible: true,
            onSeeAllPressed: _controller.gotocairoscreen,
          ),
        ),
        SizedBox(height: 4.h),
        buildGaugeSection(context, 'حمل الشبكة', 0, 18000, getTotalLoad()),
        SizedBox(height: 4.h),
        FadeInRight(
          child: HeadlineText(
            fontfamily: Appfontstring.ChangaLight,
            fontSize: 14.sp,
            headlineText: Stringshomenav.exchangeHeadline,
            buttomheadlineText: Stringshomenav.seeAll,
            color1: Colors.white70,
            color2: Colors.white70,
            screenHeight: 243.h,
            screenWidth: 375.w,
            isSeeAllVisible: true,
            onSeeAllPressed: _controller.gotocairoscreen,
          ),
        ),
        SizedBox(height: 4.h),
        buildGaugeSection(
            context, 'عبور3/عاشر', 0, 130, getStationLoad('عبور3/عاشر')),
        SizedBox(height: 2.h),
        buildGaugeSection(
            context, 'القناطر', 0, 70, getStationLoad('قليوب/قناطر')),
        SizedBox(height: 4.h),
        HeadlineText(
          fontfamily: Appfontstring.ChangaLight,
          fontSize: 16.00.sp,
          headlineText: Stringshomenav.generationHeadline,
          buttomheadlineText: Stringshomenav.seeAll,
          color1: Colors.white70,
          color2: Colors.white70,
          isSeeAllVisible: true,
          screenHeight: 243.h,
          screenWidth: 375.w,
          onSeeAllPressed: _controller.gotocairoscreen,
        ),
        buildGaugeSection(context, 'الكريمات الشمسية', 0, 110,
            getStationLoad('الكريمات الشمسية')),
        SizedBox(height: 25.h),
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
              'Failed to load',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            )
          ],
        ),
      ),
    );
  }
}

// WIDGET HELPERS

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
          width: 52.w,
          height: 52.h,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1),
          ),
          child: ClipOval(
            child: CachedNetworkImage(
              imageUrl: category.image,
              width: 52.w,
              height: 52.h,
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
        SizedBox(height: 6.h),
        SizedBox(
          width: 65.w,
          child: Text(
            truncatedText,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11.sp,
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
  return ClipRRect(
    borderRadius: BorderRadius.circular(16.r),
    child: Container(
      padding: EdgeInsets.only(left: 10.75.w, right: 10.75.w, top: 10.w),
      margin: EdgeInsets.symmetric(horizontal: 7.w),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16.r),
          border:
              Border.all(width: 1.5, color: Colors.white.withOpacity(0.12))),
      child: MyGaugeWidget(
        label: 'M.W',
        minValuescale: minValuescale,
        maxValuescale: maxValuescale,
        capital: capital,
        currentValue: currentValue,
      ),
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

    // Calculate dynamic status label and color
    String statusText = 'حمل طبيعي';
    Color statusColor = Colors.greenAccent;
    final percentage =
        (clampedValue - minValuescale) / (maxValuescale - minValuescale);
    if (percentage > 0.8) {
      statusText = 'حمل مرتفع جداً';
      statusColor = Colors.redAccent;
    } else if (percentage > 0.6) {
      statusText = 'حمل مرتفع';
      statusColor = Colors.orangeAccent;
    } else if (percentage > 0.4) {
      statusText = 'حمل متوسط';
      statusColor = Colors.blueAccent;
    }

    return Row(children: [
      Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              capital,
              style: TextStyle(
                  fontSize: 11.75.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: Appfontstring.ChangaLight,
                  color: Colors.white),
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                    fontSize: 7.sp,
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontFamily: Appfontstring.ChangaLight),
              ),
            ),
          ],
        ),
      ),
      Expanded(
        child: SizedBox(
          height: 44.h,
          child: SfRadialGauge(
            axes: [
              RadialAxis(
                  minimum: minValuescale.toDouble(),
                  maximum: maxValuescale.toDouble(),
                  startAngle: 160,
                  endAngle: 20,
                  radiusFactor: 1.2,
                  showLabels: false,
                  showTicks: false,
                  axisLineStyle: const AxisLineStyle(),
                  pointers: [
                    NeedlePointer(
                        value: clampedValue,
                        needleLength: 0.95,
                        needleStartWidth: 0.5,
                        needleEndWidth: 1,
                        knobStyle: const KnobStyle(
                            knobRadius: 0.1, color: Colors.white))
                  ],
                  ranges: gaugeRanges),
            ],
            animationDuration: 800,
            enableLoadingAnimation: true,
          ),
        ),
      ),
      Expanded(
          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
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
        Text(formattedValue,
            style: TextStyle(
                color: Colors.white,
                fontFamily: Appfontstring.ChangaLight,
                fontSize: 30.sp,
                fontWeight: FontWeight.bold))
      ]))
    ]);
  }
}

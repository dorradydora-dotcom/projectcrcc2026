import 'package:amiraly/E-commerce_project/common/models/appmodels.dart';
import 'package:amiraly/E-commerce_project/common/services/authserveces.dart';
import 'package:amiraly/E-commerce_project/common/services/mainprogservices.dart';
import 'package:amiraly/E-commerce_project/common/widgets/headlinetext.dart';
import 'package:amiraly/E-commerce_project/features/mainprog/screen/catogriesScreens/cairoscreen.dart';
import 'package:amiraly/E-commerce_project/features/mainprog/screen/catogriesScreens/cmscreen.dart';
import 'package:amiraly/E-commerce_project/util/constant/constants.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:photo_view/photo_view.dart';

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

class FavoritesNav extends StatelessWidget {
  const FavoritesNav({super.key});

  @override
  Widget build(BuildContext context) {
    final favoritesController = Get.find<FavoritesController>();
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [
            Appcolors.primaryColor,
            Color.fromARGB(255, 49, 107, 152),
            Colors.white,
          ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
          child: SafeArea(
            child: Obx(
              () => favoritesController.favorites.isEmpty
                  ? _buildEmptyState(context)
                  : _buildGridLayout(context, favoritesController),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: FadeInUp(
            duration: const Duration(milliseconds: 600),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                ZoomIn(
                  duration: const Duration(milliseconds: 800),
                  child: Container(
                    padding: EdgeInsets.all(32.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20.r,
                          offset: Offset(0, 8.h),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.favorite_border,
                      size: 64.sp,
                      color: Appcolors.primaryColor.withOpacity(0.3),
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
                FadeInUp(
                  duration: const Duration(milliseconds: 700),
                  child: Text(
                    'No Favorites Yet',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                FadeInUp(
                  duration: const Duration(milliseconds: 800),
                  child: Text(
                    'Start adding your favorite stations to access them quickly anytime.',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
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
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 8.h),
            child: FadeInDown(
              duration: const Duration(milliseconds: 600),
              child: Container(
                clipBehavior: Clip.hardEdge,
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                decoration: BoxDecoration(
                    border: Border.all(width: 1),
                    borderRadius: BorderRadius.circular(16.r),
                    color: const Color.fromARGB(156, 255, 255, 255)),
                child: Row(
                  children: [
                    Icon(Icons.favorite, color: Colors.redAccent, size: 22.sp),
                    SizedBox(width: 11.w),
                    Expanded(
                      child: Text(
                        'Your Favorite Stations (${controller.favorites.length})',
                        style: TextStyle(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14.h,
                  crossAxisSpacing: 14.w,
                  childAspectRatio: 0.8,
                ),
                delegate: SliverChildBuilderDelegate(
                    (context, index) => FadeInUp(
                        duration: Duration(milliseconds: 400 + (index * 150)),
                        child: GradientStationCard(
                            station: controller.favorites[index],
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => StationDetailsPage(
                                          station: controller.favorites[index],
                                        ))))),
                    childCount: controller.favorites.length))),
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.of(context).padding.bottom + 20.h),
        ),
      ],
    );
  }
}

class FavoritesController extends GetxController {
  static FavoritesController get instance => Get.find();
  final RxList<StationDetialesModel> favorites = <StationDetialesModel>[].obs;
  static const String _favoritesKey = 'favorites';

  @override
  void onInit() {
    super.onInit();
    _loadFavorites();
  }

  bool isFavorite(StationDetialesModel station) {
    return favorites.any((fav) => fav.name == station.name);
  }

  Future<void> toggleFavorite(StationDetialesModel station) async {
    if (isFavorite(station)) {
      favorites.removeWhere((fav) => fav.name == station.name);
    } else {
      favorites.add(station);
    }
    await _saveFavorites();
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteJsons =
        favorites.map((fav) => jsonEncode(fav.toJson())).toList();
    await prefs.setStringList(_favoritesKey, favoriteJsons);
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteJsons = prefs.getStringList(_favoritesKey) ?? [];
    favorites.clear();
    favorites.addAll(
      favoriteJsons
          .map((jsonStr) => StationDetialesModel.fromJson(jsonDecode(jsonStr)))
          .where((station) => station.name.isNotEmpty),
    );
  }
}

class GradientStationCard extends StatelessWidget {
  const GradientStationCard({
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
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: Image.network(
                station.image.isNotEmpty
                    ? station.image
                    : 'https://via.placeholder.com/150',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: Icon(Icons.error, color: Colors.red, size: 32.sp),
                  ),
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey[200],
                    child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2.sp)),
                  );
                },
              ),
            ),
            Positioned(
              top: 6.h,
              right: 6.w,
              child: HeartContainer(station: station),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.7),
                      const Color.fromARGB(98, 0, 0, 0)
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('محطة :  ${station.name}',
                        style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                            fontFamily: Appfontstring.ChangaLight),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    SizedBox(height: 2.h),
                    Text('المنطقة :  ${station.zone}',
                        style: TextStyle(
                          fontSize: 9.sp,
                          fontFamily: Appfontstring.ChangaLight,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HeartContainer extends StatelessWidget {
  const HeartContainer({super.key, required this.station});

  final StationDetialesModel station;

  @override
  Widget build(BuildContext context) {
    final favoritesController = Get.find<FavoritesController>();
    return Obx(
      () => Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(50.r),
          onTap: () => favoritesController.toggleFavorite(station),
          child: Container(
            decoration: BoxDecoration(shape: BoxShape.circle),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(
                Icons.favorite,
                key: ValueKey(favoritesController.isFavorite(station)),
                color: Colors.redAccent,
                size: 20.sp,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeNav extends StatefulWidget {
  const HomeNav({super.key});

  @override
  State<HomeNav> createState() => _HomeNavState();
}

class _HomeNavState extends State<HomeNav> {
  late Future<void> _initialDataFuture;
  String? selectedCategory;
  String? selectedAnnouncingImage;
  String? userEmail;
  String? userGroup;
  final SupabaseClient _client = Supabase.instance.client;
  final Homenavcontroller _controller = Get.put(HomenavcontrollerImp());
  late final CarouselSliderController carouselController;
  final RxInt currentIndex = 0.obs;
  Timer? _loadTimer;

  @override
  void initState() {
    super.initState();
    carouselController = CarouselSliderController();
    _initialDataFuture = _initializeData();
    Timer.periodic(const Duration(minutes: 15), (timer) {
      _controller.refreshWeather();
    });
  }

  Future<void> _initializeData() async {
    await _loadUserGroup();
    await Future.wait([
      _controller.fetchCategories(),
      _controller.fetchAnnouncImages(),
      _controller.fetchCairoWeather(),
      SupabaseService().fetchStationLoads().then((value) {
        _controller.updateStationLoads(value);
        _startLoadVariationTimer();
      }),
    ]);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadUserGroup() async {
    final AuthService authService = AuthService();
    userEmail = authService.getCurrentUserEmail();
    if (userEmail == null) {
      userGroup = null;
      if (mounted) setState(() {});
      return;
    }

    try {
      var response = await _client
          .from('user_cm')
          .select()
          .eq('user_email', userEmail!)
          .limit(1);
      if (response.isNotEmpty) {
        userGroup = 'cm';
        if (mounted) setState(() {});
        return;
      }

      response = await _client
          .from('user_stations')
          .select()
          .eq('user_email', userEmail!)
          .limit(1);
      if (response.isNotEmpty) {
        userGroup = 'stations';
        if (mounted) setState(() {});
        return;
      }

      response = await _client
          .from('user_top')
          .select()
          .eq('user_email', userEmail!)
          .limit(1);
      if (response.isNotEmpty) {
        userGroup = 'top';
        if (mounted) setState(() {});
        return;
      }

      response = await _client
          .from('user_crcc')
          .select()
          .eq('user_email', userEmail!)
          .limit(1);
      if (response.isNotEmpty) {
        userGroup = 'crcc';
        if (mounted) setState(() {});
        return;
      }

      userGroup = 'none';
      if (mounted) setState(() {});
    } catch (e) {
      userGroup = 'none';
      if (mounted) setState(() {});
    }
  }

  void _startLoadVariationTimer() {
    _loadTimer?.cancel();
    _loadTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _controller.updateStationVariations();
      // No setState needed; use Obx for reactive updates
    });
  }

  @override
  void dispose() {
    _loadTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: false,
      builder: (context, child) {
        return WillPopScope(
          onWillPop: () async => Navigator.canPop(context),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: LiquidPullToRefresh(
                color: Appcolors.buttonGradient2.first,
                backgroundColor: Colors.white,
                height: 50.h,
                showChildOpacityTransition: false,
                onRefresh: _refreshData,
                child: FutureBuilder<void>(
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
                        onRetry: _initializeData,
                      );
                    }
                    return CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(child: buildHeaderSection()),
                        SliverToBoxAdapter(child: buildContentSection()),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _refreshData() async {
    await _initializeData();
  }

  Widget buildHeaderSection() {
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
              child: buildCategoryList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCategoryList() {
    final categories = _controller.categories;
    if (categories.isEmpty) {
      return SizedBox(
        height: 147.h,
        child: const Center(child: Text('No categories available')),
      );
    }

    selectedCategory ??= categories.first.name;

    return SizedBox(
      height: 147.h,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (_, index) {
          final category = categories[index];
          final isSelected = selectedCategory == category.name;
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

  void _onCategoryTap(MainCatogoryModel category) async {
    if (userEmail == null) {
      _showSnackBar('مخصص لادارات اخرى');
      return;
    }
    if (userGroup == null) {
      _showSnackBar('جاري التحقق من الصلاحيات...');
      return;
    }

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
      _showSnackBar('غير مصرح لك بالوصول إلى هذه الفئة');
      return;
    }

    setState(() => selectedCategory = normalizedCategoryName);

    if (category.pageroute.isNotEmpty) {
      try {
        Get.toNamed(category.pageroute);
      } catch (e) {
        _showSnackBar('خطأ في التنقل: $e');
      }
    } else {
      _showSnackBar('الفئة غير جاهزة بعد');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Widget buildContentSection() {
    final announcImages = _controller.announcImages;
    if (announcImages.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(7.5),
        child: Center(child: Text('No images available')),
      );
    }

    selectedAnnouncingImage ??= announcImages.first.imageUrl;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.75.w),
      child: Column(
        children: [
          HeadlineText(
            fontfamily: Appfontstring.ChangaLight,
            fontSize: 18.75.sp,
            headlineText: 'الاخبـار',
            buttomheadlineText: '- - -',
            color: Colors.black87,
            isSeeAllVisible: true,
            screenHeight: 230.h,
            screenWidth: 375.w,
          ),
          SizedBox(height: 5.h),
          buildCarousel(),
          SizedBox(height: 5.h),
          HeadlineText(
            fontfamily: Appfontstring.ChangaLight,
            fontSize: 18.75.sp,
            headlineText: 'طقس القاهرة',
            buttomheadlineText: '- - -',
            color: Colors.black87,
            screenHeight: 230.h,
            screenWidth: 375.w,
            isSeeAllVisible: true,
          ),
          SizedBox(height: 5.h),
          buildWeatherSection(),
          SizedBox(height: 5.h),
          Obx(() => _buildStationSections()),
        ],
      ),
    );
  }

  Widget _buildStationSections() {
    final stationData = _controller.stationLoads;
    if (stationData.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(7.5),
        child: Center(child: Text('No station data available')),
      );
    }

    final Map<String, bool> direction = {
      for (final s in stationData) s.stationName: true
    };

    double getTotalLoad() {
      final total = stationData.fold(0.0, (sum, station) {
        final absLoad = station.load.abs();
        final isPositive = direction[station.stationName] ?? true;
        return sum + (isPositive ? absLoad : -absLoad);
      });
      return total;
    }

    double getStationLoad(String stationName) {
      try {
        final station =
            stationData.firstWhere((s) => s.stationName == stationName);
        final absLoad = station.load.abs();
        final isPositive = direction[stationName] ?? true;
        final load = isPositive ? absLoad : -absLoad;
        return load;
      } catch (e) {
        return 0.0;
      }
    }

    return Column(
      children: [
        HeadlineText(
          fontfamily: Appfontstring.ChangaLight,
          fontSize: 18.75.sp,
          headlineText: 'حمل شبكة القاهرة ',
          buttomheadlineText: 'الكـل',
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
          headlineText: 'التبادلات مع التحكمات الاقليمية',
          buttomheadlineText: 'الكـل',
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
          headlineText: 'التوليد',
          buttomheadlineText: 'الكـل',
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

  Widget buildWeatherSection() {
    final weatherData = _controller.weatherData;
    if (weatherData.isEmpty) {
      return _buildErrorWidget(
        error: 'No weather data available',
        onRetry: _controller.refreshWeather,
      );
    }

    final currentWeather = weatherData.firstWhere(
      (weather) => weather.isCurrent,
      orElse: () => WeatherData(
        dayName: 'الطقس الآن',
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
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCarousel() {
    final announcImages = _controller.announcImages;
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
              carouselController: carouselController,
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
                onPageChanged: (index, reason) => currentIndex.value = index,
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
                  width: currentIndex.value == i ? 20.w : 10.w,
                  backgroundColor: currentIndex.value == i
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
}

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
    height: 80.h, // Increased height for better gauge fit
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

    final formattedValue = clampedValue >= 0
        ? clampedValue.toStringAsFixed(0)
        : clampedValue.toStringAsFixed(0);

    return IntrinsicHeight(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.only(top: 20.h), // Align vertically
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
              height: 60.h, // Fixed height for gauge, using .h consistently
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

abstract class Homenavcontroller extends GetxController {
  void gotocairoscreen();
  void gotonewsscreen();
  Future<void> refreshWeather();
  List<MainCatogoryModel> get categories;
  List<AnnouncImagesModel> get announcImages;
  List<WeatherData> get weatherData;
  RxList<StationLoad> get stationLoads;

  Future<void> fetchCategories();
  Future<void> fetchAnnouncImages();
  Future<void> fetchCairoWeather();
  void updateStationLoads(List<StationLoad> loads);
  void updateStationVariations();
}

class HomenavcontrollerImp extends Homenavcontroller {
  final RxList<MainCatogoryModel> _categories = <MainCatogoryModel>[].obs;
  final RxList<AnnouncImagesModel> _announcImages = <AnnouncImagesModel>[].obs;
  final RxList<WeatherData> _weatherData = <WeatherData>[].obs;
  final RxList<StationLoad> _stationLoads = <StationLoad>[].obs;

  @override
  List<MainCatogoryModel> get categories => _categories;
  @override
  List<AnnouncImagesModel> get announcImages => _announcImages;
  @override
  List<WeatherData> get weatherData => _weatherData;
  @override
  RxList<StationLoad> get stationLoads => _stationLoads;

  @override
  void gotocairoscreen() {
    Get.to(() => const Cairoscreen());
  }

  @override
  void gotonewsscreen() {
    Get.to(() => const Cmscreen());
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
  Future<void> fetchCairoWeather() async {
    const apiUrl =
        'https://api.open-meteo.com/v1/forecast?latitude=30.0444&longitude=31.2357&daily=weathercode,temperature_2m_max,temperature_2m_min&current_weather=true&timezone=auto&forecast_days=5';

    try {
      final response = await http
          .get(Uri.parse(apiUrl))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['daily'] == null || data['current_weather'] == null) {
          throw Exception('Invalid API response: Missing required fields');
        }

        final daily = data['daily'];
        final current = data['current_weather'];

        if (daily['time'] == null ||
            daily['temperature_2m_max'] == null ||
            daily['temperature_2m_min'] == null ||
            daily['weathercode'] == null ||
            current['temperature'] == null ||
            current['weathercode'] == null) {
          throw Exception('Invalid API response: Missing weather fields');
        }

        final currentWeather = WeatherData(
          dayName: 'الطقس الآن',
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
              maxTemp:
                  (daily['temperature_2m_max'][index] as num?)?.toInt() ?? 0,
              minTemp:
                  (daily['temperature_2m_min'][index] as num?)?.toInt() ?? 0,
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
      } else {
        throw Exception('Failed to fetch weather: ${response.statusCode}');
      }
    } catch (e) {
      _weatherData.value = [];
    }
  }

  @override
  Future<void> refreshWeather() async {
    await fetchCairoWeather();
  }

  @override
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
    _stationLoads.refresh(); // Trigger reactive update
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

class LoadDisplayWidget extends StatefulWidget {
  final double totalLoad;
  final bool isLoading;

  const LoadDisplayWidget({
    super.key,
    required this.totalLoad,
    required this.isLoading,
  });

  @override
  State<LoadDisplayWidget> createState() => _LoadDisplayWidgetState();
}

class _LoadDisplayWidgetState extends State<LoadDisplayWidget> {
  static const _updateInterval = Duration(seconds: 5);
  static const _historyRetentionMinutes = 60;

  double maxLoadInLastHour = 0.0;
  double _hourlyMax = 0.0;
  int? _trackedHour;
  DateTime? _trackedDate;
  final SupabaseService _supabaseService = SupabaseService();
  final List<Map<String, dynamic>> _loadHistory = [];
  Timer? timer;

  @override
  void initState() {
    super.initState();
    initializeHourlyMax();
    timer = Timer.periodic(_updateInterval, (_) => updateLoadHistory());
  }

  Future<void> initializeHourlyMax() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisHour = now.hour;
    try {
      final hourlyData = await _supabaseService.fetchHourlyMaxLoads(today);
      final Map<String, dynamic>? currentEntry = hourlyData.firstWhere(
        (e) => e['hour'] == thisHour,
        orElse: () => <String, dynamic>{},
      );
      _hourlyMax = currentEntry != null
          ? (currentEntry['max_load'] as num).toDouble()
          : 0.0;
    } catch (e) {
      _hourlyMax = 0.0;
    }
    _trackedHour = thisHour;
    _trackedDate = today;
  }

  Future<void> updateLoadHistory() async {
    if (!mounted) return;
    final now = DateTime.now();
    _loadHistory.add({'timestamp': now, 'totalLoad': widget.totalLoad});
    _loadHistory.removeWhere(
      (entry) =>
          now.difference(entry['timestamp'] as DateTime).inMinutes >
          _historyRetentionMinutes,
    );
    setState(() {
      maxLoadInLastHour = _loadHistory.isNotEmpty
          ? _loadHistory.map((e) => e['totalLoad'] as double).reduce(max)
          : widget.totalLoad;
    });

    if (_trackedHour == null || _trackedDate == null) return;

    final today = DateTime(now.year, now.month, now.day);
    final thisHour = now.hour;
    final dateChanged = now.year != _trackedDate!.year ||
        now.month != _trackedDate!.month ||
        now.day != _trackedDate!.day;
    final hourChanged = _trackedHour != thisHour || dateChanged;

    if (hourChanged) {
      try {
        final hourlyData = await _supabaseService.fetchHourlyMaxLoads(today);
        final Map<String, dynamic>? currentEntry = hourlyData.firstWhere(
          (e) => e['hour'] == thisHour,
          orElse: () => <String, dynamic>{},
        );
        final existingMax = currentEntry != null
            ? (currentEntry['max_load'] as num).toDouble()
            : 0.0;
        final newMax = max(existingMax, widget.totalLoad);
        _hourlyMax = newMax;
        if (widget.totalLoad > existingMax) {
          await _supabaseService.upsertHourlyMaxLoad(thisHour, today, newMax);
        }
      } catch (e) {
        _hourlyMax = widget.totalLoad;
        await _supabaseService.upsertHourlyMaxLoad(thisHour, today, _hourlyMax);
      }
      _trackedHour = thisHour;
      _trackedDate = today;
    } else if (widget.totalLoad > _hourlyMax) {
      _hourlyMax = widget.totalLoad;
      _supabaseService
          .upsertHourlyMaxLoad(thisHour, today, _hourlyMax)
          .catchError((e) {});
    }
  }

  @override
  void didUpdateWidget(LoadDisplayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.totalLoad != oldWidget.totalLoad) updateLoadHistory();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1.sw,
      margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      padding: EdgeInsets.all(12.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF06141C), Color(0xFF2C3D49)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10.r,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Total Electrical Load',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
            textDirection: TextDirection.rtl,
          ),
          SizedBox(height: 2.h),
          Text(
            widget.isLoading ? '...' : widget.totalLoad.toStringAsFixed(0),
            style: TextStyle(
              color: Colors.redAccent,
              fontSize: 44.sp,
              fontFamily: Appfontstring.tejwa1,
              fontWeight: FontWeight.w600,
              shadows: const [Shadow(color: Colors.red, blurRadius: 10)],
            ),
            textDirection: TextDirection.rtl,
          ),
          SizedBox(height: 2.h),
          RichText(
            textDirection: TextDirection.rtl,
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'القيمة القصوى في الساعة الأخيرة: ',
                  style: TextStyle(
                    color: const Color(0xDBF0E769),
                    fontSize: 12.sp,
                    fontFamily: Appfontstring.ChangaLight,
                  ),
                ),
                TextSpan(
                  text: maxLoadInLastHour.toStringAsFixed(0),
                  style: TextStyle(
                    color: const Color(0xFF03C6D0),
                    fontSize: 20.sp,
                    fontFamily: Appfontstring.ChangaLight,
                  ),
                ),
                TextSpan(
                  text: ' م.و',
                  style: TextStyle(
                    color: const Color(0xDBF0E769),
                    fontSize: 12.sp,
                    fontFamily: Appfontstring.ChangaLight,
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

class CustomActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;

  const CustomActionButton({
    super.key,
    required this.onPressed,
    this.icon = Icons.settings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(4.w),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.all(8.w),
          backgroundColor: const Color(0xFF1E88E5),
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: Icon(icon, size: 16.sp),
      ),
    );
  }
}

class StationloadnavScreen extends StatefulWidget {
  const StationloadnavScreen({super.key});

  @override
  State<StationloadnavScreen> createState() => _StationloadnavScreenState();
}

class _StationloadnavScreenState extends State<StationloadnavScreen> {
  static const _updateInterval = Duration(seconds: 4);
  Map<String, String> specificStations = {};

  final SupabaseService _supabaseService = SupabaseService();
  List<StationLoad> _stationLoads = [];
  bool _isLoading = true;
  String? _errorMessage;
  final GlobalKey<LiquidPullToRefreshState> _refreshIndicatorKey =
      GlobalKey<LiquidPullToRefreshState>();
  Timer? _timer;
  List<String> adminEmails = [];
  String? userEmail;

  @override
  void initState() {
    super.initState();
    userEmail = Supabase.instance.client.auth.currentUser?.email;
    _fetchData();
    _timer = Timer.periodic(_updateInterval, (_) => _updateLoads());
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final loads = await _supabaseService.fetchStationLoads();

      specificStations = await _supabaseService.fetchSpecificStations();

      setState(() {
        _stationLoads = loads;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'خطأ في جلب البيانات: $e';
        _isLoading = false;
      });
    }
  }

  void _updateLoads() {
    if (!mounted) return;
    final random = Random();
    setState(() {
      for (var station in _stationLoads) {
        final variationRange = station.maxVariation - station.minVariation;
        final randomVariation =
            station.minVariation + random.nextDouble() * variationRange;
        station.load =
            (station.baseLoad + randomVariation).clamp(0.0, double.infinity);
      }
    });
  }

  double _getTotalLoad() =>
      _stationLoads.fold(0.0, (sum, station) => sum + station.load);

  Future<void> _handleStationAction(
      BuildContext context, StationLoad station) async {
    final currentUserEmail = Supabase.instance.client.auth.currentUser?.email;
    final requiredEmail = specificStations[station.stationName];

    bool isCrccUser = false;
    try {
      final response =
          await Supabase.instance.client.from('user_crcc').select('user_email');
      final crccEmails =
          response.map((e) => e['user_email'] as String).toList();
      isCrccUser = crccEmails.contains(currentUserEmail);
    } catch (e) {
      debugPrint('Error checking user_crcc table');
    }

    if (isCrccUser) {
      showDialog(
        context: context,
        builder: (context) => StationDialog(
          station: station,
          onUpdate: () {
            setState(() {});
            _refreshIndicatorKey.currentState?.show();
          },
        ),
      );
      return;
    }

    if (requiredEmail != null && currentUserEmail != requiredEmail) {
      _showErrorSnackBar(
          context, 'غير مصرح لك بتعديل حمل محطة ${station.stationName}');
      return;
    }

    if (adminEmails.contains(currentUserEmail) ||
        requiredEmail == currentUserEmail) {
      showDialog(
        context: context,
        builder: (context) => StationDialog(
          station: station,
          onUpdate: () {
            setState(() {});
            _refreshIndicatorKey.currentState?.show();
          },
        ),
      );
    } else {
      _showErrorSnackBar(context, 'غير مصرح لك بتحديث بيانات المحطة');
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textDirection: TextDirection.rtl),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LiquidPullToRefresh(
      key: _refreshIndicatorKey,
      color: const Color(0xFF1E88E5),
      backgroundColor: Colors.white,
      height: 60.h,
      showChildOpacityTransition: false,
      onRefresh: _fetchData,
      child: WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          body: _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontFamily: Appfontstring.ChangaLight,
                          color: Colors.red,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      SizedBox(height: 16.h),
                      ElevatedButton(
                        onPressed: _fetchData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E88E5),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 20.w, vertical: 10.h),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r)),
                        ),
                        child: Text(
                          'إعادة المحاولة',
                          style: TextStyle(
                              fontSize: 14.sp,
                              fontFamily: Appfontstring.ChangaLight),
                        ),
                      ),
                    ],
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Appcolors.primaryColor,
                        const Color.fromARGB(177, 255, 255, 255)
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: LoadDisplayWidget(
                          totalLoad: _getTotalLoad(),
                          isLoading: _isLoading,
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Container(
                          margin: EdgeInsets.symmetric(
                              horizontal: 7.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(169, 255, 255, 255),
                            borderRadius: BorderRadius.circular(12.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10.r,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: DataTable(
                            columnSpacing: 9.w,
                            dividerThickness: 0.9,
                            headingRowHeight: 40.h,
                            dataRowHeight: 36.h,
                            headingRowColor: WidgetStateProperty.all(
                              const Color(0xFF1E88E5).withOpacity(0.1),
                            ),
                            columns: [
                              DataColumn(
                                label: SizedBox(
                                  width: 60.w,
                                  child: Text(
                                    'الإجراء',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: Appfontstring.ChangaLight,
                                      color: const Color(0xFF0D47A1),
                                    ),
                                    textDirection: TextDirection.rtl,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: SizedBox(
                                  width: 80.w,
                                  child: Text(
                                    'الحمل\n(م.و)',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: Appfontstring.ChangaLight,
                                      color: const Color(0xFF0D47A1),
                                    ),
                                    textDirection: TextDirection.rtl,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: SizedBox(
                                  width: 120.w,
                                  child: Text(
                                    'المحطة',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: Appfontstring.ChangaLight,
                                      color: const Color(0xFF0D47A1),
                                    ),
                                    textDirection: TextDirection.rtl,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: SizedBox(
                                  width: 40.w,
                                  child: Text(
                                    'رقم',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: Appfontstring.ChangaLight,
                                      color: const Color(0xFF0D47A1),
                                    ),
                                    textDirection: TextDirection.rtl,
                                  ),
                                ),
                              ),
                            ],
                            rows: _stationLoads.asMap().entries.map((entry) {
                              final index = entry.key;
                              final station = entry.value;
                              final showUpdateButton =
                                  station.load >= 0 && station.load <= 700;
                              final requiredEmail =
                                  specificStations[station.stationName];
                              final isUserAssigned = userEmail != null &&
                                  requiredEmail != null &&
                                  userEmail == requiredEmail;
                              return DataRow(
                                color: WidgetStateProperty.all(
                                  index % 2 == 0
                                      ? Colors.white
                                      : const Color(0xFFE3F2FD)
                                          .withOpacity(0.05),
                                ),
                                cells: [
                                  DataCell(
                                    Center(
                                      child: showUpdateButton
                                          ? CustomActionButton(
                                              onPressed: () =>
                                                  _handleStationAction(
                                                      context, station),
                                              icon: Icons.settings,
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 80.w,
                                      child: Text(
                                        _isLoading
                                            ? '...'
                                            : station.load.toStringAsFixed(2),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize:
                                              isUserAssigned ? 13.sp : 12.sp,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: Appfontstring.ChangaLight,
                                          color: isUserAssigned
                                              ? Colors.red
                                              : const Color(0xFF0D47A1),
                                        ),
                                        textDirection: TextDirection.rtl,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 120.w,
                                      child: Text(
                                        station.stationName,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize:
                                              isUserAssigned ? 13.sp : 12.sp,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: Appfontstring.ChangaLight,
                                          color: isUserAssigned
                                              ? Colors.red
                                              : const Color(0xFF0D47A1),
                                        ),
                                        textDirection: TextDirection.rtl,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 40.w,
                                      child: Text(
                                        '${index + 1}',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize:
                                              isUserAssigned ? 13.sp : 12.sp,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: Appfontstring.ChangaLight,
                                          color: isUserAssigned
                                              ? Colors.red
                                              : const Color(0xFF0D47A1),
                                        ),
                                        textDirection: TextDirection.rtl,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class StationDialog extends StatefulWidget {
  final StationLoad station;
  final VoidCallback onUpdate;

  const StationDialog({
    super.key,
    required this.station,
    required this.onUpdate,
  });

  @override
  State<StationDialog> createState() => StationDialogState();
}

class StationDialogState extends State<StationDialog> {
  final TextEditingController _loadController = TextEditingController();
  final SupabaseService _supabaseService = SupabaseService();
  String? _errorText;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadController.text = widget.station.load.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _loadController.dispose();
    super.dispose();
  }

  Future<void> _updateLoad(double newLoad) async {
    setState(() => _isUpdating = true);
    try {
      await _supabaseService.updateStationLoad(
          widget.station.stationName, newLoad);
      setState(() => widget.station.load = newLoad);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم تحديث ${widget.station.stationName} بنجاح',
              textDirection: TextDirection.rtl,
            ),
            backgroundColor: Colors.green,
          ),
        );
        widget.onUpdate();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ في التحديث: $e',
              textDirection: TextDirection.rtl,
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _validateAndUpdate() {
    final input =
        _loadController.text.trim().replaceAll('٫', '.').replaceAll(',', '.');
    final newLoad = double.tryParse(input);
    if (newLoad == null || newLoad < 0 || newLoad > 700) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال قيمة صحيحة بين 0 و 700',
              textDirection: TextDirection.rtl),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    _updateLoad(newLoad);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      title: Text(
        'تحديث المحطة',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
          fontFamily: Appfontstring.ChangaLight,
          color: const Color(0xFF0D47A1),
        ),
        textDirection: TextDirection.rtl,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'اسم المحطة: ${widget.station.stationName}',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                fontFamily: Appfontstring.ChangaLight,
              ),
              textDirection: TextDirection.rtl,
            ),
            SizedBox(height: 8.h),
            Text(
              'الحمل الحالي: ${widget.station.load.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                fontFamily: Appfontstring.ChangaLight,
              ),
              textDirection: TextDirection.rtl,
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: _loadController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: 'أدخل الحمل الجديد',
                hintStyle: TextStyle(
                  fontSize: 14.sp,
                  fontFamily: Appfontstring.ChangaLight,
                  color: Colors.grey,
                ),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: const BorderSide(color: Color(0xFF1E88E5)),
                ),
                errorText: _errorText,
                errorMaxLines: 2,
              ),
              textDirection: TextDirection.rtl,
              onChanged: (value) {
                final input =
                    value.trim().replaceAll('٫', '.').replaceAll(',', '.');
                setState(() {
                  if (input.isEmpty) {
                    _errorText = 'يرجى إدخال قيمة الحمل';
                  } else {
                    final parsed = double.tryParse(input);
                    if (parsed == null || parsed < 0 || parsed > 700) {
                      _errorText = 'يرجى إدخال رقم صحيح بين 0 و 700';
                    } else {
                      _errorText = null;
                    }
                  }
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              onPressed: (_errorText != null || _isUpdating)
                  ? null
                  : _validateAndUpdate,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r)),
              ),
              child: _isUpdating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'تحديث',
                      style: TextStyle(
                          fontSize: 14.sp,
                          fontFamily: Appfontstring.ChangaLight),
                    ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'إلغاء',
                style: TextStyle(
                  color: Colors.red,
                  fontFamily: Appfontstring.ChangaLight,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

const kPrimaryColor = Appcolors.primaryColor;
const kSecondaryColor = Color.fromARGB(255, 230, 156, 19);
const kTextColor = Colors.black;
const kSubtitleColor = Color.fromARGB(255, 99, 110, 209);
const kBackgroundColor = Color.fromARGB(255, 219, 216, 216);
const kPadding = EdgeInsets.symmetric(horizontal: 13.0, vertical: 10.0);
const kCardBorderRadius = BorderRadius.all(Radius.circular(15));

class FullScreenImagePage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImagePage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: Stack(children: [
            PhotoView(
                imageProvider: NetworkImage(imageUrl),
                minScale: PhotoViewComputedScale.contained * 0.8,
                maxScale: PhotoViewComputedScale.covered * 2.0,
                initialScale: PhotoViewComputedScale.contained,
                backgroundDecoration: const BoxDecoration(color: Colors.black),
                errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.error, color: Colors.red, size: 40)),
                loadingBuilder: (context, event) => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2)))
          ]),
        ));
  }
}

class StationDetailsPage extends StatelessWidget {
  final StationDetialesModel station;

  const StationDetailsPage({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
        body: Directionality(
            textDirection: TextDirection.rtl,
            child: CustomScrollView(slivers: [
              SliverAppBar(
                  expandedHeight: size.height * 0.1,
                  floating: true,
                  pinned: true,
                  snap: true,
                  flexibleSpace: FlexibleSpaceBar(
                      title: Text(
                        station.name,
                        style: TextStyle(
                            fontFamily: Appfontstring.ChangaLight,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.black),
                      ),
                      centerTitle: true,
                      background: Container(
                          decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                            kPrimaryColor,
                            Appcolors.primaryColor2
                          ]))))),
              SliverToBoxAdapter(
                  child: Column(children: [
                Container(
                  margin: const EdgeInsets.all(12.0),
                  child: _buildStationImage(size),
                ),
                // Info card
                Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12.0),
                    padding: const EdgeInsets.all(22.0),
                    decoration: BoxDecoration(
                        color: Colors.white, borderRadius: kCardBorderRadius),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildStationHeader(),
                          const SizedBox(height: 15),
                          _buildInfoList(),
                          const SizedBox(height: 20),
                          _buildFavoriteButton(),
                        ]))
              ]))
            ])));
  }

  Widget _buildStationImage(Size size) {
    return GestureDetector(
      onTap: () {
        Get.to(
          () => FullScreenImagePage(
            imageUrl: station.image.isNotEmpty
                ? station.image
                : 'https://via.placeholder.com/150',
          ),
        );
      },
      child: Hero(
        tag: 'station_${station.id}',
        child: Container(
          height: size.height * 0.3, // Taller image for visual impact
          decoration: BoxDecoration(
            borderRadius: kCardBorderRadius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: kCardBorderRadius,
            child: Image.network(
              station.image.isNotEmpty
                  ? station.image
                  : 'https://via.placeholder.com/150',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.error, color: Colors.red, size: 50),
                ),
              ),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStationHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                station.name,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                  fontFamily: Appfontstring.ChangaLight,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            if (station.isnew) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Text(
                  'محطة جديدة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 2,
          decoration: BoxDecoration(
            color: kPrimaryColor,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoList() {
    final infoItems = [
      _buildInfoRow(Icons.location_on, 'المنطقة', station.zone),
      _buildInfoRow(Icons.electrical_services, 'الحمل ( م . و)', station.load),
      _buildInfoRow(Icons.access_time, 'وقت الإنشاء', station.year),
      _buildInfoRow(Icons.storage, 'السعة', station.cap),
      _buildInfoRow(Icons.category, 'النوع', station.type),
    ];

    return Column(
      children: infoItems,
    );
  }

  Widget _buildInfoRow(IconData icon, String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: kPrimaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$label:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: kSubtitleColor,
                    fontFamily: Appfontstring.ChangaLight,
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 2),
                Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: kTextColor,
                    fontFamily: Appfontstring.ChangaLight,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteButton() {
    final favoritesController = Get.find<FavoritesController>();
    return Obx(
      () => SizedBox(
        child: ElevatedButton.icon(
          onPressed: () => favoritesController.toggleFavorite(station),
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Icon(
              favoritesController.isFavorite(station)
                  ? Iconsax.heart5
                  : Iconsax.heart,
              key: ValueKey(favoritesController.isFavorite(station)),
              color: Colors.white,
              size: 22,
            ),
          ),
          label: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Text(
              favoritesController.isFavorite(station)
                  ? 'إزالة من المفضلة'
                  : 'إضافة إلى المفضلة',
              style: const TextStyle(
                fontFamily: Appfontstring.ChangaLight,
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: kSecondaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 5),
            shape: RoundedRectangleBorder(borderRadius: kCardBorderRadius),
            elevation: 5,
            shadowColor: Colors.black.withOpacity(0.25),
          ),
        ),
      ),
    );
  }
}

class WestScreen extends StatelessWidget {
  const WestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return SizedBox(
        width: screenWidth,
        height: screenHeight,
        child: Center(child: Text('WestScreen')));
  }
}

class EastScreen extends StatelessWidget {
  const EastScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return SizedBox(
        width: screenWidth,
        height: screenHeight,
        child: Center(child: Text('EastScreen')));
  }
}

class NonthScreen extends StatelessWidget {
  const NonthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return SizedBox(
        width: screenWidth,
        height: screenHeight,
        child: Center(child: Text('NonthScreen')));
  }
}

class SouthScreen extends StatelessWidget {
  const SouthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return SizedBox(
        width: screenWidth,
        height: screenHeight,
        child: Center(child: Text('SouthScreen')));
  }
}

class LoadnavScreen extends StatefulWidget {
  const LoadnavScreen({super.key});

  @override
  State<LoadnavScreen> createState() => _LoadnavScreenState();
}

class _LoadnavScreenState extends State<LoadnavScreen> {
  static const _updateInterval = Duration(seconds: 5);

  final SupabaseService _supabaseService = SupabaseService();
  List<StationLoad> _stationLoads = [];
  bool _isLoading = true;
  String? _errorMessage;
  final GlobalKey<LiquidPullToRefreshState> _refreshIndicatorKey =
      GlobalKey<LiquidPullToRefreshState>();
  final GlobalKey<_HourlyMaxLoadTableState> _hourlyKey =
      GlobalKey<_HourlyMaxLoadTableState>();
  Timer? _timer;
  Map<String, double> previousLoads = {};
  Map<String, bool> isIncreasing = {};
  double _previousTotalLoad = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _timer = Timer.periodic(_updateInterval, (_) => _updateLoads());
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final loads = await _supabaseService.fetchStationLoads();
      setState(() {
        _stationLoads = loads;
        _isLoading = false;
        _errorMessage = null;
        previousLoads.clear();
        for (final station in _stationLoads) {
          previousLoads[station.stationName] = station.load;
        }
        _previousTotalLoad = _getTotalLoad();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'خطأ في جلب بيانات المحطات: $e';
        _isLoading = false;
      });
    }
    // Refresh hourly data independently
    if (_hourlyKey.currentState != null) {
      await _hourlyKey.currentState!._fetchData();
    }
  }

  void _updateLoads() {
    if (!mounted || _stationLoads.isEmpty) return;

    final random = Random();
    bool anyChange = false;
    final Map<String, double> newPreviousLoads =
        Map<String, double>.from(previousLoads);
    final Map<String, bool> newIsIncreasing = <String, bool>{};

    for (final station in _stationLoads) {
      final prevLoad = previousLoads[station.stationName] ?? station.load;
      final variationRange = station.maxVariation - station.minVariation;
      final randomVariation =
          station.minVariation + random.nextDouble() * variationRange;
      final newLoad =
          (station.baseLoad + randomVariation).clamp(0.0, double.infinity);
      if (newLoad != prevLoad) {
        anyChange = true;
      }
      newIsIncreasing[station.stationName] = newLoad > prevLoad;
      station.load = newLoad;
      newPreviousLoads[station.stationName] = newLoad;
    }

    final newTotalLoad = _getTotalLoad();
    final totalChanged = newTotalLoad != _previousTotalLoad;

    if (anyChange || totalChanged) {
      setState(() {
        previousLoads = newPreviousLoads;
        isIncreasing = newIsIncreasing;
        _previousTotalLoad = newTotalLoad;
      });
    }
  }

  double _getTotalLoad() =>
      _stationLoads.fold(0.0, (sum, station) => sum + station.load);

  Color _getHeaderColor() =>
      const Color.fromARGB(255, 119, 235, 166).withOpacity(0.15);

  Widget _buildHeaderCell(String text, double width) {
    return SizedBox(
        width: width,
        child: Container(
            height: 36.h,
            decoration: BoxDecoration(
                color: _getHeaderColor(),
                border: Border.all(
                    color: Colors.black.withOpacity(0.2), width: 0.5),
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8), topRight: Radius.circular(8))),
            alignment: Alignment.center,
            child: Text(text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: Appfontstring.ChangaLight,
                    color: Color(0xFF0D47A1)),
                textDirection: TextDirection.rtl)));
  }

  Widget _buildLoadCell(StationLoad station, Color bgColor) {
    final bool hasChange = isIncreasing.containsKey(station.stationName);
    final Color loadColor = hasChange
        ? (isIncreasing[station.stationName]! ? Colors.green : Colors.red)
        : const Color(0xFF0D47A1);

    return SizedBox(
      width: 70.w,
      child: Container(
        height: 32.h,
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: Colors.black.withOpacity(0.2), width: 0.5),
        ),
        alignment: Alignment.center,
        child: Text(
          station.load.toStringAsFixed(0),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            fontFamily: Appfontstring.ChangaLight,
            color: loadColor,
          ),
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }

  Widget _buildNameCell(String stationName, Color bgColor) {
    return SizedBox(
      width: 100.w,
      child: Container(
        height: 32.h,
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: Colors.black.withOpacity(0.2), width: 0.5),
        ),
        alignment: Alignment.center,
        child: Text(
          stationName,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            fontFamily: Appfontstring.ChangaLight,
            color: Color(0xFF0D47A1),
          ),
          textDirection: TextDirection.rtl,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildEmptyCell(double width, Color bgColor) {
    return SizedBox(
      width: width,
      child: Container(
        height: 32.h,
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: Colors.black.withOpacity(0.2), width: 0.5),
        ),
      ),
    );
  }

  Widget _buildStationTable() {
    if (_stationLoads.isEmpty) {
      return const SizedBox.shrink();
    }

    final headerRow = Row(
      children: [
        _buildHeaderCell('الحمل\n(م.و)', 70.w),
        _buildHeaderCell('المحطة', 100.w),
        const SizedBox(width: 3),
        _buildHeaderCell('الحمل\n(م.و)', 70.w),
        _buildHeaderCell('المحطة', 100.w),
      ],
    );

    List<Widget> dataRows = [];
    for (int i = 0; i < _stationLoads.length; i += 2) {
      final pairIndex = i ~/ 2;
      final rowColor = pairIndex % 2 == 0
          ? Colors.white
          : const Color(0xFFE3F2FD).withOpacity(0.1);

      List<Widget> pairChildren = [
        _buildLoadCell(_stationLoads[i], rowColor),
        _buildNameCell(_stationLoads[i].stationName, rowColor),
      ];

      if (i + 1 < _stationLoads.length) {
        pairChildren.add(const SizedBox(width: 3));
        pairChildren.add(_buildLoadCell(_stationLoads[i + 1], rowColor));
        pairChildren
            .add(_buildNameCell(_stationLoads[i + 1].stationName, rowColor));
      } else {
        pairChildren.add(const SizedBox(width: 3));
        pairChildren.add(_buildEmptyCell(70.w, rowColor));
        pairChildren.add(_buildEmptyCell(100.w, rowColor));
      }

      dataRows.add(
        Row(
          children: pairChildren,
        ),
      );
    }

    return Column(
      children: [
        SizedBox(height: 20.h),
        const Center(
          child: Text('احمال محطات الربط و التبادلات',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: Appfontstring.ChangaLight,
                color: Colors.blueAccent,
              ),
              textDirection: TextDirection.rtl),
        ),
        SizedBox(height: 20.h),
        headerRow,
        ...dataRows,
      ],
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LiquidPullToRefresh(
      key: _refreshIndicatorKey,
      color: const Color(0xFF1E88E5),
      backgroundColor: Colors.white,
      height: 60.h,
      showChildOpacityTransition: false,
      onRefresh: _fetchData,
      child: WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          body: Container(
            decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [
              Appcolors.primaryColor,
              Colors.white,
              Colors.white
            ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  LoadDisplayWidget(
                      totalLoad: _getTotalLoad(), isLoading: _isLoading),
                  SizedBox(height: 16.h),
                  HourlyMaxLoadTable(
                    key: _hourlyKey,
                    tableName: AppConstants.tableHourlyMaxLoads,
                  ),
                  SizedBox(height: 16.h),
                  if (_errorMessage != null)
                    Container(
                        margin: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 12.h),
                        padding: EdgeInsets.all(16.h),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.r),
                          border:
                              Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Column(children: [
                          Text(
                            _errorMessage!,
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: Appfontstring.ChangaLight,
                              color: Colors.redAccent,
                            ),
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                          ),
                          SizedBox(height: 12.h),
                          ElevatedButton(
                              onPressed: _fetchData,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E88E5),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24.w,
                                  vertical: 12.h,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                              ),
                              child: const Text('إعادة المحاولة',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: Appfontstring.ChangaLight,
                                  )))
                        ]))
                  else
                    Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 12,
                                offset: const Offset(0, 4))
                          ]),
                      child: _isLoading
                          ? SizedBox(
                              height: 200.h,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF1E88E5),
                                ),
                              ),
                            )
                          : RepaintBoundary(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: _buildStationTable(),
                              ),
                            ),
                    ),
                  SizedBox(height: 60.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HourlyMaxLoadTable extends StatefulWidget {
  final String? tableName;
  final Key? key;

  const HourlyMaxLoadTable({
    this.key,
    this.tableName,
  }) : super(key: key);

  @override
  State<HourlyMaxLoadTable> createState() => _HourlyMaxLoadTableState();
}

class _HourlyMaxLoadTableState extends State<HourlyMaxLoadTable> {
  late final SupabaseClient _supabase;
  List<Map<String, dynamic>> _hourlyMaxLoadsToday = [];
  List<Map<String, dynamic>> _hourlyMaxLoadsYesterday = [];
  bool _isLoading = false;
  String? _error;
  double? _maxLoadValue;
  final bool _sortAscending = true;
  DateTime? _lastFetchTime;

  @override
  void initState() {
    super.initState();
    _supabase = Supabase.instance.client;
    _fetchData();
  }

  Future<void> _fetchData() async {
    final now = DateTime.now();
    if (_lastFetchTime != null &&
        now.difference(_lastFetchTime!).inMinutes < 1) {
      return;
    }
    _lastFetchTime = now;

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final table = widget.tableName ?? 'hourly_max_loads';
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final todayFormatted = today.toIso8601String().split('T')[0];
      final yesterdayFormatted = yesterday.toIso8601String().split('T')[0];

      final todayResponse = await _supabase
          .from(table)
          .select('hour, max_load')
          .eq('date', todayFormatted)
          .order('hour', ascending: _sortAscending)
          .timeout(const Duration(seconds: 10));

      final yesterdayResponse = await _supabase
          .from(table)
          .select('hour, max_load')
          .eq('date', yesterdayFormatted)
          .order('hour', ascending: _sortAscending)
          .timeout(const Duration(seconds: 10));

      if (mounted) {
        setState(() {
          _hourlyMaxLoadsToday = List<Map<String, dynamic>>.from(todayResponse);
          _hourlyMaxLoadsYesterday = List<Map<String, dynamic>>.from(
            yesterdayResponse,
          );
          _maxLoadValue =
              [..._hourlyMaxLoadsToday, ..._hourlyMaxLoadsYesterday].isNotEmpty
                  ? [..._hourlyMaxLoadsToday, ..._hourlyMaxLoadsYesterday]
                      .map((e) => (e['max_load'] as num?)?.toDouble() ?? 0.0)
                      .reduce((a, b) => a > b ? a : b)
                  : 0.0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _getErrorMessage(e);
          _isLoading = false;
        });
      }
    }
  }

  String _getErrorMessage(dynamic e) {
    if (e is TimeoutException) {
      return 'Request timed out. Please check your connection.';
    }
    return 'Error fetching data';
  }

  String _formatNumber(dynamic value) {
    if (value == null) return '0';
    final doubleNumber = (value as num?)?.toDouble() ?? 0.0;
    return doubleNumber == doubleNumber.roundToDouble()
        ? doubleNumber.toInt().toString()
        : doubleNumber.toStringAsFixed(1);
  }

  Widget _buildHourlyHeaderCell(
      String text, double width, Color primaryColor, double height) {
    return SizedBox(
      width: width,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.25),
          border: Border.all(color: Colors.black.withOpacity(0.2), width: 0.5),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            fontFamily: Appfontstring.ChangaLight,
            color: primaryColor,
          ),
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }

  Widget _buildHourlyLoadCell(String text, double width, Color primaryColor,
      bool isPeak, Color rowColor, double height) {
    final fontSize = height == 40.h ? 13.sp : 11.sp;
    return SizedBox(
      width: width,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: rowColor,
          border: Border.all(color: Colors.black.withOpacity(0.2), width: 0.5),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isPeak)
              const Icon(
                Icons.electric_bolt_sharp,
                size: 14,
                color: Colors.red,
              ),
            if (isPeak) SizedBox(width: 4.w),
            Flexible(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: isPeak ? FontWeight.w800 : FontWeight.w600,
                  fontFamily: Appfontstring.ChangaLight,
                  color: isPeak ? Colors.red : primaryColor,
                ),
                textDirection: TextDirection.rtl,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHourlyTimeCell(String text, double width, Color rowColor,
      Color primaryColor, double height) {
    final fontSize = height == 40.h ? 13.sp : 11.sp;
    return SizedBox(
      width: width,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: rowColor,
          border: Border.all(color: Colors.black.withOpacity(0.2), width: 0.5),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            fontFamily: Appfontstring.ChangaLight,
            color: primaryColor,
          ),
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.blue[900]!;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        image: DecorationImage(
            image: AssetImage(AppimageString.rtop),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
                const Color.fromARGB(39, 0, 0, 0).withOpacity(0.9),
                BlendMode.xor)),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isLargeScreen = constraints.maxWidth > 600.w;
          final isLandscape =
              MediaQuery.of(context).orientation == Orientation.landscape;

          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isLargeScreen ? 20.w : 16.w,
              vertical: isLargeScreen ? 16.h : 12.h,
            ),
            child: isLargeScreen && isLandscape
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: _buildTableSection(context, primaryColor),
                      ),
                      SizedBox(width: 7.w),
                      Expanded(
                        flex: 2,
                        child: _buildChartSection(context, primaryColor),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildTableSection(context, primaryColor),
                      SizedBox(height: isLargeScreen ? 28.h : 20.h),
                      _buildChartSection(context, primaryColor),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildTableSection(BuildContext context, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildTableHeader(context),
        SizedBox(height: 12.h),
        RepaintBoundary(
          child: _buildDataTable(context, primaryColor: primaryColor),
        ),
      ],
    );
  }

  Widget _buildTableHeader(BuildContext context) {
    return const Center(
      child: Text(
        'أقصى حمل لكل ساعة (اليوم)',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          fontFamily: Appfontstring.ChangaLight,
          color: Colors.black87,
        ),
        textDirection: TextDirection.rtl,
      ),
    );
  }

  Widget _buildDataTable(BuildContext context, {required Color primaryColor}) {
    final isLargeScreen = ScreenUtil().screenWidth > 600.w;

    final loadWidth = isLargeScreen ? 90.w : 80.w;
    final timeWidth = isLargeScreen ? 80.w : 70.w;
    final gap = const SizedBox(width: 12);
    final headingHeight = isLargeScreen ? 40.h : 36.h;
    final dataHeight = isLargeScreen ? 40.h : 36.h;

    if (_isLoading) {
      return SizedBox(
        height: isLargeScreen ? 320.h : 280.h,
        child: Center(
          child: CircularProgressIndicator(
            color: primaryColor,
            strokeWidth: 2.w,
          ),
        ),
      );
    }

    if (_error != null) {
      return SizedBox(
        height: isLargeScreen ? 320.h : 280.h,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error!,
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: isLargeScreen ? 16.sp : 14.sp,
                  fontFamily: Appfontstring.ChangaLight,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),
              ElevatedButton(
                onPressed: _fetchData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: EdgeInsets.symmetric(
                    horizontal: isLargeScreen ? 24.w : 20.w,
                    vertical: isLargeScreen ? 12.h : 10.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                child: Text(
                  'إعادة المحاولة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isLargeScreen ? 14.sp : 12.sp,
                    fontFamily: Appfontstring.ChangaLight,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_hourlyMaxLoadsToday.isEmpty) {
      return SizedBox(
        height: isLargeScreen ? 320.h : 280.h,
        child: Center(
          child: Text(
            'لا توجد بيانات متاحة',
            style: TextStyle(
              fontSize: isLargeScreen ? 16.sp : 14.sp,
              fontFamily: Appfontstring.ChangaLight,
              color: primaryColor,
            ),
            textDirection: TextDirection.rtl,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: primaryColor.withOpacity(0.3), width: 1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          children: [
            // Header
            Row(
              children: [
                _buildHourlyHeaderCell(
                    'أقصى حمل\n(م.و)', loadWidth, primaryColor, headingHeight),
                _buildHourlyHeaderCell(
                    'الساعة', timeWidth, primaryColor, headingHeight),
                gap,
                _buildHourlyHeaderCell(
                    'أقصى حمل\n(م.و)', loadWidth, primaryColor, headingHeight),
                _buildHourlyHeaderCell(
                    'الساعة', timeWidth, primaryColor, headingHeight),
              ],
            ),
            // Data rows
            ...List.generate(12, (pairIndex) {
              final i = pairIndex * 2;
              final hour1 = i;
              final hourData1 = _hourlyMaxLoadsToday.firstWhere(
                (data) => data['hour'] == hour1,
                orElse: () => {'hour': hour1, 'max_load': 0.0},
              );
              final isPeak1 = _maxLoadValue != null &&
                  hourData1['max_load'] != null &&
                  (hourData1['max_load'] as num).toDouble() >=
                      _maxLoadValue! * 0.95;

              final hour2 = i + 1;
              final hourData2 = _hourlyMaxLoadsToday.firstWhere(
                (data) => data['hour'] == hour2,
                orElse: () => {'hour': hour2, 'max_load': 0.0},
              );
              final isPeak2 = _maxLoadValue != null &&
                  hourData2['max_load'] != null &&
                  (hourData2['max_load'] as num).toDouble() >=
                      _maxLoadValue! * 0.95;

              final baseRowColor = pairIndex % 2 == 0
                  ? Colors.transparent
                  : primaryColor.withOpacity(0.08);
              final hasPeak = isPeak1 || isPeak2;
              final rowColor =
                  hasPeak ? primaryColor.withOpacity(0.2) : baseRowColor;

              return Row(
                children: [
                  _buildHourlyLoadCell(
                    _formatNumber(hourData1['max_load']),
                    loadWidth,
                    primaryColor,
                    isPeak1,
                    rowColor,
                    dataHeight,
                  ),
                  _buildHourlyTimeCell(
                    _formatHour(hour1),
                    timeWidth,
                    rowColor,
                    primaryColor,
                    dataHeight,
                  ),
                  gap,
                  _buildHourlyLoadCell(
                    _formatNumber(hourData2['max_load']),
                    loadWidth,
                    primaryColor,
                    isPeak2,
                    rowColor,
                    dataHeight,
                  ),
                  _buildHourlyTimeCell(
                    _formatHour(hour2),
                    timeWidth,
                    rowColor,
                    primaryColor,
                    dataHeight,
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatHour(int hour) {
    return '${hour.toString().padLeft(2, '0')}:00';
  }

  Widget _buildChartSection(BuildContext context, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RepaintBoundary(
          child: _buildLineChart(context, primaryColor),
        ),
      ],
    );
  }

  Widget _buildLineChart(BuildContext context, Color primaryColor) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isLargeScreen = ScreenUtil().screenWidth > 600.w;
    final todayColor = primaryColor;
    final yesterdayColor = Colors.greenAccent;

    final todaySpots = List.generate(24, (index) {
      final hourData = _hourlyMaxLoadsToday.firstWhere(
        (data) => data['hour'] == index,
        orElse: () => {'hour': index, 'max_load': 0.0},
      );
      return FlSpot(
        index.toDouble(),
        (hourData['max_load'] as num?)?.toDouble() ?? 0.0,
      );
    });

    final yesterdaySpots = List.generate(24, (index) {
      final hourData = _hourlyMaxLoadsYesterday.firstWhere(
        (data) => data['hour'] == index,
        orElse: () => {'hour': index, 'max_load': 0.0},
      );
      return FlSpot(
        index.toDouble(),
        (hourData['max_load'] as num?)?.toDouble() ?? 0.0,
      );
    });

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isLargeScreen ? 8.w : 4.w,
        vertical: isLargeScreen ? 12.h : 8.h,
      ),
      padding: EdgeInsets.all(isLargeScreen ? 20.w : 16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [Colors.grey[900]!, Colors.grey[800]!]
              : [Colors.white, Colors.blueGrey[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Center(
            child: Text('الحمل الأقصى لكل ساعة (اليوم مقابل الأمس)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: Appfontstring.ChangaLight,
                  color: Colors.blue,
                ),
                textDirection: TextDirection.rtl),
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('اليوم', todayColor),
              SizedBox(width: isLargeScreen ? 28.w : 20.w),
              _buildLegendItem('الأمس', yesterdayColor),
            ],
          ),
          SizedBox(height: 16.h),
          SizedBox(
            height: isLargeScreen ? 300.h : 260.h,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval:
                      _maxLoadValue != null ? _maxLoadValue! / 5 : 1.0,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                    strokeWidth: 1,
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: isLargeScreen ? 52.w : 44.w,
                      interval:
                          _maxLoadValue != null ? _maxLoadValue! / 5 : 1.0,
                      getTitlesWidget: (value, meta) => Text(
                        _formatNumber(value),
                        style: TextStyle(
                          fontSize: isLargeScreen ? 12.sp : 11.sp,
                          fontFamily: Appfontstring.ChangaLight,
                          color: isDarkMode ? Colors.white70 : Colors.black87,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: isLargeScreen ? 36.h : 32.h,
                      interval: isLargeScreen ? 3 : 4,
                      getTitlesWidget: (value, meta) {
                        final hour = value.toInt();
                        return Text(
                          _formatHour(hour),
                          style: TextStyle(
                            fontSize: isLargeScreen ? 12.sp : 11.sp,
                            fontFamily: Appfontstring.ChangaLight,
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                          textDirection: TextDirection.rtl,
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                    width: 1.5,
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: yesterdaySpots,
                    isCurved: true,
                    color: yesterdayColor,
                    barWidth: isLargeScreen ? 3 : 2,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: yesterdayColor.withOpacity(0.2),
                    ),
                  ),
                  LineChartBarData(
                    spots: todaySpots,
                    isCurved: true,
                    color: todayColor,
                    barWidth: isLargeScreen ? 3 : 2,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: todayColor.withOpacity(0.2),
                    ),
                  ),
                ],
                minX: 0,
                maxX: 23,
                minY: 0,
                maxY: _maxLoadValue != null ? _maxLoadValue! * 1.1 : 100.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    final isLargeScreen = ScreenUtil().screenWidth > 600.w;
    return Row(
      children: [
        Container(
          width: isLargeScreen ? 18.w : 14.w,
          height: isLargeScreen ? 18.h : 14.h,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 8.w),
        Text(
          label,
          style: TextStyle(
            fontSize: isLargeScreen ? 15.sp : 13.sp,
            fontFamily: Appfontstring.ChangaLight,
            color: color,
            fontWeight: FontWeight.w600,
          ),
          textDirection: TextDirection.rtl,
        ),
      ],
    );
  }
}

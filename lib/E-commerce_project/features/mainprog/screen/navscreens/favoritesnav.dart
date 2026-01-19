import 'dart:convert';
import 'package:amiraly/E-commerce_project/common/models/appmodels.dart';
import 'package:amiraly/E-commerce_project/features/mainprog/screen/stationdetailes/stationdetailes.dart';
import 'package:amiraly/E-commerce_project/util/constant/constants.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesNav extends StatelessWidget {
  const FavoritesNav({super.key});

  @override
  Widget build(BuildContext context) {
    final favoritesController = Get.find<FavoritesController>();
    return PopScope(
      canPop: false,
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
                delegate: SliverChildBuilderDelegate((context, index) {
                  // تحديد سقف للتأخير بحد أقصى ثانية واحدة لضمان سرعة الظهور
                  final delay = (index * 150).clamp(0, 1000);
                  return FadeInUp(
                    duration: Duration(milliseconds: 400 + delay),
                    child: GradientStationCard(
                      station: controller.favorites[index],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StationDetailsPage(
                            station: controller.favorites[index],
                          ),
                        ),
                      ),
                    ),
                  );
                }, childCount: controller.favorites.length))),
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

  // استخدام Set للتحقق السريع من المفضلات (Lookup Optimization O(1))
  final RxSet<String> _favoriteNames = <String>{}.obs;

  static const String _favoritesKey = 'favorites';

  @override
  void onInit() {
    super.onInit();
    _loadFavorites();
  }

  bool isFavorite(StationDetialesModel station) {
    return _favoriteNames.contains(station.name);
  }

  Future<void> toggleFavorite(StationDetialesModel station) async {
    try {
      if (isFavorite(station)) {
        favorites.removeWhere((fav) => fav.name == station.name);
        _favoriteNames.remove(station.name);
      } else {
        favorites.add(station);
        _favoriteNames.add(station.name);
      }
      await _saveFavorites();
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      Get.snackbar('خطأ', 'فشل في تحديث المفضلات');
    }
  }

  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoriteJsons =
          favorites.map((fav) => jsonEncode(fav.toJson())).toList();
      await prefs.setStringList(_favoritesKey, favoriteJsons);
    } catch (e) {
      debugPrint('Error saving favorites: $e');
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoriteJsons = prefs.getStringList(_favoritesKey) ?? [];

      favorites.clear();
      _favoriteNames.clear();

      for (var jsonStr in favoriteJsons) {
        try {
          final station = StationDetialesModel.fromJson(jsonDecode(jsonStr));
          if (station.name.isNotEmpty) {
            favorites.add(station);
            _favoriteNames.add(station.name);
          }
        } catch (e) {
          debugPrint('Error parsing favorite station: $e');
        }
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
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

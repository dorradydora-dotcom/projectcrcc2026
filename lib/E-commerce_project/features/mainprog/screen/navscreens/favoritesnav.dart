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
        backgroundColor: const Color(0xFF0F172A),
        body: Obx(
          () => CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeaderSection(context),
              ),
              if (favoritesController.favorites.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(context),
                )
              else ...[
                _buildFavoriteTitle(favoritesController),
                _buildGridLayout(context, favoritesController),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
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
      height: 120.h,
      child: Stack(
        children: [
          Positioned(
            right: 10.w,
            top: 30.h,
            child: Icon(
              Icons.favorite,
              size: 80.sp,
              color: Colors.white.withOpacity(0.09),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FadeInDown(
                  duration: const Duration(milliseconds: 600),
                  child: Text(
                    'المفضلات',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22.sp,
                      fontFamily: Appfontstring.ChangaLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteTitle(FavoritesController controller) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
        child: FadeInDown(
          duration: const Duration(milliseconds: 600),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Icon(Icons.favorite, color: Colors.redAccent, size: 18.sp),
                  SizedBox(width: 8.w),
                  Text(
                    'المحطات المفضلة (${controller.favorites.length})',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontFamily: Appfontstring.ChangaLight,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
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
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Icon(
                    Icons.favorite_border,
                    size: 64.sp,
                    color: Colors.white24,
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                'لا توجد مفضلات',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontFamily: Appfontstring.ChangaLight,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'ابدأ بإضافة محطاتك المفضلة للوصول إليها بسرعة في أي وقت.',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontFamily: Appfontstring.ChangaLight,
                  color: Colors.white54,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              )
            ],
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
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12.h,
              crossAxisSpacing: 12.w,
              childAspectRatio: 0.85,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final delay = (index * 100).clamp(0, 800);
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
            }, childCount: controller.favorites.length)));
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
          color: Colors.white.withOpacity(0.05),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
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
                  color: Colors.white.withOpacity(0.05),
                  child: Center(
                    child: Icon(Icons.error, color: Colors.red, size: 32.sp),
                  ),
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.white.withOpacity(0.05),
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
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(station.name,
                        style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: Appfontstring.ChangaLight),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    SizedBox(height: 2.h),
                    Text(station.zone,
                        style: TextStyle(
                          fontSize: 9.sp,
                          fontFamily: Appfontstring.ChangaLight,
                          color: Colors.white70,
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

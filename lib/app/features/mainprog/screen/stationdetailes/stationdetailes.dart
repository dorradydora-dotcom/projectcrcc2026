import 'package:amiraly/app/common/models/appmodels.dart';
import 'package:amiraly/app/features/mainprog/screen/navscreens/favorites_controller.dart';
import 'package:amiraly/app/util/constant/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:photo_view/photo_view.dart';
import 'package:amiraly/core/widgets/electric_loading_indicator.dart';


const kPrimaryColor = Appcolors.primaryColor;
const kSecondaryColor = StationDetailsConstants.secondaryColor;
const kTextColor = StationDetailsConstants.textColor;
const kSubtitleColor = StationDetailsConstants.subtitleColor;
const kBackgroundColor = StationDetailsConstants.backgroundColor;

// Removed const to allow ScreenUtil (which is runtime)
EdgeInsets kPadding = EdgeInsets.symmetric(
    horizontal: StationDetailsConstants.horizontalPadding.w,
    vertical: StationDetailsConstants.verticalPadding.h);
BorderRadius kCardBorderRadius =
    BorderRadius.all(Radius.circular(StationDetailsConstants.borderRadius.r));

class StationDetailsPage extends StatelessWidget {
  final StationDetialesModel station;

  const StationDetailsPage({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    // ScreenUtil takes care of sizing, so we don't strictly need MediaQuery for height if we use .h
    // But keeping size for proportional height if desired, or switching to .h

    return Scaffold(
        body: Directionality(
            textDirection: TextDirection.rtl,
            child: CustomScrollView(slivers: [
              SliverAppBar(
                  expandedHeight: 80.h, // Responsive height
                  floating: true,
                  pinned: true,
                  snap: true,
                  flexibleSpace: FlexibleSpaceBar(
                      title: Text(
                        station.name,
                        style: TextStyle(
                            fontFamily: Appfontstring.ChangaLight,
                            fontSize: 16.sp, // Responsive font
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
                  margin: EdgeInsets.all(12.w),
                  child: _buildStationImage(),
                ),
                // Info card
                Container(
                    margin: EdgeInsets.symmetric(horizontal: 12.w),
                    padding: EdgeInsets.all(22.w),
                    decoration: BoxDecoration(
                        color: Colors.white, borderRadius: kCardBorderRadius),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildStationHeader(),
                          SizedBox(height: 15.h),
                          _buildInfoList(),
                          SizedBox(height: 20.h),
                          _buildFavoriteButton(),
                        ]))
              ]))
            ])));
  }

  Widget _buildStationImage() {
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
          height: 240.h, // Fixed responsive height instead of percentage
          decoration: BoxDecoration(
            borderRadius: kCardBorderRadius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12.r,
                offset: Offset(0, 6.h),
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
                child: Center(
                  child: Icon(Icons.error, color: Colors.red, size: 50.sp),
                ),
              ),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                }
                return Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: ElectricLoadingIndicator(),
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
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                  fontFamily: Appfontstring.ChangaLight,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            if (station.isnew) ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(15.r),
                ),
                child: Text(
                  'محطة جديدة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: 12.h),
        Container(
          height: 2.h,
          decoration: BoxDecoration(
            color: kPrimaryColor,
            borderRadius: BorderRadius.circular(1.r),
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
      padding: EdgeInsets.symmetric(vertical: 8.0.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: kPrimaryColor, size: 20.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$label:',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: kSubtitleColor,
                    fontFamily: Appfontstring.ChangaLight,
                  ),
                  textAlign: TextAlign.right,
                ),
                SizedBox(height: 2.h),
                Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: kTextColor,
                    fontFamily: Appfontstring.digital,
                    fontFamilyFallback: const [Appfontstring.ChangaLight],
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
              size: 22.sp,
            ),
          ),
          label: Padding(
            padding: EdgeInsets.symmetric(vertical: 5.h),
            child: Text(
              favoritesController.isFavorite(station)
                  ? 'إزالة من المفضلة'
                  : 'إضافة إلى المفضلة',
              style: TextStyle(
                fontFamily: Appfontstring.ChangaLight,
                fontSize: 16.sp,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: kSecondaryColor,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 5.h),
            shape: RoundedRectangleBorder(borderRadius: kCardBorderRadius),
            elevation: 5,
            shadowColor: Colors.black.withOpacity(0.25),
          ),
        ),
      ),
    );
  }
}

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
                    child: ElectricLoadingIndicator()))
          ]),
        ));
  }
}

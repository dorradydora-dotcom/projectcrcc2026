import 'package:amiraly/E-commerce_project/common/models/appmodels.dart';
import 'package:amiraly/E-commerce_project/features/mainprog/screen/navscreens/favorites_controller.dart';
import 'package:amiraly/E-commerce_project/util/constant/constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:photo_view/photo_view.dart';

const kPrimaryColor = Appcolors.primaryColor;
const kSecondaryColor = StationDetailsConstants.secondaryColor;
const kTextColor = StationDetailsConstants.textColor;
const kSubtitleColor = StationDetailsConstants.subtitleColor;
const kBackgroundColor = StationDetailsConstants.backgroundColor;
const kPadding = EdgeInsets.symmetric(
    horizontal: StationDetailsConstants.horizontalPadding,
    vertical: StationDetailsConstants.verticalPadding);
const kCardBorderRadius =
    BorderRadius.all(Radius.circular(StationDetailsConstants.borderRadius));

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

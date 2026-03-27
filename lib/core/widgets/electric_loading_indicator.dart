import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';
import 'package:amiraly/app/util/constant/constants.dart';

class ElectricLoadingIndicator extends StatelessWidget {
  final double? size;
  final Color? color;

  const ElectricLoadingIndicator({
    super.key,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Flash(
        infinite: true,
        duration: const Duration(milliseconds: 1500),
        child: Icon(
          Iconsax.flash5,
          size: size ?? 40.sp,
          color: color ?? Appcolors.gold,
          shadows: [
            Shadow(
              blurRadius: 10.0,
              color: (color ?? Appcolors.gold).withValues(alpha: 0.5),
              offset: const Offset(0, 0),
            ),
          ],
        ),
      ),
    );
  }
}

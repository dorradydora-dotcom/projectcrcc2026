import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:marquee/marquee.dart';
import 'package:amiraly/app/util/constant/constants.dart';

class NewsTicker extends StatelessWidget {
  final List<String> news;
  final double velocity;
  final Color backgroundColor;
  final String title;
  final IconData icon;

  const NewsTicker({
    super.key,
    required this.news,
    this.velocity = 30.0,
    this.backgroundColor = Colors.white10,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (news.isEmpty) return const SizedBox.shrink();

    final fullText = news.join('   |   ');

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 2.h),
      height: 20.h,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
            width: 0.8,
          ),
        ),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Row(
              children: [
                // Title Section
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.1),
                    border: Border(
                      left: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        color: Colors.blueAccent.shade100,
                        size: 13.sp,
                      ),
                      SizedBox(width: 5.w),
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 9.sp,
                          fontFamily: Appfontstring.ChangaLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Marquee Section
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6.w),
                    child: Marquee(
                      text: fullText,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 10.sp,
                        fontFamily: Appfontstring.ChangaLight,
                        fontWeight: FontWeight.w400,
                      ),
                      scrollAxis: Axis.horizontal,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      blankSpace: 60.0,
                      velocity: velocity,
                      pauseAfterRound: const Duration(seconds: 1),
                      accelerationDuration: const Duration(seconds: 1),
                      accelerationCurve: Curves.linear,
                      decelerationDuration: const Duration(milliseconds: 500),
                      decelerationCurve: Curves.easeOut,
                      textDirection: TextDirection.rtl,
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

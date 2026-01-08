// ============================================================================
// HOME PAGE
// ============================================================================

import 'package:amiraly/E-commerce_project/common/widgets/appbar.dart';
import 'package:amiraly/E-commerce_project/features/auth/homepage/homepagecontroller.dart';
import 'package:amiraly/E-commerce_project/features/auth/homepage/homepagewidgets.dart';
import 'package:amiraly/E-commerce_project/util/constant/constants.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// الصفحة الرئيسية مع شريط التنقل السفلي
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final HomePageController _controller;
  late final AnimationController _animationController;
  late final Animation<double> _glowAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(HomePageController());

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.4, end: 0.8).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = AppSizes.heightcurved(context);

    return Scaffold(
      appBar: const CustomAppBar(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Appcolors.primaryColor.withOpacity(0.2),
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, -1),
            )
          ],
        ),
        child: Obx(() => Directionality(
              textDirection: TextDirection.rtl,
              child: CurvedNavigationBar(
                backgroundColor: Colors.transparent,
                color: Appcolors.primaryColor,
                buttonBackgroundColor: Colors.transparent,
                height: height,
                animationCurve: Curves.easeInOutCubic,
                index: _controller.selectedPage.value,
                items: buildNavigationItems(
                  _controller,
                  _animationController,
                  _glowAnimation,
                  _scaleAnimation,
                ),
                onTap: _controller.updateSelectedPage,
                letIndexChange: (index) => true,
                animationDuration: const Duration(milliseconds: 600),
              ),
            )),
      ),
      body: Directionality(
        textDirection: TextDirection.ltr,
        child: PageView(
          controller: _controller.pageController,
          children: _controller.pages,
          onPageChanged: (index) {
            _controller.selectedPage.value = index;
          },
        ),
      ),
    );
  }
}

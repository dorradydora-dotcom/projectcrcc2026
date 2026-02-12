import 'package:amiraly/E-commerce_project/features/auth/onboarding/onboardingcontroller.dart';
import 'package:amiraly/E-commerce_project/util/constant/constants.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

// ==============================
// الثوابت والأنماط
// ==============================

// ==============================
// نموذج بيانات الصفحة
// ==============================

class OnboardingPageData {
  final String id;
  final String imageAsset;
  final String title;
  final String subtitle;
  final Duration? animationDelay;

  const OnboardingPageData({
    required this.id,
    required this.imageAsset,
    required this.title,
    required this.subtitle,
    this.animationDelay,
  });
}

class OnboardingPagesRepository {
  static final List<OnboardingPageData> pages = [
    OnboardingPageData(
      id: '1',
      imageAsset: AppimageString.on1,
      title: AppTextString.boarding1text1,
      subtitle: AppTextString.boarding1text2,
    ),
    OnboardingPageData(
      id: '2',
      imageAsset: AppimageString.on2,
      title: AppTextString.boarding2text1,
      subtitle: AppTextString.boarding2text2,
      animationDelay: OnboardingConstants.delay200,
    ),
    OnboardingPageData(
      id: '3',
      imageAsset: AppimageString.on3,
      title: AppTextString.boarding3text1,
      subtitle: AppTextString.boarding3text2,
      animationDelay: OnboardingConstants.delay400,
    ),
    OnboardingPageData(
      id: '4',
      imageAsset: AppimageString.on4,
      title: AppTextString.boarding4text1,
      subtitle: AppTextString.boarding4text2,
      animationDelay: OnboardingConstants.delay400,
    ),
  ];

  static int get pageCount => pages.length;

  static bool isLastPage(int index) => index == pageCount - 1;
}

// ==============================
// Widgets
// ==============================

class OnboardingContent extends StatelessWidget {
  final String id;
  final String imageAsset;
  final String title;
  final String subtitle;

  const OnboardingContent({
    super.key,
    required this.id,
    required this.imageAsset,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scaleFactor = size.width / OnboardingConstants.baseScreenWidth;

    return Stack(
      children: [
        // Background - For page 4, we use a gradient background instead of full image
        if (id != '4')
          Positioned.fill(
            child: Image.asset(
              imageAsset,
              fit: BoxFit.cover,
            ),
          ),

        if (id == '4')
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Appcolors.primaryColor,
                    const Color(0xFF163C5E),
                    const Color(0xFF0F2B44),
                    const Color(0xFF081A2A),
                  ],
                ),
              ),
            ),
          ),

        // Specialized images for page 4
        if (id == '4') ...[
          // Top Center Image (on5)
          Positioned(
            top: size.height * 0.2,
            left: size.width * 0.1,
            right: size.width * 0.1,
            child: FadeInDown(
              duration: const Duration(milliseconds: 800),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(55),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(255, 0, 0, 0),
                      spreadRadius: 60,
                      blurRadius: 80,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Image.asset(
                    AppimageString.on5,
                    height: size.height * 0.25,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          // Bottom Left Image (on4)
          Positioned(
            bottom: size.height * 0.04,
            left: size.width * 0.05,
            child: FadeInLeft(
              duration: const Duration(milliseconds: 800),
              delay: const Duration(milliseconds: 400),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.asset(
                  AppimageString.on4,
                  width: size.width * 0.4,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],

        // Gradient overlay for text readability (only if background image is present)
        if (id != '4')
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.9),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

        // Gradient overlay for page 4 (vignette effect)
        if (id == '4')
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.0,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                  ],
                ),
              ),
            ),
          ),

        // Content (Title & Subtitle)
        Positioned(
          bottom: size.height * 0.22, // Positioned lower (closer to indicators)
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeInUp(
                  duration: const Duration(milliseconds: 600),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: Appfontstring.ChangaLight,
                      color: Colors.yellow,
                      fontSize:
                          OnboardingConstants.baseFontSizeTitle * scaleFactor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FadeInUp(
                  duration: const Duration(milliseconds: 600),
                  delay: const Duration(milliseconds: 200),
                  child: Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: OnboardingConstants.baseFontSizeSubtitle *
                          scaleFactor,
                      fontFamily: Appfontstring.ChangaLight,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.5,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          offset: const Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class OnboardingSkipButton extends StatelessWidget {
  final VoidCallback onSkip;

  const OnboardingSkipButton({
    super.key,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scaleFactor = size.width / OnboardingConstants.baseScreenWidth;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size.width * 0.04,
        vertical: size.height * 0.01,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: OnboardingConstants.skipButtonBorderColor,
        ),
      ),
      child: TextButton(
        onPressed: onSkip,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          'Skip',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize:
                        OnboardingConstants.baseFontSizeButton * scaleFactor,
                  ) ??
              const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

class OnboardingNextButton extends StatelessWidget {
  final bool isLastPage;
  final VoidCallback onNext;

  const OnboardingNextButton({
    super.key,
    required this.isLastPage,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scaleFactor = size.width / OnboardingConstants.baseScreenWidth;
    final controller = Get.find<OnboardingController>();

    return Stack(
      alignment: Alignment.center,
      children: [
        Obx(
          () => SizedBox(
            width: 70 * scaleFactor,
            height: 70 * scaleFactor,
            child: CircularProgressIndicator(
              value: (controller.currentPageIndex.value + 1) /
                  OnboardingPagesRepository.pageCount,
              strokeWidth: 3,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: onNext,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            shape: const CircleBorder(),
            padding: EdgeInsets.all(16 * scaleFactor),
            elevation: 10,
            shadowColor: Colors.blue.withOpacity(0.4),
          ),
          child: Icon(
            Iconsax.arrow_right_3,
            size: 24 * scaleFactor,
          ),
        ),
      ],
    );
  }
}

// ==============================
// الشاشة الرئيسية
// ==============================

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(OnboardingController());
    return Container(
      decoration: BoxDecoration(
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
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: GetBuilder<OnboardingController>(
          builder: (controller) {
            final size = MediaQuery.of(context).size;

            return Stack(
              children: [
                // Page View (Background images are inside this)
                _buildPageView(controller),

                // Skip Button
                Positioned(
                  top:
                      size.height * OnboardingConstants.skipButtonTopRatio + 20,
                  right: size.width * OnboardingConstants.skipButtonRightRatio,
                  child: FadeInRight(
                    duration: Duration(milliseconds: 800),
                    child: OnboardingSkipButton(
                      onSkip: controller.skipOnboarding,
                    ),
                  ),
                ),

                // Next/Finish Button
                Positioned(
                  bottom: size.height * OnboardingConstants.buttonBottomRatio,
                  right: size.width * OnboardingConstants.buttonRightRatio,
                  child: ZoomIn(
                    duration: OnboardingConstants.zoomDuration,
                    child: OnboardingNextButton(
                      isLastPage: controller.isLastPage,
                      onNext: controller.nextPage,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPageView(OnboardingController controller) {
    return PageView(
      controller: controller.pageController,
      onPageChanged: controller.updateCurrentPage,
      children: OnboardingPagesRepository.pages.map((page) {
        return OnboardingContent(
          id: page.id,
          imageAsset: page.imageAsset,
          title: page.title,
          subtitle: page.subtitle,
        );
      }).toList(),
    );
  }
}

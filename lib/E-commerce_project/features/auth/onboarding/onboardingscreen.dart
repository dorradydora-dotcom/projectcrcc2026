import 'package:amiraly/E-commerce_project/features/auth/onboarding/onboardingcontroller.dart';
import 'package:amiraly/E-commerce_project/util/constant/constants.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

// ==============================
// الثوابت والأنماط
// ==============================

class OnboardingConstants {
  // Animation durations
  static const fadeDuration = Duration(milliseconds: 1200);
  static const zoomDuration = Duration(milliseconds: 700);
  static const delay200 = Duration(milliseconds: 400);
  static const delay400 = Duration(milliseconds: 500);

  // Layout ratios
  static const double skipButtonTopRatio = 0.02;
  static const double skipButtonRightRatio = 0.044;
  static const double dotsBottomRatio = 0.22;
  static const double dotsLeftRatio = 0.44;
  static const double buttonBottomRatio = 0.04;
  static const double buttonRightRatio = 0.04;
  static const double contentHorizontalRatio = 0.07;
  static const double contentVerticalRatio = 0.07;
  static const double imageTopSpacingRatio = 0.1;
  static const double imageMaxHeightRatio = 0.5;
  static const double imageMaxWidthRatio = 0.8;
  static const double titleSpacingRatio = 0.05;
  static const double subtitleSpacingRatio = 0.015;

  // UI Constants
  static const borderRadius = 24.0;
  static const borderWidth = 0.5;
  static const shadowBlurRadius = 20.0;
  static const shadowSpreadRadius = 1.0;
  static const shadowOpacity = 0.3;
  static const dotSpacing = 5.0;
  static const dotRadius = 8.0;
  static const activeDotWidth = 15.0;
  static const inactiveDotHeight = 4.0;
  static const buttonElevation = 6.0;
  static const buttonPaddingRatio = 0.05;
  static const buttonIconSizeRatio = 15.0;
  static const baseScreenWidth = 375.0;
  static const baseFontSizeTitle = 25.0;
  static const baseFontSizeSubtitle = 13.0;
  static const baseFontSizeButton = 14.0;

  // Colors
  static const Color backgroundColor = Colors.white;
  static const Color shadowColor = Colors.blue;
  static const Color inactiveDotColor = Color.fromARGB(125, 158, 158, 158);
  static const Color activeDotColor = Colors.blue;
  static const Color buttonBackgroundColor = Color.fromARGB(252, 180, 214, 243);
  static const Color borderColor = Colors.black;
  static const Color subtitleColor = Colors.grey;
  static const Color skipButtonBorderColor = Color.fromARGB(115, 0, 0, 0);
}

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
      imageAsset: AppimageString.electric,
      title: AppTextString.boarding1text1,
      subtitle: AppTextString.boarding1text2,
    ),
    OnboardingPageData(
      id: '2',
      imageAsset: AppimageString.together,
      title: AppTextString.boarding2text1,
      subtitle: AppTextString.boarding2text2,
      animationDelay: OnboardingConstants.delay200,
    ),
    OnboardingPageData(
      id: '3',
      imageAsset: AppimageString.network,
      title: AppTextString.boarding3text1,
      subtitle: AppTextString.boarding3text2,
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
  final String imageAsset;
  final String title;
  final String subtitle;

  const OnboardingContent({
    super.key,
    required this.imageAsset,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scaleFactor = size.width / OnboardingConstants.baseScreenWidth;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: size.height * OnboardingConstants.contentHorizontalRatio,
        vertical: size.height * OnboardingConstants.contentVerticalRatio,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
              height: size.height * OnboardingConstants.imageTopSpacingRatio),

          // Image Container
          Flexible(
            flex: 3,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight:
                    size.height * OnboardingConstants.imageMaxHeightRatio,
                maxWidth: size.width * OnboardingConstants.imageMaxWidthRatio,
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(OnboardingConstants.borderRadius),
                  border: Border.all(
                    color: OnboardingConstants.borderColor,
                    width: OnboardingConstants.borderWidth,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: OnboardingConstants.shadowColor
                          .withOpacity(OnboardingConstants.shadowOpacity),
                      blurRadius: OnboardingConstants.shadowBlurRadius,
                      spreadRadius: OnboardingConstants.shadowSpreadRadius,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(OnboardingConstants.borderRadius),
                  child: Image.asset(
                    imageAsset,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: size.height * OnboardingConstants.titleSpacingRatio),

          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: Appfontstring.ChangaLight,
              fontSize: OnboardingConstants.baseFontSizeTitle * scaleFactor,
            ),
          ),

          SizedBox(
              height: size.height * OnboardingConstants.subtitleSpacingRatio),

          // Subtitle
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: OnboardingConstants.baseFontSizeSubtitle * scaleFactor,
              fontFamily: Appfontstring.ChangaLight,
              color: OnboardingConstants.subtitleColor,
            ),
          ),

          const Spacer(flex: 2),
        ],
      ),
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
                    fontSize:
                        OnboardingConstants.baseFontSizeButton * scaleFactor,
                  ) ??
              const TextStyle(),
        ),
      ),
    );
  }
}

class OnboardingPageIndicator extends StatelessWidget {
  final PageController controller;
  final Function(int) onDotClicked;

  const OnboardingPageIndicator({
    super.key,
    required this.controller,
    required this.onDotClicked,
  });

  @override
  Widget build(BuildContext context) {
    return SmoothPageIndicator(
      count: OnboardingPagesRepository.pageCount,
      controller: controller,
      onDotClicked: onDotClicked,
      effect: SwapEffect(
        spacing: OnboardingConstants.dotSpacing,
        radius: OnboardingConstants.dotRadius,
        dotWidth: OnboardingConstants.activeDotWidth,
        dotHeight: OnboardingConstants.inactiveDotHeight,
        paintStyle: PaintingStyle.fill,
        dotColor: OnboardingConstants.inactiveDotColor,
        activeDotColor: OnboardingConstants.activeDotColor,
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

    return ElevatedButton(
      onPressed: onNext,
      style: ElevatedButton.styleFrom(
        backgroundColor: OnboardingConstants.buttonBackgroundColor,
        shape: const CircleBorder(
          side: BorderSide(
            color: OnboardingConstants.borderColor,
            width: OnboardingConstants.borderWidth,
          ),
        ),
        padding:
            EdgeInsets.all(size.width * OnboardingConstants.buttonPaddingRatio),
        elevation: OnboardingConstants.buttonElevation,
      ),
      child: Icon(
        Iconsax.arrow_right_3,
        size: OnboardingConstants.buttonIconSizeRatio * scaleFactor,
      ),
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
    return Scaffold(
      backgroundColor: OnboardingConstants.backgroundColor,
      body: SafeArea(
        child: GetBuilder<OnboardingController>(
          builder: (controller) {
            final size = MediaQuery.of(context).size;

            return Stack(
              children: [
                // Page View
                _buildPageView(controller),

                // Skip Button
                Positioned(
                  top: size.height * OnboardingConstants.skipButtonTopRatio,
                  right: size.width * OnboardingConstants.skipButtonRightRatio,
                  child: FadeInRight(
                    duration: OnboardingConstants.fadeDuration,
                    child: OnboardingSkipButton(
                      onSkip: controller.skipOnboarding,
                    ),
                  ),
                ),

                // Page Indicator
                Positioned(
                  bottom: size.height * OnboardingConstants.dotsBottomRatio,
                  left: size.width * OnboardingConstants.dotsLeftRatio,
                  child: FadeIn(
                    duration: OnboardingConstants.fadeDuration,
                    child: OnboardingPageIndicator(
                      controller: controller.pageController,
                      onDotClicked: controller.goToPage,
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
        return FadeInUp(
          duration: OnboardingConstants.fadeDuration,
          delay: OnboardingConstants.delay200,
          child: OnboardingContent(
            imageAsset: page.imageAsset,
            title: page.title,
            subtitle: page.subtitle,
          ),
        );
      }).toList(),
    );
  }
}

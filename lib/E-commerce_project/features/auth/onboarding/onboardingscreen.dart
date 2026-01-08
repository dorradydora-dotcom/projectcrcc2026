import 'package:amiraly/E-commerce_project/features/auth/onboarding/onboardingcontroller.dart';
import 'package:amiraly/E-commerce_project/util/constant/constants.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

const _kFadeDuration = Duration(milliseconds: 1200);
const _kZoomDuration = Duration(milliseconds: 700);
const _kFadeInDuration = Duration(milliseconds: 1200);
const _kDelay200 = Duration(milliseconds: 400);
const _kDelay400 = Duration(milliseconds: 500);

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OnboardingController());

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(children: _buildStackChildren(controller, context)),
      ),
    );
  }

  List<Widget> _buildStackChildren(
    OnboardingController controller,
    BuildContext context,
  ) {
    return [
      _buildPageView(controller),
      Positioned(
          top: AppSizes.screenHeight(context) * 0.02,
          right: AppSizes.screenWidth(context) * 0.044,
          child: FadeInRight(
              duration: _kFadeDuration,
              child: OnboardingSkipWidget(
                  title: 'Skip',
                  onTap: () {
                    controller.skipPage();
                  }))),
      Positioned(
          bottom: AppSizes.screenHeight(context) * 0.22,
          left: AppSizes.screenWidth(context) * 0.44,
          child: FadeIn(
            duration: _kFadeInDuration,
            child: const Onboardingdots(),
          )),
      Positioned(
          bottom: AppSizes.screenHeight(context) * 0.04,
          right: AppSizes.screenWidth(context) * 0.04,
          child: ZoomIn(
              duration: _kZoomDuration,
              child: OnboardingElevation(
                  icon: Iconsax.arrow_right_3,
                  onTap: () {
                    controller.nextPage();
                  })))
    ];
  }

  Widget _buildPageView(OnboardingController controller) {
    return PageView(
        controller: controller.pageController,
        onPageChanged: controller.updateIndex,
        children: [
          FadeInUp(
              duration: _kFadeDuration,
              child: const OnboardingWidget(
                  image: AppimageString.electric,
                  title: AppTextString.boarding1text1,
                  subtitle: AppTextString.boarding1text2)),
          FadeInUp(
              duration: _kFadeDuration,
              delay: _kDelay200,
              child: const OnboardingWidget(
                  image: AppimageString.together,
                  title: AppTextString.boarding2text1,
                  subtitle: AppTextString.boarding2text2)),
          FadeInUp(
              duration: _kFadeDuration,
              delay: _kDelay400,
              child: const OnboardingWidget(
                  image: AppimageString.network,
                  title: AppTextString.boarding3text1,
                  subtitle: AppTextString.boarding3text2))
        ]);
  }
}

class OnboardingWidget extends StatelessWidget {
  final String image;
  final String title;
  final String subtitle;

  const OnboardingWidget({
    super.key,
    required this.image,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSizes.screenHeight(context) * 0.07,
        vertical: AppSizes.screenHeight(context) * 0.07,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(height: AppSizes.screenHeight(context) * 0.1),
          Flexible(
            flex: 3,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: AppSizes.screenHeight(context) * 0.5,
                  maxWidth: AppSizes.screenWidth(context) * 0.8),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.black, width: 0.5),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 1),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(image, fit: BoxFit.contain),
                ),
              ),
            ),
          ),
          SizedBox(height: AppSizes.screenHeight(context) * 0.05),
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: Appfontstring.ChangaLight,
                fontSize: 25 * (AppSizes.screenWidth(context) / 375.0),
              )),
          SizedBox(height: AppSizes.screenHeight(context) * 0.015),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13 * (AppSizes.screenWidth(context) / 375.0),
                fontFamily: Appfontstring.ChangaLight,
                color: Colors.grey),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class OnboardingSkipWidget extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;

  const OnboardingSkipWidget({super.key, required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSizes.screenWidth(context) * 0.04,
        vertical: AppSizes.screenHeight(context) * 0.01,
      ),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color.fromARGB(115, 0, 0, 0))),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14 * (AppSizes.screenWidth(context) / 375.0))),
      ),
    );
  }
}

class Onboardingdots extends StatelessWidget {
  const Onboardingdots({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = OnboardingController.instance;
    return Center(
      child: SmoothPageIndicator(
        count: 3,
        controller: controller.pageController,
        onDotClicked: controller.dotNavigationClick,
        effect: SwapEffect(
          spacing: 5,
          radius: 8,
          dotWidth: 15,
          dotHeight: 4,
          paintStyle: PaintingStyle.fill, // Filled dots for better visibility
          dotColor: const Color.fromARGB(125, 158, 158, 158),
          activeDotColor: Colors.blue,
        ),
      ),
    );
  }
}

class OnboardingElevation extends StatelessWidget {
  final IconData icon;
  final void Function()? onTap;

  const OnboardingElevation({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(252, 180, 214, 243),
            shape: const CircleBorder(
              side: BorderSide(color: Colors.black, width: 0.5),
            ),
            padding: EdgeInsets.all(AppSizes.screenWidth(context) * 0.05),
            elevation: 6),
        child: Icon(icon, size: 15 * (AppSizes.screenWidth(context) / 375.0)));
  }
}

import 'package:amiraly/E-commerce_project/features/auth/homepage/homepage.dart';
import 'package:amiraly/E-commerce_project/features/auth/login/loginscreen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OnboardingController extends GetxController {
  static OnboardingController get instance => Get.find();

  final pageController = PageController();
  Rx<int> currentPageIndex = 0.obs;

  void updateIndex(index) => currentPageIndex.value = index;

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
  }

  Future<void> navigateAfterOnboarding() async {
    await completeOnboarding();
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    Get.offAll(
      () => user != null ? const HomePage() : const LoginScreen(),
    );
  }

  void nextPage() {
    if (currentPageIndex.value == 2) {
      navigateAfterOnboarding();
    } else {
      int nextPageIndex = currentPageIndex.value + 1;
      pageController.animateToPage(
        nextPageIndex,
        duration: const Duration(milliseconds: 1100),
        curve: Curves.easeInOutCubicEmphasized,
      );
    }
  }

  void skipPage() {
    navigateAfterOnboarding();
  }

  void dotNavigationClick(index) {
    currentPageIndex.value = index;
    pageController.jumpToPage(index);
  }
}

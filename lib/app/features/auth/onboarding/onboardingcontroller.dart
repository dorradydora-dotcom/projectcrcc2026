// ==============================
// الـ Controller
// ==============================

import 'package:amiraly/app/features/auth/homepage/homepage.dart';
import 'package:amiraly/app/features/auth/login/loginscreen.dart';
import 'package:amiraly/app/features/auth/onboarding/onboardingscreen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OnboardingController extends GetxController {
  static OnboardingController get instance => Get.find();

  final pageController = PageController();
  final currentPageIndex = 0.obs;

  bool get isLastPage =>
      OnboardingPagesRepository.isLastPage(currentPageIndex.value);

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  void updateCurrentPage(int index) {
    currentPageIndex.value = index;
  }

  Future<void> _completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save onboarding status',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _navigateAfterOnboarding() async {
    await _completeOnboarding();

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      Get.offAll(
        () => user != null ? const HomePage() : const LoginScreen(),
        transition: Transition.fadeIn,
        duration: const Duration(milliseconds: 500),
      );
    } catch (e) {
      Get.offAll(
        () => const LoginScreen(),
        transition: Transition.fadeIn,
        duration: const Duration(milliseconds: 500),
      );
    }
  }

  void nextPage() {
    if (isLastPage) {
      _navigateAfterOnboarding();
    } else {
      final nextPageIndex = currentPageIndex.value + 1;
      pageController.animateToPage(
        nextPageIndex,
        duration: const Duration(milliseconds: 1100),
        curve: Curves.easeInOutCubicEmphasized,
      );
    }
  }

  void skipOnboarding() {
    _navigateAfterOnboarding();
  }

  void goToPage(int pageIndex) {
    if (pageIndex >= 0 && pageIndex < OnboardingPagesRepository.pageCount) {
      currentPageIndex.value = pageIndex;
      pageController.jumpToPage(pageIndex);
    }
  }
}

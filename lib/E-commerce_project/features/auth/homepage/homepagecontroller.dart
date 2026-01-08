// ============================================================================
// HOME STORE CONTROLLER
// ============================================================================

import 'package:amiraly/E-commerce_project/features/mainprog/screen/navscreens/areanav/areanav.dart';
import 'package:amiraly/E-commerce_project/util/validators/validatorHeper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// متحكم الصفحة الرئيسية
class HomePageController extends GetxController {
  final RxInt selectedPage = 0.obs;
  final RxBool isLoading = false.obs;
  final Rx<String?> error = Rx<String?>(null);

  final RxList<Widget> pages = <Widget>[
    const HomeNav(),
    const Areanav(),
    const FavoritesNav(),
    const StationloadnavScreen(),
    const LoadnavScreen(),
  ].obs;

  late PageController pageController;

  @override
  void onInit() {
    super.onInit();
    pageController = PageController(initialPage: 0);
    AppLogger.logInfo('HomeStoreController initialized');
  }

  @override
  void onClose() {
    pageController.dispose();
    AppLogger.logInfo('HomeStoreController disposed');
    super.onClose();
  }

  /// تحديث الصفحة المختارة
  void updateSelectedPage(int index) {
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// تحميل البيانات
  Future<void> loadData() async {
    try {
      isLoading.value = true;
      error.value = null;

      // يمكن إضافة منطق تحميل البيانات هنا

      AppLogger.logSuccess('Data loaded successfully');
    } catch (e, stackTrace) {
      error.value = e.toString();
      AppLogger.logError('Failed to load data', e, stackTrace);
    } finally {
      isLoading.value = false;
    }
  }
}

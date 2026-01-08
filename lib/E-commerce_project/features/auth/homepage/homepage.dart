// ============================================================================
// HOME PAGE - النسخة المحسّنة (مع الحفاظ على الأنيميشن الأصلي)
// ============================================================================

import 'package:amiraly/E-commerce_project/common/widgets/appbar.dart';
import 'package:amiraly/E-commerce_project/features/mainprog/screen/navscreens/Loadnav.dart';
import 'package:amiraly/E-commerce_project/features/mainprog/screen/navscreens/favoritesnav.dart';
import 'package:amiraly/E-commerce_project/features/mainprog/screen/navscreens/homenav.dart';
import 'package:amiraly/E-commerce_project/features/mainprog/screen/navscreens/stationloadnav.dart';
import 'package:amiraly/E-commerce_project/util/constant/constants.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:amiraly/E-commerce_project/features/mainprog/screen/navscreens/areanav.dart';
import 'package:amiraly/E-commerce_project/util/validators/validatorHeper.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';

// ============================================================================
// Navigation Item Model
// ============================================================================
class NavigationItemConfig {
  final String label;
  final IconData icon;
  final Color glowColor;

  const NavigationItemConfig({
    required this.label,
    required this.icon,
    required this.glowColor,
  });
}

// ============================================================================
// HomePage Widget
// ============================================================================
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

  // تعريف عناصر التنقل في مكان واحد
  static const _navigationItems = [
    NavigationItemConfig(
      label: 'الرئيسية',
      icon: Icons.home_outlined,
      glowColor: Color(0xFF4CAF50),
    ),
    NavigationItemConfig(
      label: 'المناطق',
      icon: Icons.account_tree_outlined,
      glowColor: Color(0xFF2196F3),
    ),
    NavigationItemConfig(
      label: 'المفضلة',
      icon: Icons.favorite_border_outlined,
      glowColor: Color(0xFFE91E63),
    ),
    NavigationItemConfig(
      label: 'محطات',
      icon: Icons.workspaces_outlined,
      glowColor: Color(0xFFFF9800),
    ),
    NavigationItemConfig(
      label: 'احمال',
      icon: Icons.bolt_outlined,
      glowColor: Color(0xFF9C27B0),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = Get.put(HomePageController());

    // الأنيميشن الأصلي بدون تعديل
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
      bottomNavigationBar: _buildBottomNavigationBar(height),
      body: _buildBody(),
    );
  }

  Widget _buildBottomNavigationBar(double height) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Appcolors.primaryColor.withOpacity(0.2),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, -1),
          ),
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
              items: _buildNavigationItems(),
              onTap: _controller.updateSelectedPage,
              letIndexChange: (_) => true,
              animationDuration: const Duration(milliseconds: 600),
            ),
          )),
    );
  }

  List<CurvedNavigationBarItem> _buildNavigationItems() {
    return List.generate(_navigationItems.length, (index) {
      final item = _navigationItems[index];
      final isSelected = _controller.selectedPage.value == index;

      return CurvedNavigationBarItem(
        child: _buildNavigationIcon(item, isSelected),
        label: item.label,
        labelStyle: TextStyle(
          fontSize: 12,
          fontFamily: Appfontstring.ChangaLight,
          color: C.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      );
    });
  }

  Widget _buildNavigationIcon(NavigationItemConfig item, bool isSelected) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) => Transform.scale(
        scale: isSelected ? _scaleAnimation.value : 0.9,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? item.glowColor : Colors.transparent,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: item.glowColor.withOpacity(_glowAnimation.value),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          padding: const EdgeInsets.all(6),
          child: Icon(
            item.icon,
            color: C.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Obx(() {
      // عرض حالة الخطأ
      if (_controller.error.value != null) {
        return _buildErrorState();
      }

      // عرض حالة التحميل
      if (_controller.isLoading.value) {
        return _buildLoadingState();
      }

      // عرض المحتوى العادي
      return Directionality(
        textDirection: TextDirection.ltr,
        child: PageView(
          controller: _controller.pageController,
          onPageChanged: _controller.onPageChanged,
          physics: const BouncingScrollPhysics(),
          children: _controller.pages,
        ),
      );
    });
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'حدث خطأ',
            style: TextStyle(
              fontSize: 20,
              fontFamily: Appfontstring.ChangaLight,
              color: Colors.red.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _controller.error.value ?? 'خطأ غير معروف',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontFamily: Appfontstring.ChangaLight,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _controller.loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Appcolors.primaryColor,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Appcolors.primaryColor,
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'جاري التحميل...',
            style: TextStyle(
              fontSize: 16,
              fontFamily: Appfontstring.ChangaLight,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// HomePage Controller - محسّن
// ============================================================================
class HomePageController extends GetxController {
  final RxInt selectedPage = 0.obs;
  final RxBool isLoading = false.obs;
  final Rx<String?> error = Rx<String?>(null);

  // الصفحات كـ RxList للتفاعلية
  final RxList<Widget> pages = <Widget>[
    const HomeNav(),
    const Areanav(),
    const FavoritesNav(),
    const StationloadnavScreen(),
    const LoadnavScreen(),
  ].obs;

  late final PageController pageController;

  @override
  void onInit() {
    super.onInit();
    pageController = PageController(initialPage: 0);
    AppLogger.logInfo('HomePageController initialized');
  }

  @override
  void onClose() {
    pageController.dispose();
    AppLogger.logInfo('HomePageController disposed');
    super.onClose();
  }

  /// تحديث الصفحة المختارة مع Validation
  void updateSelectedPage(int index) {
    if (index < 0 || index >= pages.length) {
      AppLogger.logWarning('Invalid page index: $index');
      return;
    }

    selectedPage.value = index;
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// معالج تغيير الصفحة من PageView
  void onPageChanged(int index) {
    if (index != selectedPage.value) {
      selectedPage.value = index;
    }
  }

  /// تحميل البيانات مع معالجة الأخطاء
  Future<void> loadData() async {
    try {
      isLoading.value = true;
      error.value = null;

      // محاكاة تحميل البيانات
      await Future.delayed(const Duration(seconds: 1));

      // يمكن إضافة منطق تحميل البيانات الفعلي هنا
      // مثال:
      // final result = await ApiService.getData();
      // if (result.isSuccess) {
      //   // معالجة البيانات
      // } else {
      //   throw Exception(result.error);
      // }

      AppLogger.logSuccess('Data loaded successfully');
    } on Exception catch (e, stackTrace) {
      error.value = 'فشل في تحميل البيانات: ${e.toString()}';
      AppLogger.logError('Failed to load data', e, stackTrace);
    } catch (e, stackTrace) {
      error.value = 'حدث خطأ غير متوقع';
      AppLogger.logError('Unexpected error', e, stackTrace);
    } finally {
      isLoading.value = false;
    }
  }

  /// إعادة تحميل البيانات
  @override
  Future<void> refresh() async {
    await loadData();
  }

  /// الانتقال إلى صفحة معينة مباشرة
  void jumpToPage(int index) {
    if (index >= 0 && index < pages.length) {
      selectedPage.value = index;
      pageController.jumpToPage(index);
    }
  }

  /// الحصول على الصفحة الحالية
  Widget get currentPage => pages[selectedPage.value];

  /// التحقق من وجود صفحة سابقة
  bool get hasPreviousPage => selectedPage.value > 0;

  /// التحقق من وجود صفحة تالية
  bool get hasNextPage => selectedPage.value < pages.length - 1;

  /// الانتقال للصفحة السابقة
  void goToPreviousPage() {
    if (hasPreviousPage) {
      updateSelectedPage(selectedPage.value - 1);
    }
  }

  /// الانتقال للصفحة التالية
  void goToNextPage() {
    if (hasNextPage) {
      updateSelectedPage(selectedPage.value + 1);
    }
  }
}

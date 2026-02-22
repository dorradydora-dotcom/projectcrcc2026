import 'package:amiraly/app/common/models/appmodels.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:amiraly/app/common/widgets/appbar.dart';
import 'package:amiraly/app/features/mainprog/screen/navscreens/Loadnav.dart';
import 'package:amiraly/app/features/mainprog/screen/navscreens/favoritesnav.dart';
import 'package:amiraly/app/features/mainprog/screen/navscreens/homenav.dart';
import 'package:amiraly/app/features/mainprog/screen/navscreens/stationloadnav.dart';
import 'package:amiraly/app/util/constant/constants.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:amiraly/app/features/mainprog/screen/navscreens/areanav.dart';
import 'package:amiraly/app/util/validators/validatorHeper.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import 'package:amiraly/core/services/auth_service.dart';
import 'package:amiraly/main.dart' show ensureServicesInitialized;

// ============================================================================
// HomePage Widget - مع FutureBuilder
// ============================================================================
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final Future<void> _initializationFuture;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _ensureServicesInitialized();
  }

  Future<void> _ensureServicesInitialized() async {
    try {
      // انتظار تهيئة الخدمات الأساسية
      await ensureServicesInitialized();

      // تهيئة AuthService إذا لم يكن مهيأ
      final authService = Get.find<AuthService>();
      if (!authService.isInitialized) {
        await authService.initializeServices();
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildInitializationLoading();
        }

        if (snapshot.hasError) {
          return _buildInitializationError(snapshot.error.toString());
        }

        return const _HomePageContent();
      },
    );
  }

  Widget _buildInitializationLoading() {
    return Container(
      decoration: const BoxDecoration(
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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                strokeWidth: 3.w,
                valueColor:
                    AlwaysStoppedAnimation<Color>(Appcolors.primaryColor2),
              ),
              SizedBox(height: 20.h),
              Text(
                'جاري تحميل الصفحة الرئيسية...',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontFamily: Appfontstring.ChangaLight,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInitializationError(String error) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64.sp,
                color: Colors.red.shade400,
              ),
              SizedBox(height: 20.h),
              Text(
                'فشل في تحميل الصفحة',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: Appfontstring.ChangaLight,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 10.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Text(
                  error,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontFamily: Appfontstring.ChangaLight,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              SizedBox(height: 30.h),
              ElevatedButton(
                onPressed: () => Get.offAll(() => const HomePage()),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Appcolors.primaryColor,
                    padding:
                        EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h)),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// HomePage Content (المحتوى فقط بعد التهيئة)
// ============================================================================
class _HomePageContent extends StatefulWidget {
  const _HomePageContent();

  @override
  State<_HomePageContent> createState() => __HomePageContentState();
}

class __HomePageContentState extends State<_HomePageContent>
    with SingleTickerProviderStateMixin {
  late final HomePageController _controller;
  late final AnimationController _animationController;
  late final Animation<double> _glowAnimation;
  late final Animation<double> _scaleAnimation;

  // تعريف الصفحات هنا في الـ UI
  final List<Widget> _pages = const [
    HomeNav(),
    Areanav(),
    FavoritesNav(),
    StationloadnavScreen(),
    LoadnavScreen(),
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
    final double height = 70.h;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_controller.selectedPage.value != 0) {
          _controller.updateSelectedPage(0);
        } else {
          // If already on the first page, we could show a dialog or allow exit.
          // For now, let's allow exit if we're at index 0 and press back again.
          // Note: In modern Flutter, we need to handle this carefully.
          // Setting canPop dynamically or using SystemNavigator.pop()
          _showExitDialog(context);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(
            0xFF081A2A), // 🔧 إضافة لون الخلفية لمنع ظهور الفراغ الأبيض
        appBar: const CustomAppBar(),
        bottomNavigationBar: _buildBottomNavigationBar(height),
        body: _buildBody(),
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('تنبيه',
              style: TextStyle(fontFamily: Appfontstring.ChangaLight)),
          content: Text('هل تريد الخروج من التطبيق؟',
              style: TextStyle(fontFamily: Appfontstring.ChangaLight)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('إلغاء',
                  style: TextStyle(fontFamily: Appfontstring.ChangaLight)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('خروج',
                  style: TextStyle(
                      fontFamily: Appfontstring.ChangaLight,
                      color: Colors.red)),
            ),
          ],
        ),
      ),
    ).then((value) {
      if (value == true) {
        // Exit the app
        Get.back();
      }
    });
  }

  Widget _buildBottomNavigationBar(double height) {
    return Obx(() => Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            top: false,
            child: CurvedNavigationBar(
              backgroundColor: const Color(0xFF081A2A),
              color: Appcolors.primaryColor,
              buttonBackgroundColor: const Color(0xFF081A2A),
              height: height,
              animationCurve: Curves.easeInOutCubic,
              index: _controller.selectedPage.value,
              items: _buildNavigationItems(),
              onTap: _controller.updateSelectedPage,
              letIndexChange: (_) => true,
              animationDuration: const Duration(milliseconds: 350),
            ),
          ),
        ));
  }

  List<CurvedNavigationBarItem> _buildNavigationItems() {
    return List.generate(navigationItems.length, (index) {
      final item = navigationItems[index];
      final isSelected = _controller.selectedPage.value == index;

      return CurvedNavigationBarItem(
        child: _buildNavigationIcon(item, isSelected),
        label: item.label,
        labelStyle: TextStyle(
          fontSize: 12.sp,
          fontFamily: Appfontstring.ChangaLight,
          color: Colors.white,
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
          padding: EdgeInsets.all(6.r),
          child: Icon(
            item.icon,
            color: Colors.white,
            size: 24.sp,
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

      // عرض المحتوى العادي - IndexedStack يحافظ على حالة كل تاب
      return IndexedStack(
        index: _controller.selectedPage.value,
        children: _pages,
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
            size: 64.sp,
            color: Colors.red.shade300,
          ),
          SizedBox(height: 16.h),
          Text(
            'حدث خطأ',
            style: TextStyle(
              fontSize: 20.sp,
              fontFamily: Appfontstring.ChangaLight,
              color: Colors.red.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Text(
              _controller.error.value ?? 'خطأ غير معروف',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                fontFamily: Appfontstring.ChangaLight,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: _controller.loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Appcolors.primaryColor,
              padding: EdgeInsets.symmetric(
                horizontal: 24.w,
                vertical: 12.h,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// HomePage Controller - محسّن مع Future
// ============================================================================
class HomePageController extends GetxController {
  final RxInt selectedPage = 0.obs;
  final RxBool isLoading = false.obs;
  final Rx<String?> error = Rx<String?>(null);
  final RxString userEmail = ''.obs;

  late final AuthService _authService;

  @override
  void onInit() {
    super.onInit();

    try {
      _authService = Get.find<AuthService>();

      // بدء تحميل البيانات
      _initializeData();

      AppLogger.logInfo('HomePageController initialized');
    } catch (e, stackTrace) {
      AppLogger.logError(
          'Failed to initialize HomePageController', e, stackTrace);
      error.value = 'فشل في تهيئة الصفحة الرئيسية';
    }
  }

  Future<void> _initializeData() async {
    try {
      isLoading.value = true;

      // تحميل بيانات المستخدم
      await _loadUserData();

      AppLogger.logSuccess('HomePage data initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.logError('Failed to initialize HomePage data', e, stackTrace);
      error.value = 'فشل في تحميل بيانات الصفحة';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadUserData() async {
    try {
      // استخدام الدالة الآمنة للحصول على البريد
      final email = await _authService.getCurrentUserEmailSafe();
      userEmail.value = email ?? 'مستخدم';

      AppLogger.logSuccess('User data loaded for HomePage: $email');
    } catch (e, stackTrace) {
      AppLogger.logError(
          'Failed to load user data in HomePageController', e, stackTrace);
      userEmail.value = 'مستخدم';
    }
  }

  @override
  void onClose() {
    AppLogger.logInfo('HomePageController disposed');
    super.onClose();
  }

  /// تحديث الصفحة المختارة
  void updateSelectedPage(int index) {
    selectedPage.value = index;
  }

  /// معالج تغيير الصفحة
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

      // إعادة تحميل بيانات المستخدم
      await _loadUserData();

      AppLogger.logSuccess('HomePage data reloaded successfully');
    } on Exception catch (e, stackTrace) {
      error.value = 'فشل في تحميل البيانات: ${e.toString()}';
      AppLogger.logError('Failed to reload HomePage data', e, stackTrace);
    } catch (e, stackTrace) {
      error.value = 'حدث خطأ غير متوقع';
      AppLogger.logError('Unexpected error in HomePage', e, stackTrace);
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
    selectedPage.value = index;
  }
}

import 'package:amiraly/E-commerce_project/features/auth/login/loginscreen.dart';
import 'package:amiraly/E-commerce_project/util/constant/constants.dart';
import 'package:amiraly/E-commerce_project/util/validators/validatorHeper.dart';
import 'package:amiraly/main.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CustomAppBarState extends State<CustomAppBar> {
  final AuthService _authService = AuthService.instance;
  String? _userEmail;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    try {
      // الانتظار حتى تكتمل تهيئة الخدمات
      await ensureServicesInitialized();

      // التأكد من أن AuthService مهيأ
      if (!_authService.isInitialized) {
        await _authService.initializeServices();
      }

      // الحصول على البريد الإلكتروني باستخدام الدالة الآمنة
      final email = _authService.getCurrentUserEmail();

      if (mounted) {
        setState(() {
          _userEmail = email;
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading user email: $e');
      AppLogger.logError(
          'Failed to load user email in CustomAppBar', e, stackTrace);

      if (mounted) {
        setState(() {
          _userEmail = null;
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  void _retryLoading() {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }
    _loadUserEmail();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = AppSizes.screenWidth(context);

    return AppBar(
      centerTitle: true,
      backgroundColor: Appcolors.primaryColor,
      title: _buildAppBarTitle(context, screenWidth),
      actions: [
        _buildSignOutButton(context, screenWidth),
        SizedBox(width: screenWidth * 0.01),
      ],
    );
  }

  Widget _buildAppBarTitle(BuildContext context, double screenWidth) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'الشـركـة المصريـة لنـقـل الكهـرباء',
          style: TextStyle(
            color: C.white,
            fontFamily: Appfontstring.ChangaLight,
            fontSize: responsiveFontSize(screenWidth, 0.044),
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '(القاهـرة) ',
              style: TextStyle(
                color: C.yellow,
                fontFamily: Appfontstring.ChangaLight,
                fontSize: responsiveFontSize(screenWidth, 0.033),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: screenWidth * 0.01),
            Text(
              'التحكم الاقليمى',
              style: TextStyle(
                color: C.white,
                fontFamily: Appfontstring.ChangaLight,
                fontSize: responsiveFontSize(screenWidth, 0.033),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        _buildUserEmailWidget(screenWidth),
      ],
    );
  }

  Widget _buildUserEmailWidget(double screenWidth) {
    if (_isLoading) {
      return SizedBox(
        height: responsiveFontSize(screenWidth, 0.025),
        child: Center(
          child: SizedBox(
            width: responsiveFontSize(screenWidth, 0.02),
            height: responsiveFontSize(screenWidth, 0.02),
            child: const CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                  Color.fromARGB(116, 178, 223, 155)),
            ),
          ),
        ),
      );
    }

    if (_hasError) {
      return GestureDetector(
        onTap: _retryLoading,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'فشل التحميل - انقر للمحاولة',
              style: TextStyle(
                color: const Color.fromARGB(255, 255, 123, 123),
                fontFamily: Appfontstring.ChangaLight,
                fontSize: responsiveFontSize(screenWidth, 0.023),
                fontWeight: FontWeight.normal,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.refresh,
              size: responsiveFontSize(screenWidth, 0.02),
              color: const Color.fromARGB(255, 255, 123, 123),
            ),
          ],
        ),
      );
    }

    return Text(
      'User : ${_userEmail ?? "غير معروف"}',
      style: TextStyle(
        color: const Color.fromARGB(116, 178, 223, 155),
        fontFamily: Appfontstring.ChangaLight,
        fontSize: responsiveFontSize(screenWidth, 0.025),
        fontWeight: FontWeight.normal,
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context, double screenWidth) {
    return IconButton(
      onPressed: _isLoading ? null : () => _showSignOutDialog(context),
      icon: Icon(
        Icons.exit_to_app_outlined,
        color: _isLoading
            ? const Color.fromARGB(100, 217, 10, 10) // شفاف عند التحميل
            : const Color.fromARGB(255, 217, 10, 10),
        size: responsiveFontSize(screenWidth, 0.066),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text(
              'تاكيد الخروج',
              style: TextStyle(fontFamily: Appfontstring.ChangaLight),
              textAlign: TextAlign.right,
            ),
            content: const Text(
              'هل تريد تسجيل الخروج؟',
              style: TextStyle(fontFamily: Appfontstring.ChangaLight),
              textAlign: TextAlign.right,
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  await _handleSignOut(context);
                },
                child: const Text(
                  'تسجيل الخروج',
                  style: TextStyle(
                    fontFamily: Appfontstring.ChangaLight,
                    color: C.red,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text(
                  'إلغاء',
                  style: TextStyle(fontFamily: Appfontstring.ChangaLight),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleSignOut(BuildContext context) async {
    try {
      // إضافة مؤشر تحميل أثناء تسجيل الخروج
      _showLoadingDialog(context);

      await _authService.signOut(context: context);

      if (mounted) {
        Navigator.of(context, rootNavigator: true)
            .pop(); // إغلاق dialog التحميل
        await Get.offAll(() => const LoginScreen());
      }
    } catch (e, stackTrace) {
      debugPrint('Error during sign out: $e');
      AppLogger.logError('Error during sign out', e, stackTrace);

      if (mounted) {
        Navigator.of(context, rootNavigator: true)
            .pop(); // إغلاق dialog التحميل
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'حدث خطأ أثناء تسجيل الخروج',
              textDirection: TextDirection.rtl,
              style: TextStyle(fontFamily: Appfontstring.ChangaLight),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'إعادة المحاولة',
              onPressed: () => _handleSignOut(context),
            ),
          ),
        );
      }
    }
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Expanded(
                child: Text(
                  'جاري تسجيل الخروج...',
                  style: TextStyle(fontFamily: Appfontstring.ChangaLight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // تنظيف أي resources إذا لزم
    super.dispose();
  }
}

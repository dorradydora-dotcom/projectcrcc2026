import 'package:amiraly/E-commerce_project/features/auth/login/loginscreen.dart';
import 'package:amiraly/E-commerce_project/util/constant/constants.dart';
import 'package:amiraly/E-commerce_project/util/validators/validatorHeper.dart';
import 'package:amiraly/main.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback? onRefresh;
  final List<Widget>? extraActions;
  const CustomAppBar({super.key, this.onRefresh, this.extraActions});

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
    // محاولة جلب البيانات بشكل متزامن أولاً لتجنب الوميض (Flicker)
    _tryLoadSynchronously();
  }

  void _tryLoadSynchronously() {
    try {
      // محاولة الوصول المباشر
      // نتحقق إذا كان الـ AuthService مهيأ بالفعل
      if (_authService.isInitialized) {
        final email = _authService.getCurrentUserEmail();
        if (email != null) {
          _userEmail = email;
          _isLoading = false;
          _hasError = false;
          return;
        }
      }

      // إذا لم ننجح متزامناً، نبدأ التحميل غير المتزامن
      _loadUserEmail();
    } catch (e) {
      // في حالة حدوث أي خطأ، نلجأ للطريقة الآمنة غير المتزامنة
      _loadUserEmail();
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

  Future<void> _loadUserEmail() async {
    // إذا تم التحميل بالفعل متزامناً، لا داعي للإكمال
    if (!_isLoading && _userEmail != null) return;

    try {
      // الحصول على البريد الإلكتروني مباشرة - الخدمات مضمونة من قبل AuthWrapper
      final email = await _authService.getCurrentUserEmailSafe();

      if (mounted) {
        setState(() {
          _userEmail = email;
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading user email: $e');
      // نفترض وجود AppLogger في النطاق (من main.dart أو غيره)
      try {
        AppLogger.logError('Failed to load user email', e, stackTrace);
      } catch (_) {
        // Fallback if AppLogger is not available/initialized
      }

      if (mounted) {
        setState(() {
          _userEmail = null;
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = AppSizes.screenWidth(context);

    return AppBar(
      centerTitle: true,
      backgroundColor: Appcolors.primaryColor,
      title: _buildAppBarTitle(context, screenWidth),
      actions: [
        if (widget.onRefresh != null)
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Colors.white,
              size: responsiveFontSize(screenWidth, 0.066),
            ),
            onPressed: widget.onRefresh,
          ),
        if (widget.extraActions != null) ...widget.extraActions!,
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
          AppBarText.companyName,
          style: TextStyle(
              color: C.white,
              fontFamily: Appfontstring.ChangaLight,
              fontSize: responsiveFontSize(screenWidth, 0.044),
              fontWeight: FontWeight.bold),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppBarText.cairo,
              style: TextStyle(
                color: C.yellow,
                fontFamily: Appfontstring.ChangaLight,
                fontSize: responsiveFontSize(screenWidth, 0.033),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: screenWidth * 0.01),
            Text(
              AppBarText.regionalControl,
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
              AppBarText.loadingFailed,
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
      '${AppBarText.userPrefix}${_userEmail ?? AppBarText.unknownUser}',
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
              AppBarText.signOutTitle,
              style: TextStyle(fontFamily: Appfontstring.ChangaLight),
              textAlign: TextAlign.right,
            ),
            content: const Text(
              AppBarText.signOutMessage,
              style: TextStyle(fontFamily: Appfontstring.ChangaLight),
              textAlign: TextAlign.right,
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Get.back(); // إغلاق الـ Dialog
                  await _handleSignOut(context);
                },
                child: const Text(
                  AppBarText.signOutButton,
                  style: TextStyle(
                    fontFamily: Appfontstring.ChangaLight,
                    color: C.red,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Get.back(), // إغلاق الـ Dialog
                child: const Text(
                  AppBarText.cancelButton,
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
        // إغلاق dialog التحميل (Root Navigator لأنه dialog)
        if (Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        await Get.offAll(() => const LoginScreen());
      }
    } catch (e, stackTrace) {
      debugPrint('Error during sign out: $e');
      try {
        AppLogger.logError('Error during sign out', e, stackTrace);
      } catch (_) {}

      if (mounted) {
        // إغلاق dialog التحميل عند الخطأ أيضاً
        if (Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              AppBarText.signOutError,
              textDirection: TextDirection.rtl,
              style: TextStyle(fontFamily: Appfontstring.ChangaLight),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: AppBarText.retry,
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
                  AppBarText.signOutLoading,
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

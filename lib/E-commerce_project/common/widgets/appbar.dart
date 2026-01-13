import 'package:amiraly/E-commerce_project/features/auth/login/loginscreen.dart';
import 'package:amiraly/E-commerce_project/util/constant/constants.dart';
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
  final AuthService _authService = AuthService();
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _userEmail = _authService.getCurrentUserEmail();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: true,
      backgroundColor: Appcolors.primaryColor,
      title: _buildAppBarTitle(context, AppSizes.screenWidth(context)),
      actions: [
        _buildSignOutButton(context, AppSizes.screenWidth(context)),
        SizedBox(width: AppSizes.screenWidth(context) * 0.01),
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
        Text(
          'User : $_userEmail',
          style: TextStyle(
            color: const Color.fromARGB(116, 178, 223, 155),
            fontFamily: Appfontstring.ChangaLight,
            fontSize: responsiveFontSize(screenWidth, 0.025),
            fontWeight: FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildSignOutButton(BuildContext context, double screenWidth) {
    return IconButton(
      onPressed: () => _showSignOutDialog(context),
      icon: Icon(
        Icons.exit_to_app_outlined,
        color: const Color.fromARGB(255, 217, 10, 10),
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
      await _authService.signOut(context: context);
      if (!mounted) return;

      await Get.offAll(() => const LoginScreen());
    } catch (e) {
      debugPrint('Error during sign out: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'حدث خطأ أثناء تسجيل الخروج',
            textDirection: TextDirection.rtl,
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

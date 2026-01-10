import 'package:amiraly/E-commerce_project/features/auth/login/loginscreen.dart';
import 'package:amiraly/E-commerce_project/util/constant/constants.dart';
import 'package:amiraly/main.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
        centerTitle: true,
        backgroundColor: Appcolors.primaryColor,
        title: _buildAppBarTitle(context, AppSizes.screenWidth(context)),
        actions: [
          _buildSignOutButton(context, AppSizes.screenWidth(context)),
          SizedBox(width: AppSizes.screenWidth(context) * 0.01),
        ]);
  }

  Widget _buildAppBarTitle(BuildContext context, double screenWidth) {
    AuthService authService = AuthService();
    String? userEmail = authService.getCurrentUserEmail();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('الشـركـة المصريـة لنـقـل الكهـرباء',
            style: TextStyle(
              color: C.white,
              fontFamily: Appfontstring.ChangaLight,
              fontSize: responsiveFontSize(screenWidth, 0.044),
              fontWeight: FontWeight.bold,
            )),
        Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('(القاهـرة) ',
                  style: TextStyle(
                      color: C.yellow,
                      fontFamily: Appfontstring.ChangaLight,
                      fontSize: responsiveFontSize(screenWidth, 0.033),
                      fontWeight: FontWeight.bold)),
              SizedBox(width: screenWidth * 0.01),
              Text('التحكم الاقليمى',
                  style: TextStyle(
                    color: C.white,
                    fontFamily: Appfontstring.ChangaLight,
                    fontSize: responsiveFontSize(screenWidth, 0.033),
                    fontWeight: FontWeight.bold,
                  ))
            ]),
        SizedBox(height: 5),
        Text(
          '$userEmail',
          style: TextStyle(
            color: const Color.fromARGB(116, 255, 153, 0),
            fontFamily: Appfontstring.ChangaLight,
            fontSize: responsiveFontSize(screenWidth, 0.025),
            fontWeight: FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildSignOutButton(BuildContext context, double screenWidth) {
    AuthService authService = AuthService();
    return IconButton(
        onPressed: () {
          final outerContext = context;
          showDialog(
              context: context,
              barrierDismissible: true,
              builder: (BuildContext dialogContext) {
                return Directionality(
                    textDirection: TextDirection.rtl,
                    child: AlertDialog(
                        title: const Text(
                          'تاكيد الخروج',
                          style:
                              TextStyle(fontFamily: Appfontstring.ChangaLight),
                          textAlign: TextAlign.right,
                        ),
                        content: const Text(
                          'هل تريد تسجيل الخروج؟',
                          style:
                              TextStyle(fontFamily: Appfontstring.ChangaLight),
                          textAlign: TextAlign.right,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () async {
                              Navigator.of(dialogContext).pop();
                              try {
                                await authService.signOut(
                                    context: outerContext);
                                if (outerContext.mounted) {
                                  Get.offAll(() => LoginScreen());
                                }
                                // ignore: empty_catches
                              } catch (e) {}
                            },
                            child: const Text(
                              'تسجيل الخروج',
                              style: TextStyle(
                                  fontFamily: Appfontstring.ChangaLight,
                                  color: C.red),
                            ),
                          ),
                          TextButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                              child: const Text('إلغاء',
                                  style: TextStyle(
                                      fontFamily: Appfontstring.ChangaLight)))
                        ]));
              });
        },
        icon: Icon(Icons.exit_to_app_outlined,
            color: const Color.fromARGB(255, 217, 10, 10),
            size: responsiveFontSize(screenWidth, 0.066)));
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

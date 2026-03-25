import 'package:amiraly/app/common/widgets/headlinetext.dart';
import 'package:amiraly/app/features/auth/homepage/homepage.dart';
import 'package:amiraly/app/util/constant/constants.dart';
import 'package:amiraly/app/util/validators/validator_helper.dart';
import 'package:amiraly/core/services/auth_service.dart';
import 'package:animate_do/animate_do.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:amiraly/core/widgets/electric_loading_indicator.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // استخدام nullable مؤقتاً
  LoginControllerImp? _loginController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    // تسجيل الـ Controller إذا لم يكن مسجلاً
    if (!Get.isRegistered<LoginControllerImp>()) {
      Get.put(LoginControllerImp());
    }
    _loginController = Get.find<LoginControllerImp>();
  }

  // دالة مساعدة للحصول على الـ Controller بأمان
  LoginControllerImp get loginController {
    if (_loginController == null) {
      _initializeController();
    }
    return _loginController!;
  }

  @override
  void dispose() {
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // التأكد من التهيئة قبل البناء
    if (_loginController == null) {
      _initializeController();
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: PopScope(
        canPop: false,
        child: Stack(
          children: [
            const LogBackGroung(),
            _buildLoginForm(),
            _buildDeveloperInfo(),
            _buildMinistryLogo(),
            _buildAdditionalLogo1(),
            _buildAdditionalLogo2(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: LayoutBuilder(builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: constraints.maxHeight * 0.05),
                _buildHeaderText(),
                SizedBox(height: 3.h),
                _buildDivider(),
                SizedBox(height: 4.h),
                _buildCompanyTexts(),
                SizedBox(height: constraints.maxHeight * 0.01),
                SizedBox(height: 180.h), // Reduced from 256.h
                _buildEmailField(),
                SizedBox(height: 12.h), // Reduced from 16.h
                _buildPasswordField(),
                SizedBox(height: 24.h), // Reduced from 32.h
                _buildLoginButton(constraints),
                SizedBox(height: 140.h), // Reduced from 192.h
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHeaderText() {
    return FadeInDown(
      duration: const Duration(milliseconds: 800),
      delay: const Duration(milliseconds: 50),
      child: TextLine(
        text: 'تسـجيل الدخـول',
        color: Colors.white,
        fontWeight: FF.B,
        fontSize: 18.sp,
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1.h,
      width: 120.w,
      decoration: const BoxDecoration(color: Colors.white),
    );
  }

  Widget _buildCompanyTexts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FadeInDown(
          duration: const Duration(milliseconds: 900),
          delay: const Duration(milliseconds: 100),
          child: TextLine(
            text: 'برنامج التحكم الاقليمى للقاهرة الكبرى',
            color: Colors.pink,
            fontWeight: FF.B,
            fontSize: 13.sp,
          ),
        ),
        FadeInDown(
          duration: const Duration(milliseconds: 900),
          delay: const Duration(milliseconds: 200),
          child: TextLine(
            text: 'الشركة المصرية لنقل الكهرباء',
            color: Colors.red,
            fontWeight: FF.B,
            fontSize: 10.sp,
          ),
        ),
        FadeInDown(
          duration: const Duration(milliseconds: 900),
          delay: const Duration(milliseconds: 300),
          child: TextLine(
            text: 'مـركز التحكم الاقليمى',
            color: const Color.fromARGB(255, 243, 233, 150),
            fontWeight: FF.B,
            fontSize: 10.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return FadeInUp(
      duration: const Duration(milliseconds: 800),
      child: CustomTextFormFieldlogin(
        focusNode: _emailFocusNode,
        valid: (val) => validInput(val!, 5, 30, 'email'),
        hinttext: 'Enter your mail',
        icon: Icons.email_outlined,
        labelText: 'Email',
        mycontroller: loginController.email,
        keyboardType: TextInputType.emailAddress,
        obscureText: false,
        textInputAction: TextInputAction.next,
        onFieldSubmitted: (_) {
          _emailFocusNode.unfocus();
          FocusScope.of(context).requestFocus(_passwordFocusNode);
        },
      ),
    );
  }

  Widget _buildPasswordField() {
    return FadeInUp(
      duration: const Duration(milliseconds: 800),
      delay: const Duration(milliseconds: 100),
      child: CustomTextFormFieldlogin(
        focusNode: _passwordFocusNode,
        valid: (val) => validInput(val!, 7, 30, 'password'),
        hinttext: 'Enter password',
        icon: Icons.lock,
        labelText: 'Password',
        mycontroller: loginController.password,
        obscureText: true,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) {
          _passwordFocusNode.unfocus();
          if (_formKey.currentState!.validate()) {
            loginController.loginAction(
              loginController.email.text,
              loginController.password.text,
              _formKey,
            );
          }
        },
      ),
    );
  }

  Widget _buildLoginButton(BoxConstraints constraints) {
    return Center(
      child: Obx(() => FadeInUp(
            duration: const Duration(milliseconds: 800),
            delay: const Duration(milliseconds: 200),
            child: SizedBox(
              width: 180.w,
              child: LoginButton(
                buttonHeight: 45.h,
                isLoading: loginController.isLoading.value,
                onPressed: () => loginController.loginAction(
                  loginController.email.text,
                  loginController.password.text,
                  _formKey,
                ),
                buttonwidth: constraints.maxWidth * 0.7,
              ),
            ),
          )),
    );
  }

  Widget _buildDeveloperInfo() {
    return Positioned(
      bottom: 24.h,
      left: 20.w,
      child: FadeInLeft(
        duration: const Duration(milliseconds: 3000),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextRichLine(
              text1: 'P',
              text2: 'owered ',
              text3: '  b',
              text4: 'y',
              color1: Colors.red,
              color2: Colors.white,
              color3: Colors.red,
              color4: Colors.white,
              fontSize1: 25.sp,
              fontSize2: 15.sp,
              fontSize3: 20.sp,
              fontSize4: 15.sp,
            ),
            SizedBox(height: 3.h),
            TextLine(
              text: 'د/محمود عصمت : وزير الكهرباء و الطاقة  المتجددة',
              color: Colors.cyan,
              fontFamily: Appfontstring.ChangaLight,
              fontSize: 12.sp,
              fontWeight: FF.B,
            ),
            TextLine(
              text: 'م/منى رزق :رئيـسة الشركة المصرية للنقل',
              color: const Color.fromARGB(255, 97, 205, 220),
              fontFamily: Appfontstring.ChangaLight,
              fontSize: 10.sp,
              fontWeight: FF.B,
            ),
            SizedBox(height: 4.h),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'برمجة و تصميم : ',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.orange,
                    ),
                  ),
                  TextSpan(
                    text: 'م/امير محمود بدوى',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinistryLogo() {
    return Positioned(
      bottom: 0,
      right: 5.w,
      child: FadeInDown(
        duration: const Duration(milliseconds: 1200),
        delay: const Duration(milliseconds: 300),
        child: Container(
          height: 30.h,
          width: 40.w,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Opacity(
            opacity: 0.6,
            child: Image.asset(
              AppimageString.minisrty,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.low,
              cacheHeight: (60 * 1.5).toInt(),
              cacheWidth: (80 * 1.5).toInt(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdditionalLogo1() {
    return Positioned(
      bottom: 70.h,
      right: 5.w,
      child: FadeInDown(
        duration: const Duration(milliseconds: 1600),
        delay: const Duration(milliseconds: 800),
        child: Container(
          height: 30.h,
          width: 40.w,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10.r),
              bottomRight: Radius.circular(10.r),
            ),
          ),
          child: Opacity(
            opacity: 0.9,
            child: Image.asset(
              AppimageString.qq,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.low,
              cacheHeight: (60 * 1.5).toInt(),
              cacheWidth: (80 * 1.5).toInt(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdditionalLogo2() {
    return Positioned(
      bottom: 35.h,
      right: 5.w,
      child: FadeInDown(
        duration: const Duration(milliseconds: 1400),
        delay: const Duration(milliseconds: 700),
        child: Container(
          height: 30.h,
          width: 40.w,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.red),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Opacity(
            opacity: 0.6,
            child: Image.asset(
              AppimageString.aaa,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.low,
              cacheHeight: (60 * 1.5).toInt(),
              cacheWidth: (80 * 1.5).toInt(),
            ),
          ),
        ),
      ),
    );
  }
}

abstract class LoginController extends GetxController {
  Future<void> gotohomepage();
  Future<String?> saveTokenToUserTable({
    required String email,
    required String authToken,
    String? fcmToken,
  });
  Future<void> loginAction(
    String email,
    String password,
    GlobalKey<FormState> formKey,
  );
}

class LoginControllerImp extends LoginController {
  // الحل: التهيئة الفورية بدون late
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  AuthService get authservice => Get.find<AuthService>();

  @override
  void onInit() {
    super.onInit();
    AppLogger.logInfo('LoginController initialized');
  }

  @override
  void onClose() {
    email.dispose();
    password.dispose();
    AppLogger.logInfo('LoginController disposed');
    super.onClose();
  }

  @override
  Future<void> gotohomepage() async {
    Get.offAll(() => const HomePage());
  }

  @override
  Future<String?> saveTokenToUserTable({
    required String email,
    required String authToken,
    String? fcmToken,
  }) async {
    final supabase = Supabase.instance.client;
    const tables = [
      AppConstants.tableUserCrcc,
      AppConstants.tableUserStations,
      'user_others',
      'user_cm',
      AppConstants.tableUserTop
    ];
    String? updatedTable;

    for (final table in tables) {
      try {
        final response = await supabase
            .from(table)
            .select('id')
            .eq('user_email', email.trim())
            .limit(1);

        if (response.isNotEmpty && response.isNotEmpty) {
          final Map<String, dynamic> updateMap = {'user_token': authToken};

          if (fcmToken != null && fcmToken.isNotEmpty) {
            updateMap['user_token'] = fcmToken;
          }

          await supabase
              .from(table)
              .update(updateMap)
              .eq('user_email', email.trim());
          updatedTable = table;
          break;
        }
      } catch (e) {
        AppLogger.logWarning('Error updating table $table: $e');
        continue;
      }
    }

    return updatedTable;
  }

  @override
  Future<void> loginAction(
    String email,
    String password,
    GlobalKey<FormState> formKey,
  ) async {
    if (formKey.currentState!.validate()) {
      isLoading.value = true;
      errorMessage.value = '';

      try {
        final session = await authservice.login(
          context: Get.context!,
          email: email.trim(),
          password: password,
        );

        if (session == null) {
          throw Exception('فشل تسجيل الدخول: بيانات غير صحيحة');
        }

        final authToken = session.accessToken;
        if (authToken.isEmpty) {
          throw Exception('لم يتم إنشاء رمز المصادقة');
        }

        String? fcmToken;
        try {
          final messaging = FirebaseMessaging.instance;
          final NotificationSettings settings =
              await messaging.requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false,
          );

          if (settings.authorizationStatus == AuthorizationStatus.authorized) {
            fcmToken = await messaging.getToken();
            AppLogger.logInfo(
                'FCM Token obtained: ${fcmToken?.substring(0, 10)}...');
          } else {
            AppLogger.logWarning('Notifications not authorized');
          }
        } catch (e) {
          AppLogger.logError('Failed to get FCM token', e);
        }

        final updatedTable = await saveTokenToUserTable(
          email: email.trim(),
          authToken: authToken,
          fcmToken: fcmToken,
        );

        if (updatedTable != null) {
          AppLogger.logSuccess(
              'User logged in successfully. Table: $updatedTable');

          if (fcmToken != null) {
            Get.snackbar(
              'نجاح',
              'تم حفظ البيانات بنجاح',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            );
          }

          await Future.delayed(const Duration(milliseconds: 500));
          // تحرير الـ LoginControllerImp من الذاكرة قبل الانتقال
          Get.delete<LoginControllerImp>();
          await gotohomepage();
        } else {
          AppLogger.logWarning('User found but token not saved to any table');
          Get.delete<LoginControllerImp>();
          await gotohomepage();
        }
      } catch (e) {
        errorMessage.value = e.toString();
        AppLogger.logError('Login failed', e);

        Get.snackbar(
          'خطأ',
          'فشل تسجيل الدخول: ${e.toString().replaceAll('Exception: ', '')}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        );
      } finally {
        isLoading.value = false;
      }
    }
  }
}

class LogBackGroung extends StatelessWidget {
  const LogBackGroung({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(AppimageString.image55),
          fit: BoxFit.fill,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

class CustomTextFormFieldlogin extends StatefulWidget {
  final String hinttext;
  final IconData icon;
  final bool? obscureText;
  final String labelText;
  final TextEditingController? mycontroller;
  final String? Function(String?)? valid;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final Function(String)? onFieldSubmitted;

  const CustomTextFormFieldlogin({
    super.key,
    required this.hinttext,
    required this.icon,
    required this.labelText,
    required this.mycontroller,
    this.valid,
    required this.keyboardType,
    this.obscureText,
    this.textInputAction,
    this.focusNode,
    this.onFieldSubmitted,
  });

  @override
  CustomTextFormFieldloginState createState() =>
      CustomTextFormFieldloginState();
}

class CustomTextFormFieldloginState extends State<CustomTextFormFieldlogin> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText ?? false;
  }

  void toggleObscureText() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.mycontroller,
      focusNode: widget.focusNode,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      obscureText: _obscureText,
      validator: widget.valid,
      onFieldSubmitted: widget.onFieldSubmitted,
      style: TextStyle(color: Colors.white, fontSize: 14.sp),
      decoration: InputDecoration(
        prefixIcon: Icon(widget.icon, color: Colors.white70, size: 24.sp),
        suffixIcon: widget.obscureText == true
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white70,
                  size: 20.sp,
                ),
                onPressed: toggleObscureText,
                splashRadius: 20.r,
              )
            : null,
        alignLabelWithHint: false,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        floatingLabelAlignment: FloatingLabelAlignment.start,
        hintText: widget.hinttext,
        hintStyle: TextStyle(
          color: const Color.fromARGB(154, 255, 255, 255),
          fontSize: 14.sp,
        ),
        labelText: widget.labelText,
        labelStyle: TextStyle(
          color: Colors.white,
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: Colors.black.withOpacity(0.2),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 20.w,
          vertical: 16.h,
        ),
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white54),
          borderRadius: BorderRadius.circular(30.r),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white54),
          borderRadius: BorderRadius.circular(30.r),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white, width: 1.5),
          borderRadius: BorderRadius.circular(30.r),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red),
          borderRadius: BorderRadius.circular(30.r),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
          borderRadius: BorderRadius.circular(30.r),
        ),
      ),
    );
  }
}

class LoginButton extends StatelessWidget {
  const LoginButton({
    super.key,
    required this.buttonHeight,
    required this.isLoading,
    required this.buttonwidth,
    this.onPressed,
  });

  final double buttonHeight;
  final double buttonwidth;
  final bool isLoading;
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: buttonwidth,
      height: buttonHeight,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.3),
            blurRadius: 10.r,
            spreadRadius: 1.r,
          ),
        ],
        borderRadius: BorderRadius.circular(30.r),
        gradient: const LinearGradient(
          colors: [
            Colors.white,
            Colors.cyanAccent,
            Color.fromARGB(255, 59, 136, 62),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.r),
          ),
          padding: EdgeInsets.zero,
        ),
        child: isLoading
            ? const ElectricLoadingIndicator(size: 24, color: Colors.white)
            : Text(
                'تسجيل الدخول',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

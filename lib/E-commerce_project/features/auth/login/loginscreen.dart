import 'package:amiraly/E-commerce_project/common/widgets/headlinetext.dart';
import 'package:amiraly/E-commerce_project/features/auth/homepage/homepage.dart';
import 'package:amiraly/E-commerce_project/util/constant/constants.dart';
import 'package:amiraly/E-commerce_project/util/validators/validatorHeper.dart';
import 'package:amiraly/main.dart';
import 'package:animate_do/animate_do.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      Get.put(LoginControllerImp(), permanent: true);
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
      resizeToAvoidBottomInset: false,
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
          padding: const EdgeInsets.all(AppPadding.loginpadding),
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
                const SizedBox(height: AppPadding.loginspacing * 0.3),
                _buildDivider(),
                const SizedBox(height: AppPadding.loginspacing * 0.5),
                _buildCompanyTexts(),
                SizedBox(height: constraints.maxHeight * 0.01),
                const SizedBox(height: AppPadding.loginspacing * 16),
                _buildEmailField(),
                const SizedBox(height: AppPadding.loginspacing),
                _buildPasswordField(),
                const SizedBox(height: AppPadding.loginspacing * 2),
                _buildLoginButton(constraints),
                const SizedBox(height: AppPadding.loginspacing * 12),
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
        color: C.white,
        fontWeight: FF.B,
        fontSize: 18,
        fontFamily: Appfontstring.ChangaLight,
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      width: AppSizes.screenWidth(context) * 0.3,
      decoration: const BoxDecoration(color: C.white),
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
            color: C.pink,
            fontWeight: FF.B,
            fontSize: 13,
            fontFamily: Appfontstring.ChangaLight,
          ),
        ),
        FadeInDown(
          duration: const Duration(milliseconds: 900),
          delay: const Duration(milliseconds: 200),
          child: TextLine(
            text: 'الشركة المصرية لنقل الكهرباء',
            color: C.red,
            fontWeight: FF.B,
            fontSize: 10,
            fontFamily: Appfontstring.ChangaLight,
          ),
        ),
        FadeInDown(
          duration: const Duration(milliseconds: 900),
          delay: const Duration(milliseconds: 300),
          child: TextLine(
            text: 'مـركز التحكم الاقليمى',
            color: const Color.fromARGB(255, 243, 233, 150),
            fontWeight: FF.B,
            fontSize: 10,
            fontFamily: Appfontstring.ChangaLight,
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
              width: AppSizes.screenWidth(context) * 0.5,
              child: LoginButton(
                buttonHeight: AppSizes.screenWidth(context) * 0.08,
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
      bottom: AppSizes.screenHeight(Get.context!) * 0.03,
      left: AppSizes.screenWidth(Get.context!) * 0.05,
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
              color1: C.red,
              color2: C.white,
              color3: C.red,
              color4: C.white,
              fontSize1: 25,
              fontSize2: 15,
              fontSize3: 20,
              fontSize4: 15,
            ),
            const SizedBox(height: 3),
            TextLine(
              text: 'د/محمود عصمت : وزير الكهرباء و الطاقة  المتجددة',
              color: Colors.cyan,
              fontFamily: Appfontstring.ChangaLight,
              fontSize: 12,
              fontWeight: FF.B,
            ),
            TextLine(
              text: 'م/منى رزق :رئيـسة الشركة المصرية للنقل',
              color: const Color.fromARGB(255, 97, 205, 220),
              fontFamily: Appfontstring.ChangaLight,
              fontSize: 10,
              fontWeight: FF.B,
            ),
            const SizedBox(height: 4),
            Text.rich(
              const TextSpan(
                children: [
                  TextSpan(
                    text: 'برمجة و تصميم : ',
                    style: TextStyle(
                      fontFamily: Appfontstring.ChangaLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: C.orange,
                    ),
                  ),
                  TextSpan(
                    text: 'م/امير محمود بدوى',
                    style: TextStyle(
                      fontFamily: Appfontstring.ChangaLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      color: C.white,
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
      right: 5,
      child: FadeInDown(
        duration: const Duration(milliseconds: 1200),
        delay: const Duration(milliseconds: 300),
        child: Container(
          height: 30,
          width: 40,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            border: Border.all(color: C.blue),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Opacity(
            opacity: 0.6,
            child: Image.asset(
              AppimageString.minisrty,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.low,
              cacheHeight: 60,
              cacheWidth: 80,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdditionalLogo1() {
    return Positioned(
      bottom: 70,
      right: 5,
      child: FadeInDown(
        duration: const Duration(milliseconds: 1600),
        delay: const Duration(milliseconds: 800),
        child: Container(
          height: 30,
          width: 40,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
          ),
          child: Opacity(
            opacity: 0.9,
            child: Image.asset(
              AppimageString.qq,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.low,
              cacheHeight: 60,
              cacheWidth: 80,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdditionalLogo2() {
    return Positioned(
      bottom: 35,
      right: 5,
      child: FadeInDown(
        duration: const Duration(milliseconds: 1400),
        delay: const Duration(milliseconds: 700),
        child: Container(
          height: 30,
          width: 40,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            border: Border.all(color: C.red),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Opacity(
            opacity: 0.6,
            child: Image.asset(
              AppimageString.aaa,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.low,
              cacheHeight: 60,
              cacheWidth: 80,
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
  final AuthService authservice = AuthService();

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
      'user_crcc',
      'user_stations',
      'user_others',
      'user_cm',
      'user_top'
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
              'تم حفظ التوكن بنجاح',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            );
          }

          await Future.delayed(const Duration(milliseconds: 500));
          await gotohomepage();
        } else {
          AppLogger.logWarning('User found but token not saved to any table');
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
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(widget.icon, color: Colors.white70),
        suffixIcon: widget.obscureText == true
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white70,
                  size: 20,
                ),
                onPressed: toggleObscureText,
                splashRadius: 20,
              )
            : null,
        alignLabelWithHint: false,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        floatingLabelAlignment: FloatingLabelAlignment.start,
        hintText: widget.hinttext,
        hintStyle: const TextStyle(
          color: Color.fromARGB(154, 255, 255, 255),
          fontSize: 14,
        ),
        labelText: widget.labelText,
        labelStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: Colors.black.withOpacity(0.2),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white54),
          borderRadius: BorderRadius.circular(30),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white54),
          borderRadius: BorderRadius.circular(30),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white, width: 1.5),
          borderRadius: BorderRadius.circular(30),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red),
          borderRadius: BorderRadius.circular(30),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
          borderRadius: BorderRadius.circular(30),
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
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
        borderRadius: BorderRadius.circular(30),
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
            borderRadius: BorderRadius.circular(30),
          ),
          padding: EdgeInsets.zero,
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                'تسجيل الدخول',
                style: TextStyle(
                  color: Colors.black,
                  fontFamily: Appfontstring.ChangaLight,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

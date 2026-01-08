import 'package:amiraly/E-commerce_project/common/services/authserveces.dart';
import 'package:amiraly/E-commerce_project/common/widgets/headlinetext.dart';
import 'package:amiraly/E-commerce_project/features/auth/homepage/homepage.dart';
import 'package:amiraly/E-commerce_project/features/auth/login/loginwidgets.dart';
import 'package:amiraly/E-commerce_project/util/constant/constants.dart';
import 'package:amiraly/E-commerce_project/util/validators/validatorHeper.dart';
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
  late final LoginControllerImp loginController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    loginController = Get.put(LoginControllerImp());
  }

  @override
  void dispose() {
    Get.delete<LoginControllerImp>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: PopScope(
        canPop: false,
        child: Stack(
          children: [
            LogBackGroung(),
            Form(
              key: _formKey,
              child: LayoutBuilder(builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppPadding.loginpadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: constraints.maxHeight * 0.05),
                      FadeInDown(
                          duration: const Duration(milliseconds: 800),
                          delay: const Duration(milliseconds: 50),
                          child: TextLine(
                              text: 'تسـجيل الدخـول',
                              color: C.white,
                              fontWeight: FF.B,
                              fontSize: 18,
                              fontFamily: Appfontstring.ChangaLight)),
                      const SizedBox(height: AppPadding.loginspacing * 0.5),
                      Container(
                          height: 1,
                          width: AppSizes.screenWidth(context) * 0.3,
                          decoration: BoxDecoration(color: C.white)),
                      const SizedBox(height: AppPadding.loginspacing * 1),
                      FadeInDown(
                          duration: const Duration(milliseconds: 900),
                          delay: const Duration(milliseconds: 100),
                          child: TextLine(
                              text: 'برنامج التحكم الاقليمى للقاهرة الكبرى',
                              color: C.red,
                              fontWeight: FF.B,
                              fontSize: 10,
                              fontFamily: Appfontstring.ChangaLight)),
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
                          text: '(CRCC) مـركز التحكم الاقليمى',
                          color: C.yellow,
                          fontWeight: FF.B,
                          fontSize: 12,
                          fontFamily: Appfontstring.ChangaLight,
                        ),
                      ),
                      SizedBox(height: constraints.maxHeight * 0.01),
                      const SizedBox(height: AppPadding.loginspacing * 16),
                      FadeInUp(
                        duration: const Duration(milliseconds: 800),
                        child: CustomTextFormFieldlogin(
                          valid: (val) => validInput(val!, 5, 30, 'email'),
                          hinttext: 'Enter your mail ',
                          icon: Icons.email_outlined,
                          labelText: 'Email',
                          mycontroller: loginController.email,
                          keyboardType: TextInputType.emailAddress,
                          obscureText: false,
                        ),
                      ),
                      const SizedBox(height: AppPadding.loginspacing),
                      FadeInUp(
                          duration: const Duration(milliseconds: 800),
                          delay: const Duration(milliseconds: 100),
                          child: CustomTextFormFieldlogin(
                              valid: (val) =>
                                  validInput(val!, 7, 30, 'password'),
                              hinttext: 'Enter password ',
                              icon: Icons.lock,
                              labelText: 'Password ',
                              mycontroller: loginController.password,
                              obscureText: true,
                              keyboardType: TextInputType.text)),
                      const SizedBox(height: AppPadding.loginspacing * 2),
                      Center(
                          child: Obx(() => FadeInUp(
                                duration: const Duration(milliseconds: 800),
                                delay: const Duration(milliseconds: 200),
                                child: SizedBox(
                                  width: AppSizes.screenWidth(context) * 0.5,
                                  child: LoginButton(
                                      buttonHeight:
                                          AppSizes.screenWidth(context) * 0.08,
                                      isLoading:
                                          loginController.isLoading.value,
                                      onPressed: () =>
                                          loginController.loginAction(
                                            loginController.email.text,
                                            loginController.password.text,
                                            _formKey,
                                          ),
                                      buttonwidth: constraints.maxWidth * 0.7),
                                ),
                              ))),
                      const SizedBox(height: AppPadding.loginspacing * 12),
                    ],
                  ),
                );
              }),
            ),
            Positioned(
              bottom: AppSizes.screenHeight(context) * 0.05,
              left: AppSizes.screenWidth(context) * 0.05,
              child: FadeInLeft(
                duration: const Duration(milliseconds: 3000),
                child: Column(
                  children: [
                    TextRichLine(
                        text1: 'P',
                        text2: 'owered ',
                        text3: '  b',
                        text4: 'y :',
                        color1: C.red,
                        color2: C.white,
                        color3: C.red,
                        color4: C.white,
                        fontSize1: 25,
                        fontSize2: 15,
                        fontSize3: 20,
                        fontSize4: 15),
                    TextLine(
                        text: 'م/منى رزق : رئيسة الشركة المصرية لنقل الكهرباء',
                        color: Colors.cyan,
                        fontFamily: Appfontstring.ChangaLight,
                        fontSize: 10,
                        fontWeight: FF.B),
                    TextLine(
                        text: 'م/محمد رياض :العضو المتفرغ للمنـطقة الشمالية',
                        color: Colors.cyan,
                        fontFamily: Appfontstring.ChangaLight,
                        fontSize: 10,
                        fontWeight: FF.B),
                    TextLine(
                        text: 'م/ايهـاب عـطية :رئيـس منطـقة القاهرة الكبرى',
                        color: Colors.cyan,
                        fontFamily: Appfontstring.ChangaLight,
                        fontSize: 10,
                        fontWeight: FF.B),
                    Text.rich(
                      TextSpan(
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
            ),
            Positioned(
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
                    child:
                        Image.asset(AppimageString.minisrty, fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
            Positioned(
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
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        bottomRight: Radius.circular(10)),
                  ),
                  child: Opacity(
                    opacity: 0.9,
                    child: Image.asset(AppimageString.qq),
                  ),
                ),
              ),
            ),
            Positioned(
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
                    child: Image.asset(AppimageString.aaa),
                  ),
                ),
              ),
            ),
          ],
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
  late final TextEditingController email;
  late final TextEditingController password;
  final RxBool isLoading = false.obs;
  final AuthService authservice = AuthService();

  @override
  void onInit() {
    email = TextEditingController();
    password = TextEditingController();
    super.onInit();
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
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
    final tables = [
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
            .eq('user_email', email)
            .limit(1);

        if (response.isNotEmpty) {
          final Map<String, dynamic> updateMap = {
            'user_token': authToken,
          };
          if (fcmToken != null) {
            updateMap['user_token'] = fcmToken;
          }

          final updateResponse = await supabase
              .from(table)
              .update(updateMap)
              .eq('user_email', email);

          if (updateResponse != null && updateResponse.isNotEmpty) {
            updatedTable = table;
            break;
          }
        }
      } catch (e) {
        continue;
      }
    }

    return updatedTable;
  }

  @override
  Future<void> loginAction(
    String emailValue,
    String passwordValue,
    GlobalKey<FormState> formKey,
  ) async {
    if (formKey.currentState!.validate()) {
      isLoading.value = true;
      try {
        final session = await authservice.login(
          context: Get.context!,
          email: emailValue,
          password: passwordValue,
        );

        if (session != null) {
          final authToken = session.accessToken;
          String? fcmToken;
          try {
            final messaging = FirebaseMessaging.instance;
            NotificationSettings settings = await messaging.requestPermission(
              alert: true,
              badge: true,
              sound: true,
              provisional: false,
            );

            if (settings.authorizationStatus ==
                AuthorizationStatus.authorized) {
              fcmToken = await messaging.getToken();
            } else {
              Get.snackbar(
                'Info',
                'Notifications disabled. Enable in app settings to receive updates.',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.blue,
              );
            }
          } catch (e) {
            Get.snackbar(
              'Error',
              'Failed to get FCM token',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
            );
          }

          final updatedTable = await saveTokenToUserTable(
            email: emailValue, // FIXED: Use passed email
            authToken: authToken,
            fcmToken: fcmToken,
          );

          if (updatedTable != null) {
            Get.snackbar(
              'Success',
              'Tokens saved to table: $updatedTable${fcmToken != null ? ' (including FCM for notifications)' : ''}',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green,
            );
            await gotohomepage();
          } else {
            await gotohomepage();
          }
        } else {
          throw Exception('No session returned from login');
        }
      } catch (e) {
        Get.snackbar(
          'Error',
          'Login failed: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
        );
      } finally {
        isLoading.value = false;
      }
    }
  }
}

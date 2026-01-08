import 'package:amiraly/E-commerce_project/common/models/appmodels.dart';
import 'package:amiraly/E-commerce_project/common/services/authserveces.dart';
import 'package:amiraly/E-commerce_project/common/services/authwraper.dart';
import 'package:amiraly/E-commerce_project/common/services/mainprogservices.dart';
import 'package:amiraly/E-commerce_project/features/mainprog/screen/navscreens/favoritesnav.dart';
import 'package:amiraly/E-commerce_project/util/validators/validatorHeper.dart';
import 'package:carousel_slider/carousel_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
    await AuthService().initializeAppServices();
    await InAppWebViewController.setWebContentsDebuggingEnabled(true);
    Get.put(AuthService());
    Get.put(FavoritesController());
    Get.put(CarouselSliderController());

    runApp(const MyApp());
  } catch (e, stackTrace) {
    AppLogger.logError('initialization failed', e, stackTrace);
    runApp(const ErrorApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'E-Commerce App',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const AuthWrapper(),
      routes: pageRoutes,
    );
  }
}

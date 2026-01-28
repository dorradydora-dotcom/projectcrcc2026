import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:amiraly/E-commerce_project/common/models/appmodels.dart';
import 'package:amiraly/E-commerce_project/features/mainprog/screen/catogriesScreens/cairoscreen.dart';
import 'package:amiraly/E-commerce_project/features/mainprog/screen/catogriesScreens/cmscreen.dart';
import 'package:amiraly/E-commerce_project/util/constant/constants.dart';
import 'package:amiraly/E-commerce_project/util/validators/validatorHeper.dart';
import 'package:amiraly/main.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class Homenavcontroller extends GetxController {
  void gotocairoscreen();
  void gotonewsscreen();
  Future<void> refreshAllData();
  Future<void> refreshWeather();
  List<MainCatogoryModel> get categories;
  List<AnnouncImagesModel> get announcImages;
  List<WeatherData> get weatherData;
  RxList<StationLoad> get stationLoads;
  String get userGroup;

  Future<void> fetchCategories();
  Future<void> fetchAnnouncImages();
  Future<void> fetchCairoWeather();
  Future<void> fetchStationLoads();
  Future<void> checkUserGroup();
  void updateStationVariations();
  void handleCategoryTap(BuildContext context, MainCatogoryModel category);
}

class HomenavcontrollerImp extends Homenavcontroller {
  final RxList<MainCatogoryModel> _categories = <MainCatogoryModel>[].obs;
  final RxList<AnnouncImagesModel> _announcImages = <AnnouncImagesModel>[].obs;
  final RxList<WeatherData> _weatherData = <WeatherData>[].obs;
  final RxList<StationLoad> _stationLoads = <StationLoad>[].obs;
  final RxString _userGroup = 'none'.obs;
  final RxBool isLoading = false.obs;
  final RxBool isOffline = false.obs;
  final RxString userEmail = 'جاري التحميل...'.obs;
  final RxString currentDate = ''.obs;
  final RxInt currentCarouselIndex = 0.obs;
  final CarouselSliderController carouselController =
      CarouselSliderController();

  Timer? _loadTimer;
  StreamSubscription? _connectivitySubscription;
  static const String _weatherCacheKey = 'cached_weather_data';

  @override
  List<MainCatogoryModel> get categories => _categories;
  @override
  List<AnnouncImagesModel> get announcImages => _announcImages;
  @override
  List<WeatherData> get weatherData => _weatherData;
  @override
  RxList<StationLoad> get stationLoads => _stationLoads;
  @override
  String get userGroup => _userGroup.value;

  @override
  void onInit() {
    super.onInit();
    _checkInitialConnectivity();
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      _updateConnectionStatus(results);
    });
    _loadCachedWeather();
    _initializeData();
    _startLoadVariationTimer();
    _updateCurrentDate();
  }

  void _updateCurrentDate() {
    final now = DateTime.now();
    final formatter = DateFormat.yMMMMEEEEd('ar');
    currentDate.value = formatter.format(now);
  }

  @override
  void onClose() {
    _loadTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.onClose();
  }

  Future<void> _checkInitialConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    _updateConnectionStatus(results);
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    isOffline.value =
        results.contains(ConnectivityResult.none) || results.isEmpty;
    if (!isOffline.value && _categories.isEmpty) {
      _initializeData();
    }
  }

  Future<void> _initializeData() async {
    if (isOffline.value) return;

    isLoading.value = true;
    try {
      final email = Get.find<AuthService>().getCurrentUserEmail();
      userEmail.value = email ?? 'مستخدم';

      await Future.wait([
        checkUserGroup(),
        fetchCategories(),
        fetchAnnouncImages(),
        fetchCairoWeather(),
        fetchStationLoads(),
      ]);
    } catch (e) {
      AppLogger.logError('Error initializing data', e);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void gotocairoscreen() {
    Get.to(() => const Cairoscreen());
  }

  @override
  void gotonewsscreen() {
    Get.to(() => const Cmscreen());
  }

  @override
  Future<void> checkUserGroup() async {
    final email = Get.find<AuthService>().getCurrentUserEmail();
    if (email == null) {
      _userGroup.value = 'none';
      return;
    }

    try {
      final client = Supabase.instance.client;
      final results = await Future.wait([
        client.from('user_cm').select().eq('user_email', email).limit(1),
        client.from('user_stations').select().eq('user_email', email).limit(1),
        client.from('user_top').select().eq('user_email', email).limit(1),
        client.from('user_crcc').select().eq('user_email', email).limit(1),
      ]);

      if (results[0].isNotEmpty)
        _userGroup.value = 'cm';
      else if (results[1].isNotEmpty)
        _userGroup.value = 'stations';
      else if (results[2].isNotEmpty)
        _userGroup.value = 'top';
      else if (results[3].isNotEmpty)
        _userGroup.value = 'crcc';
      else
        _userGroup.value = 'none';
    } catch (e) {
      _userGroup.value = 'none';
      AppLogger.logError('Error checking user group', e);
    }
  }

  @override
  void handleCategoryTap(BuildContext context, MainCatogoryModel category) {
    if (Get.find<AuthService>().getCurrentUserEmail() == null) {
      _showSnackBar(context, Stringshomenav.msgOtherDepts);
      return;
    }

    final normalizedCategoryName = category.name.trim();
    bool isAllowed = false;
    List<String> allowedCategories = [];

    switch (userGroup) {
      case 'cm':
        allowedCategories = ['العالم', 'القاهرة', 'مؤشرات', 'الازمات', 'خريطة'];
        break;
      case 'stations':
        allowedCategories = ['العالم', 'القاهرة', 'مؤشرات', 'خريطة'];
        break;
      case 'top':
      case 'crcc':
        isAllowed = true;
        break;
      case 'none':
        allowedCategories = [];
        break;
    }

    if (!isAllowed && !allowedCategories.contains(normalizedCategoryName)) {
      _showSnackBar(context, Stringshomenav.msgAccessDenied);
      return;
    }

    if (category.pageroute.isNotEmpty) {
      try {
        Get.toNamed(category.pageroute);
      } catch (e) {
        _showSnackBar(context, 'خطأ في التنقل: $e');
      }
    } else {
      _showSnackBar(context, Stringshomenav.msgNotReady);
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Future<void> fetchCategories() async {
    if (isOffline.value) return;
    try {
      final response = await Supabase.instance.client
          .from('category_items')
          .select()
          .timeout(const Duration(seconds: 10));
      _categories.assignAll((response as List<dynamic>)
          .map((json) =>
              MainCatogoryModel.fromJson(json as Map<String, dynamic>))
          .toList());
    } catch (e) {
      AppLogger.logError('Error fetching categories', e);
      _categories.clear();
    }
  }

  @override
  Future<void> fetchAnnouncImages() async {
    if (isOffline.value) return;
    try {
      final response = await Supabase.instance.client
          .from('announcing_images')
          .select()
          .timeout(const Duration(seconds: 10));
      _announcImages.assignAll((response as List<dynamic>)
          .map((json) =>
              AnnouncImagesModel.fromJson(json as Map<String, dynamic>))
          .toList());
    } catch (e) {
      AppLogger.logError('Error fetching announc images', e);
      _announcImages.clear();
    }
  }

  @override
  Future<void> fetchStationLoads() async {
    if (isOffline.value) return;
    try {
      final loads = await SupabaseService().fetchStationLoads();
      _stationLoads.assignAll(loads);
    } catch (e) {
      AppLogger.logError('Error fetching station loads', e);
      _stationLoads.clear();
    }
  }

  @override
  Future<void> fetchCairoWeather() async {
    if (isOffline.value) return;

    const apiUrl =
        'https://api.open-meteo.com/v1/forecast?latitude=30.0444&longitude=31.2357&daily=weathercode,temperature_2m_max,temperature_2m_min&current_weather=true&timezone=auto&forecast_days=5';

    try {
      final response = await http
          .get(Uri.parse(apiUrl))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['daily'] != null && data['current_weather'] != null) {
          _parseWeatherData(data);
          _cacheWeather(data);
        }
      }
    } catch (e) {
      AppLogger.logError('Error fetching weather', e);
    }
  }

  void _parseWeatherData(Map<String, dynamic> data) {
    final daily = data['daily'];
    final current = data['current_weather'];

    final currentWeather = WeatherData(
      dayName: Stringshomenav.weatherNow,
      maxTemp: (current['temperature'] as num?)?.toInt() ?? 0,
      minTemp: (current['temperature'] as num?)?.toInt() ?? 0,
      description: _getWeatherDescription(
          (current['weathercode'] as num?)?.toInt() ?? 0),
      icon: _getWeatherIcon(_getWeatherDescription(
          (current['weathercode'] as num?)?.toInt() ?? 0)),
      isToday: false,
      isCurrent: true,
      date: DateTime.now(),
    );

    final forecast = List.generate(
      (daily['time'] as List<dynamic>).length - 1,
      (i) {
        final index = i + 1;
        return WeatherData(
          dayName: _getDayName(DateTime.parse(daily['time'][index])),
          maxTemp: (daily['temperature_2m_max'][index] as num?)?.toInt() ?? 0,
          minTemp: (daily['temperature_2m_min'][index] as num?)?.toInt() ?? 0,
          description: _getWeatherDescription(
              (daily['weathercode'][index] as num?)?.toInt() ?? 0),
          icon: _getWeatherIcon(_getWeatherDescription(
              (daily['weathercode'][index] as num?)?.toInt() ?? 0)),
          isToday: false,
          isCurrent: false,
          date: DateTime.parse(daily['time'][index]),
        );
      },
    ).take(4).toList();

    _weatherData.assignAll([currentWeather, ...forecast]);
  }

  Future<void> _cacheWeather(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_weatherCacheKey, json.encode(data));
    } catch (e) {
      AppLogger.logError('Error caching weather', e);
    }
  }

  Future<void> _loadCachedWeather() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_weatherCacheKey);
      if (cached != null) {
        final data = json.decode(cached);
        _parseWeatherData(data);
      }
    } catch (e) {
      AppLogger.logError('Error loading cached weather', e);
    }
  }

  @override
  Future<void> refreshAllData() async {
    await _initializeData();
  }

  @override
  Future<void> refreshWeather() async {
    await fetchCairoWeather();
  }

  void _startLoadVariationTimer() {
    _loadTimer?.cancel();
    _loadTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      updateStationVariations();
    });
  }

  @override
  void updateStationVariations() {
    final random = Random();
    for (var station in _stationLoads) {
      final delta = station.maxVariation - station.minVariation;
      final variation = random.nextDouble() * delta + station.minVariation;
      station.load = station.baseLoad + variation;
    }
    _stationLoads.refresh();
  }

  String _getDayName(DateTime date) {
    return [
      '',
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد'
    ][date.weekday];
  }

  String _getWeatherDescription(int code) {
    return switch (code) {
      0 => 'Clear sky',
      1 || 2 || 3 => 'Mainly clear with few clouds',
      45 || 48 => 'Dense fog',
      51 || 53 || 55 => 'Light drizzle',
      61 || 63 || 65 => 'Rainfall',
      71 || 73 || 75 => 'Snowfall',
      80 || 81 || 82 => 'Intermittent rain showers',
      95 || 96 || 99 => 'Thunderstorms',
      _ => 'Unknown',
    };
  }

  String _getWeatherIcon(String desc) {
    final icons = {
      'clear sky': '☀️',
      'mainly clear with few clouds': '⛅',
      'dense fog': '🌫️',
      'light drizzle': '🌦️',
      'rainfall': '🌧️',
      'snowfall': '❄️',
      'intermittent rain showers': '🌦️',
      'thunderstorms': '⛈️',
      'unknown': '🌤️',
    };
    return icons[desc.toLowerCase()] ?? '🌤️';
  }
}

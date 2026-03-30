import 'dart:async';
import 'dart:convert';
import 'package:amiraly/app/util/validators/validator_helper.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:amiraly/app/common/models/appmodels.dart';
import 'package:amiraly/app/features/mainprog/screen/catogriesScreens/cairoscreen.dart';
import 'package:amiraly/app/features/mainprog/screen/catogriesScreens/cmscreen.dart';
import 'package:amiraly/app/util/constant/constants.dart';
import 'package:amiraly/core/services/auth_service.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:amiraly/app/features/mainprog/screen/navscreens/station_load_controller.dart';
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
  double get totalLoad;
  double getStationLoad(String name);
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
  late final StationLoadController _stationController;
  RxList<StationLoad> get _stationLoads => _stationController.stationLoads;
  final RxString _userGroup = 'none'.obs;
  final RxBool isLoading = true.obs;
  final RxBool isOffline = false.obs;
  final RxString userEmail = 'جاري التحميل...'.obs;
  final RxString currentDate = ''.obs;
  final CarouselSliderController carouselController =
      CarouselSliderController();

  final RxList<String> electricityNews = <String>[].obs;
  final RxList<String> techNews = <String>[].obs;
  final RxBool isNewsLoading = false.obs;
  final RxInt currentCarouselIndex = 0.obs;

  Timer? _loadTimer;
  StreamSubscription? _connectivitySubscription;
  static const String _weatherCacheKey = WeatherConstants.weatherCacheKey;
  // ✅ SharedPreferences instance مرة واحدة - بدل ما يتفتح في كل مرة
  SharedPreferences? _prefs;

  @override
  List<MainCatogoryModel> get categories => _categories;
  @override
  List<AnnouncImagesModel> get announcImages => _announcImages;
  @override
  List<WeatherData> get weatherData => _weatherData;
  @override
  RxList<StationLoad> get stationLoads => _stationLoads;
  @override
  double get totalLoad => _stationController.totalLoad;
  @override
  double getStationLoad(String name) => _stationController.getStationLoad(name);
  @override
  String get userGroup => _userGroup.value;

  @override
  void onInit() {
    _stationController = Get.find<StationLoadController>();
    super.onInit();
    _updateCurrentDate();
    _startLoadVariationTimer();
    // ✅ جلب الكاش والتحقق من الاتصال فوراً في onInit
    _loadCachedWeather();
    _checkInitialConnectivity();
    // ✅ تأجيل جلب الأخبار لبعد ما الـ UI يتبنى كاملاً
    SchedulerBinding.instance.addPostFrameCallback((_) => fetchNews());
  }

  @override
  void onReady() {
    super.onReady();
    // ✅ العمليات الثقيلة والـ Networking تبدأ بعد ظهور الواجهة
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      _updateConnectionStatus(results);
    });
    _initializeData();
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
    if (isOffline.value) {
      return;
    }

    isLoading.value = true;
    try {
      final email = Get.find<AuthService>().getCurrentUserEmail();
      userEmail.value = email ?? 'مستخدم';

      // ✅ تأخير لمدة 3 ثوانٍ لضمان استقرار الواجهة وظهور الـ Loading
      await Future.delayed(const Duration(seconds: 4));

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
        client
            .from(AppConstants.tableUserCm)
            .select()
            .eq('user_email', email)
            .limit(1),
        client
            .from(AppConstants.tableUserStations)
            .select()
            .eq('user_email', email)
            .limit(1),
        client
            .from(AppConstants.tableUserTop)
            .select()
            .eq('user_email', email)
            .limit(1),
        client
            .from(AppConstants.tableUserCrcc)
            .select()
            .eq('user_email', email)
            .limit(1),
        client
            .from(AppConstants.tableUserProject)
            .select()
            .eq('user_email', email)
            .limit(1),
        client
            .from(AppConstants.tableUserOthers)
            .select()
            .eq('user_email', email)
            .limit(1),
      ]);

      if (results[0].isNotEmpty) {
        _userGroup.value = 'cm';
      } else if (results[1].isNotEmpty) {
        _userGroup.value = 'stations';
      } else if (results[2].isNotEmpty) {
        _userGroup.value = 'top';
      } else if (results[3].isNotEmpty) {
        _userGroup.value = 'crcc';
      } else if (results[4].isNotEmpty) {
        _userGroup.value = 'project';
      } else if (results[5].isNotEmpty) {
        _userGroup.value = 'others';
      } else {
        _userGroup.value = 'none';
      }
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
      case 'crcc':
      case 'top':
      case 'others':
        isAllowed = true;
        break;
      case 'cm':
        allowedCategories = ['القاهرة', 'مؤشرات', 'الازمات', 'خريطة', 'العالم'];
        break;
      case 'stations':
        allowedCategories = ['القاهرة', 'مؤشرات', 'خريطة', 'العالم', 'Go live'];
        break;
      case 'project':
        allowedCategories = [
          'القاهرة',
          'مؤشرات',
          'تقارير',
          'خريطة',
          'العالم',
          'المشروعات'
        ];
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
    if (isOffline.value) {
      return;
    }
    try {
      final response = await Supabase.instance.client
          .from(AppConstants.tableCategoryItems)
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
      final rssUrls = await _getRssUrls();
      
      // 10 صور عالية الجودة وسريعة التحميل (مضغوطة) للطاقة والتكنولوجيا
      final fallbackImages = [
         'https://images.unsplash.com/photo-1466611653911-95081537e5b7?w=600&q=70', // توربينات رياح
         'https://images.unsplash.com/photo-1509391366360-1e96191cb14b?w=600&q=70', // طاقة شمسية
         'https://images.unsplash.com/photo-1548337138-e87f88ebcc8a?w=600&q=70', // خطوط كهرباء
         'https://images.unsplash.com/photo-1518770660439-4636190af475?w=600&q=70', // لوحة تقنية
         'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?w=600&q=70', // محطة توليد
         'https://images.unsplash.com/photo-1519389950473-47ba0277781c?w=600&q=70', // شبكة أجهزة
         'https://images.unsplash.com/photo-1493612276216-ee3925520721?w=600&q=70', // مصباح متوهج
         'https://images.unsplash.com/photo-1555066931-4365d14bab8c?w=600&q=70', // تقنية برمجيات
         'https://images.unsplash.com/photo-1558494949-ef010cbdcc31?w=600&q=70', // سيرفرات
         'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=600&q=70'  // شبكة العالم الرقمي
      ];
      int fallbackIndex = 0;
      
      List<AnnouncImagesModel> fetchedNews = [];
      
      for (var url in rssUrls) {
        final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          final decoded = utf8.decode(response.bodyBytes);
          final regExp = RegExp(r'<item>(.*?)<\/item>', dotAll: true);
          final matches = regExp.allMatches(decoded);
          
          for (var m in matches) {
             final itemStr = m.group(1) ?? '';
             final titleMatch = RegExp(r'<title><!\[CDATA\[(.*?)\]\]><\/title>', dotAll: true).firstMatch(itemStr) 
                             ?? RegExp(r'<title>(.*?)<\/title>', dotAll: true).firstMatch(itemStr);
             final descMatch = RegExp(r'<description>(.*?)<\/description>', dotAll: true).firstMatch(itemStr);
             
             if (titleMatch != null) {
                String title = titleMatch.group(1) ?? '';
                title = title.replaceAll('&#39;', "'").replaceAll('&quot;', '"').replaceAll('&amp;', '&');
                if (title.contains(' - ')) title = title.split(' - ')[0]; // حذف اسم المصدر

                String? imageUrl;
                
                if (descMatch != null) {
                   final imgMatch = RegExp(r'<img[^>]+src="([^"]+)"', dotAll: true).firstMatch(descMatch.group(1)!);
                   if (imgMatch != null) imageUrl = imgMatch.group(1);
                }
                
                if (imageUrl == null || imageUrl.isEmpty) {
                    final encMatch = RegExp(r'<enclosure[^>]+url="([^"]+)"', dotAll: true).firstMatch(itemStr);
                    if (encMatch != null) imageUrl = encMatch.group(1);
                }
                
                // إضافة الصورة الافتراضية المناسبة من الـ 10 صور إذا لم تتوفر صورة
                if (imageUrl == null || imageUrl.isEmpty) {
                   imageUrl = fallbackImages[fallbackIndex % fallbackImages.length];
                   fallbackIndex++;
                }
                
                fetchedNews.add(AnnouncImagesModel(imageUrl: imageUrl, title: title.trim()));
             }
          }
        }
      }
      
      if (fetchedNews.isNotEmpty) {
         fetchedNews.shuffle(); // تنويع الأخبار
         _announcImages.assignAll(fetchedNews.take(10).toList());
         return; // نجاح
      }
    } catch (e) {
      AppLogger.logWarning('Failed to fetch/parse news RSS for carousel images: $e');
    }

    // Fallback: Fetch from Supabase
    try {
      final response = await Supabase.instance.client
          .from(AppConstants.tableAnnouncingImages)
          .select()
          .timeout(const Duration(seconds: 10));
      _announcImages.assignAll((response as List<dynamic>)
          .map((json) =>
              AnnouncImagesModel.fromJson(json as Map<String, dynamic>))
          .toList());
    } catch (e) {
      AppLogger.logError(
          'Error fetching announc images from Supabase fallback', e);
      _announcImages.clear();
    }
  }

  @override
  Future<void> fetchStationLoads() async {
    if (isOffline.value) {
      return;
    }
    await _stationController.fetchData();
  }

  @override
  Future<void> fetchCairoWeather() async {
    if (isOffline.value) {
      return;
    }

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
      // ✅ استخدام الـ instance المخزن بدل فتح SharedPreferences جديد
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs!.setString(_weatherCacheKey, json.encode(data));
    } catch (e) {
      AppLogger.logError('Error caching weather', e);
    }
  }

  Future<void> _loadCachedWeather() async {
    try {
      // ✅ نفس الـ instance - لا يتفتح SharedPreferences مرتين
      _prefs ??= await SharedPreferences.getInstance();
      final cached = _prefs!.getString(_weatherCacheKey);
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

  Future<void> fetchNews() async {
    isNewsLoading.value = true;
    try {
      final rssUrls = await _getRssUrls();
      final List<Future> fetchTasks = [];
      
      if (rssUrls.isNotEmpty) {
        fetchTasks.add(_fetchRssNews(rssUrls[0], electricityNews));
      }
      if (rssUrls.length > 1) {
        fetchTasks.add(_fetchRssNews(rssUrls[1], techNews));
      }
      
      if (fetchTasks.isNotEmpty) {
        await Future.wait(fetchTasks);
      }
    } catch (e) {
      AppLogger.logError('Error fetching news', e);
    } finally {
      isNewsLoading.value = false;
    }
  }

  Future<void> _fetchRssNews(String url, RxList<String> targetList) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        // Target titles inside <item> tags only to avoid channel/image metadata
        final regExp = RegExp(r'<item>.*?<title>(.*?)<\/title>', dotAll: true);
        final matches = regExp.allMatches(decoded);
        final news = matches
            .map((m) => m.group(1) ?? '')
            .map((t) => t
                .replaceAll('&#39;', "'")
                .replaceAll('&quot;', '"')
                .replaceAll('&amp;', '&'))
            .map((t) => t.contains(' - ')
                ? t.split(' - ')[0]
                : t) // Remove publication name suffix
            .where((t) =>
                t.isNotEmpty &&
                !t.contains('Google News') &&
                !t.contains('أخبار Google'))
            .toList();
        targetList.assignAll(news);
      }
    } catch (e) {
      AppLogger.logError('Error fetching RSS news from $url', e);
    }
  }

  Future<List<String>> _getRssUrls() async {
    final defaultUrls = [
      'https://news.google.com/rss/search?q=%D9%83%D9%87%D8%B1%D8%A8%D8%A7%D8%A1%20%D9%85%D8%B5%D8%B1%20%D8%B7%D8%A7%D9%82%D8%A9&hl=ar&gl=EG&ceid=EG:ar',
      'https://news.google.com/rss/search?q=%D8%AA%D9%83%D9%86%D9%88%D9%84%D9%88%D8%AC%D9%8A%D8%A1%20%D8%A7%D9%84%D8%B7%D8%A7%D9%82%D8%A9&hl=ar&gl=EG&ceid=EG:ar'
    ];

    try {
      final response = await Supabase.instance.client
          .from(AppConstants.tableWorldTable)
          .select('link_string')
          .like('url_name', 'rss_url_%')
          .order('url_name', ascending: true);

      if ((response as List).isNotEmpty) {
        return (response as List)
            .map((e) => e['link_string'] as String)
            .toList();
      }
    } catch (e) {
      AppLogger.logWarning('Failed to fetch RSS URLs from Supabase: $e');
    }
    return defaultUrls;
  }

  void _startLoadVariationTimer() {
    _loadTimer?.cancel();
    _loadTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      updateStationVariations();
    });
  }

  @override
  void updateStationVariations() {
    // Rely on StationLoadController's updateLoads logic
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

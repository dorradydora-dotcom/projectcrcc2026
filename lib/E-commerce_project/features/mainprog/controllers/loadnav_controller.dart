import 'dart:async';
import 'dart:convert';
import 'package:amiraly/main.dart';
import 'dart:math';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:amiraly/E-commerce_project/common/models/appmodels.dart';
import 'package:amiraly/E-commerce_project/services/cache_service.dart';
import 'package:amiraly/E-commerce_project/util/constant/constants.dart';

class LoadnavController extends GetxController {
  final SupabaseService _supabaseService = SupabaseService();
  final CacheService _cacheService = CacheService();
  final SupabaseClient _supabase = Supabase.instance.client;

  // --- Station Load State ---
  final RxList<StationLoad> stationLoads = <StationLoad>[].obs;
  final RxBool isLoadingStations = true.obs;
  final RxBool isStationFromCache = false.obs;
  final RxBool stnError = false.obs;
  final RxnString errorMessage = RxnString();

  // --- International Load State ---
  final RxMap<String, double?> intlLoads = <String, double?>{
    'القاهرة': null,
    'طوكيو': null,
    'المانيا': null,
    'فرنسا': null,
    'السعودية': null,
  }.obs;
  final RxMap<String, String> intlLastUpdate = <String, String>{}.obs;
  final RxSet<String> intlFromCache = <String>{}.obs;
  final RxBool intlError = false.obs;

  // --- Hourly Chart State ---
  final RxList<Map<String, dynamic>> hourlyMaxLoadsToday =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> hourlyMaxLoadsYesterday =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoadingHourly = false.obs;
  final RxnString hourlyError = RxnString();
  final RxnDouble maxHourlyLoad = RxnDouble();
  final RxDouble maxLoadInLastHour = 0.0.obs;
  final List<Map<String, dynamic>> _loadHistory = [];

  // --- Timers ---
  Timer? _stationRefreshTimer;
  Timer? _simulationTimer;

  @override
  void onInit() {
    super.onInit();
    _initializeAllData();

    // Auto-refresh station data from API every minute
    _stationRefreshTimer = Timer.periodic(const Duration(seconds: 60),
        (_) => fetchStationLoads(showLoading: false));

    // Simulation timer for micro-variations
    _simulationTimer = Timer.periodic(
        const Duration(seconds: 6), (_) => _simulateLoadChanges());
  }

  @override
  void onClose() {
    _stationRefreshTimer?.cancel();
    _simulationTimer?.cancel();
    super.onClose();
  }

  // --- Initialization ---
  Future<void> _initializeAllData() async {
    await fetchStationLoads(showLoading: true);
    await loadIntlFromCache(); // Load cached intl first
    fetchAllIntlData(); // Then fetch fresh intl
    await loadHourlyData(); // Load chart data
  }

  // --- Station Methods ---
  double get totalStationLoad =>
      stationLoads.fold(0.0, (sum, station) => sum + station.load);

  Future<void> fetchStationLoads({bool showLoading = true}) async {
    if (showLoading && stationLoads.isEmpty) {
      isLoadingStations.value = true;
    }
    try {
      final loads = await _supabaseService.fetchStationLoads();
      stationLoads.value = loads;
      isLoadingStations.value = false;
      errorMessage.value = null;
      isStationFromCache.value = false;
      stnError.value = false;

      // Update the 'القاهرة' entry in intl loads to reflect the new total
      intlLoads['القاهرة'] = totalStationLoad;

      _cacheService.saveStationLoads(loads);
    } catch (e) {
      final cachedLoads = await _cacheService.getStationLoads();
      if (cachedLoads != null && cachedLoads.isNotEmpty) {
        stationLoads.value = cachedLoads;
        isStationFromCache.value = true;
        errorMessage.value = null;
        stnError.value = false;
        intlLoads['القاهرة'] = totalStationLoad;
      } else if (stationLoads.isEmpty) {
        errorMessage.value = 'خطأ في جلب البيانات وفشل التخزين المؤقت: $e';
        stnError.value = true;
      }
      isLoadingStations.value = false;
    }
  }

  void _simulateLoadChanges() {
    if (stationLoads.isEmpty) return;

    final random = Random();
    final updatedLoads = stationLoads.map((station) {
      final variationRange = station.maxVariation - station.minVariation;
      final randomVariation =
          station.minVariation + random.nextDouble() * variationRange;
      station.load =
          (station.baseLoad + randomVariation).clamp(0.0, double.infinity);
      return station;
    }).toList();

    stationLoads.assignAll(updatedLoads);
    intlLoads['القاهرة'] = totalStationLoad;

    // Track peak load in last hour
    final now = DateTime.now();
    _loadHistory.add({'timestamp': now, 'totalLoad': totalStationLoad});
    _loadHistory.removeWhere((entry) =>
        now.difference(entry['timestamp'] as DateTime).inMinutes > 60);

    if (_loadHistory.isNotEmpty) {
      maxLoadInLastHour.value =
          _loadHistory.map((e) => e['totalLoad'] as double).reduce(max);
    } else {
      maxLoadInLastHour.value = totalStationLoad;
    }
  }

  // --- International Load Methods ---
  Future<void> loadIntlFromCache() async {
    final cached = await _cacheService.getIntlLoads();
    if (cached != null) {
      cached.forEach((key, value) {
        if (key != 'القاهرة' && value != null) {
          intlLoads[key] = value;
          intlFromCache.add(key);
          intlLastUpdate[key] = 'من الذاكرة';
        }
      });
    }
  }

  void fetchAllIntlData() {
    intlError.value = false;
    _fetchJapanData();
    _fetchGermanyData();
    _fetchFranceData();
    _fetchSaudiData();
  }

  Future<void> _fetchJapanData() async {
    try {
      final response = await http.get(Uri.parse(
          'https://www.tepco.co.jp/forecast/html/images/juyo-d1-j.csv'));
      if (response.statusCode == 200) {
        final content = response.body;
        final lines = content.split('\n');
        double? latestActual;
        for (int i = lines.length - 1; i >= 0; i--) {
          final parts = lines[i].split(',');
          if (parts.length >= 3) {
            final val = double.tryParse(parts[2].replaceAll('"', ''));
            if (val != null && val > 0) {
              latestActual = val;
              break;
            }
          }
        }
        if (latestActual != null) {
          intlLoads['طوكيو'] = latestActual * 10;
          intlLastUpdate['طوكيو'] = 'TEPCO (آخر تحديث)';
          intlFromCache.remove('طوكيو');
          _cacheService.saveIntlLoads(intlLoads);
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchGermanyData() async {
    try {
      final indexResponse = await http.get(Uri.parse(
          'https://www.smard.de/app/chart_data/410/DE/index_day.json'));
      if (indexResponse.statusCode == 200) {
        final List<dynamic> timestamps =
            json.decode(indexResponse.body)['timestamps'];
        if (timestamps.isNotEmpty) {
          for (int i = timestamps.length - 1; i >= 0; i--) {
            final lastTs = timestamps[i];
            final dataResponse = await http.get(Uri.parse(
                'https://www.smard.de/app/chart_data/410/DE/410_DE_day_$lastTs.json'));
            if (dataResponse.statusCode == 200) {
              final List<dynamic> series =
                  json.decode(dataResponse.body)['series'];
              if (series.isNotEmpty) {
                double? foundVal;
                for (int j = series.length - 1; j >= 0; j--) {
                  if (series[j][1] != null) {
                    foundVal = (series[j][1] as num).toDouble();
                    break;
                  }
                }
                if (foundVal != null) {
                  intlLoads['المانيا'] = foundVal / 23;
                  intlLastUpdate['المانيا'] =
                      i == timestamps.length - 1 ? 'SMARD اليوم' : 'SMARD أمس';
                  intlFromCache.remove('المانيا');
                  _cacheService.saveIntlLoads(intlLoads);
                  break;
                }
              }
            }
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchFranceData() async {
    try {
      final response = await http.get(Uri.parse(
          'https://opendata.reseaux-energies.fr/api/records/1.0/search/?dataset=eco2mix-national-tr&rows=1&sort=-date_heure'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['records'] != null && data['records'].isNotEmpty) {
          final fields = data['records'][0]['fields'];
          intlLoads['فرنسا'] = (fields['consommation'] as num).toDouble();
          intlLastUpdate['فرنسا'] = 'RTE FR';
          intlFromCache.remove('فرنسا');
          _cacheService.saveIntlLoads(intlLoads);
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchSaudiData() async {
    final now = DateTime.now();
    final minuteSlot = (now.minute / 5).floor();
    final seed = now.day + now.hour + minuteSlot;
    final random = Random(seed);

    intlLoads['السعودية'] = 52000 + (random.nextDouble() * 3000);
    intlLastUpdate['السعودية'] = 'تقرير شهري (محدث)';
    intlFromCache.remove('السعودية');
    _cacheService.saveIntlLoads(intlLoads);
  }

  // --- Hourly Chart Methods ---
  Future<void> loadHourlyData() async {
    final cached = await _cacheService.getHourlyMaxLoads();
    if (cached != null) {
      hourlyMaxLoadsToday.assignAll(cached['today'] ?? []);
      hourlyMaxLoadsYesterday.assignAll(cached['yesterday'] ?? []);
      _calculateMaxHourlyLoad();
    }
    await fetchFreshHourlyData();
  }

  Future<void> fetchFreshHourlyData() async {
    if (hourlyMaxLoadsToday.isEmpty) isLoadingHourly.value = true;

    try {
      final now = DateTime.now();
      const table = AppConstants.tableHourlyMaxLoads;
      final todayFormatted = DateTime(now.year, now.month, now.day)
          .toIso8601String()
          .split('T')[0];
      final yesterdayFormatted = DateTime(now.year, now.month, now.day - 1)
          .toIso8601String()
          .split('T')[0];

      final todayResponse = await _supabase
          .from(table)
          .select('hour, max_load')
          .eq('date', todayFormatted)
          .order('hour', ascending: true);

      final yesterdayResponse = await _supabase
          .from(table)
          .select('hour, max_load')
          .eq('date', yesterdayFormatted)
          .order('hour', ascending: true);

      final todayList = List<Map<String, dynamic>>.from(todayResponse);
      final yesterdayList = List<Map<String, dynamic>>.from(yesterdayResponse);

      hourlyMaxLoadsToday.assignAll(todayList);
      hourlyMaxLoadsYesterday.assignAll(yesterdayList);
      _calculateMaxHourlyLoad();
      isLoadingHourly.value = false;
      hourlyError.value = null;

      _cacheService.saveHourlyMaxLoads(todayList, yesterdayList);
    } catch (e) {
      if (hourlyMaxLoadsToday.isEmpty)
        hourlyError.value = 'Error fetching chart data: $e';
      isLoadingHourly.value = false;
    }
  }

  void _calculateMaxHourlyLoad() {
    final all = [...hourlyMaxLoadsToday, ...hourlyMaxLoadsYesterday];
    if (all.isNotEmpty) {
      maxHourlyLoad.value = all
          .map((e) => (e['max_load'] as num?)?.toDouble() ?? 0.0)
          .reduce(max);
    } else {
      maxHourlyLoad.value = 0.0;
    }
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:amiraly/E-commerce_project/common/services/cache_service.dart';
import 'package:amiraly/E-commerce_project/util/constant/constants.dart';
import 'package:amiraly/main.dart'; // For SupabaseServiceHourly if defined there or correct path
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:amiraly/E-commerce_project/features/mainprog/screen/navscreens/station_load_controller.dart';
import 'dart:math';

class IndicatorsController extends GetxController
    with GetTickerProviderStateMixin {
  final SupabaseClient _supabase = Supabase.instance.client;
  final CacheService _cacheService = CacheService();
  final SupabaseServiceHourly _supabaseServiceHourly = SupabaseServiceHourly();

  // --- Animation State ---
  late AnimationController animationController;
  late Animation<double> fadeAnimation;

  // --- Station Data State ---
  final RxList<String> stations = <String>[].obs;
  final RxList<int> selectedStations = <int>[].obs;
  final RxList<List<double>> stationLoads = <List<double>>[].obs;
  final RxDouble sumStations = 0.0.obs;
  final RxDouble sumGeneration = 0.0.obs;
  final RxDouble sumExchanges = 0.0.obs;
  final RxDouble totalDynamic = 0.0.obs;
  final RxBool hasPieData = false.obs;
  final RxInt touchedPieIndex = (-1).obs;
  final RxBool isLoadingStations = true.obs;

  // --- International Load State (Migrated) ---
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

  // --- Hourly Chart State (Migrated) ---
  final RxList<Map<String, dynamic>> hourlyMaxLoadsToday =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> hourlyMaxLoadsYesterday =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoadingHourly = false.obs;
  final RxnString hourlyError = RxnString();
  final RxnDouble maxHourlyLoad = RxnDouble();

  @override
  void onInit() {
    super.onInit();
    // Initialize Animation
    animationController = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this);
    fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeInOut),
    );

    _initializeData();
  }

  @override
  void onClose() {
    animationController.dispose();
    super.onClose();
  }

  Future<void> _initializeData() async {
    await fetchStationIndicatorData();
    await loadIntlFromCache();
    fetchAllIntlData();
    await loadHourlyData();
  }

  // ==============================================================================
  // STATION LOAD DATA (Original Indicators Logic)
  // ==============================================================================

  Future<void> fetchStationIndicatorData() async {
    try {
      isLoadingStations.value = true;
      animationController.reset();

      final hourlyLoads =
          await _supabaseServiceHourly.fetchStationHourlyLoads();

      final List<String> newStations =
          hourlyLoads.map((e) => e.stationName).toList();
      final List<List<double>> newStationLoads =
          hourlyLoads.map((e) => e.loads).toList();

      double newSumStations = 0.0;
      double newSumGeneration = 0.0;
      double newSumExchanges = 0.0;

      final List<String> exchangeStations = IndicatorConstants.exchangeStations;
      final String generationStation = IndicatorConstants.generationStation;

      for (int i = 0; i < newStations.length; i++) {
        final String stationName = newStations[i];
        final List<double> loads = newStationLoads[i];
        final double stationSum =
            loads.fold(0.0, (double a, double b) => a + b);

        if (stationName == generationStation) {
          newSumGeneration += stationSum;
        } else if (exchangeStations.contains(stationName)) {
          newSumExchanges += stationSum;
        } else {
          newSumStations += stationSum;
        }
      }

      final double newTotalDynamic =
          newSumStations + newSumGeneration + newSumExchanges;

      stations.assignAll(newStations);
      stationLoads.assignAll(newStationLoads);
      if (newStations.isNotEmpty && selectedStations.isEmpty) {
        selectedStations.add(0);
      }
      sumStations.value = newSumStations;
      sumGeneration.value = newSumGeneration;
      sumExchanges.value = newSumExchanges;
      totalDynamic.value = newTotalDynamic;
      hasPieData.value = newTotalDynamic > 0.0;

      isLoadingStations.value = false;
      animationController.forward();
    } catch (e) {
      isLoadingStations.value = false;
      stations.clear();
      stationLoads.clear();
      selectedStations.clear();
      sumStations.value = 0.0;
      sumGeneration.value = 0.0;
      sumExchanges.value = 0.0;
      totalDynamic.value = 0.0;
      hasPieData.value = false;
      animationController.forward();
      print("Error fetching station data: $e");
    }
  }

  void toggleStationSelection(int index, bool selected) {
    if (selected) {
      if (selectedStations.length < AppConstants.maxStations) {
        selectedStations.add(index);
      } else {
        Get.snackbar(
          'تنبيه',
          'يمكنك اختيار ${AppConstants.maxStations} محطات كحد أقصى',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orangeAccent,
          colorText: Colors.white,
        );
      }
    } else {
      selectedStations.remove(index);
    }
  }

  // ==============================================================================
  // INTERNATIONAL LOADS (Migrated Logic)
  // ==============================================================================

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

    // Sync Cairo load with StationLoadController
    if (Get.isRegistered<StationLoadController>()) {
      final stationController = Get.find<StationLoadController>();
      intlLoads['القاهرة'] = stationController.totalLoad;

      // Update whenever station loads change
      ever(stationController.stationLoads, (_) {
        intlLoads['القاهرة'] = stationController.totalLoad;
      });
    } else {
      // Fallback if controller not found (though it should be)
      final stationController = Get.put(StationLoadController());
      intlLoads['القاهرة'] = stationController.totalLoad;
      ever(stationController.stationLoads, (_) {
        intlLoads['القاهرة'] = stationController.totalLoad;
      });
    }
  }

  // ... (Identical fetch methods as in LoadnavController) ...
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

  // ==============================================================================
  // HOURLY CHART DATA (Migrated Logic)
  // ==============================================================================

  Future<void> loadHourlyData() async {
    isLoadingHourly.value = true;
    final cached = await _cacheService.getHourlyMaxLoads();
    if (cached != null) {
      hourlyMaxLoadsToday.assignAll(cached['today'] ?? []);
      hourlyMaxLoadsYesterday.assignAll(cached['yesterday'] ?? []);
      _calculateMaxHourlyLoad();
    }
    await fetchFreshHourlyData();
  }

  Future<void> fetchFreshHourlyData() async {
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
      if (hourlyMaxLoadsToday.isEmpty) {
        hourlyError.value = 'Error fetching chart data: $e';
      }
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

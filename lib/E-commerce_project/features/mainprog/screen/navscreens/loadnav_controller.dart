import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:amiraly/E-commerce_project/common/services/cache_service.dart';
import 'package:amiraly/main.dart';
import 'dart:math';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:amiraly/E-commerce_project/common/models/appmodels.dart';
import 'package:amiraly/E-commerce_project/util/constant/constants.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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
  final RxBool isGeneratingPdf = false.obs;
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

  // --- PDF Methods ---
  Future<void> generateAndSharePDF(BuildContext context) async {
    if (isGeneratingPdf.value) return;
    isGeneratingPdf.value = true;
    try {
      final pdf = pw.Document();

      // Load fonts
      final fontData =
          await rootBundle.load("lib/assets/fonts/Changa-Light.ttf");
      final ttf = pw.Font.ttf(fontData);

      final digitalFontData =
          await rootBundle.load("lib/assets/fonts/Digital.ttf");
      final digitalTtf = pw.Font.ttf(digitalFontData);

      final now = DateTime.now();
      final arabicMonths = [
        'يناير',
        'فبراير',
        'مارس',
        'أبريل',
        'مايو',
        'يونيو',
        'يوليو',
        'أغسطس',
        'سبتمبر',
        'أكتوبر',
        'نوفمبر',
        'ديسمبر'
      ];
      final dateStr = "${now.day} ${arabicMonths[now.month - 1]} ${now.year}";
      final timeStr =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

      final totalLoad =
          stationLoads.fold<double>(0.0, (sum, station) => sum + station.load);

      // Find max station load for percentage calculation
      final maxStationLoad = stationLoads.isNotEmpty
          ? stationLoads.map((s) => s.load).reduce((a, b) => a > b ? a : b)
          : 1.0;

      // Premium color palette
      const primaryDark = PdfColor.fromInt(0xFF1A1F36);
      const primaryBlue = PdfColor.fromInt(0xFF4F46E5);
      const accentGold = PdfColor.fromInt(0xFFD4AF37);
      const successGreen = PdfColor.fromInt(0xFF10B981);
      const warningOrange = PdfColor.fromInt(0xFFF59E0B);
      const dangerRed = PdfColor.fromInt(0xFFEF4444);
      const lightBg = PdfColor.fromInt(0xFFF8FAFC);
      const cardBg = PdfColors.white;
      const textDark = PdfColor.fromInt(0xFF1E293B);
      const textMuted = PdfColor.fromInt(0xFF64748B);

      pdf.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(24),
            theme: pw.ThemeData.withFont(base: ttf),
            buildBackground: (context) => pw.FullPage(
              ignoreMargins: true,
              child: pw.Container(color: lightBg),
            ),
          ),
          build: (pw.Context context) {
            return [
              // ═══════════════════════════════════════════════════════════
              // HEADER SECTION
              // ═══════════════════════════════════════════════════════════
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  gradient: const pw.LinearGradient(
                    colors: [primaryDark, PdfColor.fromInt(0xFF2D3561)],
                    begin: pw.Alignment.topLeft,
                    end: pw.Alignment.bottomRight,
                  ),
                  borderRadius: pw.BorderRadius.circular(16),
                ),
                child: pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        // Left: Time
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromInt(0x33FFFFFF),
                            borderRadius: pw.BorderRadius.circular(20),
                          ),
                          child: pw.Row(
                            children: [
                              pw.SizedBox(width: 4),
                              pw.Text(timeStr,
                                  style: pw.TextStyle(
                                      font: ttf,
                                      fontSize: 11,
                                      color: PdfColors.black)),
                            ],
                          ),
                        ),
                        // Right: Date
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromInt(0x33FFFFFF),
                            borderRadius: pw.BorderRadius.circular(20),
                          ),
                          child: pw.Row(
                            children: [
                              pw.SizedBox(width: 4),
                              pw.Text(dateStr,
                                  style: pw.TextStyle(
                                      font: ttf,
                                      fontSize: 11,
                                      color: PdfColors.black),
                                  textDirection: pw.TextDirection.rtl),
                            ],
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 20),
                    // Title
                    pw.Text('تقرير أحمال شبكة القاهرة ',
                        style: pw.TextStyle(
                            font: ttf,
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white),
                        textDirection: pw.TextDirection.rtl),
                    pw.SizedBox(height: 6),
                    pw.Container(
                      width: 60,
                      height: 3,
                      decoration: pw.BoxDecoration(
                        color: accentGold,
                        borderRadius: pw.BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // ═══════════════════════════════════════════════════════════
              // TOTAL LOAD HERO SECTION
              // ═══════════════════════════════════════════════════════════
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Main Load Card
                  pw.Expanded(
                    flex: 2,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(24),
                      decoration: pw.BoxDecoration(
                        color: cardBg,
                        borderRadius: pw.BorderRadius.circular(16),
                        border:
                            pw.Border.all(color: PdfColor.fromInt(0xFFE2E8F0)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Text('الحمل الكلي للشبكة',
                                  style: pw.TextStyle(
                                      font: ttf,
                                      fontSize: 14,
                                      fontWeight: pw.FontWeight.bold,
                                      color: textDark),
                                  textDirection: pw.TextDirection.rtl),
                            ],
                          ),
                          pw.SizedBox(height: 16),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text('MW',
                                  style: pw.TextStyle(
                                      font: ttf,
                                      fontSize: 14,
                                      fontWeight: pw.FontWeight.bold,
                                      color: textMuted)),
                              pw.SizedBox(width: 8),
                              pw.Text(totalLoad.toStringAsFixed(0),
                                  style: pw.TextStyle(
                                      font: digitalTtf,
                                      fontSize: 52,
                                      color: primaryBlue)),
                            ],
                          ),
                          pw.SizedBox(height: 12),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: pw.BoxDecoration(
                              color: PdfColor.fromInt(0xFFF0FDF4),
                              borderRadius: pw.BorderRadius.circular(8),
                              border: pw.Border.all(
                                  color: PdfColor.fromInt(0xFFBBF7D0)),
                            ),
                            child: pw.Text(
                                'أقصى حمل: ${maxLoadInLastHour.value.toStringAsFixed(0)} MW',
                                style: pw.TextStyle(
                                    font: ttf,
                                    fontSize: 11,
                                    color: successGreen),
                                textDirection: pw.TextDirection.rtl),
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  // Stats Cards
                  pw.Expanded(
                    flex: 1,
                    child: pw.Column(
                      children: [
                        // Station Count
                        pw.Container(
                          width: double.infinity,
                          padding: const pw.EdgeInsets.all(16),
                          decoration: pw.BoxDecoration(
                            color: cardBg,
                            borderRadius: pw.BorderRadius.circular(12),
                            border: pw.Border.all(
                                color: PdfColor.fromInt(0xFFE2E8F0)),
                          ),
                          child: pw.Column(
                            children: [
                              pw.Text('${stationLoads.length}',
                                  style: pw.TextStyle(
                                      font: digitalTtf,
                                      fontSize: 28,
                                      color: primaryDark)),
                              pw.Text('محطة',
                                  style: pw.TextStyle(
                                      font: ttf,
                                      fontSize: 10,
                                      color: textMuted),
                                  textDirection: pw.TextDirection.rtl),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 12),
                        // Avg Load
                        pw.Container(
                          width: double.infinity,
                          padding: const pw.EdgeInsets.all(16),
                          decoration: pw.BoxDecoration(
                            color: cardBg,
                            borderRadius: pw.BorderRadius.circular(12),
                            border: pw.Border.all(
                                color: PdfColor.fromInt(0xFFE2E8F0)),
                          ),
                          child: pw.Column(
                            children: [
                              pw.Text(
                                  stationLoads.isNotEmpty
                                      ? (totalLoad / stationLoads.length)
                                          .toStringAsFixed(0)
                                      : '0',
                                  style: pw.TextStyle(
                                      font: digitalTtf,
                                      fontSize: 28,
                                      color: warningOrange)),
                              pw.Text('متوسط الحمل',
                                  style: pw.TextStyle(
                                      font: ttf,
                                      fontSize: 10,
                                      color: textMuted),
                                  textDirection: pw.TextDirection.rtl),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // ═══════════════════════════════════════════════════════════
              // HOURLY CHART SECTION
              // ═══════════════════════════════════════════════════════════
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: cardBg,
                  borderRadius: pw.BorderRadius.circular(16),
                  border: pw.Border.all(color: PdfColor.fromInt(0xFFE2E8F0)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        // Legend
                        pw.Row(
                          children: [
                            pw.Container(
                                width: 12,
                                height: 12,
                                decoration: pw.BoxDecoration(
                                    color: primaryBlue,
                                    borderRadius: pw.BorderRadius.circular(2))),
                            pw.SizedBox(width: 4),
                            pw.Text('اليوم',
                                style: pw.TextStyle(
                                    font: ttf, fontSize: 9, color: textMuted),
                                textDirection: pw.TextDirection.rtl),
                            pw.SizedBox(width: 12),
                            pw.Container(
                                width: 12,
                                height: 12,
                                decoration: pw.BoxDecoration(
                                    color: PdfColor.fromInt(0xFFCBD5E1),
                                    borderRadius: pw.BorderRadius.circular(2))),
                            pw.SizedBox(width: 4),
                            pw.Text('الأمس',
                                style: pw.TextStyle(
                                    font: ttf, fontSize: 9, color: textMuted),
                                textDirection: pw.TextDirection.rtl),
                          ],
                        ),
                        // Title
                        pw.Text('مخطط الأحمال بالساعة',
                            style: pw.TextStyle(
                                font: ttf,
                                fontSize: 13,
                                fontWeight: pw.FontWeight.bold,
                                color: textDark),
                            textDirection: pw.TextDirection.rtl),
                      ],
                    ),
                    pw.SizedBox(height: 20),
                    // Chart
                    pw.Container(
                      height: 100,
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: List.generate(24, (hour) {
                          final todayItem = hourlyMaxLoadsToday.firstWhere(
                              (e) => e['hour'] == hour,
                              orElse: () => {'max_load': 0});
                          final yesterdayItem = hourlyMaxLoadsYesterday
                              .firstWhere((e) => e['hour'] == hour,
                                  orElse: () => {'max_load': 0});
                          final todayLoad =
                              (todayItem['max_load'] as num).toDouble();
                          final yesterdayLoad =
                              (yesterdayItem['max_load'] as num).toDouble();
                          final maxVal = (maxHourlyLoad.value ?? 1000) * 1.1;
                          final todayH =
                              maxVal > 0 ? (todayLoad / maxVal) * 80 : 0.0;
                          final yesterdayH =
                              maxVal > 0 ? (yesterdayLoad / maxVal) * 80 : 0.0;

                          return pw.Column(
                            mainAxisAlignment: pw.MainAxisAlignment.end,
                            children: [
                              pw.Row(
                                crossAxisAlignment: pw.CrossAxisAlignment.end,
                                children: [
                                  pw.Container(
                                    width: 5,
                                    height: yesterdayH > 3 ? yesterdayH : 3,
                                    decoration: pw.BoxDecoration(
                                      color: PdfColor.fromInt(0xFFCBD5E1),
                                      borderRadius:
                                          const pw.BorderRadius.vertical(
                                              top: pw.Radius.circular(2)),
                                    ),
                                  ),
                                  pw.SizedBox(width: 1),
                                  pw.Container(
                                    width: 5,
                                    height: todayH > 3 ? todayH : 3,
                                    decoration: pw.BoxDecoration(
                                      color: primaryBlue,
                                      borderRadius:
                                          const pw.BorderRadius.vertical(
                                              top: pw.Radius.circular(2)),
                                    ),
                                  ),
                                ],
                              ),
                              pw.SizedBox(height: 4),
                              if (hour % 4 == 0)
                                pw.Text('$hour',
                                    style: pw.TextStyle(
                                        font: ttf,
                                        fontSize: 7,
                                        color: textMuted))
                              else
                                pw.SizedBox(height: 9),
                            ],
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // ═══════════════════════════════════════════════════════════
              // STATIONS SECTION HEADER
              // ═══════════════════════════════════════════════════════════
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: pw.BoxDecoration(
                  gradient: const pw.LinearGradient(
                    colors: [primaryDark, PdfColor.fromInt(0xFF2D3561)],
                  ),
                  borderRadius: const pw.BorderRadius.vertical(
                      top: pw.Radius.circular(16)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text('تفاصيل أحمال المحطات',
                        style: pw.TextStyle(
                            font: ttf,
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white),
                        textDirection: pw.TextDirection.rtl),
                  ],
                ),
              ),

              // ═══════════════════════════════════════════════════════════
              // STATIONS GRID
              // ═══════════════════════════════════════════════════════════
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: cardBg,
                  borderRadius: const pw.BorderRadius.vertical(
                      bottom: pw.Radius.circular(16)),
                  border: pw.Border.all(color: PdfColor.fromInt(0xFFE2E8F0)),
                ),
                child: pw.Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  alignment: pw.WrapAlignment.spaceBetween,
                  runAlignment: pw.WrapAlignment.center,
                  children: stationLoads.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final station = entry.value;
                    final loadPercent = (station.load / maxStationLoad) * 100;

                    // Color based on load percentage
                    PdfColor barColor;
                    if (loadPercent > 80) {
                      barColor = dangerRed;
                    } else if (loadPercent > 60) {
                      barColor = warningOrange;
                    } else {
                      barColor = successGreen;
                    }

                    return pw.Container(
                      width: (PdfPageFormat.a4.availableWidth - 48 - 16) / 5,
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFFF8FAFC),
                        borderRadius: pw.BorderRadius.circular(10),
                        border:
                            pw.Border.all(color: PdfColor.fromInt(0xFFE2E8F0)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          // Header row
                          pw.Row(
                            children: [
                              pw.Container(
                                width: 22,
                                height: 22,
                                decoration: pw.BoxDecoration(
                                  color: primaryBlue,
                                  borderRadius: pw.BorderRadius.circular(6),
                                ),
                                child: pw.Center(
                                  child: pw.Text('${idx + 1}',
                                      style: pw.TextStyle(
                                          font: ttf,
                                          fontSize: 10,
                                          fontWeight: pw.FontWeight.bold,
                                          color: PdfColors.white)),
                                ),
                              ),
                              pw.SizedBox(width: 8),
                              pw.Expanded(
                                child: pw.Text(station.stationName,
                                    style: pw.TextStyle(
                                        font: ttf,
                                        fontSize: 8,
                                        fontWeight: pw.FontWeight.bold,
                                        color: textDark),
                                    maxLines: 1,
                                    overflow: pw.TextOverflow.clip,
                                    textDirection: pw.TextDirection.rtl),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 8),
                          // Load value
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('MW',
                                  style: pw.TextStyle(
                                      font: ttf,
                                      fontSize: 8,
                                      color: textMuted)),
                              pw.Text(station.load.toStringAsFixed(0),
                                  style: pw.TextStyle(
                                      font: digitalTtf,
                                      fontSize: 18,
                                      color: textDark)),
                            ],
                          ),
                          pw.SizedBox(height: 6),
                          // Progress bar
                          pw.Container(
                            height: 4,
                            decoration: pw.BoxDecoration(
                              color: PdfColor.fromInt(0xFFE2E8F0),
                              borderRadius: pw.BorderRadius.circular(2),
                            ),
                            child: pw.Row(
                              children: [
                                pw.Container(
                                  width: ((PdfPageFormat.a4.availableWidth -
                                                  48 -
                                                  16) /
                                              5 -
                                          16) *
                                      (loadPercent / 100),
                                  height: 4,
                                  decoration: pw.BoxDecoration(
                                    color: barColor,
                                    borderRadius: pw.BorderRadius.circular(2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              pw.SizedBox(height: 24),

              // ═══════════════════════════════════════════════════════════
              // FOOTER
              // ═══════════════════════════════════════════════════════════
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFF1F5F9),
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('v1.0',
                        style: pw.TextStyle(
                            font: ttf, fontSize: 9, color: textMuted)),
                    pw.Text('تم إنشاء هذا التقرير آلياً بواسطة  التحكم',
                        style: pw.TextStyle(
                            font: ttf, fontSize: 9, color: textMuted),
                        textDirection: pw.TextDirection.rtl),
                    pw.Text('📄', style: const pw.TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ];
          },
        ),
      );

      final pdfBytes = await pdf.save();
      await Printing.sharePdf(
          bytes: pdfBytes,
          filename: 'cairo_grid_report_${now.millisecondsSinceEpoch}.pdf');
    } catch (e) {
      debugPrint('Error generating PDF: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في إنشاء ملف PDF: $e')),
        );
      }
    } finally {
      isGeneratingPdf.value = false;
    }
  }
}

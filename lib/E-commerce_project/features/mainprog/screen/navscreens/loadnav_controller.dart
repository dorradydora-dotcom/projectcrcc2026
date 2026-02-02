import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:get/get.dart';
import 'package:amiraly/E-commerce_project/common/models/appmodels.dart';
import 'package:amiraly/E-commerce_project/features/mainprog/screen/navscreens/station_load_controller.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class LoadnavController extends GetxController {
  final StationLoadController _stationController =
      Get.find<StationLoadController>();

  // --- Station Load State ---
  RxList<StationLoad> get stationLoads => _stationController.stationLoads;
  RxBool get isLoadingStations => _stationController.isLoading;
  RxBool get isStationFromCache => _stationController.isFromCache;
  RxBool get stnError => _stationController.hasError;
  RxString get errorMessage => _stationController.errorMessage;
  RxMap<String, bool> get directions => _stationController.directions;

  // --- Hourly Chart State ---
  // Removed migrated logic (hourlyMaxLoadsToday, etc.)
  final RxDouble maxLoadInLastHour = 0.0.obs;
  final RxBool isGeneratingPdf = false.obs;
  final List<Map<String, dynamic>> _loadHistory = [];

  // --- Timers ---
  Timer? _stationRefreshTimer;
  Timer? _simulationTimer;

  @override
  void onInit() {
    super.onInit();
    // Use microtask to avoid calling build-triggering updates during the very first build
    Future.microtask(() => _initializeAllData());

    // Auto-refresh station data from API every minute
    _stationRefreshTimer = Timer.periodic(
        const Duration(seconds: 60), (_) => _stationController.fetchData());

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
  }

  // --- Station Methods ---
  double get totalStationLoad => _stationController.totalLoad;

  Future<void> fetchStationLoads({bool showLoading = true}) async {
    await _stationController.fetchData();
  }

  void _simulateLoadChanges() {
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
              // Hourly Chart Section removed as logic migrated to Indicators screen
              pw.SizedBox(height: 10),

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

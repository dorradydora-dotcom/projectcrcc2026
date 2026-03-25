import 'package:amiraly/app/common/widgets/appbar.dart';
import 'package:amiraly/app/features/mainprog/screen/navscreens/station_load_controller.dart';
import 'package:amiraly/app/util/constant/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:amiraly/app/util/helpers/pdf_helper.dart';
import 'package:amiraly/core/widgets/electric_loading_indicator.dart';


class TransformerReportScreen extends StatefulWidget {
  const TransformerReportScreen({super.key});

  @override
  State<TransformerReportScreen> createState() =>
      _TransformerReportScreenState();
}

class _TransformerReportScreenState extends State<TransformerReportScreen> {
  final _supabase = Supabase.instance.client;
  final StationLoadController _loadController =
      Get.find<StationLoadController>();
  bool _isGeneratingPdf = false;
  List<Map<String, dynamic>>? _cachedData;

  // Stations to exclude from the report
  static const List<String> _excludedStations = [
    'عبور3/عاشر',
    'برقاش /ابوغالب',
    'قليوب/قناطر',
    'الكريمات/بنى سويف',
    'ابو زعبل ق / بلبيس',
  ];

  bool _canEditUser = false;

  @override
  void initState() {
    super.initState();
    _checkUserPermission();
  }

  Future<void> _checkUserPermission() async {
    final user = _supabase.auth.currentUser;
    if (user?.email != null) {
      final response = await _supabase
          .from(AppConstants.tableUserCrcc)
          .select()
          .eq('user_email', user!.email!)
          .maybeSingle();

      if (response != null) {
        setState(() {
          _canEditUser = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: const Color(0xFF0F172A),
      appBar: const CustomAppBar(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: EdgeInsets.symmetric(horizontal: 15.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FloatingActionButton(
              heroTag: 'pdf_btn',
              onPressed: _isGeneratingPdf
                  ? null
                  : () {
                      if (_cachedData != null) {
                        _generatePDF(context, _cachedData!);
                      } else {
                        Get.snackbar(
                            'تنبيه', 'يرجى انتظار تحميل البيانات أولاً',
                            snackPosition: SnackPosition.BOTTOM);
                      }
                    },
              backgroundColor:
                  _isGeneratingPdf ? Colors.grey : Colors.redAccent,
              child: _isGeneratingPdf
                  ? const ElectricLoadingIndicator(
                      color: Colors.white,
                      size: 15,
                    )
                  : const Icon(Icons.picture_as_pdf, color: Colors.white),
            ),
            FloatingActionButton(
              heroTag: 'refresh_btn',
              onPressed: () {
                _loadController.fetchData();
                setState(() {});
              },
              backgroundColor: Colors.blue,
              child: const Icon(Icons.refresh, color: Colors.white),
            ),
          ],
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Appcolors.primaryColor,
                Appcolors.primaryColor,
                Color(0xFF163C5E),
                Color(0xFF0F2B44),
                Color(0xFF081A2A)
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 10.h),
                child: Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                          color: const Color.fromARGB(120, 255, 153, 0),
                          width: 1.w),
                      color: const Color.fromARGB(110, 0, 0, 0)),
                  child: Text(
                    'نسب تحميل المحطات',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.orange,
                      fontFamily: Appfontstring.ChangaLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _fetchCapacityData(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildShimmer();
                    }
                    if (snapshot.hasError) {
                      return Center(
                          child: Text('حدث خطأ في تحميل البيانات',
                              style: TextStyle(
                                  color: Colors.redAccent,
                                  fontFamily: Appfontstring.ChangaLight,
                                  fontSize: 10.sp)));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                          child: Text('لا توجد بيانات متاحة',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontFamily: Appfontstring.ChangaLight,
                                  fontSize: 10.sp)));
                    }

                    final capacityData = snapshot.data!;
                    _cachedData = capacityData;
                    return LayoutBuilder(builder: (context, constraints) {
                      final tableWidth = constraints.maxWidth;
                      final col2 = tableWidth * 0.25; // Station Name
                      final col3 = tableWidth * 0.20; // Load
                      final col4 = tableWidth * 0.18; // Capacity
                      final col5 = tableWidth * 0.25; // Ratio

                      return Obx(() {
                        final liveLoads = _loadController.stationLoads;
                        return Container(
                          margin: EdgeInsets.all(10.w),
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                  width: 1)),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              children: [
                                DataTable(
                                  headingRowColor: WidgetStateProperty.all(
                                      Colors.white.withOpacity(0.1)),
                                  dataRowColor: WidgetStateProperty.all(
                                      Colors.transparent),
                                  dataRowMinHeight: 32.h,
                                  dataRowMaxHeight: 35.h,
                                  columnSpacing: 0,
                                  horizontalMargin: 4.w,
                                  columns: [
                                    DataColumn(
                                        label: SizedBox(
                                            width: col2,
                                            child: Row(
                                              children: [
                                                Icon(Icons.location_city,
                                                    size: 12.sp,
                                                    color: Appcolors.gold),
                                                SizedBox(width: 4.w),
                                                Text('المحطة',
                                                    style: TextStyle(
                                                        fontSize: 11.sp,
                                                        color: Appcolors.gold)),
                                              ],
                                            ))),
                                    DataColumn(
                                        label: SizedBox(
                                            width: col3,
                                            child: Row(
                                              children: [
                                                Icon(Icons.bolt,
                                                    size: 12.sp,
                                                    color: Colors.white70),
                                                SizedBox(width: 4.w),
                                                Text('الحمل',
                                                    style: TextStyle(
                                                        fontSize: 11.sp,
                                                        color: Colors.white)),
                                              ],
                                            ))),
                                    DataColumn(
                                        label: SizedBox(
                                            width: col4,
                                            child: Row(
                                              children: [
                                                Icon(Icons.battery_full,
                                                    size: 12.sp,
                                                    color: Colors.white70),
                                                SizedBox(width: 4.w),
                                                Text('السعة',
                                                    style: TextStyle(
                                                        fontSize: 11.sp,
                                                        color: Colors.white)),
                                              ],
                                            ))),
                                    DataColumn(
                                        label: SizedBox(
                                            width: col5,
                                            child: Row(
                                              children: [
                                                Icon(Icons.pie_chart,
                                                    size: 12.sp,
                                                    color: Colors.white70),
                                                SizedBox(width: 4.w),
                                                Text('النسبة',
                                                    style: TextStyle(
                                                        fontSize: 11.sp,
                                                        color: Colors.white))
                                              ],
                                            ))),
                                  ],
                                  rows: () {
                                    final filteredData =
                                        capacityData.where((item) {
                                      final name = item['station_name'] ?? '';
                                      return !_excludedStations.any(
                                          (excluded) =>
                                              name.contains(excluded) ||
                                              excluded.contains(name));
                                    }).toList();

                                    return filteredData.map((item) {
                                      final stationName =
                                          item['station_name'] ?? '-';
                                      final capacity =
                                          (item['total_capacity_mva'] as num?)
                                                  ?.toDouble() ??
                                              0.0;

                                      double liveLoad = 0.0;
                                      try {
                                        final station = liveLoads.firstWhere(
                                            (s) =>
                                                s.stationName == stationName);
                                        liveLoad = station.load;
                                      } catch (_) {
                                        // Station not found in live data
                                      }

                                      final ratio = capacity > 0
                                          ? (liveLoad / capacity) * 100
                                          : 0.0;

                                      return DataRow(cells: [
                                        DataCell(SizedBox(
                                            width: col2,
                                            child: Text(stationName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                    fontSize: 10.sp,
                                                    color: Colors.white70)))),
                                        DataCell(SizedBox(
                                            width: col3,
                                            child: Text(
                                                liveLoad.toStringAsFixed(1),
                                                style: TextStyle(
                                                    fontSize: 10.sp,
                                                    fontFamily: Appfontstring.digital,
                                                    fontFamilyFallback: const [Appfontstring.ChangaLight],
                                                    color: Colors.blue)))),
                                        DataCell(
                                          SizedBox(
                                            width: col4,
                                            child: InkWell(
                                              onTap: _canEditUser
                                                  ? () => _showEditDialog(
                                                      stationName, capacity)
                                                  : null,
                                              child: Container(
                                                margin: EdgeInsets.symmetric(
                                                    horizontal: 4.w),
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 4.w,
                                                    vertical: 2.h),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.05),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          6.r),
                                                  border: Border.all(
                                                      color: Colors.white
                                                          .withValues(
                                                              alpha: 0.1)),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                        capacity
                                                            .toStringAsFixed(0),
                                                        style: TextStyle(
                                                            fontSize: 10.sp,
                                                            fontFamily:
                                                                Appfontstring
                                                                    .digital,
                                                                    fontFamilyFallback: const [Appfontstring.ChangaLight],
                                                            color:
                                                                Colors.white)),
                                                    if (_canEditUser) ...[
                                                      SizedBox(width: 4.w),
                                                      Icon(Icons.edit,
                                                          size: 8.sp,
                                                          color: Colors
                                                              .blueAccent
                                                              .withValues(
                                                                  alpha: 0.8)),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(SizedBox(
                                            width: col5,
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 6.w,
                                                  height: 6.w,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: ratio > 90
                                                        ? Colors.red
                                                        : ratio > 70
                                                            ? Colors.orange
                                                            : Colors.green,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: (ratio > 90
                                                                ? Colors.red
                                                                : ratio > 70
                                                                    ? Colors
                                                                        .orange
                                                                    : Colors
                                                                        .green)
                                                            .withValues(
                                                                alpha: 0.5),
                                                        blurRadius: 4,
                                                        spreadRadius: 1,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                SizedBox(width: 6.w),
                                                Text(
                                                    '${ratio.toStringAsFixed(1)}%',
                                                    style: TextStyle(
                                                        fontSize: 12.sp,
                                                        fontFamily: Appfontstring.digital,
                                                        fontFamilyFallback: const [Appfontstring.ChangaLight],
                                                        color: ratio > 90
? Colors.red
: ratio > 70
? Colors.orange
: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                              ],
                                            ))),
                                      ]);
                                    }).toList();
                                  }(),
                                ),
                                SizedBox(height: 70.h),
                              ],
                            ),
                          ),
                        );
                      });
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchCapacityData() async {
    final response = await _supabase
        .from(AppConstants.tableStation)
        .select('station_name, total_capacity_mva')
        .limit(AppConstants.defaultFetchLimit)
        .order('station_name', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> _showEditDialog(
      String stationName, double currentCapacity) async {
    await Get.dialog(
      CapacityEditDialog(
        stationName: stationName,
        currentCapacity: currentCapacity,
        onSave: (newCap) => _updateCapacity(stationName, newCap),
      ),
    );
  }

  Future<void> _updateCapacity(String stationName, double newCapacity) async {
    try {
      await _supabase.from(AppConstants.tableStation).update(
          {'total_capacity_mva': newCapacity}).eq('station_name', stationName);
      setState(() {});
      Get.snackbar('نجاح', 'تم تحديث سعة المحطة بنجاح',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.7),
          colorText: Colors.white);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في تحديث البيانات',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.7),
          colorText: Colors.white);
    }
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.white.withOpacity(0.1),
      highlightColor: Colors.white.withOpacity(0.3),
      child: ListView.builder(
        itemCount: 10,
        itemBuilder: (_, __) => Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          height: 40.h,
          color: Colors.white,
        ),
      ),
    );
  }

  Future<void> _generatePDF(
      BuildContext context, List<Map<String, dynamic>> data) async {
    if (_isGeneratingPdf) {
      return;
    }
    setState(() => _isGeneratingPdf = true);

    try {
      final pdf = pw.Document();
      final fontData =
          await rootBundle.load("lib/assets/fonts/Changa-Light.ttf");
      final ttf = pw.Font.ttf(fontData);

      final filteredData = data.where((item) {
        final name = item['station_name'] ?? '';
        return !_excludedStations.any(
            (excluded) => name.contains(excluded) || excluded.contains(name));
      }).toList();

      final now = DateTime.now();
      final dateStr = PdfHelper.prepareArabic("${now.day}/${now.month}/${now.year}");

      final primaryBlue = PdfColor.fromInt(0xFF163C5E);
      final accentGold = PdfColor.fromInt(0xFFD4AF37);
      final dangerRed = PdfColor.fromInt(0xFFC00000);
      final warningOrange = PdfColor.fromInt(0xFFE67E22);
      final successGreen = PdfColor.fromInt(0xFF008000);

      pdf.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(32),
            theme: pw.ThemeData.withFont(base: ttf),
            buildBackground: (context) => pw.FullPage(
              ignoreMargins: true,
              child: pw.Container(color: PdfColors.white),
            ),
          ),
          header: (context) => pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: primaryBlue,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(PdfHelper.prepareArabic('تقرير نسب تحميل المحطات'),
                              style: pw.TextStyle(
                                  font: ttf,
                                  fontSize: 22,
                                  color: PdfColors.white,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 4),
                          pw.Container(
                            width: 100,
                            height: 2,
                            color: accentGold,
                          ),
                        ],
                      ),
                      pw.Text(dateStr,
                          style: const pw.TextStyle(
                              color: PdfColors.white, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          footer: (context) => pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              PdfHelper.prepareArabic('صفحة ${context.pageNumber} من ${context.pagesCount}'),
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ),
          build: (context) => [
            pw.SizedBox(height: 20),
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Table(
                border:
                    pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1.2), // Ratio (Far Left)
                  1: const pw.FlexColumnWidth(1), // Capacity
                  2: const pw.FlexColumnWidth(1), // Load
                  3: const pw.FlexColumnWidth(3.5), // Station (Far Right)
                },
                children: [
                  // Header Row
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: primaryBlue),
                    children: [
                      _buildHeaderCell(PdfHelper.prepareArabic('النسبة'), ttf, color: PdfColors.white),
                      _buildHeaderCell(PdfHelper.prepareArabic('السعة'), ttf, color: PdfColors.white),
                      _buildHeaderCell(PdfHelper.prepareArabic('الحمل'), ttf, color: PdfColors.white),
                      _buildHeaderCell(PdfHelper.prepareArabic('المحطة'), ttf, color: PdfColors.white),
                    ],
                  ),
                  // Data Rows
                  ...filteredData.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final station = entry.value;
                    final name = station['station_name'] ?? '-';
                    final capacity =
                        (station['total_capacity_mva'] as num?)?.toDouble() ??
                            0.0;
                    double load = 0.0;
                    try {
                      load = _loadController.stationLoads
                          .firstWhere((s) => s.stationName == name)
                          .load;
                    } catch (_) {}
                    final ratio = capacity > 0 ? (load / capacity) * 100 : 0.0;

                    // Color logic for ratio
                    PdfColor ratioColor = successGreen;
                    if (ratio > 90) {
                      ratioColor = dangerRed;
                    } else if (ratio > 70) {
                      ratioColor = warningOrange;
                    }

                    return pw.TableRow(
                      decoration: idx % 2 == 0
                          ? const pw.BoxDecoration(color: PdfColors.grey100)
                          : null,
                      children: [
                        _buildDataCell('${ratio.toStringAsFixed(1)}%', ttf,
                            color: ratioColor, isBold: true),
                        _buildDataCell(capacity.toStringAsFixed(0), ttf),
                        _buildDataCell(load.toStringAsFixed(1), ttf),
                        _buildDataCell(PdfHelper.prepareArabic(name), ttf,
                            align: pw.Alignment.centerRight),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      );

      final pdfBytes = await pdf.save();
      await Printing.sharePdf(
          bytes: pdfBytes, filename: 'station_load_ratio_report.pdf');
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }

  pw.Widget _buildHeaderCell(String text, pw.Font font,
      {PdfColor color = PdfColors.black}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
            font: font,
            fontWeight: pw.FontWeight.bold,
            fontSize: 12,
            color: color),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildDataCell(String text, pw.Font font,
      {pw.Alignment align = pw.Alignment.center,
      PdfColor color = PdfColors.black,
      bool isBold = false}) {
    return pw.Container(
      alignment: align,
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: 10,
          color: color,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}

class CapacityEditDialog extends StatefulWidget {
  final String stationName;
  final double currentCapacity;
  final Function(double) onSave;

  const CapacityEditDialog({
    super.key,
    required this.stationName,
    required this.currentCapacity,
    required this.onSave,
  });

  @override
  State<CapacityEditDialog> createState() => _CapacityEditDialogState();
}

class _CapacityEditDialogState extends State<CapacityEditDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: widget.currentCapacity.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF163C5E),
      title: Text('تعديل سعة محطة ${widget.stationName}',
          style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontFamily: Appfontstring.ChangaLight)),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          labelText: 'السعة الكلية (MVA)',
          labelStyle: TextStyle(color: Colors.white70),
          enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24)),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white70))),
        ElevatedButton(
          onPressed: () {
            final newCap = double.tryParse(_controller.text);
            if (newCap != null) {
              widget.onSave(newCap);
              Get.back();
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          child: const Text('حفظ', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

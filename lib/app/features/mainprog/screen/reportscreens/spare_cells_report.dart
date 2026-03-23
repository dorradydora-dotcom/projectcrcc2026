import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import 'package:amiraly/app/common/widgets/appbar.dart';
import 'package:amiraly/app/util/constant/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:get/get.dart';
import 'package:amiraly/app/util/helpers/pdf_helper.dart';
import 'package:amiraly/core/widgets/electric_loading_indicator.dart';


class SpareCellsReportScreen extends StatefulWidget {
  const SpareCellsReportScreen({super.key});

  @override
  State<SpareCellsReportScreen> createState() => _SpareCellsReportScreenState();
}

class _SpareCellsReportScreenState extends State<SpareCellsReportScreen> {
  final _supabase = Supabase.instance.client;
  bool _canEditUser = false;
  bool _isGeneratingPdf = false;
  List<Map<String, dynamic>> _cachedData = [];
  late Future<List<Map<String, dynamic>>> dataFuture;

  @override
  void initState() {
    super.initState();
    _checkUserPermission();
    dataFuture = _fetchData();
  }

  Future<void> _checkUserPermission() async {
    final user = _supabase.auth.currentUser;
    if (user?.email != null) {
      try {
        final response = await _supabase
            .from(AppConstants.tableUserCrcc)
            .select()
            .eq('user_email', user!.email!)
            .maybeSingle();

        if (response != null && mounted) {
          setState(() {
            _canEditUser = true;
          });
        }
      } catch (e) {
        debugPrint('Error checking permissions');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: const Color(0xFF0F172A),
      appBar: const CustomAppBar(),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_cachedData.isNotEmpty)
            FloatingActionButton(
              onPressed: _isGeneratingPdf ? null : _generateAndSharePdf,
              backgroundColor: Colors.white.withOpacity(0.15),
              mini: true,
              heroTag: 'pdfFAB',
              child: _isGeneratingPdf
                  ? const ElectricLoadingIndicator(
                      color: Colors.white, size: 18)
                  : const Icon(Icons.picture_as_pdf,
                      color: Colors.lightGreenAccent),
            ),
          SizedBox(height: 5.h),
          if (_canEditUser)
            FloatingActionButton(
              onPressed: _showAddDialog,
              backgroundColor: Appcolors.gold,
              heroTag: 'addFAB',
              child: const Icon(Icons.add, color: Colors.black),
            ),
        ],
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
              // Header
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 8.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FadeInRight(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20.r),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.inventory_2,
                                color: Appcolors.gold, size: 16.sp),
                            SizedBox(width: 8.w),
                            Text('الخلايا الاحتياطية',
                                style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: Appfontstring.ChangaLight)),
                          ],
                        ),
                      ),
                    ),
                    FadeInLeft(
                      child: Text(
                        'الإجمالي: ${_cachedData.length}',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12.sp,
                            fontFamily: Appfontstring.digital),
                      ),
                    ),
                  ],
                ),
              ),

              Text(
                'اسحب الشاشة لأسفل لتحديث البيانات',
                style: TextStyle(
                    color: Colors.white24,
                    fontSize: 10.sp,
                    fontFamily: Appfontstring.ChangaLight),
              ),
              SizedBox(height: 4.h),

              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: dataFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        _cachedData.isEmpty) {
                      return _buildShimmer();
                    }

                    final currentData = snapshot.data ?? _cachedData;

                    if (currentData.isEmpty) {
                      return Center(
                        child: Text('لا توجد بيانات متاحة',
                            style: TextStyle(
                                color: Colors.white30, fontSize: 14.sp)),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        setState(() {
                          dataFuture = _fetchData();
                        });
                      },
                      backgroundColor: const Color(0xFF163C5E),
                      color: Appcolors.gold,
                      child: ListView.builder(
                        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 100.h),
                        physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics()),
                        itemCount: currentData.length,
                        itemBuilder: (context, index) {
                          final item = currentData[index];
                          return FadeInUp(
                            delay: Duration(milliseconds: index * 50),
                            child: _buildCellCard(item),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCellCard(Map<String, dynamic> item) {
    final status = item['status'] ?? '-';
    final isReserved = status.toString().toLowerCase().contains('eserv') ||
        status.toString().contains('محجوز');

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(8.r),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 30.w,
                height: 30.w,
                decoration: BoxDecoration(
                  color: (isReserved ? Colors.redAccent : Colors.blue)
                      .withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isReserved ? Icons.lock : Icons.check_circle,
                  color: isReserved ? Colors.redAccent : Colors.blue,
                  size: 16.sp,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['station_name'] ?? '-',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          fontFamily: Appfontstring.ChangaLight),
                      textAlign: TextAlign.right,
                    ),
                    Text(
                      status,
                      style: TextStyle(
                        color: isReserved ? Colors.redAccent : Colors.white60,
                        fontSize: 10.sp,
                        fontFamily: Appfontstring.ChangaLight,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),
              if (_canEditUser)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit_outlined,
                          size: 17.sp, color: Colors.blue),
                      onPressed: () => _showEditDialog(item),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    SizedBox(width: 3.w),
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          size: 17.sp, color: Colors.redAccent),
                      onPressed: () => _showDeleteConfirm(item),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
            ],
          ),
          Divider(color: Colors.white.withOpacity(0.05), height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBadge(
                Icons.bolt,
                '${item['voltage_level'] ?? '-'} جهد',
                Colors.orangeAccent,
              ),
              _buildBadge(
                Icons.numbers,
                'خلية رقم ${item['cell_number'] ?? '-'}',
                Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10.sp, color: color),
          SizedBox(width: 6.w),
          Text(
            text,
            style: TextStyle(
                color: color,
                fontSize: 10.sp,
                fontFamily: Appfontstring.digital),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchData() async {
    try {
      final response = await _supabase
          .from(AppConstants.tableSpareCells)
          .select()
          .order('id', ascending: true)
          .limit(AppConstants.defaultFetchLimit);
      final data = List<Map<String, dynamic>>.from(response);

      if (mounted) {
        Future.microtask(() {
          if (mounted && _cachedData.length != data.length) {
            setState(() {
              _cachedData = data;
            });
          }
        });
      }
      return data;
    } catch (e) {
      return _cachedData;
    }
  }

  void _showAddDialog() async {
    final stationController = TextEditingController();
    final voltageController = TextEditingController();
    final cellController = TextEditingController();
    final statusController = TextEditingController();

    await Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF163C5E),
        title: const Text('إضافة خلية احتياطية',
            style: TextStyle(color: Colors.white), textAlign: TextAlign.right),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(stationController, 'اسم المحطة'),
              _buildTextField(voltageController, 'مستوى الجهد'),
              _buildTextField(cellController, 'رقم الخلية', isNumber: true),
              _buildTextField(statusController, 'الحالة'),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Get.back(),
              child:
                  const Text('إلغاء', style: TextStyle(color: Colors.white70))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Appcolors.gold),
            onPressed: () async {
              if (stationController.text.isNotEmpty) {
                await _supabase.from(AppConstants.tableSpareCells).insert({
                  'station_name': stationController.text,
                  'voltage_level': voltageController.text,
                  'cell_number': int.tryParse(cellController.text) ?? 0,
                  'status': statusController.text,
                });
                Get.back();
                setState(() {});
              }
            },
            child: const Text('إضافة', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );

    // تفريغ الذاكرة بعد إغلاق النافذة
    stationController.dispose();
    voltageController.dispose();
    cellController.dispose();
    statusController.dispose();
  }

  void _showEditDialog(Map<String, dynamic> item) async {
    final stationController =
        TextEditingController(text: item['station_name']?.toString());
    final voltageController =
        TextEditingController(text: item['voltage_level']?.toString());
    final cellController =
        TextEditingController(text: item['cell_number']?.toString());
    final statusController =
        TextEditingController(text: item['status']?.toString());

    await Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF163C5E),
        title: const Text('تعديل البيانات',
            style: TextStyle(color: Colors.white), textAlign: TextAlign.right),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(stationController, 'اسم المحطة'),
              _buildTextField(voltageController, 'مستوى الجهد'),
              _buildTextField(cellController, 'رقم الخلية', isNumber: true),
              _buildTextField(statusController, 'الحالة'),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Get.back(),
              child:
                  const Text('إلغاء', style: TextStyle(color: Colors.white70))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Appcolors.gold),
            onPressed: () async {
              await _supabase.from(AppConstants.tableSpareCells).update({
                'station_name': stationController.text,
                'voltage_level': voltageController.text,
                'cell_number': int.tryParse(cellController.text) ?? 0,
                'status': statusController.text,
              }).eq('id', item['id']);
              Get.back();
              setState(() {});
            },
            child: const Text('حفظ', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );

    // تفريغ الذاكرة بعد إغلاق النافذة
    stationController.dispose();
    voltageController.dispose();
    cellController.dispose();
    statusController.dispose();
  }

  void _showDeleteConfirm(Map<String, dynamic> item) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF163C5E),
        title: const Text('تأكيد الحذف',
            style: TextStyle(color: Colors.white), textAlign: TextAlign.right),
        content: Text('هل أنت متأكد من حذف بيانات ${item['station_name']}؟',
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.right),
        actions: [
          TextButton(
              onPressed: () => Get.back(),
              child:
                  const Text('إلغاء', style: TextStyle(color: Colors.white70))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _supabase
                  .from(AppConstants.tableSpareCells)
                  .delete()
                  .eq('id', item['id']);
              Get.back();
              setState(() {});
            },
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool isNumber = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        textAlign: TextAlign.right,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24)),
          focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Appcolors.gold)),
        ),
      ),
    );
  }

  Future<void> _generateAndSharePdf() async {
    setState(() => _isGeneratingPdf = true);
    try {
      final pdf = pw.Document();

      // تحميل الخطوط يدوياً لضمان معالجة النص العربي بشكل سليم
      final fontData =
          await rootBundle.load("lib/assets/fonts/Changa-Light.ttf");
      final ttf = pw.Font.ttf(fontData);

      final boldFontData =
          await rootBundle.load("lib/assets/fonts/Changa-Light.ttf");
      final boldTtf = pw.Font.ttf(boldFontData);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(base: ttf, bold: boldTtf),
          build: (context) => [
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Column(
                children: [
                  pw.Header(
                    level: 0,
                    child: pw.Center(
                      child: pw.Text(PdfHelper.prepareArabic('تقرير الخلايا الاحتياطية'),
                          style: pw.TextStyle(fontSize: 24, font: boldTtf)),
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Table(
                    border: pw.TableBorder.all(
                        color: PdfColors.grey300, width: 0.5),
                    children: [
                      // Header Row
                      pw.TableRow(
                        decoration:
                            const pw.BoxDecoration(color: PdfColors.grey300),
                        children: [
                          _buildPdfCell(PdfHelper.prepareArabic('الحالة'), boldTtf, isHeader: true),
                          _buildPdfCell(PdfHelper.prepareArabic('رقم الخلية'), boldTtf, isHeader: true),
                          _buildPdfCell(PdfHelper.prepareArabic('الجهد'), boldTtf, isHeader: true),
                          _buildPdfCell(PdfHelper.prepareArabic('المحطة'), boldTtf, isHeader: true),
                        ],
                      ),
                      // Data Rows
                      ..._cachedData.map((e) => pw.TableRow(
                            children: [
                              _buildPdfCell(PdfHelper.prepareArabic(e['status'] ?? '-'), ttf),
                              _buildPdfCell(
                                  e['cell_number']?.toString() ?? '-', ttf),
                              _buildPdfCell(
                                  e['voltage_level']?.toString() ?? '-', ttf),
                              _buildPdfCell(
                                  PdfHelper.prepareArabic(e['station_name']?.toString() ?? '-'), ttf),
                            ],
                          )),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );

      await Printing.sharePdf(
          bytes: await pdf.save(), filename: 'spare_cells_report.pdf');
    } catch (e) {
      Get.snackbar('خطأ', 'فشل استخراج ملف PDF: $e');
    } finally {
      setState(() => _isGeneratingPdf = false);
    }
  }

  pw.Widget _buildPdfCell(String text, pw.Font font, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: isHeader ? 12 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: pw.TextAlign.right,
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.white.withOpacity(0.1),
      highlightColor: Colors.white.withOpacity(0.3),
      child: ListView.builder(
        itemCount: 10,
        itemBuilder: (_, __) => Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          height: 45.h,
          color: Colors.white,
        ),
      ),
    );
  }
}

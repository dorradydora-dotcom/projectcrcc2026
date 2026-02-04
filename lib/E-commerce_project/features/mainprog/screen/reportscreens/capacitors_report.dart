import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import 'package:amiraly/E-commerce_project/common/widgets/appbar.dart';
import 'package:amiraly/E-commerce_project/util/constant/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:get/get.dart';

class CapacitorsReportScreen extends StatefulWidget {
  const CapacitorsReportScreen({super.key});

  @override
  State<CapacitorsReportScreen> createState() => _CapacitorsReportScreenState();
}

class _CapacitorsReportScreenState extends State<CapacitorsReportScreen> {
  final _supabase = Supabase.instance.client;
  bool _canEditUser = false;
  bool _isGeneratingPdf = false;
  List<Map<String, dynamic>> _cachedData = [];
  late Future<List<Map<String, dynamic>>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _checkUserPermission();
    _dataFuture = _fetchData();
  }

  Future<void> _checkUserPermission() async {
    final user = _supabase.auth.currentUser;
    if (user?.email != null) {
      final response = await _supabase
          .from('user_crcc')
          .select()
          .eq('user_email', user!.email!)
          .maybeSingle();

      if (response != null && mounted) {
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
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_cachedData.isNotEmpty)
            FloatingActionButton(
              onPressed: _isGeneratingPdf ? null : _generateAndSharePdf,
              backgroundColor: Colors.white.withOpacity(0.15),
              mini: true,
              heroTag: 'pdfFAB_Cap',
              child: _isGeneratingPdf
                  ? SizedBox(
                      width: 18.w,
                      height: 18.w,
                      child: const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.picture_as_pdf,
                      color: Colors.lightGreenAccent),
            ),
          SizedBox(height: 5.h),
          if (_canEditUser)
            FloatingActionButton(
              onPressed: _showAddDialog,
              backgroundColor: C.gold,
              heroTag: 'addFAB_Cap',
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
                            Icon(Icons.power_input_outlined,
                                color: C.gold, size: 16.sp),
                            SizedBox(width: 8.w),
                            Text('تقرير المكثفات',
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
                            fontFamily: Appfontstring.ChangaLight),
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
                  future: _dataFuture,
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
                          _dataFuture = _fetchData();
                        });
                      },
                      backgroundColor: const Color(0xFF163C5E),
                      color: C.gold,
                      child: ListView.builder(
                        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 100.h),
                        physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics()),
                        itemCount: currentData.length,
                        itemBuilder: (context, index) {
                          final item = currentData[index];
                          return FadeInUp(
                            delay: Duration(milliseconds: index * 50),
                            child: _buildCapacitorCard(item),
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

  Widget _buildCapacitorCard(Map<String, dynamic> item) {
    final status = item['status'] ?? '-';
    final isOut = status.toString().toLowerCase().contains('out') ||
        status.toString().contains('خارج');

    return Container(
      margin: EdgeInsets.only(bottom: 6.h),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 24.w,
                height: 24.w,
                decoration: BoxDecoration(
                  color: (isOut ? Colors.redAccent : C.blue).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isOut ? Icons.error_outline : Icons.bolt,
                  color: isOut ? Colors.redAccent : C.blue,
                  size: 14.sp,
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
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          fontFamily: Appfontstring.ChangaLight),
                      textAlign: TextAlign.right,
                    ),
                    Text(
                      status,
                      style: TextStyle(
                        color: isOut ? Colors.redAccent : Colors.white60,
                        fontSize: 9.sp,
                        fontFamily: Appfontstring.ChangaLight,
                      ),
                      textAlign: TextAlign.right,
                      softWrap: true,
                      maxLines: null,
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
                          size: 16.sp, color: Colors.blue),
                      onPressed: () => _showEditDialog(item),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    SizedBox(width: 4.w),
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          size: 16.sp, color: Colors.redAccent),
                      onPressed: () => _showDeleteConfirm(item),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
            ],
          ),
          Divider(color: Colors.white.withOpacity(0.05), height: 6.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBadge(
                Icons.flash_on,
                '${item['voltage_level'] ?? '-'} جهد',
                Colors.orangeAccent,
              ),
              _buildBadge(
                Icons.electric_meter,
                '${item['capacity_mvar'] ?? '-'} MVAR',
                C.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(5.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9.sp, color: color),
          SizedBox(width: 6.w),
          Text(
            text,
            style: TextStyle(
                color: color,
                fontSize: 10.sp,
                fontFamily: Appfontstring.ChangaLight),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchData() async {
    try {
      final response = await _supabase
          .from('capacitors')
          .select()
          .order('id', ascending: true);
      final data = List<Map<String, dynamic>>.from(response);

      if (mounted) {
        // Schedule FAB update
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

  void _showAddDialog() {
    final stationController = TextEditingController();
    final voltageController = TextEditingController();
    final capacityController = TextEditingController();
    final statusController = TextEditingController();

    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF163C5E),
        title: Text('إضافة مكثف جديد',
            style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontFamily: Appfontstring.ChangaLight)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(stationController, 'اسم المحطة'),
              _buildTextField(voltageController, 'مستوى الجهد'),
              _buildTextField(capacityController, 'السعة (MVAR)',
                  isNumber: true),
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
            onPressed: () async {
              if (stationController.text.isNotEmpty) {
                await _supabase.from('capacitors').insert({
                  'station_name': stationController.text,
                  'voltage_level': voltageController.text,
                  'capacity_mvar': double.tryParse(capacityController.text),
                  'status': statusController.text,
                });
                Get.back();
                setState(() {});
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: C.gold),
            child: const Text('إضافة', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> item) {
    final stationController =
        TextEditingController(text: item['station_name']?.toString());
    final voltageController =
        TextEditingController(text: item['voltage_level']?.toString());
    final capacityController =
        TextEditingController(text: item['capacity_mvar']?.toString());
    final statusController =
        TextEditingController(text: item['status']?.toString());

    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF163C5E),
        title: Text('تعديل بيانات المكثف',
            style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontFamily: Appfontstring.ChangaLight)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(stationController, 'اسم المحطة'),
              _buildTextField(voltageController, 'مستوى الجهد'),
              _buildTextField(capacityController, 'السعة (MVAR)',
                  isNumber: true),
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
            onPressed: () async {
              await _supabase.from('capacitors').update({
                'station_name': stationController.text,
                'voltage_level': voltageController.text,
                'capacity_mvar': double.tryParse(capacityController.text),
                'status': statusController.text,
              }).eq('id', item['id']);
              Get.back();
              setState(() {});
            },
            style: ElevatedButton.styleFrom(backgroundColor: C.blue),
            child: const Text('حفظ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(Map<String, dynamic> item) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF163C5E),
        title: const Text('تأكيد الحذف', style: TextStyle(color: Colors.white)),
        content: Text('هل أنت متأكد من حذف مكثف محطة ${item['station_name']}؟',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Get.back(),
              child:
                  const Text('إلغاء', style: TextStyle(color: Colors.white70))),
          ElevatedButton(
            onPressed: () async {
              await _supabase.from('capacitors').delete().eq('id', item['id']);
              Get.back();
              setState(() {});
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
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
          focusedBorder:
              const UnderlineInputBorder(borderSide: BorderSide(color: C.gold)),
        ),
      ),
    );
  }

  Future<void> _generateAndSharePdf() async {
    setState(() => _isGeneratingPdf = true);
    try {
      final pdf = pw.Document();
      final fontData =
          await rootBundle.load("lib/assets/fonts/Changa-Light.ttf");
      final ttf = pw.Font.ttf(fontData);

      final boldFontData =
          await rootBundle.load("lib/assets/fonts/Changa-Bold.ttf");
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
                      child: pw.Text('تقرير المكثفات',
                          style: pw.TextStyle(fontSize: 24, font: boldTtf)),
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Table(
                    border: pw.TableBorder.all(
                        color: PdfColors.grey300, width: 0.5),
                    children: [
                      pw.TableRow(
                        decoration:
                            const pw.BoxDecoration(color: PdfColors.grey300),
                        children: [
                          _buildPdfCell('الحالة', boldTtf, isHeader: true),
                          _buildPdfCell('السعة (MVAR)', boldTtf,
                              isHeader: true),
                          _buildPdfCell('الجهد', boldTtf, isHeader: true),
                          _buildPdfCell('المحطة', boldTtf, isHeader: true),
                        ],
                      ),
                      ..._cachedData.map((e) => pw.TableRow(
                            children: [
                              _buildPdfCell(e['status'] ?? '-', ttf),
                              _buildPdfCell(
                                  e['capacity_mvar']?.toString() ?? '-', ttf),
                              _buildPdfCell(e['voltage_level'] ?? '-', ttf),
                              _buildPdfCell(e['station_name'] ?? '-', ttf),
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
          bytes: await pdf.save(), filename: 'capacitors_report.pdf');
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
        softWrap: true,
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

import 'package:animate_do/animate_do.dart';
import 'package:amiraly/app/common/widgets/appbar.dart';
import 'package:amiraly/app/util/constant/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:get/get.dart';
import 'package:amiraly/app/util/helpers/pdf_helper.dart';
import 'package:amiraly/core/widgets/electric_loading_indicator.dart';
import 'package:intl/intl.dart' as intl;

class HourlyLoadReportScreen extends StatefulWidget {
  const HourlyLoadReportScreen({super.key});

  @override
  State<HourlyLoadReportScreen> createState() => _HourlyLoadReportScreenState();
}

class _HourlyLoadReportScreenState extends State<HourlyLoadReportScreen> {
  final _supabase = Supabase.instance.client;
  bool _isGeneratingPdf = false;
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _data = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      // Automatic cleanup: Delete records older than 7 days (Today + 6 previous days)
      final retentionDate = DateTime.now().subtract(const Duration(days: 6));
      final formattedRetentionDate =
          intl.DateFormat('yyyy-MM-dd').format(retentionDate);
      await _supabase
          .from(AppConstants.tableHourlyMaxLoads)
          .delete()
          .lt('date', formattedRetentionDate);

      final formattedDate = intl.DateFormat('yyyy-MM-dd').format(_selectedDate);
      final response = await _supabase
          .from(AppConstants.tableHourlyMaxLoads)
          .select('hour, max_load')
          .eq('date', formattedDate)
          .order('hour', ascending: true);

      final fetchedData = List<Map<String, dynamic>>.from(response);

      // Ensure all 24 hours are represented even if missing in DB
      final List<Map<String, dynamic>> fullDayData = List.generate(24, (hour) {
        final existing = fetchedData.firstWhere(
          (element) => element['hour'] == hour,
          orElse: () => {'hour': hour, 'max_load': 0.0},
        );
        return existing;
      });

      setState(() {
        _data = fullDayData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar('خطأ', 'فشل في جلب البيانات: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: const CustomAppBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: _isGeneratingPdf ? null : _generateAndSharePdf,
        backgroundColor: Appcolors.gold,
        heroTag: 'pdfFAB_Hourly',
        child: _isGeneratingPdf
            ? const ElectricLoadingIndicator(color: Colors.black, size: 20)
            : const Icon(Icons.picture_as_pdf, color: Colors.black),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
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
              _buildHeader(),
              _buildDaysScroller(),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: ElectricLoadingIndicator(color: Appcolors.gold))
                    : _buildTable(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDaysScroller() {
    final now = DateTime.now();
    return Container(
      height: 58.h,
      margin: EdgeInsets.only(bottom: 8.h),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        itemCount: 7,
        itemBuilder: (context, index) {
          final date = now.subtract(Duration(days: index));
          final isSelected = intl.DateFormat('yyyy-MM-dd').format(date) ==
              intl.DateFormat('yyyy-MM-dd').format(_selectedDate);

          String label;
          if (index == 0) {
            label = 'اليوم';
          } else if (index == 1) {
            label = 'أمس';
          } else if (index == 2) {
            label = 'أول أمس';
          } else {
            label = intl.DateFormat('EEEE', 'ar').format(date);
          }

          final dateLabel = intl.DateFormat('dd/MM').format(date);

          return GestureDetector(
            onTap: () {
              setState(() => _selectedDate = date);
              _fetchData();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? Appcolors.gold
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: isSelected
                      ? Appcolors.gold
                      : Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Appcolors.gold.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white70,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontFamily: Appfontstring.ChangaLight,
                      fontSize: 11.sp,
                    ),
                  ),
                  Text(
                    dateLabel,
                    style: TextStyle(
                      color: isSelected ? Colors.black54 : Colors.white38,
                      fontFamily: Appfontstring.digital,
                      fontSize: 10.sp,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: Appcolors.gold.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.history_toggle_off,
                color: Appcolors.gold, size: 24.sp),
          ),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الحمل اليومي على مدار الساعة',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: Appfontstring.ChangaLight,
                ),
              ),
              Text(
                'تقرير الأحمال القصوى لكل ساعة',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 12.sp,
                  fontFamily: Appfontstring.ChangaLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: Container(
        margin: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 16.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Table(
          border: TableBorder.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 0.5,
            borderRadius: BorderRadius.circular(8.r),
          ),
          children: [
            // Header Row
            TableRow(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
              ),
              children: List.generate(
                  2,
                  (index) => Container(
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text('الساعة',
                                style: TextStyle(
                                    color: Appcolors.gold,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: Appfontstring.ChangaLight)),
                            Text('الحمل',
                                style: TextStyle(
                                    color: Appcolors.gold,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: Appfontstring.ChangaLight)),
                          ],
                        ),
                      )),
            ),
            // Data Rows
            ...List.generate(12, (rowIndex) {
              return TableRow(
                children: List.generate(2, (colIndex) {
                  final int dataIndex = rowIndex + (colIndex * 12);
                  if (dataIndex >= _data.length) return const SizedBox.shrink();

                  final item = _data[dataIndex];
                  final int hour = item['hour'] as int;
                  final double load =
                      (item['max_load'] as num?)?.toDouble() ?? 0.0;

                  return Container(
                    padding:
                        EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text(
                          '${hour + 1}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.sp,
                            fontFamily: Appfontstring.ChangaLight,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          load.toStringAsFixed(1),
                          style: TextStyle(
                            color: load > 0 ? Appcolors.gold : Colors.white24,
                            fontSize: 14.sp,
                            fontFamily: Appfontstring.digital,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              );
            }),
          ],
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

      final dateStr = intl.DateFormat('yyyy/MM/dd').format(_selectedDate);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(base: ttf, bold: ttf),
          build: (context) => [
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                              PdfHelper.prepareArabic(
                                  'الشركة المصرية لنقل الكهرباء'),
                              textDirection: pw.TextDirection.ltr,
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(fontSize: 12, font: ttf)),
                          pw.Text(
                              PdfHelper.prepareArabic('قطاع التحكم القاهره'),
                              textDirection: pw.TextDirection.ltr,
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(fontSize: 10, font: ttf)),
                        ],
                      ),
                      pw.Text(PdfHelper.prepareArabic('تقرير الأحمال اليومي'),
                          textDirection: pw.TextDirection.ltr,
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                              fontSize: 18,
                              font: ttf,
                              fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.SizedBox(height: 20),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(5),
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey200),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                            PdfHelper.prepareArabic('تاريخ التقرير: $dateStr'),
                            textDirection: pw.TextDirection.ltr,
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(fontSize: 12, font: ttf)),
                        pw.Text(
                            PdfHelper.prepareArabic(
                                'تم استخراجة بواسطة تطبيق التحكم الاقليمى للقاهرة الكبرى'),
                            textDirection: pw.TextDirection.ltr,
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(fontSize: 10, font: ttf)),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Table(
                    border: pw.TableBorder.all(
                        color: PdfColors.grey400, width: 0.5),
                    children: [
                      // PDF Header Row
                      pw.TableRow(
                        decoration:
                            const pw.BoxDecoration(color: PdfColors.grey100),
                        children: List.generate(
                            2,
                            (index) => pw.Container(
                                  padding: const pw.EdgeInsets.symmetric(
                                      vertical: 4, horizontal: 10),
                                  child: pw.Row(
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.spaceBetween,
                                    children: [
                                      pw.Text(PdfHelper.prepareArabic('الساعة'),
                                          textDirection: pw.TextDirection.ltr,
                                          textAlign: pw.TextAlign.right,
                                          style: pw.TextStyle(
                                              fontSize: 9,
                                              font: ttf,
                                              fontWeight: pw.FontWeight.bold)),
                                      pw.Text(PdfHelper.prepareArabic('الحمل'),
                                          textDirection: pw.TextDirection.ltr,
                                          textAlign: pw.TextAlign.right,
                                          style: pw.TextStyle(
                                              fontSize: 9,
                                              font: ttf,
                                              fontWeight: pw.FontWeight.bold)),
                                    ],
                                  ),
                                )),
                      ),
                      // PDF Data Rows
                      ...List.generate(12, (rowIndex) {
                        return pw.TableRow(
                          children: List.generate(2, (colIndex) {
                            final int dataIndex = rowIndex + (colIndex * 12);
                            if (dataIndex >= _data.length) return pw.SizedBox();

                            final item = _data[dataIndex];
                            final int hour = item['hour'] as int;
                            final double load =
                                (item['max_load'] as num?)?.toDouble() ?? 0.0;

                            return pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 10),
                              child: pw.Row(
                                mainAxisAlignment:
                                    pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text('${hour + 1}',
                                      style: pw.TextStyle(
                                          fontSize: 11,
                                          font: ttf,
                                          color: PdfColors.grey700,
                                          fontWeight: pw.FontWeight.bold)),
                                  pw.Text(load.toStringAsFixed(1),
                                      style: pw.TextStyle(
                                          fontSize: 12,
                                          font: ttf,
                                          fontWeight: pw.FontWeight.bold)),
                                ],
                              ),
                            );
                          }),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );

      final fileName = 'hourly_load_report_${dateStr.replaceAll('/', '-')}.pdf';
      await Printing.sharePdf(bytes: await pdf.save(), filename: fileName);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل استخراج ملف PDF: $e');
    } finally {
      setState(() => _isGeneratingPdf = false);
    }
  }
}

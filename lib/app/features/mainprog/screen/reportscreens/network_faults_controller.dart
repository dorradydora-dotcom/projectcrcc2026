import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:amiraly/app/util/constant/constants.dart';
import 'package:amiraly/app/util/helpers/pdf_helper.dart';

class NetworkFaultsController extends GetxController {
  final _supabase = Supabase.instance.client;
  var canEditUser = false.obs;
  var isGeneratingPdf = false.obs;
  var cachedData = <Map<String, dynamic>>[].obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    _checkUserPermission();
    fetchData();
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
        canEditUser.value = true;
      }
    }
  }

  Future<void> fetchData() async {
    isLoading.value = true;
    try {
      final response = await _supabase
          .from(AppConstants.tableNetworkFaults)
          .select()
          .limit(AppConstants.defaultFetchLimit)
          .order('id', ascending: true);
      cachedData.assignAll(List<Map<String, dynamic>>.from(response));
    } catch (e) {
      Get.snackbar('خطأ', 'فشل تحميل البيانات: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addFault(Map<String, dynamic> data) async {
    try {
      await _supabase.from(AppConstants.tableNetworkFaults).insert(data);
      if (Get.isDialogOpen ?? false) Get.back();
      await fetchData();
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ أثناء الإضافة: $e');
    }
  }

  Future<void> updateFault(int id, Map<String, dynamic> data) async {
    try {
      await _supabase
          .from(AppConstants.tableNetworkFaults)
          .update(data)
          .eq('id', id);
      if (Get.isDialogOpen ?? false) Get.back();
      await fetchData();
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ أثناء حفظ التعديلات: $e');
    }
  }

  Future<void> deleteFault(int id) async {
    try {
      await _supabase
          .from(AppConstants.tableNetworkFaults)
          .delete()
          .eq('id', id);
      if (Get.isDialogOpen ?? false) Get.back();
      await fetchData();
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ أثناء الحذف: $e');
    }
  }

  Future<void> generateAndSharePdf() async {
    isGeneratingPdf.value = true;
    try {
      final pdf = pw.Document();
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
                      child: pw.Text(
                          PdfHelper.prepareArabic('تقرير أعطال الشبكة'),
                          textDirection: pw.TextDirection.ltr,
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
                          _buildPdfCell(
                              PdfHelper.prepareArabic('سبب العطل'), boldTtf,
                              isHeader: true),
                          _buildPdfCell(
                              PdfHelper.prepareArabic('المهمه العاطلة'),
                              boldTtf,
                              isHeader: true),
                          _buildPdfCell(
                              PdfHelper.prepareArabic('التاريخ'), boldTtf,
                              isHeader: true),
                          _buildPdfCell(
                              PdfHelper.prepareArabic('المحطة'), boldTtf,
                              isHeader: true),
                        ],
                      ),
                      ...cachedData.map((e) => pw.TableRow(
                            children: [
                              _buildPdfCell(
                                  PdfHelper.prepareArabic(
                                      e['fault_reason']?.toString() ?? '-'),
                                  ttf),
                              _buildPdfCell(
                                  PdfHelper.prepareArabic(
                                      e['faulty_equipment']?.toString() ?? '-'),
                                  ttf),
                              _buildPdfCell(
                                  e['fault_date'] != null &&
                                          e['fault_date']
                                              .toString()
                                              .contains('-')
                                      ? e['fault_date']
                                          .toString()
                                          .split('-')
                                          .reversed
                                          .join('-')
                                      : (e['fault_date'] != null &&
                                              e['fault_date']
                                                  .toString()
                                                  .contains('/')
                                          ? e['fault_date']
                                              .toString()
                                              .split('/')
                                              .reversed
                                              .join('/')
                                          : '${e['fault_date'] ?? '-'}'),
                                  ttf),
                              _buildPdfCell(
                                  PdfHelper.prepareArabic(
                                      e['station_name']?.toString() ?? '-'),
                                  ttf),
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
          bytes: await pdf.save(), filename: 'network_faults_report.pdf');
    } catch (e) {
      Get.snackbar('خطأ', 'فشل استخراج ملف PDF: $e');
    } finally {
      isGeneratingPdf.value = false;
    }
  }

  pw.Widget _buildPdfCell(String text, pw.Font font, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        textDirection: pw.TextDirection.ltr,
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
}

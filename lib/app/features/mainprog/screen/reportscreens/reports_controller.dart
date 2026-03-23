import 'package:amiraly/app/common/models/appmodels.dart';
import 'package:amiraly/core/services/supabase_service.dart';
import 'package:get/get.dart';

class ReportsController extends GetxController {
  final SupabaseService _supabaseService = Get.find<SupabaseService>();

  final RxList<Report> reports = <Report>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchReports();
  }

  Future<void> fetchReports({bool forceRefresh = false}) async {
    try {
      isLoading.value = true;
      if (forceRefresh) {
        _supabaseService.clearCacheKey('reports_config');
      }
      final fetchedReports = await _supabaseService.fetchReportsConfig();
      reports.assignAll(fetchedReports);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في تحميل قائمة التقارير');
    } finally {
      isLoading.value = false;
    }
  }
}

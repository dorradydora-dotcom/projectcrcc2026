import 'package:amiraly/app/common/models/appmodels.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:amiraly/app/util/constant/constants.dart';

class AreaNavController extends GetxController {
  final RxList<StationDetialesModel> stations = <StationDetialesModel>[].obs;
  final RxBool isLoading = true.obs;

  final RxString searchQuery = ''.obs;
  final RxInt selectedIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchStations();
  }

  /// تصفية المحطات بناءً على البحث
  List<StationDetialesModel> get filteredStations {
    if (searchQuery.value.trim().isEmpty) {
      return stations;
    }
    final query = searchQuery.value.trim().toLowerCase();
    return stations
        .where((s) =>
            s.name.toLowerCase().contains(query) ||
            s.zone.toLowerCase().contains(query))
        .toList();
  }

  bool get isSearchActive => searchQuery.value.trim().isNotEmpty;
  bool get hasNoSearchResults => isSearchActive && filteredStations.isEmpty;

  int get totalStations => stations.length;
  int get activeStations => stations.where((s) => s.image.isNotEmpty).length;
  int get maintenanceStations => stations.where((s) => s.image.isEmpty).length;

  Future<void> fetchStations({bool refresh = false}) async {
    // التحقق مما إذا كانت البيانات موجودة بالفعل لمنع الاستدعاء المتكرر
    if (stations.isNotEmpty && !refresh) {
      return;
    }

    try {
      isLoading.value = true;

      // جلب جميع المحطات من الجدول بدون قيود
      final response = await Supabase.instance.client
          .from(AppConstants.tableStation)
          .select()
          .timeout(const Duration(seconds: 10));

      final fetchedData = response.map((json) {
        return StationDetialesModel.fromJson(json);
      }).toList();

      stations.assignAll(fetchedData);
    } catch (e) {
      // تسجيل الخطأ في الـ Console للمساعدة في التصحيح
      debugPrint('Error fetching stations');

      Get.snackbar(
        'خطأ في الاتصال',
        'فشل في جلب بيانات المحطات',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        mainButton: TextButton(
          onPressed: () {
            if (Get.isSnackbarOpen) {
              Get.back();
            }
            fetchStations(refresh: true);
          },
          child: const Text(
            'إعادة المحاولة',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
    } finally {
      isLoading.value = false;
    }
  }
}

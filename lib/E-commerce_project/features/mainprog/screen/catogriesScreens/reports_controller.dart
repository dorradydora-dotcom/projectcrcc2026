import 'package:amiraly/E-commerce_project/common/models/appmodels.dart';
import 'package:get/get.dart';

class ReportsController extends GetxController {
  static const Map<String, String> _offers = {
    'المكثفات': 'Description for Report 1',
    'الخلايا الاحطياتية بالمحطات': 'Description for Report 2',
    'نسب تحميل المحطات': 'Description for Report 3',
  };

  final RxList<Report> reports = <Report>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchReports();
  }

  Future<void> fetchReports() async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));
    reports.value = _offers.entries
        .map(
          (e) => Report(
            name: e.key,
            description: e.value,
            date: DateTime.now().toString().substring(0, 10),
          ),
        )
        .toList();
    isLoading.value = false;
  }
}

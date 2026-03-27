import 'package:amiraly/app/common/models/appmodels.dart';
import 'package:amiraly/app/common/widgets/appbar.dart';
import 'package:amiraly/app/features/mainprog/screen/reportscreens/capacitors_report.dart';
import 'package:amiraly/app/features/mainprog/screen/reportscreens/spare_cells_report.dart';
import 'package:amiraly/app/features/mainprog/screen/reportscreens/transformer_ratio_report.dart';
import 'package:amiraly/app/features/mainprog/screen/reportscreens/network_faults_report.dart';
import 'package:amiraly/app/features/mainprog/screen/reportscreens/report1_screen.dart';
import 'package:amiraly/app/features/mainprog/screen/reportscreens/report2_screen.dart';
import 'package:amiraly/app/features/mainprog/screen/reportscreens/report3_screen.dart';
import 'package:amiraly/app/features/mainprog/screen/reportscreens/report4_screen.dart';
import 'package:amiraly/app/util/constant/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:amiraly/core/widgets/electric_loading_indicator.dart';
import '../reportscreens/reports_controller.dart';
import '../reportscreens/report1_controller.dart';
import '../reportscreens/report2_controller.dart';
import '../reportscreens/report3_controller.dart';
import '../reportscreens/report4_controller.dart';


class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportsController controller = Get.put(ReportsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Appcolors.primaryColor,
      appBar: const CustomAppBar(),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Appcolors.primaryColor,
                Color(0xFF163C5E),
                Color(0xFF0F2B44),
                Color(0xFF081A2A)
              ],
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
                child: Row(
                  children: [
                    Container(
                      width: 5,
                      height: 24.h,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBBC05),
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'التقارير الفنية',
                          style: TextStyle(
                            fontFamily: Appfontstring.ChangaLight,
                            fontSize: 18.sp,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'نظام استعراض وإدارة التقارير الدورية',
                          style: TextStyle(
                            fontFamily: Appfontstring.ChangaLight,
                            fontSize: 10.sp,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Icon(
                      Icons.description_outlined,
                      color: Colors.white.withValues(alpha: 0.3),
                      size: 28.sp,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(child: ElectricLoadingIndicator());
                  }

                  if (controller.reports.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: () => controller.fetchReports(forceRefresh: true),
                      color: const Color(0xFFFBBC05),
                      child: ListView(
                        children: [
                          SizedBox(height: 120.h),
                          Center(
                            child: Text(
                              'لا يوجد تقارير حالياً\nاسحب لأسفل للتحديث',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white60,
                                fontFamily: Appfontstring.ChangaLight,
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => controller.fetchReports(forceRefresh: true),
                    color: const Color(0xFFFBBC05),
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      itemCount: controller.reports.length,
                      itemBuilder: (context, index) {
                        return OfferCard(
                          report: controller.reports[index],
                          index: index,
                        );
                      },
                    ),
                  );
                }),
              ),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  border: Border(
                    top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.security_outlined,
                      size: 14.sp,
                      color: const Color(0xFFFBBC05),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'جميع التقارير محمية ومشفرة وفقاً لمعايير الأمن السيبراني',
                      style: TextStyle(
                        fontFamily: Appfontstring.ChangaLight,
                        fontSize: 9.sp,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OfferCard extends StatelessWidget {
  final Report report;
  final int index;

  const OfferCard({super.key, required this.report, required this.index});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(
        vertical: 8,
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.blueAccent, Colors.lightBlueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue, width: 1),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: Appfontstring.ChangaLight,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      report.description,
                      style: const TextStyle(color: Colors.white70),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      report.date,
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  switch (report.type) {
                    case 'capacitors':
                      Get.to(() => const CapacitorsReportScreen());
                      break;
                    case 'spare_cells':
                      Get.to(() => const SpareCellsReportScreen());
                      break;
                    case 'load_ratios':
                      Get.to(() => const TransformerReportScreen());
                      break;
                    case 'network_faults':
                      Get.to(() => NetworkFaultsReportScreen());
                      break;
                     case 'report_1':
                       Get.to(() => const Report1Screen(),
                           binding: BindingsBuilder(
                               () => Get.lazyPut(() => Report1Controller())));
                       break;
                     case 'report_2':
                       Get.to(() => const Report2Screen(),
                           binding: BindingsBuilder(
                               () => Get.lazyPut(() => Report2Controller())));
                       break;
                     case 'report_3':
                       Get.to(() => const Report3Screen(),
                           binding: BindingsBuilder(
                               () => Get.lazyPut(() => Report3Controller())));
                       break;
                     case 'report_4':
                       Get.to(() => const Report4Screen(),
                           binding: BindingsBuilder(
                               () => Get.lazyPut(() => Report4Controller())));
                       break;
                    default:
                      Get.snackbar('تنبيه', 'هذا التقرير غير متاح حالياً');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Icon(Icons.read_more, color: Colors.black),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

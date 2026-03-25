import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import 'package:amiraly/app/common/widgets/appbar.dart';
import 'package:amiraly/app/util/constant/constants.dart';
import 'package:shimmer/shimmer.dart';
import 'package:amiraly/core/widgets/electric_loading_indicator.dart';

import 'network_faults_controller.dart';

class NetworkFaultsReportScreen extends StatelessWidget {
  NetworkFaultsReportScreen({super.key});

  final controller = Get.put(NetworkFaultsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: const Color(0xFF0F172A),
      appBar: const CustomAppBar(),
      floatingActionButton: Obx(() => Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (controller.cachedData.isNotEmpty)
                FloatingActionButton(
                  onPressed: controller.isGeneratingPdf.value
                      ? null
                      : controller.generateAndSharePdf,
                  backgroundColor: Colors.white.withOpacity(0.15),
                  mini: true,
                  heroTag: 'pdfFAB_NetFaults',
                  child: controller.isGeneratingPdf.value
                      ? const ElectricLoadingIndicator(
                          color: Colors.white, size: 18)
                      : const Icon(Icons.picture_as_pdf,
                          color: Colors.lightGreenAccent),
                ),
              SizedBox(height: 5.h),
              if (controller.canEditUser.value)
                FloatingActionButton(
                  onPressed: () => _showAddDialog(context),
                  backgroundColor: Appcolors.gold,
                  heroTag: 'addFAB_NetFaults',
                  child: const Icon(Icons.add, color: Colors.black),
                ),
            ],
          )),
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
                            Icon(Icons.warning_amber_rounded,
                                color: Appcolors.gold, size: 16.sp),
                            SizedBox(width: 8.w),
                            Text('تقرير أعطال الشبكة',
                                style: TextStyle(
                                    fontSize: 16.sp,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: Appfontstring.ChangaLight)),
                          ],
                        ),
                      ),
                    ),
                    FadeInLeft(
                      child: Obx(() => Text(
                            'الإجمالي: ${controller.cachedData.length}',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14.sp,
                                fontFamily: Appfontstring.digital,
                                fontFamilyFallback: const [Appfontstring.ChangaLight]),
                          )),
                    ),
                  ],
                ),
              ),

              Text(
                'اسحب الشاشة لأسفل لتحديث البيانات',
                style: TextStyle(
                    color: Colors.white24,
                    fontSize: 13.sp,
                    fontFamily: Appfontstring.ChangaLight),
              ),
              SizedBox(height: 4.h),

              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value &&
                      controller.cachedData.isEmpty) {
                    return _buildShimmer();
                  }

                  if (controller.cachedData.isEmpty) {
                    return Center(
                      child: Text('لا توجد بيانات متاحة',
                          style: TextStyle(
                              color: Colors.white30, fontSize: 16.sp)),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: controller.fetchData,
                    backgroundColor: const Color(0xFF163C5E),
                    color: Appcolors.gold,
                    child: ListView.builder(
                      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 100.h),
                      physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics()),
                      itemCount: controller.cachedData.length,
                      itemBuilder: (context, index) {
                        final item = controller.cachedData[index];
                        return FadeInUp(
                          delay: Duration(milliseconds: index * 50),
                          child: _buildFaultCard(item, context),
                        );
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaultCard(Map<String, dynamic> item, BuildContext context) {
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
                  color: Colors.redAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.report_problem_outlined,
                  color: Colors.redAccent,
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
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          fontFamily: Appfontstring.ChangaLight),
                      textAlign: TextAlign.right,
                    ),
                    Text(
                      item['faulty_equipment'] ?? '-',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12.sp,
                        fontFamily: Appfontstring.ChangaLight,
                      ),
                      textAlign: TextAlign.right,
                      softWrap: true,
                      maxLines: null,
                    ),
                  ],
                ),
              ),
              Obx(() {
                if (controller.canEditUser.value) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit_outlined,
                            size: 16.sp, color: Colors.blue),
                        onPressed: () => _showEditDialog(item, context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      SizedBox(width: 4.w),
                      IconButton(
                        icon: Icon(Icons.delete_outline,
                            size: 16.sp, color: Colors.redAccent),
                        onPressed: () => _showDeleteConfirm(item, context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
          Divider(color: Colors.white.withOpacity(0.05), height: 6.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBadge(
                Icons.info_outline,
                '${item['fault_reason'] ?? '-'}',
                Colors.redAccent,
                fontSize: 11.sp,
              ),
              _buildBadge(
                Icons.calendar_today,
                item['fault_date'] != null &&
                        item['fault_date'].toString().contains('-')
                    ? item['fault_date']
                        .toString()
                        .split('-')
                        .reversed
                        .join('-')
                    : (item['fault_date'] != null &&
                            item['fault_date'].toString().contains('/')
                        ? item['fault_date']
                            .toString()
                            .split('/')
                            .reversed
                            .join('/')
                        : '${item['fault_date'] ?? '-'}'),
                Colors.amberAccent,
                textDirection: TextDirection.ltr,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text, Color color,
      {double? fontSize, TextDirection? textDirection}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(5.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: color),
          SizedBox(width: 6.w),
          Text(
            text,
            textDirection: textDirection,
            style: TextStyle(
                color: color,
                fontSize: fontSize ?? 13.sp,
                fontFamily: Appfontstring.ChangaLight),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final stationController = TextEditingController();
    final dateController = TextEditingController();
    final equipmentController = TextEditingController();
    final reasonController = TextEditingController();

    await Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF163C5E),
        title: Text('إضافة عطل جديد',
            style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontFamily: Appfontstring.ChangaLight)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(stationController, 'اسم المحطة'),
              _buildTextField(dateController, 'تاريخ العطل (مثال: 01-10-2023)'),
              _buildTextField(equipmentController, 'المهمه العاطلة'),
              _buildTextField(reasonController, 'سبب العطل'),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Get.back(),
              child:
                  const Text('إلغاء', style: TextStyle(color: Colors.white70))),
          ElevatedButton(
            onPressed: () {
              if (stationController.text.isNotEmpty) {
                controller.addFault({
                  'station_name': stationController.text,
                  'fault_date': dateController.text,
                  'faulty_equipment': equipmentController.text,
                  'fault_reason': reasonController.text,
                });
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Appcolors.gold),
            child: const Text('إضافة', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      stationController.dispose();
      dateController.dispose();
      equipmentController.dispose();
      reasonController.dispose();
    });
  }

  Future<void> _showEditDialog(
      Map<String, dynamic> item, BuildContext context) async {
    final stationController =
        TextEditingController(text: item['station_name']?.toString());
    final dateController =
        TextEditingController(text: item['fault_date']?.toString());
    final equipmentController =
        TextEditingController(text: item['faulty_equipment']?.toString());
    final reasonController =
        TextEditingController(text: item['fault_reason']?.toString());

    await Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF163C5E),
        title: Text('تعديل بيانات العطل',
            style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontFamily: Appfontstring.ChangaLight)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(stationController, 'اسم المحطة'),
              _buildTextField(dateController, 'تاريخ العطل'),
              _buildTextField(equipmentController, 'المهمه العاطلة'),
              _buildTextField(reasonController, 'سبب العطل'),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Get.back(),
              child:
                  const Text('إلغاء', style: TextStyle(color: Colors.white70))),
          ElevatedButton(
            onPressed: () {
              controller.updateFault(item['id'], {
                'station_name': stationController.text,
                'fault_date': dateController.text,
                'faulty_equipment': equipmentController.text,
                'fault_reason': reasonController.text,
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('حفظ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      stationController.dispose();
      dateController.dispose();
      equipmentController.dispose();
      reasonController.dispose();
    });
  }

  void _showDeleteConfirm(Map<String, dynamic> item, BuildContext context) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF163C5E),
        title: const Text('تأكيد الحذف', style: TextStyle(color: Colors.white)),
        content: Text('هل أنت متأكد من حذف هذا العطل؟',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Get.back(),
              child:
                  const Text('إلغاء', style: TextStyle(color: Colors.white70))),
          ElevatedButton(
            onPressed: () {
              controller.deleteFault(item['id']);
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
          focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Appcolors.gold)),
        ),
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
          height: 60.h,
          color: Colors.white,
        ),
      ),
    );
  }
}

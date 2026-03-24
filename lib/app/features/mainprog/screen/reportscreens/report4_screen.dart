import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:animate_do/animate_do.dart';
import 'package:amiraly/app/common/widgets/appbar.dart';
import 'package:amiraly/app/util/constant/constants.dart';
import 'package:amiraly/core/widgets/electric_loading_indicator.dart';
import 'report4_controller.dart';

class Report4Screen extends GetView<Report4Controller> {
  const Report4Screen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: const CustomAppBar(),
      floatingActionButton: Obx(() => Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (controller.cachedData.isNotEmpty)
                FloatingActionButton(
                  onPressed: controller.isGeneratingPdf.value
                      ? null
                      : () => controller.generateAndSharePdf(),
                  backgroundColor: Colors.white.withOpacity(0.15),
                  mini: true,
                  heroTag: 'pdfFAB_4',
                  child: controller.isGeneratingPdf.value
                      ? const ElectricLoadingIndicator(
                          color: Colors.white, size: 18)
                      : const Icon(Icons.picture_as_pdf,
                          color: Colors.lightGreenAccent),
                ),
              SizedBox(height: 8.h),
              if (controller.canEditUser.value)
                FloatingActionButton(
                  onPressed: () => _showAddEditDialog(context),
                  backgroundColor: Appcolors.gold,
                  heroTag: 'addFAB_4',
                  child: const Icon(Icons.add, color: Colors.black),
                ),
            ],
          )),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: Appcolors.indicatorBackground,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value &&
                      controller.cachedData.isEmpty) {
                    return const Center(child: ElectricLoadingIndicator());
                  }

                  if (controller.cachedData.isEmpty) {
                    return Center(
                      child: Text('لا توجد بيانات متاحة',
                          style: TextStyle(
                              color: Colors.white30, fontSize: 14.sp)),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => controller.fetchData(),
                    color: Appcolors.gold,
                    child: ListView.builder(
                      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 100.h),
                      itemCount: controller.cachedData.length,
                      itemBuilder: (context, index) {
                        final item = controller.cachedData[index];
                        return FadeInUp(
                          delay: Duration(milliseconds: index * 50),
                          child: _buildReportCard(context, item),
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

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Icon(Icons.description_outlined,
                    color: Appcolors.gold, size: 18.sp),
                SizedBox(width: 8.w),
                Text('تقرير الاعطال الطارئة',
                    style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: Appfontstring.ChangaLight)),
              ],
            ),
          ),
          Obx(() => Text(
                'الإجمالي: ${controller.cachedData.length}',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.sp,
                    fontFamily: Appfontstring.digital),
              )),
        ],
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, Map<String, dynamic> item) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item['name'] ?? '-',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: Appfontstring.ChangaLight),
              ),
              if (controller.canEditUser.value)
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showAddEditDialog(context, item: item),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _showDeleteConfirm(item),
                    ),
                  ],
                ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            item['description'] ?? '-',
            style: TextStyle(color: Colors.white70, fontSize: 12.sp),
          ),
          const Divider(color: Colors.white24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoBadge('الحالة', item['status'] ?? '-'),
              _buildInfoBadge('ملاحظات', item['notes'] ?? '-'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBadge(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.white38, fontSize: 10.sp)),
          Text(value, style: TextStyle(color: Colors.white, fontSize: 11.sp)),
        ],
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, {Map<String, dynamic>? item}) {
    final nameController = TextEditingController(text: item?['name']);
    final descController = TextEditingController(text: item?['description']);
    final statusController = TextEditingController(text: item?['status']);
    final notesController = TextEditingController(text: item?['notes']);

    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF163C5E),
        title: Text(item == null ? 'إضافة سجل جديد' : 'تعديل السجل',
            style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(nameController, 'الاسم'),
              _buildTextField(descController, 'الوصف'),
              _buildTextField(statusController, 'الحالة'),
              _buildTextField(notesController, 'ملاحظات'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              final data = {
                'name': nameController.text,
                'description': descController.text,
                'status': statusController.text,
                'notes': notesController.text,
              };
              if (item == null) {
                controller.addRecord(data);
              } else {
                controller.updateRecord(item['id'], data);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Appcolors.gold),
            child: Text(item == null ? 'إضافة' : 'حفظ',
                style: const TextStyle(color: Colors.black)),
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
        content: const Text('هل أنت متأكد من حذف هذا السجل؟',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => controller.deleteRecord(item['id']),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: TextField(
        controller: controller,
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
}

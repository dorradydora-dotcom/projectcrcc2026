import 'package:amiraly/app/common/models/appmodels.dart';
import 'package:amiraly/app/common/widgets/appbar.dart';
import 'package:amiraly/app/util/constant/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'package:get/get.dart';
import 'events_controller.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final EventsController controller = Get.put(EventsController());

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLargeScreen = screenWidth > 900;

    return PopScope(
      canPop: Navigator.canPop(context),
      child: Scaffold(
        backgroundColor: Appcolors.primaryColor,
        floatingActionButton: Padding(
          padding: EdgeInsets.only(bottom: 20.h),
          child: FloatingActionButton(
            heroTag: 'events_add_fab',
            onPressed: () {
              controller.clearForm();
              showDialog(
                  context: context, builder: (_) => _buildEventFormDialog());
            },
            backgroundColor: const Color(0xFF03DAC6),
            foregroundColor: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r)),
            elevation: 4,
            child: Icon(Icons.add, size: 24.sp),
          ),
        ),
        appBar: const CustomAppBar(),
        body: Directionality(
          textDirection: ui.TextDirection.rtl,
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
                ])),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: 20.h, horizontal: 16.w),
                      child: Row(
                        children: [
                          Container(
                            width: 5,
                            height: 20.h,
                            decoration: BoxDecoration(
                              color: const Color(
                                  0xFF03DAC6), // Teal accent like HomeNav
                              borderRadius: BorderRadius.circular(2.r),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('الأحداث الهامة والتقرير اليومي',
                                  style: TextStyle(
                                      fontFamily: Appfontstring.ChangaLight,
                                      fontSize: (isLargeScreen
                                              ? 18
                                              : isTablet
                                                  ? 16
                                                  : 14)
                                          .sp,
                                      color: Colors.white,
                                      letterSpacing: 0.5)),
                              Text(
                                'إدارة ومتابعة كافة الأحداث المسجلة',
                                style: TextStyle(
                                  fontFamily: Appfontstring.ChangaLight,
                                  fontSize: 8.sp,
                                  color: Colors.white60,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Icon(Icons.event_note,
                              color: Colors.white.withOpacity(0.3),
                              size: 24.sp),
                        ],
                      )),
                  Expanded(
                    child: Obx(() {
                      if (controller.isLoading.value) {
                        return Center(
                            child: CircularProgressIndicator(
                                color: const Color(0xFF03DAC6),
                                strokeWidth: 2.w));
                      }
                      return RefreshIndicator(
                        color: const Color(0xFF03DAC6),
                        backgroundColor: Colors.white,
                        onRefresh: controller.loadEvents,
                        child: controller.events.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.event_available,
                                        size: (isTablet ? 40 : 32).sp,
                                        color: Colors.white
                                            .withOpacity(0.2)),
                                    SizedBox(height: 8.h),
                                    Text('لا يوجد أحداث حالياً',
                                        style: TextStyle(
                                            fontFamily:
                                                Appfontstring.ChangaLight,
                                            fontSize: (isTablet ? 14 : 12).sp,
                                            color: Colors.white
                                                .withOpacity(0.5))),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: EdgeInsets.all(8.w),
                                itemCount: controller.events.length,
                                itemBuilder: (context, index) =>
                                    _buildEventCard(controller.events[index],
                                        isTablet, isLargeScreen),
                              ),
                      );
                    }),
                  ),
                  Container(
                    decoration: BoxDecoration(
                        color: const Color.fromARGB(191, 250, 211, 114),
                        borderRadius: BorderRadius.circular(4.r),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.1))),
                    padding:
                        EdgeInsets.symmetric(vertical: 4.h, horizontal: 16.w),
                    child: Text(
                      'اسحب الشاشة لأسفل لتحديث البيانات',
                      style: TextStyle(
                          fontFamily: Appfontstring.ChangaLight,
                          fontSize: 10.sp,
                          color: Colors.black),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding:
                        EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      border: Border(
                          top: BorderSide(
                              color: Colors.white.withOpacity(0.1))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline,
                            size: 12.sp, color: const Color(0xFF03DAC6)),
                        SizedBox(width: 8.w),
                        Text(
                          'جميع الأحداث مسجلة بالتفصيل بالتحكم الإقليمي للقاهرة الكبرى',
                          style: TextStyle(
                              fontFamily: Appfontstring.ChangaLight,
                              fontSize: 9.sp,
                              color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(Event event, bool isTablet, bool isLargeScreen) {
    const Color primaryBlue = Color(0xFF0D47A1);
    const Color alertOrange = Color(0xFFEF6C00);
    final Color accentColor = event.powerCut ? alertOrange : primaryBlue;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(16.r),
                  bottomRight: Radius.circular(16.r),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: TextStyle(
                              fontFamily: Appfontstring.ChangaLight,
                              fontSize: 14.sp,
                              color: const Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (event.powerCut)
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: alertOrange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.bolt,
                                    color: alertOrange, size: 10.sp),
                                SizedBox(width: 4.w),
                                Text(
                                  'تنبيه انقطاع',
                                  style: TextStyle(
                                    fontFamily: Appfontstring.ChangaLight,
                                    fontSize: 8.sp,
                                    color: alertOrange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        PopupMenuButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(Icons.more_vert,
                              color: Colors.black26, size: 18.sp),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r)),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              onTap: () {
                                controller.editEvent(event);
                                Future.microtask(() {
                                  if (mounted) {
                                    showDialog(
                                        context: this.context,
                                        builder: (_) => _buildEventFormDialog(
                                            event: event));
                                  }
                                });
                              },
                              child: Row(children: [
                                const Icon(Icons.edit_outlined,
                                    color: primaryBlue, size: 16),
                                SizedBox(width: 10.w),
                                Text('تعديل البيانات',
                                    style: TextStyle(
                                        fontFamily: Appfontstring.ChangaLight,
                                        fontSize: 11.sp))
                              ]),
                            ),
                            PopupMenuItem(
                              onTap: () => Future.microtask(() {
                                if (mounted) {
                                  _confirmDelete(event);
                                }
                              }),
                              child: Row(children: [
                                const Icon(Icons.delete_outline,
                                    color: Colors.redAccent, size: 16),
                                SizedBox(width: 10.w),
                                Text('حذف الحدث',
                                    style: TextStyle(
                                        fontFamily: Appfontstring.ChangaLight,
                                        fontSize: 11.sp))
                              ]),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 10.sp, color: Colors.black38),
                        SizedBox(width: 4.w),
                        Text(
                          DateFormat('MMM d, yyyy').format(event.date),
                          style: TextStyle(
                            fontFamily: Appfontstring.ChangaLight,
                            fontSize: 9.sp,
                            color: Colors.black38,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Icon(Icons.access_time,
                            size: 10.sp, color: Colors.blueGrey),
                        SizedBox(width: 4.w),
                        Text(
                          DateFormat('HH:mm').format(event.date),
                          style: TextStyle(
                            fontFamily: Appfontstring.ChangaLight,
                            fontSize: 9.sp,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ],
                    ),
                    if (event.location.isNotEmpty) ...[
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 11.sp, color: Colors.black45),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(
                              event.location,
                              style: TextStyle(
                                fontFamily: Appfontstring.ChangaLight,
                                fontSize: 10.sp,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (event.description.isNotEmpty) ...[
                      SizedBox(height: 8.h),
                      Text(
                        event.description,
                        style: TextStyle(
                          fontFamily: Appfontstring.ChangaLight,
                          fontSize: 10.sp,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (event.powerCut) ...[
                      SizedBox(height: 10.h),
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'إجمالي الحمل المفصول:',
                              style: TextStyle(
                                fontFamily: Appfontstring.ChangaLight,
                                fontSize: 9.sp,
                                color: Colors.orange[800],
                              ),
                            ),
                            Text(
                              '${event.amount} م.و',
                              style: TextStyle(
                                fontFamily: Appfontstring.ChangaLight,
                                fontSize: 11.sp,
                                color: Colors.orange[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Event event) async {
    final String? deleteReason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Row(
          children: [
            Icon(Icons.report_problem_outlined,
                color: Colors.redAccent, size: 22.sp),
            SizedBox(width: 12.w),
            Text('تأكيد حذف الحدث',
                style: TextStyle(
                    fontFamily: Appfontstring.ChangaLight,
                    fontSize: 13.sp,
                    color: Colors.redAccent)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'هل أنت متأكد من رغبتك في حذف: "${event.title}"؟ لا يمكن التراجع عن هذه الخطوة.',
                style: TextStyle(
                    fontFamily: Appfontstring.ChangaLight,
                    fontSize: 11.sp,
                    color: const Color(0xFF475569)),
                textAlign: TextAlign.right),
            SizedBox(height: 20.h),
            _buildFormField(
                controller.deleteReasonController, 'سبب الحذف (اختياري)'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء',
                  style: TextStyle(
                      fontFamily: Appfontstring.ChangaLight,
                      fontSize: 12.sp,
                      color: const Color(0xFF64748B)))),
          ElevatedButton(
            onPressed: () {
              final reason = controller.deleteReasonController.text.trim();
              Navigator.pop(context, reason);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r))),
            child: Text('حذف الآن',
                style: TextStyle(
                    fontFamily: Appfontstring.ChangaLight, fontSize: 11.sp)),
          ),
        ],
      ),
    );

    if (deleteReason != null) {
      await controller.deleteEvent(event.id, event.title, deleteReason);
    }
  }

  Widget _buildEventFormDialog({Event? event}) {
    const Color primaryBlue = Color(0xFF0D47A1);
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: primaryBlue.withOpacity(0.03),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
          ),
        ),
        child: Row(
          children: [
            Icon(event == null ? Icons.add_circle_outline : Icons.edit_calendar,
                color: primaryBlue, size: 22.sp),
            SizedBox(width: 10.w),
            Text(
              event == null ? 'إضافة حدث جديد' : 'تعديل بيانات الحدث',
              style: TextStyle(
                  fontFamily: Appfontstring.ChangaLight,
                  fontSize: 14.sp,
                  color: const Color(0xFF0F172A)),
            ),
          ],
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFormField(controller.titleController, 'عنوان الحدث'),
            SizedBox(height: 16.h),
            _buildFormField(
                controller.descriptionController, 'وصف تفصيلي (اختياري)',
                maxLines: 3),
            SizedBox(height: 16.h),
            _buildFormField(controller.locationController, 'مكان وقوع الحدث'),
            SizedBox(height: 16.h),
            Obx(() => _buildSwitchTile('نوع الحدث: انقطاع تغذية كهربائية',
                    controller.isPowerCut.value, (value) {
                  controller.isPowerCut.value = value;
                  if (!value) {
                    controller.amountController.clear();
                  }
                })),
            Obx(() {
              if (controller.isPowerCut.value) {
                return Column(
                  children: [
                    SizedBox(height: 16.h),
                    _buildFormField(controller.amountController,
                        'كمية الحمل المنقطع (ميغاواط)',
                        keyboardType: TextInputType.number),
                  ],
                );
              }
              return const SizedBox.shrink();
            }),
            SizedBox(height: 16.h),
            _buildTimePickerTile(),
          ],
        ),
      ),
      actionsPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('تجاهل',
                style: TextStyle(
                    fontFamily: Appfontstring.ChangaLight,
                    fontSize: 12.sp,
                    color: const Color(0xFF64748B)))),
        ElevatedButton(
          onPressed: () async {
            if (event == null) {
              await controller.addEvent();
            } else {
              await controller.updateEvent(event);
            }
            if (mounted) {
              Navigator.of(context).pop();
            }
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r))),
          child: Text(event == null ? 'إضافة الآن' : 'تحديث البيانات',
              style: TextStyle(
                  fontFamily: Appfontstring.ChangaLight, fontSize: 11.sp)),
        ),
      ],
    );
  }

  Widget _buildFormField(TextEditingController controller, String label,
      {int maxLines = 1, TextInputType? keyboardType}) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: TextStyle(
            color: const Color(0xFF0F172A),
            fontSize: 12.sp,
            fontFamily: Appfontstring.ChangaLight),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
              fontFamily: Appfontstring.ChangaLight,
              fontSize: 10.sp,
              color: const Color(0xFF64748B)),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide:
                  BorderSide(color: Colors.black.withOpacity(0.08))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide:
                  BorderSide(color: Colors.black.withOpacity(0.08))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide:
                  const BorderSide(color: Color(0xFF0D47A1), width: 1.5)),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
      String title, bool value, ValueChanged<bool> onChanged) {
    return Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Container(
            decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(5.r)),
            child: SwitchListTile(
              title: Text(title,
                  style: TextStyle(
                      fontFamily: Appfontstring.ChangaLight, fontSize: 12.sp)),
              value: value,
              onChanged: onChanged,
              activeThumbColor: Colors.blue,
            )));
  }

  Widget _buildTimePickerTile() {
    return GestureDetector(
        onTap: () async {
          final TimeOfDay? picked = await showTimePicker(
            context: context,
            initialTime: controller.selectedTime.value ?? TimeOfDay.now(),
            builder: (context, child) => Theme(
                data: Theme.of(context).copyWith(
                    colorScheme:
                        const ColorScheme.light(primary: Colors.purple)),
                child: child!),
          );
          if (picked != null) {
            controller.selectedTime.value = picked;
          }
        },
        child: Directionality(
          textDirection: ui.TextDirection.rtl,
          child: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.05),
                borderRadius: BorderRadius.circular(5.r),
                border:
                    Border.all(color: Colors.purple.withOpacity(0.2))),
            child: Row(
              children: [
                Icon(Icons.access_time, size: 16.sp, color: Colors.purple),
                SizedBox(width: 6.w),
                Obx(() => Text(
                    controller.selectedTime.value == null
                        ? 'اختر الوقت'
                        : controller.selectedTime.value!.format(context),
                    style: TextStyle(
                        fontFamily: Appfontstring.ChangaLight,
                        fontSize: 11.sp,
                        color: Colors.purple[700]))),
              ],
            ),
          ),
        ));
  }
}

import 'dart:ui';
import 'package:amiraly/app/common/models/appmodels.dart';
import 'package:amiraly/app/common/widgets/appbar.dart';
import 'package:amiraly/app/util/constant/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';
import 'package:get/get.dart';
import 'announcement_controller.dart';

class AnnouncementScreenDark extends StatefulWidget {
  const AnnouncementScreenDark({super.key});

  @override
  State<AnnouncementScreenDark> createState() => _AnnouncementScreenDarkState();
}

class _AnnouncementScreenDarkState extends State<AnnouncementScreenDark>
    with TickerProviderStateMixin {
  final AnnouncementController controller = Get.put(AnnouncementController());
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController =
        AnimationController(duration: const Duration(seconds: 2), vsync: this);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: const CustomAppBar(),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          children: [
            _buildHeaderSection(),
            _buildContentSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      height: 280.h,
      width: double.infinity,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeInDown(
            duration: const Duration(milliseconds: 600),
            child: ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.redAccent.withOpacity(0.1),
                  border: Border.all(
                    color: Colors.redAccent.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.warning_rounded,
                  size: 40.sp,
                  color: Colors.redAccent,
                ),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'التعليمات الطارئة',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20.sp,
              fontFamily: Appfontstring.ChangaLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'الإدارة العليا والتحكم الإقليمي',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 10.sp,
              fontFamily: Appfontstring.ChangaLight,
            ),
          ),
          SizedBox(height: 40.h), // Space for the overlap
        ],
      ),
    );
  }

  Widget _buildContentSection() {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 220.h), // Push content down to overlap properly
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: FadeInUp(
              duration: const Duration(milliseconds: 800),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24.r),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: EdgeInsets.all(24.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withOpacity(0.95),
                      borderRadius: BorderRadius.circular(24.r),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildMessageField(),
                        SizedBox(height: 20.h),
                        const Divider(color: Colors.white10),
                        SizedBox(height: 20.h),
                        _buildDepartmentDropdown(),
                        SizedBox(height: 30.h),
                        _buildSendButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 30.h),
        ],
      ),
    );
  }

  Widget _buildMessageField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Iconsax.message_text5, color: Colors.blueAccent, size: 20.sp),
            SizedBox(width: 8.w),
            Text(
              'نص الرسالة',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14.sp,
                fontFamily: Appfontstring.ChangaLight,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
          ),
          child: TextField(
            controller: controller.messageController,
            textAlign: TextAlign.right,
            maxLines: 5,
            onChanged: (_) => controller.update(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontFamily: Appfontstring.ChangaLight,
            ),
            decoration: InputDecoration(
              hintText: 'اكتب تفاصيل التعليمات الطارئة هنا...',
              hintStyle: TextStyle(
                color: Colors.white30,
                fontFamily: Appfontstring.ChangaLight,
                fontSize: 12.sp,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16.w),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDepartmentDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Iconsax.radar5, color: Colors.orangeAccent, size: 20.sp),
            SizedBox(width: 8.w),
            Text(
              'الجهة المستهدفة',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14.sp,
                fontFamily: Appfontstring.ChangaLight,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(16.r),
            border:
                Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: Obx(() => DropdownButton<String>(
                  value: controller.selectedDepartment.value.isEmpty
                      ? null
                      : controller.selectedDepartment.value,
                  isExpanded: true,
                  icon: Icon(
                    Iconsax.arrow_circle_down,
                    color: Colors.white54,
                    size: 20.sp,
                  ),
                  hint: Text(
                    'اختر الجهة...',
                    style: TextStyle(
                      color: Colors.white30,
                      fontFamily: Appfontstring.ChangaLight,
                      fontSize: 12.sp,
                    ),
                  ),
                  dropdownColor: const Color(0xFF0F172A),
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: Appfontstring.ChangaLight,
                    fontSize: 14.sp,
                  ),
                  items: announcmentdepartments.map((String department) {
                    return DropdownMenuItem<String>(
                      value: department,
                      child: Text(
                        department,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: Appfontstring.ChangaLight,
                          fontSize: 14.sp,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: controller.setSelectedDepartment,
                )),
          ),
        ),
      ],
    );
  }

  Widget _buildSendButton() {
    return Obx(() {
      bool isEnabled = controller.isEnabled;
      return Container(
        width: double.infinity,
        height: 50.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14.r),
          gradient: isEnabled
              ? const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                )
              : null,
          color: isEnabled ? null : Colors.white.withOpacity(0.1),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: ElevatedButton(
          onPressed:
              isEnabled ? () => controller.sendAnnouncement(context) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r),
            ),
          ),
          child: controller.isLoading.value
              ? SizedBox(
                  width: 22.w,
                  height: 22.h,
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Iconsax.send_1,
                      size: 20.sp,
                      color: isEnabled ? Colors.white : Colors.white38,
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      'إرسال التعليمات الطارئة',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: Appfontstring.ChangaLight,
                        color: isEnabled ? Colors.white : Colors.white38,
                      ),
                    ),
                  ],
                ),
        ),
      );
    });
  }
}

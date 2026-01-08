import 'package:amiraly/E-commerce_project/common/models/appmodels.dart';
import 'package:amiraly/E-commerce_project/common/services/mainprogservices.dart';
import 'package:amiraly/E-commerce_project/common/widgets/appbar.dart';
import 'package:amiraly/E-commerce_project/common/widgets/headlinetext.dart';
import 'package:amiraly/E-commerce_project/util/constant/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AnnouncementScreenDark extends StatefulWidget {
  const AnnouncementScreenDark({super.key});

  @override
  State<AnnouncementScreenDark> createState() => _AnnouncementScreenDarkState();
}

class _AnnouncementScreenDarkState extends State<AnnouncementScreenDark>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();

  String? _selectedDepartment;
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
    _messageController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return Scaffold(
              resizeToAvoidBottomInset: false,
              appBar: const CustomAppBar(),
              body: Container(
                  height: double.infinity,
                  width: double.infinity,
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                        Appcolors.primaryColor,
                        const Color.fromARGB(255, 36, 116, 178),
                        const Color.fromARGB(255, 183, 182, 182)
                      ])),
                  child: SafeArea(
                      child: SingleChildScrollView(
                          padding: EdgeInsets.all(20.w),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildHeader(),
                                SizedBox(height: 0.13.sh),
                                _buildMessageSection(),
                                SizedBox(height: 0.03.sh),
                                _buildDepartmentSection(),
                                SizedBox(height: 0.06.sh),
                                _buildSendButton()
                              ])))));
        });
  }

  Widget _buildHeader() {
    return Card(
        elevation: 16,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        color: Colors.black.withOpacity(0.3),
        child: Container(
            padding: EdgeInsets.all(18.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: Colors.red.withOpacity(0.5)),
            ),
            child: Column(children: [
              ScaleTransition(
                  scale: _pulseAnimation,
                  child: Icon(Icons.warning, size: 64.sp, color: Colors.red)),
              SizedBox(height: 12.h),
              TextLine(
                text: 'صفحة التعليمات الطارئة',
                color: Colors.white,
                fontSize: 26.sp,
                fontFamily: Appfontstring.ChangaLight,
                fontWeight: FF.B,
              ),
              SizedBox(height: 4.h),
              TextLine(
                text: 'خاصة بالادارة العليا و التحكم الاقليمى',
                color: Colors.red,
                fontSize: 13.sp,
                fontFamily: Appfontstring.ChangaLight,
                fontWeight: FF.B,
              )
            ])));
  }

  Widget _buildMessageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(
            Icons.message,
            color: Colors.black,
            size: 24.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
              child: Text(
            ' الرسالــــة ',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18.sp,
              fontWeight: FF.B,
              fontFamily: Appfontstring.ChangaLight,
            ),
            textAlign: TextAlign.right,
          ))
        ]),
        SizedBox(height: 12.h),
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.black.withOpacity(0.3)),
          ),
          child: TextField(
            controller: _messageController,
            textAlign: TextAlign.right,
            maxLines: 5,
            onChanged: (_) => setState(() {}),
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontFamily: Appfontstring.ChangaLight,
            ),
            decoration: InputDecoration(
              hintText: 'اكتب رسالتك الطارئة...',
              hintStyle: TextStyle(
                color: const Color.fromARGB(82, 255, 255, 255),
                fontFamily: Appfontstring.ChangaLight,
                fontSize: 16.sp,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16.w),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDepartmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.group, color: Colors.black, size: 24.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'الجـهـة المرسل اليها ',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  fontFamily: Appfontstring.ChangaLight,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.black.withOpacity(0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedDepartment,
              isExpanded: true,
              hint: Text(
                'اختر الجهة...',
                style: TextStyle(
                  color: Colors.white54,
                  fontFamily: Appfontstring.ChangaLight,
                  fontSize: 16.sp,
                ),
                textAlign: TextAlign.right,
              ),
              dropdownColor: Colors.black.withOpacity(0.8),
              style: TextStyle(
                color: Colors.white,
                fontFamily: Appfontstring.ChangaLight,
                fontSize: 16.sp,
              ),
              items: announcmentdepartments.map((String department) {
                return DropdownMenuItem<String>(
                  value: department,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          department,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: Appfontstring.ChangaLight,
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16.sp,
                        color: Colors.red,
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedDepartment = newValue;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  bool _isLoading = false;

  Widget _buildSendButton() {
    bool isEnabled = _selectedDepartment != null &&
        _messageController.text.isNotEmpty &&
        !_isLoading;

    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        width: 180.w,
        height: 44.h,
        child: ElevatedButton(
          onPressed: isEnabled ? _sendAnnouncement : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: isEnabled
                ? Colors.green
                : const Color.fromARGB(255, 190, 177, 177),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
              side: BorderSide(
                color: isEnabled ? Colors.greenAccent : Colors.grey,
                width: 1,
              ),
            ),
            elevation: 0,
            padding: EdgeInsets.symmetric(horizontal: 8.w),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'إرسال التعليمات الطارئة',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: Appfontstring.ChangaLight,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
        ),
      ),
    );
  }

  void _sendAnnouncement() async {
    if (_selectedDepartment == null || _messageController.text.isEmpty) {
      return;
    }

    // Set loading state
    setState(() {
      _isLoading = true;
    });

    String topic = announcmentdepartmentToTopic[_selectedDepartment!]!;
    String tableName = 'user_$topic';

    try {
      await NotificationService.sendNotification(
        tableName,
        'تعليمات طارئة',
        _messageController.text,
        route: 'announcement',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال التعليمات بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        _messageController.clear();
        setState(() {
          _selectedDepartment = null;
          _isLoading = false; // Reset loading on success
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إرسال التعليمات: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false; // Reset loading on error
        });
      }
    }
  }
}

class Indicator extends StatelessWidget {
  final Color color;
  final String text;
  final bool isSquare;
  final double size;
  final Color textColor;

  const Indicator({
    super.key,
    required this.color,
    required this.text,
    this.isSquare = false,
    this.size = 16,
    this.textColor = IndicatorAppColors.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size.w,
          height: size.h,
          decoration: BoxDecoration(
            shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
            color: color,
            border: Border.all(color: Colors.white, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
        SizedBox(width: 8.w),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.sp,
              fontFamily: Appfontstring.Almarai_Bold,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

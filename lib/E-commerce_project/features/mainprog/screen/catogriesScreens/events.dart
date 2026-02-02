import 'package:amiraly/E-commerce_project/common/models/appmodels.dart';
import 'package:amiraly/E-commerce_project/common/widgets/appbar.dart';
import 'package:amiraly/E-commerce_project/util/constant/constants.dart';
import 'package:amiraly/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

import 'package:supabase_flutter/supabase_flutter.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  bool _isLoading = false;
  List<Event> _events = [];
  final _supabase = Supabase.instance.client;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _amountController = TextEditingController();
  final _deleteReasonController = TextEditingController();
  TimeOfDay? _selectedTime;
  bool _isPowerCut = false;

  @override
  void initState() {
    super.initState();
    loadEvents();
  }

  Future<void> loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('events')
          .select()
          .order('date', ascending: true);

      if (mounted) {
        setState(() {
          _events = (response as List<dynamic>)
              .map(
                (e) => Event(
                  id: e['id'].toString(),
                  title: e['title'] as String,
                  description: e['description'] as String? ?? '',
                  date: DateTime.parse(e['date'] as String),
                  location: e['location'] as String? ?? '',
                  powerCut: e['power_cut'] as bool? ?? false,
                  amount: double.parse(e['power_amount'] as String? ?? '0'),
                ),
              )
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('خطأ في تحميل الأحداث: $e')));
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _amountController.dispose();
    _deleteReasonController.dispose();
    super.dispose();
  }

  Future<void> _addEvent() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('يرجى إدخال العنوان')));
      return;
    }

    final DateTime now = DateTime.now();
    final int hour = _selectedTime?.hour ?? now.hour;
    final int minute = _selectedTime?.minute ?? now.minute;
    final DateTime eventDate =
        DateTime(now.year, now.month, now.day, hour, minute);

    final double amount =
        _isPowerCut ? double.tryParse(_amountController.text) ?? 0.0 : 0.0;

    try {
      await _supabase.from('events').insert({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'date': eventDate.toIso8601String(),
        'location': _locationController.text,
        'power_cut': _isPowerCut,
        'power_amount': amount,
      });

      final String eventBody = '''
حدث جديد: ${_titleController.text}
وصف: ${_descriptionController.text}
تاريخ: ${DateFormat('MMM d, yyyy').format(eventDate)}
وقت: ${DateFormat('HH:mm').format(eventDate)}
${_isPowerCut ? 'انقطاع التغذية : يوجد\nالمقدار : $amount م.و' : ''}
الموقع: ${_locationController.text.isEmpty ? 'غير محدد' : _locationController.text}
      '''
          .trim();

      await NotificationService.sendNotification(
          'user_crcc', 'حدث جديد', eventBody,
          route: 'الاحداث');
      await NotificationService.sendNotification(
          'user_top', 'حدث جديد', eventBody,
          route: 'الاحداث');

      _clearForm();
      await loadEvents();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إضافة الحدث بنجاح')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('خطأ في إضافة الحدث: $e')));
      }
    }
  }

  Future<void> _updateEvent(Event event) async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('يرجى إدخال العنوان')));
      return;
    }

    final DateTime originalDate = event.date;
    final int hour = _selectedTime?.hour ?? originalDate.hour;
    final int minute = _selectedTime?.minute ?? originalDate.minute;
    final DateTime eventDate = DateTime(
        originalDate.year, originalDate.month, originalDate.day, hour, minute);

    final double amount =
        _isPowerCut ? double.tryParse(_amountController.text) ?? 0.0 : 0.0;

    try {
      await _supabase.from('events').update({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'date': eventDate.toIso8601String(),
        'location': _locationController.text,
        'power_cut': _isPowerCut,
        'power_amount': amount,
      }).eq('id', event.id);

      final String eventBody = '''
حدث تعديل: ${_titleController.text}
وصف: ${_descriptionController.text}
تاريخ: ${DateFormat('MMM d, yyyy').format(eventDate)}
وقت: ${DateFormat('HH:mm').format(eventDate)}
${_isPowerCut ? 'انقطاع التغذية : يوجد\nالمقدار : $amount م.و' : ''}
الموقع: ${_locationController.text.isEmpty ? 'غير محدد' : _locationController.text}
      '''
          .trim();

      await NotificationService.sendNotification(
          'user_crcc', 'تعديل حدث', eventBody,
          route: 'الاحداث');
      await NotificationService.sendNotification(
          'user_top', 'تعديل حدث', eventBody,
          route: 'الاحداث');

      _clearForm();
      await loadEvents();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحديث الحدث بنجاح')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('خطأ في تحديث الحدث: $e')));
      }
    }
  }

  Future<void> _deleteEvent(Event event) async {
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
                    fontFamily: Appfontstring.ChangaBold,
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
            _buildFormField(_deleteReasonController, 'سبب الحذف (اختياري)'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء',
                  style: TextStyle(
                      fontFamily: Appfontstring.ChangaBold,
                      fontSize: 12.sp,
                      color: const Color(0xFF64748B)))),
          ElevatedButton(
            onPressed: () {
              final reason = _deleteReasonController.text.trim();
              _deleteReasonController.clear();
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
                    fontFamily: Appfontstring.ChangaBold, fontSize: 11.sp)),
          ),
        ],
      ),
    );

    if (deleteReason == null) return;

    try {
      await _supabase.from('events').delete().eq('id', event.id);

      final String deleteBody =
          'تم حذف: ${event.title}\nسبب: ${deleteReason.isEmpty ? 'غير محدد' : deleteReason}'
              .trim();

      await NotificationService.sendNotification(
          'user_crcc', 'حذف حدث', deleteBody,
          route: 'الاحداث');
      await NotificationService.sendNotification(
          'user_top', 'حذف حدث', deleteBody,
          route: 'الاحداث');

      await loadEvents();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تم حذف الحدث بنجاح')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('خطأ في حذف الحدث: $e')));
      }
    }
  }

  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    _locationController.clear();
    _amountController.clear();
    _deleteReasonController.clear();
    _selectedTime = null;
    _isPowerCut = false;
    if (mounted) setState(() {});
  }

  void _editEvent(Event event) {
    _titleController.text = event.title;
    _descriptionController.text = event.description;
    _locationController.text = event.location;
    _amountController.text = event.amount.toString();
    _selectedTime = TimeOfDay.fromDateTime(event.date);
    _isPowerCut = event.powerCut;
    showDialog(
        context: context, builder: (_) => _buildEventFormDialog(event: event));
  }

  Widget _buildEventFormDialog({Event? event}) {
    const Color primaryBlue = Color(0xFF0D47A1);
    return StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
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
              Icon(
                  event == null
                      ? Icons.add_circle_outline
                      : Icons.edit_calendar,
                  color: primaryBlue,
                  size: 22.sp),
              SizedBox(width: 10.w),
              Text(
                event == null ? 'إضافة حدث جديد' : 'تعديل بيانات الحدث',
                style: TextStyle(
                    fontFamily: Appfontstring.ChangaBold,
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
              _buildFormField(_titleController, 'عنوان الحدث'),
              SizedBox(height: 16.h),
              _buildFormField(_descriptionController, 'وصف تفصيلي (اختياري)',
                  maxLines: 3),
              SizedBox(height: 16.h),
              _buildFormField(_locationController, 'مكان وقوع الحدث'),
              SizedBox(height: 16.h),
              _buildSwitchTile('نوع الحدث: انقطاع تغذية كهربائية', _isPowerCut,
                  (value) {
                setDialogState(() {
                  _isPowerCut = value;
                  if (!value) _amountController.clear();
                });
              }),
              if (_isPowerCut) ...[
                SizedBox(height: 16.h),
                _buildFormField(
                    _amountController, 'كمية الحمل المنقطع (ميغاواط)',
                    keyboardType: TextInputType.number),
              ],
              SizedBox(height: 16.h),
              _buildTimePickerTile(setDialogState),
            ],
          ),
        ),
        actionsPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('تجاهل',
                  style: TextStyle(
                      fontFamily: Appfontstring.ChangaBold,
                      fontSize: 12.sp,
                      color: const Color(0xFF64748B)))),
          ElevatedButton(
            onPressed: () async {
              if (event == null) {
                await _addEvent();
              } else {
                await _updateEvent(event);
              }
              Navigator.pop(context);
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
                    fontFamily: Appfontstring.ChangaBold, fontSize: 11.sp)),
          ),
        ],
      ),
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
              borderSide: BorderSide(color: Colors.black.withOpacity(0.08))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: Colors.black.withOpacity(0.08))),
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
              activeColor: Colors.blue,
            )));
  }

  Widget _buildTimePickerTile(StateSetter setDialogState) {
    return GestureDetector(
        onTap: () async {
          final TimeOfDay? picked = await showTimePicker(
            context: context,
            initialTime: _selectedTime ?? TimeOfDay.now(),
            builder: (context, child) => Theme(
                data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(primary: Colors.purple)),
                child: child!),
          );
          if (picked != null) setDialogState(() => _selectedTime = picked);
        },
        child: Directionality(
          textDirection: ui.TextDirection.rtl,
          child: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.05),
                borderRadius: BorderRadius.circular(5.r),
                border: Border.all(color: Colors.purple.withOpacity(0.2))),
            child: Row(
              children: [
                Icon(Icons.access_time, size: 16.sp, color: Colors.purple),
                SizedBox(width: 6.w),
                Text(
                    _selectedTime == null
                        ? 'اختر الوقت'
                        : _selectedTime!.format(context),
                    style: TextStyle(
                        fontFamily: Appfontstring.ChangaLight,
                        fontSize: 11.sp,
                        color: Colors.purple[700])),
              ],
            ),
          ),
        ));
  }

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
              _clearForm();
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
                                      fontFamily: Appfontstring.ChangaBold,
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
                    child: _isLoading
                        ? Center(
                            child: CircularProgressIndicator(
                                color: const Color(0xFF03DAC6),
                                strokeWidth: 2.w))
                        : RefreshIndicator(
                            color: const Color(0xFF03DAC6),
                            backgroundColor: Colors.white,
                            onRefresh: loadEvents,
                            child: _events.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.event_available,
                                            size: (isTablet ? 40 : 32).sp,
                                            color:
                                                Colors.white.withOpacity(0.2)),
                                        SizedBox(height: 8.h),
                                        Text('لا يوجد أحداث حالياً',
                                            style: TextStyle(
                                                fontFamily:
                                                    Appfontstring.ChangaLight,
                                                fontSize:
                                                    (isTablet ? 14 : 12).sp,
                                                color: Colors.white
                                                    .withOpacity(0.5))),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    padding: EdgeInsets.all(8.w),
                                    itemCount: _events.length,
                                    itemBuilder: (context, index) =>
                                        _buildEventCard(_events[index],
                                            isTablet, isLargeScreen),
                                  ),
                          ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                        color: const Color.fromARGB(191, 250, 211, 114),
                        borderRadius: BorderRadius.circular(4.r),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.1))),
                    padding:
                        EdgeInsets.symmetric(vertical: 4.h, horizontal: 16.w),
                    child: Text(
                      'اسحب الشاشة لأسفل لتحديث البيانات',
                      style: TextStyle(
                          fontFamily: Appfontstring.ChangaBold,
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
                          top:
                              BorderSide(color: Colors.white.withOpacity(0.1))),
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
                              fontFamily: Appfontstring.ChangaBold,
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
                                    fontFamily: Appfontstring.ChangaBold,
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
                              onTap: () =>
                                  Future.microtask(() => _editEvent(event)),
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
                              onTap: () =>
                                  Future.microtask(() => _deleteEvent(event)),
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
                    if (event.description.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Text(
                        event.description,
                        style: TextStyle(
                          fontFamily: Appfontstring.ChangaLight,
                          fontSize: 10.sp,
                          color: const Color(0xFF64748B),
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const Spacer(),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        _buildCleanChip(
                            Icons.calendar_month_outlined,
                            DateFormat('yyyy/MM/dd').format(event.date),
                            const Color(0xFF64748B)),
                        SizedBox(width: 12.w),
                        _buildCleanChip(
                            Icons.schedule,
                            DateFormat('HH:mm').format(event.date),
                            const Color(0xFF64748B)),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCleanChip(
                              Icons.location_on_outlined,
                              event.location.isNotEmpty
                                  ? event.location
                                  : 'موقع غير محدد',
                              const Color(0xFF0F172A)),
                        ),
                        if (event.powerCut && event.amount > 0) ...[
                          SizedBox(width: 10.w),
                          _buildCleanChip(Icons.electric_bolt,
                              '${event.amount} ميغاواط', alertOrange),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCleanChip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12.sp, color: color.withOpacity(0.6)),
        SizedBox(width: 5.w),
        Text(
          label,
          style: TextStyle(
            fontFamily: Appfontstring.ChangaLight,
            fontSize: 9.sp,
            color: color,
          ),
        ),
      ],
    );
  }
}

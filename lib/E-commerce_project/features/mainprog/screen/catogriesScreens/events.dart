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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 20.sp),
            SizedBox(width: 8.w),
            Text('تأكيد الحذف',
                style: TextStyle(
                    fontFamily: Appfontstring.ChangaBold,
                    fontSize: 14.sp,
                    color: Colors.orange)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('هل أنت متأكد من حذف "${event.title}"؟',
                style: TextStyle(
                    fontFamily: Appfontstring.ChangaLight, fontSize: 12.sp),
                textAlign: TextAlign.center),
            SizedBox(height: 8.h),
            TextField(
              controller: _deleteReasonController,
              decoration: InputDecoration(
                labelText: 'سبب الحذف (اختياري)',
                labelStyle: TextStyle(
                    fontFamily: Appfontstring.ChangaLight, fontSize: 11.sp),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5.r)),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء',
                  style: TextStyle(
                      fontFamily: Appfontstring.ChangaLight, fontSize: 12.sp))),
          ElevatedButton(
            onPressed: () {
              final reason = _deleteReasonController.text.trim();
              _deleteReasonController.clear();
              Navigator.pop(context, reason);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.r))),
            child: Text('حذف',
                style: TextStyle(
                    fontFamily: Appfontstring.ChangaLight,
                    color: Colors.white,
                    fontSize: 12.sp)),
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
    return StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        title: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 4.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.red, Colors.orange]),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(
            event == null ? 'إضافة حدث' : 'تعديل حدث',
            style: TextStyle(
                fontFamily: Appfontstring.ChangaBold,
                fontSize: 14.sp,
                color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFormField(_titleController, 'عنوان الحدث'),
              SizedBox(height: 6.h),
              _buildFormField(_descriptionController, 'الوصف', maxLines: 2),
              SizedBox(height: 6.h),
              _buildFormField(_locationController, 'الموقع'),
              SizedBox(height: 6.h),
              _buildSwitchTile('انقطاع التغذية', _isPowerCut, (value) {
                setDialogState(() {
                  _isPowerCut = value;
                  if (!value) _amountController.clear();
                });
              }),
              if (_isPowerCut) ...[
                SizedBox(height: 6.h),
                _buildFormField(_amountController, 'المقدار',
                    keyboardType: TextInputType.number),
              ],
              SizedBox(height: 6.h),
              _buildTimePickerTile(setDialogState),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء',
                  style: TextStyle(
                      fontFamily: Appfontstring.ChangaLight, fontSize: 12.sp))),
          ElevatedButton(
            onPressed: () async {
              if (event == null) {
                await _addEvent();
              } else {
                await _updateEvent(event);
              }
              // ignore: use_build_context_synchronously
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.r))),
            child: Text(event == null ? 'إضافة' : 'تحديث',
                style: TextStyle(
                    fontFamily: Appfontstring.ChangaLight,
                    color: Colors.white,
                    fontSize: 12.sp)),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField(TextEditingController controller, String label,
      {int maxLines = 2, TextInputType? keyboardType}) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
              fontFamily: Appfontstring.ChangaLight,
              fontSize: 11.sp,
              color: Colors.grey[700]),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5.r),
              borderSide: BorderSide(color: Colors.grey[400]!)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5.r),
              borderSide: BorderSide(color: Colors.red, width: 1)),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
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
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _clearForm();
            showDialog(
                context: context, builder: (_) => _buildEventFormDialog());
          },
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: CircleBorder(),
          elevation: 3,
          child: Icon(Icons.add, size: 20.sp),
        ),
        appBar: const CustomAppBar(),
        body: Directionality(
          textDirection: ui.TextDirection.rtl,
          child: Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Appcolors.primaryColor, Colors.white70])),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                      padding: EdgeInsets.all(12.w),
                      child: Text('الاحـداث الهــامـة',
                          style: TextStyle(
                              fontFamily: Appfontstring.ChangaBold,
                              fontSize: (isLargeScreen
                                      ? 25
                                      : isTablet
                                          ? 20
                                          : 18)
                                  .sp,
                              color: Colors.redAccent))),
                  Expanded(
                    child: _isLoading
                        ? Center(
                            child: CircularProgressIndicator(
                                color: Colors.green, strokeWidth: 2.w))
                        : RefreshIndicator(
                            color: Colors.green,
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
                                            color: Colors.grey[400]),
                                        SizedBox(height: 8.h),
                                        Text('لا يوجد أحداث',
                                            style: TextStyle(
                                                fontFamily:
                                                    Appfontstring.ChangaLight,
                                                fontSize:
                                                    (isTablet ? 14 : 12).sp,
                                                color: Colors.grey[600])),
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
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Colors.yellow.shade100,
                      borderRadius: BorderRadius.all(Radius.circular(10.r)),
                      border: Border.all(color: Colors.black),
                    ),
                    child: Text(
                      'جميع الاحداث مسجلة بالتفصيل بالتحكم الاقليمى للقاهرة الكبرى',
                      style: TextStyle(
                          fontFamily: Appfontstring.ChangaLight,
                          fontSize: (isLargeScreen ? 9 : 8).sp,
                          color: Colors.blue),
                      textAlign: TextAlign.center,
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
    final iconColor = event.powerCut ? Colors.orange : Colors.blue;
    final bgColor = event.powerCut
        ? Colors.orange.withOpacity(0.08)
        : Colors.blue.withOpacity(0.08);
    final iconData = event.powerCut ? Icons.bolt : Icons.bolt_outlined;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 3.h),
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5.r,
              offset: Offset(0, 1))
        ],
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black)),
                child: Icon(iconData,
                    color: iconColor, size: (isTablet ? 20 : 18).sp),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.title,
                        style: TextStyle(
                            fontFamily: Appfontstring.ChangaBold,
                            fontSize: (isTablet ? 14 : 12).sp,
                            color: Colors.red)),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 12.sp, color: Colors.black),
                        SizedBox(width: 2.w),
                        Text(DateFormat('MMM d, yyyy').format(event.date),
                            style: TextStyle(
                                fontFamily: Appfontstring.ChangaLight,
                                fontSize: (isTablet ? 11 : 10).sp,
                                color: Colors.black)),
                        SizedBox(width: 8.w),
                        Icon(Icons.location_on,
                            size: 12.sp, color: Colors.green),
                        SizedBox(width: 2.w),
                        Flexible(
                          child: Text(
                              event.location.isNotEmpty
                                  ? event.location
                                  : 'غير محدد',
                              style: TextStyle(
                                  fontFamily: Appfontstring.ChangaLight,
                                  fontSize: (isTablet ? 11 : 10).sp,
                                  color: Colors.green),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 12.sp, color: Colors.blue),
                        SizedBox(width: 2.w),
                        Text(DateFormat('HH:mm').format(event.date),
                            style: TextStyle(
                                fontFamily: Appfontstring.ChangaLight,
                                fontSize: (isTablet ? 11 : 10).sp,
                                color: Colors.blue)),
                        SizedBox(height: 2.h),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton(
                icon:
                    Icon(Icons.more_vert, color: Colors.grey[600], size: 16.sp),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.r)),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    onTap: () {
                      Navigator.pop(context);
                      _editEvent(event);
                    },
                    child: Row(children: [
                      Icon(Icons.edit, color: Colors.blue, size: 16.sp),
                      SizedBox(width: 6.w),
                      Text('تعديل',
                          style: TextStyle(
                              fontFamily: Appfontstring.ChangaLight,
                              fontSize: 12.sp))
                    ]),
                  ),
                  PopupMenuItem(
                    onTap: () {
                      Navigator.pop(context);
                      _deleteEvent(event);
                    },
                    child: Row(children: [
                      Icon(Icons.delete, color: Colors.red, size: 16.sp),
                      SizedBox(width: 6.w),
                      Text('حذف',
                          style: TextStyle(
                              fontFamily: Appfontstring.ChangaLight,
                              fontSize: 12.sp))
                    ]),
                  ),
                ],
              ),
            ],
          ),
          if (event.description.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(4.r)),
              child: Text('الوصف: ${event.description}',
                  style: TextStyle(
                      fontFamily: Appfontstring.ChangaLight,
                      fontSize: (isTablet ? 11 : 10).sp,
                      color: Colors.black87)),
            ),
          ],
          if (event.powerCut && event.amount > 0) ...[
            SizedBox(height: 4.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r)),
              child: Text('المقدار: ${event.amount}',
                  style: TextStyle(
                      fontFamily: Appfontstring.ChangaBold,
                      fontSize: (isTablet ? 11 : 10).sp,
                      color: Colors.orange[800])),
            ),
          ],
        ],
      ),
    );
  }
}

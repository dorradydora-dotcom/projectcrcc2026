import 'package:amiraly/E-commerce_project/common/models/appmodels.dart';
import 'package:amiraly/main.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EventsController extends GetxController {
  final _supabase = Supabase.instance.client;

  final RxBool isLoading = false.obs;
  final RxList<Event> events = <Event>[].obs;

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController deleteReasonController = TextEditingController();

  final Rx<TimeOfDay?> selectedTime = Rx<TimeOfDay?>(null);
  final RxBool isPowerCut = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadEvents();
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    amountController.dispose();
    deleteReasonController.dispose();
    super.onClose();
  }

  Future<void> loadEvents() async {
    isLoading.value = true;
    try {
      final response = await _supabase
          .from('events')
          .select()
          .order('date', ascending: true);

      events.value = (response as List<dynamic>)
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
    } catch (e) {
      Get.snackbar('خطأ', 'خطأ في تحميل الأحداث: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void clearForm() {
    titleController.clear();
    descriptionController.clear();
    locationController.clear();
    amountController.clear();
    deleteReasonController.clear();
    selectedTime.value = null;
    isPowerCut.value = false;
  }

  void editEvent(Event event) {
    titleController.text = event.title;
    descriptionController.text = event.description;
    locationController.text = event.location;
    amountController.text = event.amount.toString();
    selectedTime.value = TimeOfDay.fromDateTime(event.date);
    isPowerCut.value = event.powerCut;
  }

  Future<void> addEvent() async {
    if (titleController.text.isEmpty) {
      Get.snackbar('تنبیه', 'يرجى إدخال العنوان');
      return;
    }

    final DateTime now = DateTime.now();
    final int hour = selectedTime.value?.hour ?? now.hour;
    final int minute = selectedTime.value?.minute ?? now.minute;
    final DateTime eventDate =
        DateTime(now.year, now.month, now.day, hour, minute);

    final double amount =
        isPowerCut.value ? double.tryParse(amountController.text) ?? 0.0 : 0.0;

    try {
      await _supabase.from('events').insert({
        'title': titleController.text,
        'description': descriptionController.text,
        'date': eventDate.toIso8601String(),
        'location': locationController.text,
        'power_cut': isPowerCut.value,
        'power_amount': amount,
      });

      final String eventBody = '''
حدث جديد: ${titleController.text}
وصف: ${descriptionController.text}
تاريخ: ${DateFormat('MMM d, yyyy').format(eventDate)}
وقت: ${DateFormat('HH:mm').format(eventDate)}
${isPowerCut.value ? 'انقطاع التغذية : يوجد\nالمقدار : $amount م.و' : ''}
الموقع: ${locationController.text.isEmpty ? 'غير محدد' : locationController.text}
      '''
          .trim();

      await NotificationService.sendNotification(
          'user_crcc', 'حدث جديد', eventBody,
          route: 'الاحداث');
      await NotificationService.sendNotification(
          'user_top', 'حدث جديد', eventBody,
          route: 'الاحداث');

      clearForm();
      await loadEvents();
      Get.snackbar('نجاح', 'تم إضافة الحدث بنجاح');
    } catch (e) {
      Get.snackbar('خطأ', 'خطأ في إضافة الحدث: $e');
    }
  }

  Future<void> updateEvent(Event event) async {
    if (titleController.text.isEmpty) {
      Get.snackbar('تنبیه', 'يرجى إدخال العنوان');
      return;
    }

    final DateTime originalDate = event.date;
    final int hour = selectedTime.value?.hour ?? originalDate.hour;
    final int minute = selectedTime.value?.minute ?? originalDate.minute;
    final DateTime eventDate = DateTime(
        originalDate.year, originalDate.month, originalDate.day, hour, minute);

    final double amount =
        isPowerCut.value ? double.tryParse(amountController.text) ?? 0.0 : 0.0;

    try {
      await _supabase.from('events').update({
        'title': titleController.text,
        'description': descriptionController.text,
        'date': eventDate.toIso8601String(),
        'location': locationController.text,
        'power_cut': isPowerCut.value,
        'power_amount': amount,
      }).eq('id', event.id);

      final String eventBody = '''
حدث تعديل: ${titleController.text}
وصف: ${descriptionController.text}
تاريخ: ${DateFormat('MMM d, yyyy').format(eventDate)}
وقت: ${DateFormat('HH:mm').format(eventDate)}
${isPowerCut.value ? 'انقطاع التغذية : يوجد\nالمقدار : $amount م.و' : ''}
الموقع: ${locationController.text.isEmpty ? 'غير محدد' : locationController.text}
      '''
          .trim();

      await NotificationService.sendNotification(
          'user_crcc', 'تعديل حدث', eventBody,
          route: 'الاحداث');
      await NotificationService.sendNotification(
          'user_top', 'تعديل حدث', eventBody,
          route: 'الاحداث');

      clearForm();
      await loadEvents();
      Get.snackbar('نجاح', 'تم تحديث الحدث بنجاح');
    } catch (e) {
      Get.snackbar('خطأ', 'خطأ في تحديث الحدث: $e');
    }
  }

  Future<void> deleteEvent(
      String eventId, String eventTitle, String deleteReason) async {
    try {
      await _supabase.from('events').delete().eq('id', eventId);

      final String deleteBody =
          'تم حذف: $eventTitle\nسبب: ${deleteReason.isEmpty ? 'غير محدد' : deleteReason}'
              .trim();

      await NotificationService.sendNotification(
          'user_crcc', 'حذف حدث', deleteBody,
          route: 'الاحداث');
      await NotificationService.sendNotification(
          'user_top', 'حذف حدث', deleteBody,
          route: 'الاحداث');

      await loadEvents();
      Get.snackbar('نجاح', 'تم حذف الحدث بنجاح');
      deleteReasonController.clear();
    } catch (e) {
      Get.snackbar('خطأ', 'خطأ في حذف الحدث: $e');
    }
  }
}

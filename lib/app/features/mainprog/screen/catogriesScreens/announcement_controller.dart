import 'package:amiraly/app/common/models/appmodels.dart';
import 'package:amiraly/core/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AnnouncementController extends GetxController {
  final TextEditingController messageController = TextEditingController();
  final RxString selectedDepartment = RxString('');
  final RxBool isLoading = false.obs;

  @override
  void onClose() {
    messageController.dispose();
    super.onClose();
  }

  void setSelectedDepartment(String? value) {
    selectedDepartment.value = value ?? '';
  }

  bool get isEnabled =>
      selectedDepartment.value.isNotEmpty &&
      messageController.text.isNotEmpty &&
      !isLoading.value;

  Future<void> sendAnnouncement(BuildContext context) async {
    if (!isEnabled) {
      return;
    }

    isLoading.value = true;

    String topic = announcmentdepartmentToTopic[selectedDepartment.value]!;
    String tableName = 'user_$topic';

    try {
      await NotificationService.sendNotification(
        tableName,
        'تعليمات طارئة',
        messageController.text,
        route: 'announcement',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text('تم إرسال التعليمات بنجاح'),
              ],
            ),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      messageController.clear();
      selectedDepartment.value = '';
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text('خطأ في إرسال التعليمات: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }
}

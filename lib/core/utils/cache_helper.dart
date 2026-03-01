import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

class CacheHelper {
  static Future<void> clearImageCache() async {
    try {
      await DefaultCacheManager().emptyCache();
      Get.snackbar(
        'نجاح',
        'تم مسح التخزين المؤقت للصور بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
        margin: const EdgeInsets.all(15),
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل مسح التخزين المؤقت: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        margin: const EdgeInsets.all(15),
      );
    }
  }
}

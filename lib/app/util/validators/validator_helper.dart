import 'package:flutter/material.dart';
import 'package:get/get.dart';

validInput(String val, int min, int max, String type) {
  if (type == 'username') {
    if (!GetUtils.isUsername(val)) {
      return "not valid username";
    }
  }
  if (type == 'email') {
    /* if (!GetUtils.isEmail(val)) {
      return "not valid email";
    }*/
  }
  if (type == 'password') {
    if (!GetUtils.isLengthBetween(val, 7, 32)) {
      if (val.length > max) {
        return "can't be more than $max";
      }
      if (val.length < min) {
        return "can't be less than $min";
      }
    }
  }
  if (type == 'phone') {
    if (!GetUtils.isPhoneNumber(val)) {
      return "not valid phone";
    }
  }
  if (val.length > max) {
    return "can't be more than $max";
  }
  if (val.length < min) {
    return "can't be less than $min";
  }
}

class AppLogger {
  static void logError(String message,
      [dynamic error, StackTrace? stackTrace]) {
    debugPrint('❌ ERROR: $message');
    if (error != null) {
      debugPrint('Details: $error');
    }
    if (stackTrace != null) {
      debugPrint('StackTrace: $stackTrace');
    }
  }

  static void logInfo(String message) {
    debugPrint('ℹ️ INFO: $message');
  }

  static void logSuccess(String message) {
    debugPrint('✅ SUCCESS: $message');
  }

  static void logWarning(String message) {
    debugPrint('⚠️ WARNING: $message');
  }
}

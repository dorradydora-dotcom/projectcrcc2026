// ignore: file_names
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Validatorheper {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Invalid email format';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 8 characters long';
    }
    return null;
  }

  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (!RegExp(r'^\d{10}$').hasMatch(value)) {
      return 'Invalid phone number format';
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    return null;
  }
}

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

copmareInput(
  String val1,
  String val2,
) {
  if (val1 != val2) {
    return 'password not match';
  } else if (val1.isEmpty) {
    return 'password Empty';
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

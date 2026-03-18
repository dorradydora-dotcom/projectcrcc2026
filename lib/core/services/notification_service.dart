import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:amiraly/app/util/validators/validator_helper.dart';

class NotificationService {
  static Future<bool> _sendSingleNotification(
    String deviceToken,
    String title,
    String body, {
    String? route,
  }) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'send-fcm',
        body: {
          'targetToken': deviceToken,
          'title': title,
          'body': body,
          'route': route,
          'payloadType': 'notification',
        },
      );

      if (response.status == 200) {
        AppLogger.logSuccess('Notification sent via Edge Function');
        return true;
      } else {
        AppLogger.logError(
            'Failed to send via Edge Function', 'Status: ${response.status}');
        return false;
      }
    } catch (e, stackTrace) {
      AppLogger.logError('Error invoking send-fcm', e, stackTrace);
      return false;
    }
  }

  static Future<Map<String, dynamic>> sendNotification(
    String tableName,
    String title,
    String body, {
    String? route,
  }) async {
    if (tableName.isEmpty) {
      return {'success': false, 'message': 'Table name is empty'};
    }

    try {
      final supabase = Supabase.instance.client;
      final data = await supabase.from(tableName).select('user_token');

      if (data.isEmpty) {
        AppLogger.logWarning('No device tokens found in table: $tableName');
        return {'success': false, 'message': 'No tokens found', 'sent': 0};
      }

      final futures = data.map((row) {
        final String? deviceToken = row['user_token'];
        if (deviceToken != null && deviceToken.isNotEmpty) {
          return _sendSingleNotification(deviceToken, title, body,
              route: route);
        }
        return Future.value(false);
      });

      final results = await Future.wait(futures);
      final successCount = results.where((r) => r).length;

      if (kDebugMode) {
        AppLogger.logSuccess(
            '📨 Notifications sent: $successCount/${data.length}');
      }
      return {'success': true, 'sent': successCount, 'total': data.length};
    } catch (e, stackTrace) {
      AppLogger.logError('Supabase query error', e, stackTrace);
      return {'success': false, 'message': e.toString()};
    }
  }
}

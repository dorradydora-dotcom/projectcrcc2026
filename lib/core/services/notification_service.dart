import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:amiraly/app/util/validators/validator_helper.dart';

class NotificationService {
  static Future<bool> _sendSingleNotification(
    String deviceToken,
    String title,
    String body, {
    String? route,
    String? tableName,
    List<String>? recordIds,
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
          'priority': 'HIGH',
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
      // Check for "Requested entity was not found" error
      final errorStr = e.toString();
      if (errorStr.contains('Requested entity was not found') &&
          tableName != null &&
          recordIds != null &&
          recordIds.isNotEmpty) {
        AppLogger.logWarning(
            '🗑️ Invalid token detected. Clearing from $tableName for IDs: ${recordIds.join(', ')}');

        for (final id in recordIds) {
          unawaited(Supabase.instance.client
              .from(tableName)
              .update({'user_token': null})
              .eq('id', id)
              .then((_) => AppLogger.logSuccess('✅ Token cleared for ID: $id'))
              .catchError(
                  (err) => AppLogger.logError('❌ Failed to clear token', err)));
        }
      }

      AppLogger.logError('❌ Error invoking send-fcm for token: $deviceToken', e, stackTrace);
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
      final data = await supabase.from(tableName).select('id, user_token');

      if (data.isEmpty) {
        AppLogger.logWarning('No device tokens found in table: $tableName');
        return {'success': false, 'message': 'No tokens found', 'sent': 0};
      }

      // Group by user_token to prevent duplicates
      final Map<String, List<String>> tokenGroups = {};
      for (final row in data) {
        final String? token = row['user_token'];
        final String? id = row['id']?.toString();
        if (token != null && token.isNotEmpty && id != null) {
          tokenGroups.putIfAbsent(token, () => []).add(id);
        }
      }

      final futures = tokenGroups.entries.map((entry) {
        return _sendSingleNotification(
          entry.key,
          title,
          body,
          route: route,
          tableName: tableName,
          recordIds: entry.value,
        );
      });

      final results = await Future.wait(futures);
      final successCount = results.where((r) => r).length;

      if (kDebugMode) {
        AppLogger.logSuccess(
            '📨 Notifications sent: $successCount/${tokenGroups.length} unique tokens (from ${data.length} records)');
      }
      return {'success': true, 'sent': successCount, 'total': data.length};
    } catch (e, stackTrace) {
      AppLogger.logError('Supabase query error', e, stackTrace);
      return {'success': false, 'message': e.toString()};
    }
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:amiraly/app/util/constant/constants.dart';
import 'package:amiraly/app/util/validators/validator_helper.dart';

class NotificationService {
  static Future<Map<String, dynamic>> getServiceAccountJson() async {
    final String? jsonString = dotenv.env['SERVICE_ACCOUNT_JSON'];
    if (jsonString == null || jsonString.isEmpty) {
      throw Exception('SERVICE_ACCOUNT_JSON not found in .env');
    }
    try {
      final Map<String, dynamic> parsed = jsonDecode(jsonString);
      if (parsed['private_key'] == null) {
        throw Exception('Invalid SERVICE_ACCOUNT_JSON: private_key is missing');
      }
      return parsed;
    } catch (e, stackTrace) {
      AppLogger.logError('Failed to parse SERVICE_ACCOUNT_JSON', e, stackTrace);
      rethrow;
    }
  }

  static Future<String> getAccessToken() async {
    try {
      final Map<String, dynamic> serviceAccountJson =
          await getServiceAccountJson();
      final List<String> scopes = [
        "https://www.googleapis.com/auth/userinfo.email",
        "https://www.googleapis.com/auth/firebase.database",
        "https://www.googleapis.com/auth/firebase.messaging",
      ];

      final http.Client client = await auth.clientViaServiceAccount(
        auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
        scopes,
      );

      final auth.AccessCredentials credentials =
          await auth.obtainAccessCredentialsViaServiceAccount(
        auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
        scopes,
        client,
      );

      client.close();
      return credentials.accessToken.data;
    } catch (e, stackTrace) {
      AppLogger.logError('Failed to get access token', e, stackTrace);
      rethrow;
    }
  }

  static String get fcmProjectId =>
      dotenv.env['FCM_PROJECT_ID'] ?? 'crccproject-98fb0';

  static String get fcmEndpoint =>
      dotenv.env['FCM_ENDPOINT'] ??
      'https://fcm.googleapis.com/v1/projects/$fcmProjectId/messages:send';

  static Future<bool> _sendSingleNotification(
    String deviceToken,
    String title,
    String body, {
    String? route,
  }) async {
    try {
      final String accessToken = await getAccessToken();

      final Map<String, dynamic> messagePayload = {
        "notification": {"title": title, "body": body},
        "android": {
          "notification": {
            "channel_id": AppConstants.notificationChannelId,
            "icon": AppConstants.notificationIcon,
          },
        },
        "data": {
          "title": title,
          "body": body,
          if (route != null) "route": route,
        },
        "token": deviceToken,
      };

      final http.Response response = await http.post(
        Uri.parse(fcmEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({"message": messagePayload}),
      );

      if (response.statusCode == 200) {
        AppLogger.logSuccess('Notification sent');
        return true;
      } else {
        AppLogger.logError(
            'Failed to send notification', 'Status: ${response.statusCode}');
        return false;
      }
    } catch (e, stackTrace) {
      AppLogger.logError('Error sending notification', e, stackTrace);
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

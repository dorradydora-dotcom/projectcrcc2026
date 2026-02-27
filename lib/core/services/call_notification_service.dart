import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:amiraly/app/util/constant/constants.dart';
import 'package:amiraly/app/util/validators/validator_helper.dart';

class CallNotificationService {
  static Future<Map<String, dynamic>> getServiceAccountJson() async {
    final String? jsonString = dotenv.env['SERVICE_ACCOUNT_JSON'];
    if (jsonString == null || jsonString.isEmpty) {
      throw Exception('SERVICE_ACCOUNT_JSON not found in .env');
    }
    try {
      return jsonDecode(jsonString);
    } catch (e, stackTrace) {
      AppLogger.logError(
          'Failed to parse SERVICE_ACCOUNT_JSON for Call', e, stackTrace);
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
      AppLogger.logError('Failed to get access token for Call', e, stackTrace);
      rethrow;
    }
  }

  static String get fcmProjectId =>
      dotenv.env['FCM_PROJECT_ID'] ?? 'crccproject-98fb0';
  static String get fcmEndpoint =>
      'https://fcm.googleapis.com/v1/projects/$fcmProjectId/messages:send';

  static Future<bool> sendCallNotification({
    required String deviceToken,
    required String title,
    required String body,
    required String callId,
    required String callerName,
    required String channelName,
  }) async {
    try {
      final String accessToken = await getAccessToken();

      final Map<String, dynamic> messagePayload = {
        "android": {
          "priority": "high",
          "notification": {
            "channel_id": AppConstants.notificationChannelId,
            "icon": AppConstants.notificationIcon,
            "sound": "default",
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
          },
        },
        "data": {
          "title": title,
          "body": body,
          "route": "call",
          "call_id": callId,
          "caller_name": callerName,
          "channel_name": channelName,
          "click_action": "FLUTTER_NOTIFICATION_CLICK",
          "status": "ringing"
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
        AppLogger.logSuccess('Call notification sent to token');
        return true;
      } else {
        AppLogger.logError('Failed to send call notification',
            'Status: ${response.statusCode}');
        return false;
      }
    } catch (e, stackTrace) {
      AppLogger.logError('Error sending call notification', e, stackTrace);
      return false;
    }
  }
}

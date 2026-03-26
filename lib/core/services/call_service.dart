import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:amiraly/app/util/constant/constants.dart';
import 'package:amiraly/app/util/validators/validator_helper.dart';

class CallNotificationService {
  static Future<bool> sendCallNotification({
    required String deviceToken,
    required String title,
    required String body,
    required String callId,
    required String callerName,
    required String channelName,
  }) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'send-fcm',
        body: {
          'targetToken': deviceToken,
          'title': title,
          'body': body,
          'payloadType': 'call',
          'route': 'call',
          'call_id': callId,
          'caller_name': callerName,
          'channel_name': channelName,
          'status': 'ringing',
          'priority': 'HIGH',
        },
      );
      if (response.status == 200) {
        AppLogger.logSuccess('Call notification sent via Edge Function');
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      AppLogger.logError('Error invoking send-fcm for call', e, stackTrace);
      return false;
    }
  }

  static Future<bool> sendCancelNotification({
    required String deviceToken,
    required String callId,
  }) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'send-fcm',
        body: {
          'targetToken': deviceToken,
          'payloadType': 'call',
          'route': 'call',
          'call_id': callId,
          'status': 'ended',
        },
      );
      return response.status == 200;
    } catch (e) {
      return false;
    }
  }
}

class GlobalCallService extends GetxService {
  static GlobalCallService get to => Get.find();

  StreamSubscription? _signalingSubscription;
  final Rx<String?> currentCallId = Rx<String?>(null);
  final Rx<Map<String, dynamic>?> incomingCall = Rx<Map<String, dynamic>?>(null);

  @override
  void onInit() {
    super.onInit();
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.session?.user != null) {
        startListening();
      } else {
        _signalingSubscription?.cancel();
        incomingCall.value = null;
        currentCallId.value = null;
      }
    });
    startListening();
    _listenToCallkitEvents();
  }

  void _listenToCallkitEvents() {
    FlutterCallkitIncoming.onEvent.listen((event) async {
      switch (event!.event) {
        case Event.actionCallIncoming:
          break;
        case Event.actionCallAccept:
          final data = event.body['extra'];
          if (data != null && data['route'] == 'call') {
            _navigateToCall({...data, 'accepted': true});
          }
          break;
        case Event.actionCallDecline:
          final data = event.body['extra'];
          if (data != null && data['call_id'] != null) {
            await Supabase.instance.client
                .from(AppConstants.tableCallsSignaling)
                .update({'status': 'rejected'}).eq('id', data['call_id']);
          }
          break;
        case Event.actionCallEnded:
          break;
        case Event.actionCallTimeout:
          break;
        default:
          break;
      }
    });
  }

  void startListening() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      // Retry when auth state changes if needed, but for now just return
      return;
    }

    _signalingSubscription?.cancel();
    _signalingSubscription = Supabase.instance.client
        .from(AppConstants.tableCallsSignaling)
        .stream(primaryKey: ['id'])
        .eq('receiver_id', userId)
        .listen((List<Map<String, dynamic>> data) {
          if (data.isNotEmpty) {
            final now = DateTime.now();
            final activeCall = data.firstWhere(
              (call) {
                if (call['status'] != 'ringing') return false;
                final createdAtStr = call['created_at'];
                if (createdAtStr != null) {
                  final createdAt = DateTime.parse(createdAtStr);
                  // Ignore calls older than 60 seconds
                  if (now.difference(createdAt).inSeconds.abs() > 60) {
                    return false;
                  }
                }
                return true;
              },
              orElse: () => {},
            );

            if (activeCall.isNotEmpty) {
              final String callId = activeCall['id'];
              if (currentCallId.value != callId) {
                currentCallId.value = callId;
                incomingCall.value = activeCall;
                _navigateToCall(activeCall);
              }
            } else {
              if (incomingCall.value != null &&
                  incomingCall.value!['status'] == 'ringing') {
                incomingCall.value = null;
                currentCallId.value = null;
              }
            }
          } else {
            incomingCall.value = null;
            currentCallId.value = null;
          }
        }, onError: (error) {
          debugPrint('Global signaling error: $error');
          // Auto-reconnect after delay
          Future.delayed(const Duration(seconds: 5), () => startListening());
        });
  }

  void _navigateToCall(Map<String, dynamic> callData) {
    if (Get.currentRoute != 'Go live') {
      Get.toNamed('Go live', arguments: {
        'route': 'call',
        'call_id': callData['id'],
        'caller_id': callData['caller_id'],
        'channel_name': callData['channel_name'],
        'accepted': callData['accepted'] ?? false,
      });
    }
  }

  @override
  void onClose() {
    _signalingSubscription?.cancel();
    super.onClose();
  }
}

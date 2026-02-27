import 'dart:async';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:amiraly/app/util/constant/constants.dart';
import 'package:flutter/foundation.dart';

class GlobalCallService extends GetxService {
  static GlobalCallService get to => Get.find();

  StreamSubscription? _signalingSubscription;
  final Rx<String?> currentCallId = Rx<String?>(null);

  @override
  void onInit() {
    super.onInit();
    startListening();
  }

  void startListening() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      // Retry when auth state changes if needed, but for now we'll rely on app start
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
                  // Check if call is fresh (within 2 minutes)
                  if (now.difference(createdAt).inSeconds.abs() > 120) {
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
                _navigateToCall(activeCall);
              }
            }
          }
        }, onError: (error) {
          debugPrint('Global signaling error: $error');
          Future.delayed(const Duration(seconds: 10), () => startListening());
        });
  }

  void _navigateToCall(Map<String, dynamic> callData) {
    // If we are already on the Go Live page, the controller will handle it
    // If not, navigate there with arguments
    if (Get.currentRoute != 'Go live') {
      Get.toNamed('Go live', arguments: {
        'route': 'call',
        'call_id': callData['id'],
        'caller_id': callData['caller_id'],
        'channel_name': callData['channel_name'],
      });
    }
  }

  @override
  void onClose() {
    _signalingSubscription?.cancel();
    super.onClose();
  }
}

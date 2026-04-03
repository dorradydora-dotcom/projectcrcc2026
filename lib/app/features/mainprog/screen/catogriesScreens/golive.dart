import 'dart:async';
import 'dart:ui';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:animate_do/animate_do.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shimmer/shimmer.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:amiraly/app/common/models/appmodels.dart';
import 'package:amiraly/app/common/widgets/appbar.dart';
import 'package:amiraly/app/util/constant/constants.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart' as callkit;
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
      debugPrint(
          '📞 [CallNotificationService] Preparing to send FCM to token: $deviceToken');
      debugPrint(
          '📞 [CallNotificationService] Payload: callId=$callId, channel=$channelName');
      final response = await Supabase.instance.client.functions.invoke(
        'send-fcm',
        body: {
          'targetToken': deviceToken,
          'payloadType': 'call',
          'route': 'call',
          'call_id': callId,
          'caller_name': callerName,
          'channel_name': channelName,
          'status': 'ringing',
          'priority': 'high', // Standard high priority
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        },
      );

      debugPrint(
          '📞 [CallNotificationService] Edge function response status: ${response.status}');
      if (response.status == 200) {
        AppLogger.logSuccess('Call notification sent via Edge Function');
        debugPrint('📞 [CallNotificationService] Success payload sent.');
        return true;
      }
      debugPrint(
          '📞 [CallNotificationService] Failed to send notification. Response body: ${response.data}');
      return false;
    } catch (e, stackTrace) {
      debugPrint('📞 [CallNotificationService] Exception during send-fcm: $e');
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
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        },
      );
      return response.status == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<void> handleCallNotification(Map<String, dynamic> data) async {
    try {
      debugPrint(
          '📞 [CallNotificationService] handleCallNotification received data: $data');
      final status = data['status'];

      // Always show CallKit as the primary UNIFIED interface for answering
      final String? timestampStr = data['timestamp']?.toString();
      if (timestampStr != null) {
        final createdAt = DateTime.tryParse(timestampStr)?.toUtc();
        if (createdAt != null) {
          final now = DateTime.now().toUtc();
          final diff = now.difference(createdAt).inSeconds.abs();
          if (diff > 600) {
            debugPrint(
                '📞 [CallNotificationService] STALE MESSAGE DETECTED. Ignoring.');
            return;
          }
        }
      }

      if (!GetPlatform.isMobile) return;

      if (status == 'ended' || status == 'rejected') {
        final callId = data['call_id'];
        if (callId != null) {
          await FlutterCallkitIncoming.endCall(callId);
        } else {
          await FlutterCallkitIncoming.endAllCalls();
        }
        // إغلاق أي Dialog مفتوح للمكالمة
        if (Get.isDialogOpen ?? false) {
          Get.back();
        }
        return;
      }

      // التحقق مما إذا كان التطبيق في المقدمة
      final bool isForeground =
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

      if (isForeground) {
        debugPrint('📞 [CallNotificationService] App is in foreground, showing custom Dialog...');
        await showForegroundCallDialog(data);
      } else {
        debugPrint('📞 [CallNotificationService] App is in background/terminated, showing CallKit UI...');
        await showCallKit(data);
      }
    } catch (e, stack) {
      debugPrint('Error handling call notification: $e\n$stack');
    }
  }

  static Future<void> showForegroundCallDialog(Map<String, dynamic> data) async {
    try {
      final String callId =
          data['call_id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
      final String callerName = data['caller_name'] ?? 'مكالمة واردة';
      final String channelName = data['channel_name'] ?? callId;

      // التأكد من عدم تكرار الـ Dialog أو فتحه لمكالمة منتهية أو ناتجة عن المتصل نفسه
      if (Get.isDialogOpen ?? false) return;
      if (GlobalCallService.to.currentCallId.value == callId && 
          Get.currentRoute == '/VideoCallPage') return;

      // تشغيل الرنين داخلياً (سيتم إيقافه عند الرد أو الرفض أو إنهاء المكالمة)
      if (Get.isRegistered<GoLiveController>()) {
        Get.find<GoLiveController>().playRinging();
      }

      await Get.dialog(
        PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: const Color(0xFF071624),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80.w,
                    height: 80.w,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blue, width: 2),
                    ),
                    child: Icon(
                      Iconsax.video5,
                      color: Colors.white,
                      size: 40.w,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'مكالمة فيديو واردة',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    callerName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // زر الرفض
                      _buildCallActionButton(
                        icon: Icons.call_end,
                        color: Colors.red,
                        label: 'رفض',
                        onTap: () async {
                          final GoLiveController controller = Get.isRegistered<GoLiveController>()
                              ? Get.find<GoLiveController>()
                              : Get.put(GoLiveController(), permanent: true);
                          
                          controller.stopRinging();
                          
                          await Supabase.instance.client
                              .from(AppConstants.tableCallsSignaling)
                              .update({'status': 'rejected'}).eq('id', callId);
                          
                          if (Get.isDialogOpen ?? false) {
                            Get.back();
                          }
                        },
                      ),
                      // زر الرد
                      _buildCallActionButton(
                        icon: Icons.videocam,
                        color: Colors.green,
                        label: 'رد',
                        onTap: () async {
                          // التأكد من الحصول على المتحكم سواء كان مسجلاً أم لا
                          final GoLiveController controller = Get.isRegistered<GoLiveController>()
                              ? Get.find<GoLiveController>()
                              : Get.put(GoLiveController(), permanent: true);

                          controller.stopRinging();
                          
                          // إغلاق الـ Dialog أولاً
                          if (Get.isDialogOpen ?? false) {
                            Get.back();
                          }

                          // انتظار استجابة قاعدة البيانات وتجهيز أغورا قبل الانتقال
                          await controller.respondToCall(
                              callId: callId, accept: true, channelName: channelName);
                          
                          // التنقل لصفحة المكالمة
                          Get.to(
                            () => VideoCallPage(controller: controller, channelName: channelName),
                            transition: Transition.zoom,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );
    } catch (e) {
      debugPrint('Error in showForegroundCallDialog: $e');
    }
  }

  static Widget _buildCallActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 30.w),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          label,
          style: TextStyle(color: Colors.white70, fontSize: 12.sp),
        ),
      ],
    );
  }

  static Future<void> showCallKit(Map<String, dynamic> data) async {
    try {
      final String callId =
          data['call_id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
      final String callerName = data['caller_name'] ?? 'مكالمة واردة';
      final String channelName = data['channel_name'] ?? callId;

      // 🧹 Ensure strict Single UI by ending everything else first
      await FlutterCallkitIncoming.endAllCalls();

      final params = callkit.CallKitParams(
        id: callId,
        nameCaller: callerName,
        appName: 'Amiraly GoLive',
        handle: 'فيديو مباشر',
        type: 1, // 0: Audio, 1: Video
        duration: 60000,
        textAccept: 'رد',
        textDecline: 'رفض',
        missedCallNotification: const callkit.NotificationParams(
          showNotification: true,
          isShowCallback: true,
          subtitle: 'مكالمة فائتة',
          callbackText: 'اتصال لاحقاً',
        ),
        extra: <String, dynamic>{
          'route': 'call',
          'call_id': callId,
          'channel_name': channelName,
          'caller_name': callerName,
        },
        android: const callkit.AndroidParams(
          isCustomNotification: true,
          isShowLogo: true,
          ringtonePath: 'system_ringtone_default',
          backgroundColor: '#071624',
          actionColor: '#4CAF50',
          incomingCallNotificationChannelName: "Incoming Call",
          missedCallNotificationChannelName: "Missed Call",
        ),
      );

      if (!GetPlatform.isMobile) return;
      await FlutterCallkitIncoming.showCallkitIncoming(params);
    } catch (e) {
      debugPrint('Error in showCallKit: $e');
    }
  }
}

class GlobalCallService extends GetxService {
  static GlobalCallService get to => Get.find();

  StreamSubscription? _signalingSubscription;
  final Rx<String?> currentCallId = Rx<String?>(null);
  final Rx<Map<String, dynamic>?> incomingCall =
      Rx<Map<String, dynamic>?>(null);

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
    // 🚀 Start listening immediately only if session is already present
    // because onAuthStateChange might not fire for the initial session in some versions
    if (Supabase.instance.client.auth.currentUser != null) {
      startListening();
    }

    if (GetPlatform.isMobile) {
      _listenToCallkitEvents();
      _checkCurrentCall(); 
      _setupActiveCallMonitor(); 
    }
  }

  StreamSubscription? _activeCallSubscription;

  void _setupActiveCallMonitor() {
    // مراقبة تغير currentCallId لبدء/إيقاف الاشتراك المخصص
    ever(currentCallId, (callId) {
      _activeCallSubscription?.cancel();
      if (callId != null) {
        debugPrint(
            '📞 [GlobalCallService] Active monitor started for: $callId');
        _activeCallSubscription = Supabase.instance.client
            .from(AppConstants.tableCallsSignaling)
            .stream(primaryKey: ['id'])
            .eq('id', callId)
            .listen((data) {
              if (data.isNotEmpty) {
                final snap = data.first;
                final status = snap['status'];
                if (status == 'ended' || status == 'rejected') {
                  debugPrint(
                      '📞 [GlobalCallService] Monitor: Remote $status detect for $callId');
                  if (Get.isRegistered<GoLiveController>()) {
                    Get.find<GoLiveController>()
                        .endCall('Signaling monitor ($status)', false);
                  }
                } else if (status == 'accepted' && Get.isRegistered<GoLiveController>()) {
                  final controller = Get.find<GoLiveController>();
                  // 🚀 للمتصل فقط: إذا تم القبول ولم ننتقل بعد للصفحة، انتقل فوراً
                  if (controller.isOutgoingCall.value && Get.currentRoute != '/VideoCallPage') {
                    debugPrint('📞 [GlobalCallService] Monitor: Call accepted by receiver. Navigating initiator...');
                    final channelName = snap['channel_name'] ?? controller.currentUserId;
                    _handleCallNavigation(controller, channelName);
                  }
                }
              }
            },
                onError: (e) =>
                    debugPrint('📞 [GlobalCallService] Monitor Error: $e'));
      }
    });
  }

  Future<void> _checkCurrentCall() async {
    try {
      final calls = await FlutterCallkitIncoming.activeCalls();
      if (calls is List && calls.isNotEmpty) {
        final call = calls.first;
        final bool isAccepted = call['isAccepted'] ?? false;
        if (isAccepted) {
          final data = call['extra'] != null
              ? Map<String, dynamic>.from(call['extra'])
              : null;
          if (data != null &&
              (data['route'] == 'call' || data['call_id'] != null)) {
            final callId = data['call_id'];
            final channelName = data['channel_name'] ?? callId;

            if (callId != null) {
              // 🔍 التحقق من حالة المكالمة في سوبابيز قبل محاولة الفتح
              final callStatus = await Supabase.instance.client
                  .from(AppConstants.tableCallsSignaling)
                  .select('status')
                  .eq('id', callId)
                  .maybeSingle();

              if (callStatus == null ||
                  callStatus['status'] == 'ended' ||
                  callStatus['status'] == 'rejected') {
                debugPrint(
                    '📞 [GlobalCallService] Call $callId is already dead. Cleaning up.');
                await FlutterCallkitIncoming.endCall(callId);
                return; // لا تفتح الواجهة
              }

              debugPrint(
                  '📞 [GlobalCallService] Found valid active accepted call: $callId');
              final controller = Get.put(GoLiveController(), permanent: true);
              await controller.respondToCall(
                  callId: callId, accept: true, channelName: channelName);
              _handleCallNavigation(controller, channelName);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking current call: $e');
    }
  }

  void _handleCallNavigation(GoLiveController controller, String channelName) {
    if (Get.currentRoute == '/VideoCallPage') {
      debugPrint('📞 [GlobalCallService] Already in VideoCallPage. Skipping navigation.');
      return;
    }

    final String currentRoute = Get.currentRoute;
    final bool isSplash = currentRoute == '/' ||
        currentRoute == '/SplashScreen' ||
        currentRoute == '' ||
        currentRoute.contains('Splash');

    if (isSplash) {
      debugPrint(
          '📞 [GlobalCallService] Navigation delayed (Route: $currentRoute)');
      Future.delayed(const Duration(milliseconds: 800), () {
        _handleCallNavigation(controller, channelName);
      });
    } else {
      debugPrint(
          '📞 [GlobalCallService] Navigating to VideoCallPage (Target: $channelName)');
      Get.to(
          () => VideoCallPage(controller: controller, channelName: channelName),
          transition: Transition.noTransition);
    }
  }

  void _listenToCallkitEvents() {
    if (!GetPlatform.isMobile) return;
    FlutterCallkitIncoming.onEvent.listen((event) async {
      switch (event!.event) {
        case callkit.Event.actionCallIncoming:
          break;
        case callkit.Event.actionCallAccept:
          final data = event.body['extra'];
          if (data != null &&
              (data['route'] == 'call' || data['call_id'] != null)) {
            final callId = data['call_id'];
            final channelName = data['channel_name'] ?? callId;
            if (callId != null) {
              // 🔍 التحقق الإضافي عند حدث القبول المباشر
              final controller = Get.put(GoLiveController(), permanent: true);

              final callStatus = await Supabase.instance.client
                  .from(AppConstants.tableCallsSignaling)
                  .select('status')
                  .eq('id', callId)
                  .maybeSingle();

              if (callStatus != null &&
                  (callStatus['status'] == 'ringing' ||
                      callStatus['status'] == 'accepted')) {
                debugPrint(
                    '📞 [GlobalCallService] Valid event accept for call: $callId');
                await controller.respondToCall(
                    callId: callId, accept: true, channelName: channelName);
                _handleCallNavigation(controller, channelName);
              } else {
                debugPrint(
                    '📞 [GlobalCallService] Ignoring stale accept event for call: $callId');
                await FlutterCallkitIncoming.endCall(callId);
              }
            }
          }
          break;
        case callkit.Event.actionCallDecline:
          final data = event.body['extra'];
          if (data != null && data['call_id'] != null) {
            await Supabase.instance.client
                .from(AppConstants.tableCallsSignaling)
                .update({'status': 'rejected'}).eq('id', data['call_id']);
          }
          break;
        case callkit.Event.actionCallEnded:
          break;
        case callkit.Event.actionCallTimeout:
          break;
        default:
          break;
      }
    });
  }

  StreamSubscription? _legacySignalingSubscription;

  void startListening() async {
    final authId = Supabase.instance.client.auth.currentUser?.id;
    if (authId == null) return;

    // 🛡️ Deduplication Guard
    if (_signalingSubscription != null) {
      debugPrint('📞 [GlobalCallService] Listening already active for: $authId (Deduplicated)');
      return;
    }

    // 1. Listen to Auth UID directly
    _setupStreamListener(authId, isLegacy: false);

    // 2. [Dual Listening] Try to find and listen to legacy Table ID as fallback
    try {
      final email = Supabase.instance.client.auth.currentUser?.email;
      if (email != null) {
        final legacyId = await _fetchLegacyTableId(email);
        if (legacyId != null && legacyId != authId) {
          debugPrint(
              '📞 [GlobalCallService] Dual listening enabled for legacy ID: $legacyId');
          _setupLegacyStreamListener(legacyId);
        }
      }
    } catch (e) {
      debugPrint('⚠️ [GlobalCallService] Dual listening failed to setup: $e');
    }
  }

  Future<String?> _fetchLegacyTableId(String email) async {
    final tables = [
      AppConstants.tableUserStations,
      AppConstants.tableUserCrcc,
      AppConstants.tableUserTop
    ];
    for (final table in tables) {
      try {
        final res = await Supabase.instance.client
            .from(table)
            .select('id')
            .eq('user_email', email)
            .maybeSingle();
        if (res != null && res['id'] != null) return res['id'].toString();
      } catch (_) {}
    }
    return null;
  }

  void _setupStreamListener(String userId, {bool isLegacy = false}) {
    if (_signalingSubscription != null) return; // 🛡️ Idempotent check
    
    debugPrint(
        '📞 [GlobalCallService] Starting stream listener for ${isLegacy ? "Legacy" : "Auth"} ID: $userId');
    _signalingSubscription = Supabase.instance.client
        .from(AppConstants.tableCallsSignaling)
        .stream(primaryKey: ['id'])
        .eq('receiver_id', userId)
        .listen((List<Map<String, dynamic>> data) {
          debugPrint(
              '📞 [GlobalCallService] Stream updated. Rows count: ${data.length}');

          if (data.isNotEmpty) {
            final activeCall = data.firstWhere(
              (call) {
                // الفحص للمستقبل ليشمل الرنين (للتنبيه) والمقبول (لاستمرار الاتصال)
                if (call['status'] != 'ringing' && call['status'] != 'accepted') return false;
                final createdAtStr = call['created_at'];
                if (createdAtStr != null) {
                  final createdAt = DateTime.tryParse(createdAtStr)?.toUtc();
                  if (createdAt != null) {
                    final now = DateTime.now().toUtc();
                    final diff = now.difference(createdAt).inSeconds.abs();
                    debugPrint('📞 [GlobalCallService] Time Match: Server=$createdAt, Local=$now, Diff=${diff}s');
                    if (diff > 1200) { // نافذة 20 دقيقة لتجاوز فروق التوقيت الشديدة
                      debugPrint('📞 [GlobalCallService] Ignoring old call (Drift > 20m): ID=${call['id']}');
                      return false;
                    }
                  }
                }
                return true;
              },
              orElse: () => <String, dynamic>{},
            );

            if (activeCall.isNotEmpty) {
              debugPrint(
                  '📞 [GlobalCallService] MATCHED active call: ${activeCall['id']}');
              final String callId = activeCall['id'];
                if (currentCallId.value != callId) {
                  currentCallId.value = callId;
                  incomingCall.value = activeCall;
                  
                  // 🚀 لا نفتح النافذة إلا إذا كانت الحالة "رنين"
                  if (activeCall['status'] == 'ringing') {
                    debugPrint(
                        '📞 [GlobalCallService] Navigating to call: $callId');
                    _navigateToCall(activeCall);
                  } else {
                    debugPrint(
                        '📞 [GlobalCallService] Active call resumed: $callId (Status: ${activeCall['status']})');
                  }
                }
            } else {
              debugPrint(
                  '📞 [GlobalCallService] No active ringing calls within last 60s.');
              if (incomingCall.value != null &&
                  incomingCall.value!['status'] == 'ringing') {
                incomingCall.value = null;
                currentCallId.value = null;
                // 🛑 إغلاق الـ Dialog إذا انتهى الرنين ولم يتم الرد
                if (Get.isDialogOpen ?? false) {
                  Get.back();
                }
                if (Get.isRegistered<GoLiveController>()) {
                  Get.find<GoLiveController>().stopRinging();
                }
              }
            }
          } else {
            debugPrint('📞 [GlobalCallService] Stream returned empty list.');
            if (incomingCall.value != null &&
                incomingCall.value!['status'] == 'ringing') {
              // 🛑 إغلاق الـ Dialog إذا تم حذف سجل المكالمة
              if (Get.isDialogOpen ?? false) {
                Get.back();
              }
              if (Get.isRegistered<GoLiveController>()) {
                Get.find<GoLiveController>().stopRinging();
              }
            }
            incomingCall.value = null;
            currentCallId.value = null;
          }
        }, onError: (error) {
          debugPrint('Global signaling error: $error');
          // 🚀 إعادة الاتصال الذكية عند حدوث خطأ 1006 أو أي عطل في القناة
          if (error.toString().contains('1006') ||
              error.toString().contains('channelError')) {
            debugPrint(
                '📞 [GlobalCallService] Realtime channel closed (1006). Reconnecting in 3s...');
          }
          Future.delayed(const Duration(seconds: 3), () {
            if (Supabase.instance.client.auth.currentUser != null) {
              startListening();
            }
          });
        });
  }

  void _navigateToCall(Map<String, dynamic> callData) {
    // 🚫 DISABLED internal auto-navigation to avoid double UI.
    // CallKit (CallNotificationService) handles the initial ringing interaction.
    debugPrint(
        '📞 [GlobalCallService] Internal navigation suppressed to keep UI unified via CallKit.');
  }

  void _setupLegacyStreamListener(String legacyId) {
    _legacySignalingSubscription?.cancel();
    _legacySignalingSubscription = Supabase.instance.client
        .from(AppConstants.tableCallsSignaling)
        .stream(primaryKey: ['id'])
        .eq('receiver_id', legacyId)
        .listen((data) {
          if (data.isNotEmpty) {
            debugPrint('📞 [GlobalCallService] LEGACY stream detected call!');
            _handleInboundStream(data);
          }
        });
  }

  void _handleInboundStream(List<Map<String, dynamic>> data) {
    if (data.isNotEmpty) {
      final activeCall = data.firstWhere(
        (call) {
          if (call['status'] != 'ringing' && call['status'] != 'accepted') return false;
          final createdAtStr = call['created_at'];
          if (createdAtStr != null) {
            final createdAt = DateTime.tryParse(createdAtStr)?.toUtc();
            if (createdAt != null) {
              final now = DateTime.now().toUtc();
              final diff = now.difference(createdAt).inSeconds.abs();
              if (diff > 600) return false;
            }
          }
          return true;
        },
        orElse: () => <String, dynamic>{},
      );

      if (activeCall.isNotEmpty) {
        final String callId = activeCall['id'];
        if (currentCallId.value != callId) {
          currentCallId.value = callId;
          incomingCall.value = activeCall;
          _navigateToCall(activeCall);
        }
      }
    }
  }

  @override
  void onClose() {
    _signalingSubscription?.cancel();
    _legacySignalingSubscription?.cancel();
    _activeCallSubscription?.cancel();
    super.onClose();
  }
}

class GoLiveController extends GetxController {
  final RxList<StationModelCall> users = <StationModelCall>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isAccessDenied = false.obs;
  final RxBool canInitiateCalls = false.obs;
  final Rx<String?> errorMessage = Rx<String?>(null);

  Timer? _callTimeoutTimer;

  final AudioPlayer _ringPlayer = AudioPlayer();
  final AudioPlayer _effectPlayer = AudioPlayer();

  String get _appId => dotenv.env['AGORA_APP_ID'] ?? '';

  static const List<String> _excludedStations = [
    'عبور3/عاشر',
    'برقاش/ابوغالب',
    'قليوب/قناطر',
    'الكريمات/بنى سويف',
    'ابو زعبل/بلبيس',
  ];

  static const String ringSound = 'lib/assets/sounds/ring.mp3';
  static const String connectSound = 'lib/assets/sounds/connect.mp3';
  static const String hangupSound = 'lib/assets/sounds/hangup.mp3';

  // [Refactored] Use GlobalCallService.to.currentCallId instead
  Rx<String?> get currentCallId => GlobalCallService.to.currentCallId;

  RtcEngine? _engine;
  RtcEngine? get engine => _engine;

  final localUserJoined = false.obs;
  final remoteUid = Rxn<int>();
  final localViewController = Rxn<VideoViewController>();
  final remoteViewController = Rxn<VideoViewController>();
  final isLocalVideoReady = false.obs;
  final isRemoteVideoReady = false.obs;
  final isAudioEnabled = true.obs;
  final isVideoEnabled = true.obs;
  final isOutgoingCall = false.obs;
  final remoteName = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _syncUserIdentity();

    // 🎧 Listen to global signaling for ring sounds
    ever(GlobalCallService.to.incomingCall, (call) {
      if (call != null && call['status'] == 'ringing') {
        playRinging();
      } else {
        stopRinging();
      }
    });

    // 🚀 [Auto-Answer Check] If navigated with 'accepted', trigger connection immediately
    final args = Get.arguments;
    if (args is Map && args['route'] == 'call' && args['accepted'] == true) {
      debugPrint(
          '📞 [GoLiveController] Detected AUTO-ANSWER from arguments. Connecting...');
      Future.delayed(const Duration(milliseconds: 500), () {
        final channel = args['channel_name'];
        respondToCall(channelName: channel);
      });
    }
  }

  @override
  void onReady() {
    super.onReady();
    checkAccess();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;
      final response = await Supabase.instance.client
          .from(AppConstants.tableUserStations)
          .select();

      final List<dynamic> data = response;
      debugPrint(
          '📞 [GoLiveController] fetchUsers raw sample: ${data.isNotEmpty ? data.first : 'Empty'}');
      final fetched =
          data.map((json) => StationModelCall.fromJson(json)).where((user) {
        final name = user.stationName ?? '';
        return !_excludedStations.any((excluded) => name.contains(excluded));
      }).toList();

      fetched
          .sort((a, b) => (a.stationName ?? '').compareTo(b.stationName ?? ''));
      users.assignAll(fetched);
    } catch (e) {
      errorMessage.value = 'Failed to load users: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> checkAccess() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user?.email == null) {
      isAccessDenied.value = true;
      return;
    }

    try {
      final email = user!.email!;
      final client = Supabase.instance.client;
      final results = await Future.wait([
        client
            .from(AppConstants.tableUserTop)
            .select()
            .eq('user_email', email)
            .limit(1),
        client
            .from(AppConstants.tableUserCrcc)
            .select()
            .eq('user_email', email)
            .limit(1),
        client
            .from(AppConstants.tableUserStations)
            .select()
            .eq('user_email', email)
            .limit(1),
      ]);

      isAccessDenied.value = results.every((r) => r.isEmpty);
      canInitiateCalls.value = results[0].isNotEmpty || results[1].isNotEmpty;
    } catch (e) {
      isAccessDenied.value = true;
    }
  }

  Future<void> initializeAgora() async {
    isLocalVideoReady.value = false;
    isRemoteVideoReady.value = false;
    try {
      if (GetPlatform.isMobile) {
        final status =
            await [Permission.camera, Permission.microphone].request();
        if (status[Permission.camera] != PermissionStatus.granted) {
          throw 'صلاحية الكاميرا مطلوبة';
        }
        if (status[Permission.microphone] != PermissionStatus.granted) {
          throw 'صلاحية الميكروفون مطلوبة';
        }
      }

      if (_engine == null) {
        _engine = createAgoraRtcEngine();
        await _engine!.initialize(RtcEngineContext(
          appId: _appId,
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        ));

        _engine!.registerEventHandler(
          RtcEngineEventHandler(
            onJoinChannelSuccess: (connection, elapsed) {
              debugPrint('📞 [GoLiveController] Agora: Joined channel successfully. UID: ${connection.localUid}');
              localUserJoined.value = true;
              isLocalVideoReady.value = true;
            },
            onUserJoined: (connection, uid, elapsed) {
              debugPrint('📞 [GoLiveController] Agora: Remote user joined. UID: $uid');
              remoteUid.value = uid;
              isRemoteVideoReady.value = true;
              stopRinging();
              playConnect();
              _callTimeoutTimer?.cancel();
            },
            onUserOffline: (connection, uid, reason) {
              debugPrint('📞 [GoLiveController] Agora: Remote user offline. UID: $uid, Reason: $reason');
              remoteUid.value = null;
              isRemoteVideoReady.value = false;
              Get.snackbar('انتهت المكالمة', 'قام الطرف الآخر بالمغادرة');
              endCall('Remote user offline ($reason)');
              if (Get.currentRoute != 'Go live' && Get.currentRoute != '/HomePage') {
                Get.back();
              }
            },
          ),
        );
      }

      await _engine!.enableVideo();

      // 🚀 تحسين الجودة المتوازنة (Balanced Quality) للعمل على 4G
      await _engine!
          .setVideoEncoderConfiguration(const VideoEncoderConfiguration(
        dimensions: VideoDimensions(width: 640, height: 360),
        frameRate: 24,
        bitrate: 1000,
        degradationPreference: DegradationPreference.maintainFramerate,
        orientationMode: OrientationMode.orientationModeFixedPortrait,
      ));

      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      await _engine!.startPreview();

      localViewController.value = VideoViewController(
        rtcEngine: _engine!,
        canvas: const VideoCanvas(uid: 0),
        useAndroidSurfaceView: GetPlatform.isAndroid,
      );
    } catch (e) {
      debugPrint('Agora Error: $e');
      rethrow;
    }
  }

  Future<void> joinChannel(String channelName, String? token) async {
    try {
      await initializeAgora();
      final int uid = currentUserId.hashCode & 0x7FFFFFFF;
      await _engine!.joinChannel(
        token: token ?? '',
        channelId: channelName,
        uid: uid,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishCameraTrack: true,
          publishMicrophoneTrack: true,
        ),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> leaveChannel() async {
    if (_engine != null) {
      await _engine!.leaveChannel();
      localUserJoined.value = false;
      remoteUid.value = null;
    }
  }

  String? get currentUserId => Supabase.instance.client.auth.currentUser?.id;

  Future<String?> _getReceiverToken(String receiverId) async {
    const tables = [
      AppConstants.tableUserStations,
      AppConstants.tableUserCrcc,
      AppConstants.tableUserTop
    ];
    for (final table in tables) {
      try {
        final data = await Supabase.instance.client
            .from(table)
            .select('user_token')
            .eq('id', receiverId)
            .maybeSingle();
        if (data?['user_token'] != null) return data!['user_token'] as String;
      } catch (_) {}
    }
    return null;
  }

  Future<void> _syncUserIdentity() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || user.email == null) return;

    final userId = user.id;
    final email = user.email!.trim().toLowerCase();

    try {
      // 🚀 جلب أحدث توكن للإشعارات لضمان وصول المكالمات
      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
      } catch (e) {
        debugPrint(
            '⚠️ [GoLiveController] Could not fetch FCM token for sync: $e');
      }

      debugPrint(
          '📞 [GoLiveController] Syncing identity & token for $email -> $userId');

      const tables = [
        AppConstants.tableUserStations,
        AppConstants.tableUserCrcc,
        AppConstants.tableUserTop
      ];

      for (final table in tables) {
        final updateData = {'id': userId};
        if (fcmToken != null) {
          updateData['user_token'] = fcmToken;
        }

        final response = await Supabase.instance.client
            .from(table)
            .update(updateData)
            .eq('user_email', email)
            .select();

        if ((response as List).isNotEmpty) {
          debugPrint(
              '✅ [GoLiveController] Identity & Token synced in $table for $email');
        }
      }
    } catch (e) {
      debugPrint('⚠️ [GoLiveController] Identity sync failed: $e');
    }
  }

  Future<String> _fetchCallerName(String callId) async {
    try {
      final call = await Supabase.instance.client
          .from(AppConstants.tableCallsSignaling)
          .select('caller_id')
          .eq('id', callId)
          .maybeSingle();
      if (call != null && call['caller_id'] != null) {
        return await _getUserName(call['caller_id']);
      }
    } catch (e) {
      debugPrint('⚠️ [GoLiveController] Fetch caller name failed: $e');
    }
    return 'مكالمة واردة';
  }

  Future<String> _getUserName(String userId) async {
    const tables = [
      AppConstants.tableUserStations,
      AppConstants.tableUserCrcc,
      AppConstants.tableUserTop
    ];
    for (final table in tables) {
      try {
        final data = await Supabase.instance.client
            .from(table)
            .select('station_name')
            .eq('id', userId)
            .maybeSingle();
        if (data?['station_name'] != null) {
          return data!['station_name'] as String;
        }
      } catch (_) {}
    }
    return 'اتصال فيديو';
  }

  Future<void> makeCall(String receiverId) async {
    // 🧹 Reset stale state
    isOutgoingCall.value = true;
    localUserJoined.value = false;
    remoteUid.value = null;
    remoteName.value = 'جاري التحميل...';
    
    debugPrint(
        '📞 [GoLiveController] makeCall started for receiver: $receiverId');
    final userId = currentUserId;
    if (userId == null) {
      debugPrint('📞 [GoLiveController] makeCall failed: currentUserId is null');
      return;
    }

    try {
      // 🧹 ZOMBIE CLEANUP: Clear any existing ringing/accepted records for these users
      await Supabase.instance.client
          .from(AppConstants.tableCallsSignaling)
          .delete()
          .or('caller_id.eq.$userId,receiver_id.eq.$userId,caller_id.eq.$receiverId,receiver_id.eq.$receiverId')
          .inFilter('status', ['ringing', 'accepted']);
      
      debugPrint('📞 [GoLiveController] Zombie cleanup finished. Starting fresh call.');

      debugPrint('📞 [GoLiveController] Fetching tokens...');
      final callerToken = await _getReceiverToken(userId);
      final receiverToken = await _getReceiverToken(receiverId);
      debugPrint(
          '📞 [GoLiveController] callerToken fetched: ${callerToken != null}');
      debugPrint(
          '📞 [GoLiveController] receiverToken fetched: ${receiverToken != null}');

      debugPrint(
          '📞 [GoLiveController] Signaling data: caller=$userId, receiver=$receiverId');
      final response = await Supabase.instance.client
          .from(AppConstants.tableCallsSignaling)
          .insert({
            'caller_id': userId,
            'receiver_id': receiverId,
            'channel_name': receiverId,
            'status': 'ringing',
          })
          .select()
          .single();

      debugPrint(
          '📞 [GoLiveController] Signaling record created. Call ID: ${response['id']}');
      GlobalCallService.to.currentCallId.value = response['id'];

      if (receiverToken != null) {
        debugPrint(
            '📞 [GoLiveController] Sending push notification to receiver...');
        final callerName = await _getUserName(userId);
        await CallNotificationService.sendCallNotification(
          deviceToken: receiverToken,
          title: 'مكالمة واردة 📞',
          body: 'مكالمة فيديو واردة من $callerName',
          callId: response['id'],
          callerName: callerName,
          channelName: receiverId,
        );
      } else {
        debugPrint(
            '📞 [GoLiveController] WARNING: Receiver token is NULL! Push notification will not be sent.');
      }

      debugPrint('📞 [GoLiveController] Joining Agora channel...');
      // 🚀 عاجل: تمرير null لأن توكن FCM لا يصلح للاتصال عبر أغورا
      await joinChannel(receiverId, null);

      // Fetch receiver name for UI
      _getUserName(receiverId).then((name) => remoteName.value = name);

      debugPrint('📞 [GoLiveController] Navigating to VideoCallPage...');
      Get.to(() => VideoCallPage(controller: this, channelName: receiverId));

      _callTimeoutTimer?.cancel();
      _callTimeoutTimer = Timer(const Duration(seconds: 60), () {
        if (remoteUid.value == null) {
          endCall();
          Get.snackbar('تنبيه', 'الطرف الآخر لا يرد',
              backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
              colorText: Colors.white,
              snackPosition: SnackPosition.TOP);
        }
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> respondToCall(
      {String? callId, bool accept = true, String? channelName}) async {
    // 🧹 Reset stale state
    isOutgoingCall.value = false;
    localUserJoined.value = false;
    remoteUid.value = null;
    remoteName.value = 'مكالمة واردة...';

    debugPrint(
        '📞 [GoLiveController] respondToCall triggered. Accept: $accept');
    stopRinging();

    final effectiveCallId = callId ?? GlobalCallService.to.currentCallId.value;
    if (effectiveCallId == null) {
      debugPrint('📞 [GoLiveController] Cannot respond: callId is null.');
      return;
    }

    try {
      if (accept) {
        // 1. Update status in DB first to sync status across all devices
        await Supabase.instance.client
            .from(AppConstants.tableCallsSignaling)
            .update({'status': 'accepted'}).eq(
                'id', effectiveCallId);
        
        // Fetch caller name for UI
        _fetchCallerName(effectiveCallId).then((name) => remoteName.value = name);

        // 2. Initialize and Join
        final effectiveChannel = (channelName != null && channelName.isNotEmpty) 
            ? channelName 
            : currentUserId;

        if (effectiveChannel != null) {
          await joinChannel(effectiveChannel, null);
          debugPrint(
              '✅ [GoLiveController] Successfully connected after respondToCall.');
        }
      } else {
        await Supabase.instance.client
            .from(AppConstants.tableCallsSignaling)
            .update({'status': 'rejected'}).eq('id', effectiveCallId);
        endCall('User rejected', false);
      }
    } catch (e) {
      debugPrint('⚠️ [GoLiveController] Error responding to call: $e');
    }
  }

  Future<void> endCall([String reason = 'Direct user action', bool notifyRemote = true]) async {
    debugPrint('📞 [GoLiveController] endCall triggered. Reason: $reason, Notify: $notifyRemote');
    _callTimeoutTimer?.cancel();
    if (GlobalCallService.to.currentCallId.value != null && notifyRemote) {
      final callId = GlobalCallService.to.currentCallId.value!;
      
      try {
        final callData = await Supabase.instance.client
            .from(AppConstants.tableCallsSignaling)
            .select('receiver_id, caller_id')
            .eq('id', callId)
            .maybeSingle();

        await Supabase.instance.client
            .from(AppConstants.tableCallsSignaling)
            .update({'status': 'ended'}).eq('id', callId);

        if (callData != null) {
          final receiverId = callData['receiver_id'];
          final callerId = callData['caller_id'];
          final targetUserId = currentUserId == callerId ? receiverId : callerId;
          if (targetUserId != null) {
            final targetToken = await _getReceiverToken(targetUserId.toString());
            if (targetToken != null) {
              CallNotificationService.sendCancelNotification(
                deviceToken: targetToken,
                callId: callId,
              );
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ [GoLiveController] DB error in endCall: $e');
      }
    }
    stopRinging();
    playHangup();
    
    // 🧹 Immediate release of hardware resources
    await leaveChannel();
    await disposeAgora();
    
    await FlutterCallkitIncoming.endAllCalls(); 

    currentCallId.value = null;
    GlobalCallService.to.incomingCall.value = null;
    localViewController.value = null;
    remoteViewController.value = null;

    // 🆕 إغلاق واجهة الفيديو بذكاء لتجنب الانغلاق المبكر
    if (Get.isRegistered<GoLiveController>()) {
      final String currentRoute = Get.currentRoute;
      debugPrint(
          '📞 [GoLiveController] Navigation check - Current Route: $currentRoute');

      if (currentRoute.contains('VideoCall') || currentRoute == '') {
        if (currentRoute != 'Go live' &&
            currentRoute != '/HomePage' &&
            !currentRoute.contains('Splash')) {
          debugPrint('📞 [GoLiveController] Closing VideoCallPage...');
          Get.back();
        }
      }
    }
    GlobalCallService.to.currentCallId.value =
        null; // نغيرها في النهاية لضمان عمل الـ Cleanup
    
    // 🗑️ Optional: Remove controller from memory if no call is active and we are not in GoLive screen
    if (Get.isRegistered<GoLiveController>() && Get.currentRoute != 'Go live') {
      debugPrint('📞 [GoLiveController] Self-disposing to save memory...');
      Get.delete<GoLiveController>();
    }
  }

  Future<void> disposeAgora() async {
    if (_engine != null) {
      await _engine!.release();
      _engine = null;
    }
  }

  void playRinging() {
    try {
      AudioCache.instance.prefix = '';
      _ringPlayer.setReleaseMode(ReleaseMode.loop);
      _ringPlayer.play(AssetSource(ringSound));
    } catch (_) {}
  }

  void stopRinging() => _ringPlayer.stop();
  void playConnect() {
    AudioCache.instance.prefix = '';
    _effectPlayer.play(AssetSource(connectSound));
  }

  void playHangup() {
    AudioCache.instance.prefix = '';
    _effectPlayer.play(AssetSource(hangupSound));
  }

  @override
  void onClose() {
    _callTimeoutTimer?.cancel();
    _ringPlayer.dispose();
    _effectPlayer.dispose();
    disposeAgora();
    super.onClose();
  }

  Future<void> toggleAudio() async {
    if (_engine == null) return;
    isAudioEnabled.value = !isAudioEnabled.value;
    await _engine!.enableLocalAudio(isAudioEnabled.value);
  }

  Future<void> switchCamera() async {
    if (_engine != null) await _engine!.switchCamera();
  }
}

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 🚀 Use Get.find or non-permanent put. Default is lazy initialized in main.dart
    final controller = Get.isRegistered<GoLiveController>() 
        ? Get.find<GoLiveController>() 
        : Get.put(GoLiveController());

    return Scaffold(
      backgroundColor: Appcolors.primaryColor,
      appBar: const CustomAppBar(),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Appcolors.primaryColor,
                    Appcolors.primaryColor,
                    Color(0xFF163C5E),
                    Color(0xFF0F2B44),
                    Color(0xFF081A2A)
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    FadeInDown(
                      duration: const Duration(milliseconds: 800),
                      child: _buildHeader(),
                    ),
                    FadeIn(
                      delay: const Duration(milliseconds: 500),
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 10.h),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_downward,
                                size: 14.sp, color: Colors.white38),
                            SizedBox(width: 8.w),
                            Text(
                              'اسحب الشاشة لاسفل للتحديث',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: Colors.white38,
                                fontFamily: Appfontstring.ChangaLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Obx(() {
                        if (controller.isAccessDenied.value) {
                          return _buildAccessDenied();
                        }
                        if (controller.isLoading.value) {
                          return _buildShimmerLoading();
                        }
                        if (controller.errorMessage.value != null) {
                          return Center(
                            child: FadeIn(
                              child: Text(
                                controller.errorMessage.value!,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                          );
                        }
                        if (controller.users.isEmpty) {
                          return Center(
                            child: FadeInUp(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Iconsax.user_remove,
                                    size: 48.sp,
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                  SizedBox(height: 16.h),
                                  Text(
                                    'لا يوجد مستخدمين حالياً',
                                    style: TextStyle(
                                      fontFamily: Appfontstring.ChangaLight,
                                      fontSize: 14.sp,
                                      color: Colors.white54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return LayoutBuilder(builder: (context, constraints) {
                          final tableWidth = constraints.maxWidth;
                          final col1 = tableWidth * 0.60;
                          final col2 = tableWidth * 0.28;

                          return FadeInUp(
                            duration: const Duration(milliseconds: 1000),
                            child: Container(
                              margin: EdgeInsets.all(15.w),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20.r),
                                child: BackdropFilter(
                                  filter:
                                      ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: RefreshIndicator(
                                    color: Appcolors.secondaryColor,
                                    onRefresh: controller.fetchUsers,
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.vertical,
                                      physics:
                                          const AlwaysScrollableScrollPhysics(
                                              parent: BouncingScrollPhysics()),
                                      child: Column(
                                        children: [
                                          DataTable(
                                            headingRowColor:
                                                WidgetStateProperty.all(Colors
                                                    .white
                                                    .withValues(alpha: 0.12)),
                                            dataRowColor:
                                                WidgetStateProperty.all(
                                                    Colors.transparent),
                                            dataRowMinHeight: 45.h,
                                            dataRowMaxHeight: 45.h,
                                            columnSpacing: 0,
                                            horizontalMargin: 12.w,
                                            columns: [
                                              DataColumn(
                                                  label: SizedBox(
                                                      width: col1,
                                                      child: Padding(
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                                  horizontal:
                                                                      10.w),
                                                          child: Row(children: [
                                                            Icon(
                                                                Icons
                                                                    .location_city,
                                                                size: 16.sp,
                                                                color: Appcolors
                                                                    .gold),
                                                            SizedBox(
                                                                width: 10.w),
                                                            Text('المحطة',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        13.sp,
                                                                    fontFamily:
                                                                        Appfontstring
                                                                            .ChangaLight,
                                                                    color: Appcolors
                                                                        .gold))
                                                          ])))),
                                              DataColumn(
                                                  label: SizedBox(
                                                      width: col2,
                                                      child: Row(
                                                        children: [
                                                          Icon(Iconsax.video5,
                                                              size: 16.sp,
                                                              color: Colors
                                                                  .white70),
                                                          SizedBox(width: 10.w),
                                                          Text('بث مباشر',
                                                              style: TextStyle(
                                                                  fontSize:
                                                                      13.sp,
                                                                  fontFamily:
                                                                      Appfontstring
                                                                          .ChangaLight,
                                                                  color: Colors
                                                                      .white)),
                                                        ],
                                                      ))),
                                            ],
                                            rows: controller.users.map((user) {
                                              return DataRow(cells: [
                                                DataCell(SizedBox(
                                                    width: col1,
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              horizontal: 10.w),
                                                      child: Text(
                                                          user.stationName ??
                                                              '',
                                                          style: TextStyle(
                                                              fontSize: 12.sp,
                                                              fontFamily:
                                                                  Appfontstring
                                                                      .ChangaLight,
                                                              color: Colors
                                                                  .white)),
                                                    ))),
                                                DataCell(SizedBox(
                                                  width: col2,
                                                  child: Obx(() {
                                                    if (!controller
                                                        .canInitiateCalls
                                                        .value) {
                                                      return const SizedBox
                                                          .shrink();
                                                    }
                                                    return ZoomIn(
                                                      child: IconButton(
                                                        padding:
                                                            EdgeInsets.zero,
                                                        constraints:
                                                            const BoxConstraints(),
                                                        icon: Container(
                                                          padding:
                                                              EdgeInsets.all(
                                                                  8.r),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors.blue
                                                                .withValues(
                                                                    alpha: 0.2),
                                                            shape:
                                                                BoxShape.circle,
                                                            border: Border.all(
                                                                color: Colors
                                                                    .blue
                                                                    .withValues(
                                                                        alpha:
                                                                            0.5),
                                                                width: 1),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: Colors
                                                                    .blue
                                                                    .withValues(
                                                                        alpha:
                                                                            0.3),
                                                                blurRadius: 8,
                                                                spreadRadius: 1,
                                                              ),
                                                            ],
                                                          ),
                                                          child: Icon(
                                                              Iconsax.video5,
                                                              size: 18.sp,
                                                              color:
                                                                  Colors.white),
                                                        ),
                                                        onPressed: () async {
                                                          await _handleStartCall(
                                                              context,
                                                              controller,
                                                              user.id);
                                                        },
                                                      ),
                                                    );
                                                  }),
                                                )),
                                              ]);
                                            }).toList(),
                                          ),
                                          SizedBox(height: 20.h),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        });
                      }),
                    ),
                  ],
                ),
              ),
            ),
            // Incoming Call Overlay
            Obx(() => _buildIncomingCallOverlay(
                context, controller, GlobalCallService.to.incomingCall.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20.h),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        margin: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15.r),
            border: Border.all(
                color: Colors.orange.withValues(alpha: 0.5), width: 1.5.w),
            color: Colors.black.withValues(alpha: 0.4),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withValues(alpha: 0.1),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ]),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Pulse(
              infinite: true,
              child: Icon(Iconsax.video_circle5,
                  color: Colors.orange, size: 24.sp),
            ),
            SizedBox(width: 12.w),
            Flexible(
              child: Text(
                'مركز الاتصال المرئي للمحطات',
                style: TextStyle(
                  fontSize: 15.sp,
                  color: Colors.orange,
                  fontFamily: Appfontstring.ChangaLight,
                  letterSpacing: 0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleStartCall(BuildContext context,
      GoLiveController controller, String receiverId) async {
    // 1. Navigate immediately to VideoCallPage (Messenger Style)
    Get.to(
      () => VideoCallPage(controller: controller, channelName: receiverId),
    );

    try {
      // 2. Initialize Agora in the background while the user is on the VideoCallPage
      await controller.initializeAgora();

      // 3. Start ringing and trigger the call
      controller.playRinging();
      await controller.makeCall(receiverId);
    } catch (e) {
      Get.back(); // Return to users page on failure
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل بدء المكالمة: $e')),
        );
      }
    }
  }

  Widget _buildIncomingCallOverlay(BuildContext context,
      GoLiveController controller, Map<String, dynamic>? call) {
    if (call == null) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: FadeIn(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            color: Colors.black.withValues(alpha: 0.5),
            child: Center(
              child: ZoomIn(
                child: Container(
                  width: 0.8.sw,
                  padding: EdgeInsets.all(25.r),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(30.r),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Pulse(
                        infinite: true,
                        child: Icon(Iconsax.call_calling5,
                            color: Colors.greenAccent, size: 50.sp),
                      ),
                      SizedBox(height: 20.h),
                      Text('مكالمة واردة',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13.sp,
                              fontFamily: Appfontstring.ChangaLight)),
                      SizedBox(height: 5.h),
                      Text('اتصال مرئي جديد',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18.sp,
                              fontFamily: Appfontstring.ChangaLight)),
                      SizedBox(height: 30.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: Container(
                              padding: EdgeInsets.all(12.r),
                              decoration: const BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle),
                              child: const Icon(Iconsax.call_remove5,
                                  color: Colors.white),
                            ),
                            onPressed: () => controller.respondToCall(
                                callId: call['id'], accept: false),
                          ),
                          IconButton(
                            icon: Container(
                              padding: EdgeInsets.all(12.r),
                              decoration: const BoxDecoration(
                                  color: Colors.greenAccent,
                                  shape: BoxShape.circle),
                              child: const Icon(Iconsax.call5,
                                  color: Colors.white),
                            ),
                            onPressed: () {
                              controller.respondToCall(
                                  callId: call['id'], accept: true);
                              Get.to(
                                () => VideoCallPage(
                                    controller: controller,
                                    channelName: call['channel_name']),
                              );
                            },
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      itemCount: 8,
      padding: EdgeInsets.all(15.w),
      itemBuilder: (context, index) => _buildShimmerRow(),
    );
  }

  Widget _buildShimmerRow() {
    return Shimmer.fromColors(
      baseColor: Colors.white.withValues(alpha: 0.05),
      highlightColor: Colors.white.withValues(alpha: 0.12),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        height: 50.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.r),
        ),
      ),
    );
  }

  Widget _buildAccessDenied() {
    return Center(
      child: FadeInUp(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.shield_cross5,
              size: 80.sp,
              color: Colors.redAccent.withValues(alpha: 0.5),
            ),
            SizedBox(height: 20.h),
            Text(
              'عفواً، لا تملك تصريح لدخول الصفحة',
              style: TextStyle(
                fontFamily: Appfontstring.ChangaLight,
                fontSize: 16.sp,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              'هذه الصفحة مخصصة للمسئولين فقط',
              style: TextStyle(
                fontFamily: Appfontstring.ChangaLight,
                fontSize: 12.sp,
                color: Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Video Call Page
class VideoCallPage extends StatelessWidget {
  final GoLiveController controller;
  final String channelName;

  const VideoCallPage(
      {super.key, required this.controller, required this.channelName});

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) {
          // إغلاق الواجهة فوراً ثم إنهاء الاتصال في الخلفية لتفادي وميض (جاري الاتصال)
          controller.endCall('PopScope Invoked');
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Remote Video (Full Screen)
              Positioned.fill(
                child: Obx(() {
                  if (controller.remoteUid.value != null &&
                      controller.engine != null) {
                    return AgoraVideoView(
                      controller: VideoViewController.remote(
                        rtcEngine: controller.engine!,
                        canvas: VideoCanvas(
                            uid: controller.remoteUid.value!,
                            renderMode: RenderModeType.renderModeHidden),
                        connection: RtcConnection(
                            channelId: channelName,
                            localUid:
                                controller.currentUserId.hashCode & 0x7FFFFFFF),
                        useAndroidSurfaceView: true,
                      ),
                    );
                  }
                  return Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SpinKitRipple(
                          color: Colors.white.withValues(alpha: 0.3),
                          size: 100.r,
                        ),
                        SizedBox(height: 24.h),
                        Obx(() => Text(
                              controller.remoteName.value,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                                fontFamily: Appfontstring.ChangaLight,
                              ),
                            )),
                        SizedBox(height: 8.h),
                        Obx(() => Text(
                              controller.isOutgoingCall.value &&
                                      controller.remoteUid.value == null
                                  ? 'جاري الاتصال...'
                                  : 'جاري الانضمام للمكالمة...',
                              style: TextStyle(
                                fontFamily: Appfontstring.ChangaLight,
                                fontSize: 16.sp,
                                color: Colors.white70,
                              ),
                            )),
                      ],
                    ),
                  );
                }),
              ),

              // Local Video (Overlay)
              Obx(() {
                if (controller.localViewController.value != null) {
                  return AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    top: 50.h,
                    right: controller.remoteUid.value != null
                        ? 20.w
                        : (1.sw - 150.w) / 2,
                    child: Container(
                      width: controller.remoteUid.value != null ? 120.w : 150.w,
                      height:
                          controller.remoteUid.value != null ? 180.h : 220.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: Colors.white24, width: 2),
                        boxShadow: [
                          BoxShadow(color: Colors.black54, blurRadius: 10)
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18.r),
                        child: AgoraVideoView(
                            controller: controller.localViewController.value!),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),

              // Header
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(
                      top: ScreenUtil().statusBarHeight + 10,
                      left: 20,
                      right: 20,
                      bottom: 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black87, Colors.transparent],
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios,
                            color: Colors.white70, size: 20.sp),
                        onPressed: () => _handleBack(),
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'مكالمة فيديو',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontFamily: Appfontstring.ChangaLight),
                          ),
                          Text(
                            'آمنة ومشفرة',
                            style: TextStyle(
                                color: Colors.white54, fontSize: 10.sp),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Controls
              Positioned(
                  bottom: 40.h,
                  left: 0,
                  right: 0,
                  child: _buildControls(controller)),
            ],
          ),
        ));
  }

  void _handleBack() {
    Get.back();
    controller.endCall();
  }

  Widget _buildControls(GoLiveController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _controlButton(
          icon: Iconsax.refresh,
          onPressed: controller.switchCamera,
          color: Colors.white24,
        ),
        SizedBox(width: 20.w),
        Obx(() => _controlButton(
              icon: controller.isAudioEnabled.value
                  ? Iconsax.microphone_2
                  : Iconsax.microphone_slash,
              onPressed: controller.toggleAudio,
              color: controller.isAudioEnabled.value
                  ? Colors.white24
                  : Colors.orange,
            )),
        SizedBox(width: 20.w),
        _controlButton(
          icon: Iconsax.call_remove5,
          onPressed: () {
            // الخروج مباشرة لتفادي وميض شاشة (جاري الاتصال) ثم مسح الموارد بالخلفية
            Get.back();
            controller.endCall();
          },
          color: Colors.redAccent,
          isLarge: true,
        ),
      ],
    );
  }

  Widget _controlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
    bool isLarge = false,
  }) {
    return ZoomIn(
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: EdgeInsets.all(isLarge ? 20.r : 15.r),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2)
            ],
          ),
          child: Icon(icon, color: Colors.white, size: isLarge ? 30.sp : 24.sp),
        ),
      ),
    );
  }
}

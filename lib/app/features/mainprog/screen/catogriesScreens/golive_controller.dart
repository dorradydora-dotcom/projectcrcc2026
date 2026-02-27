import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:amiraly/app/common/models/appmodels.dart';
import 'package:amiraly/app/util/constant/constants.dart';
import 'package:amiraly/core/services/call_notification_service.dart';

class GoLiveController extends GetxController {
  final RxList<StationModelCall> users = <StationModelCall>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isAccessDenied = false.obs;
  final RxBool canInitiateCalls = false.obs;
  final RxBool isVideoEnabled = true.obs;
  final RxBool isAudioEnabled = true.obs;
  final Rx<String?> errorMessage = Rx<String?>(null);

  // Audio players
  final AudioPlayer _ringPlayer = AudioPlayer();
  final AudioPlayer _effectPlayer = AudioPlayer();

  // Constants
  String get _appId => dotenv.env['AGORA_APP_ID'] ?? '';

  static const List<String> _excludedStations = [
    'عبور3/عاشر',
    'برقاش/ابوغالب',
    'قليوب/قناطر',
    'الكريمات/بنى سويف',
    'ابو زعبل/بلبيس',
  ];

  // Sound paths
  static const String ringSound = 'lib/assets/sounds/ring.mp3';
  static const String connectSound = 'lib/assets/sounds/connect.mp3';
  static const String hangupSound = 'lib/assets/sounds/hangup.mp3';

  // Signaling state
  final Rx<String?> currentCallId = Rx<String?>(null);
  final Rx<Map<String, dynamic>?> incomingCall =
      Rx<Map<String, dynamic>?>(null);
  StreamSubscription? _signalingSubscription;
  Timer? _timeoutTimer;

  RtcEngine? _engine;
  RtcEngine? get engine => _engine;

  // Persistent Controllers to prevent flickering/noise on rebuild
  final Rx<VideoViewController?> localViewController =
      Rx<VideoViewController?>(null);
  final Rx<VideoViewController?> remoteViewController =
      Rx<VideoViewController?>(null);

  final Rx<int?> remoteUid = Rx<int?>(null);
  final RxBool localUserJoined = false.obs;

  @override
  void onInit() {
    super.onInit();
    checkAccess();
    fetchUsers();
    // startSignaling() is now handled globally by GlobalCallService

    // Check if we opened the page from a call notification or global navigation
    if (Get.arguments != null && Get.arguments is Map) {
      final data = Get.arguments as Map<String, dynamic>;
      if (data['route'] == 'call' && data['call_id'] != null) {
        // Pre-fill incoming call to show the overlay immediately
        incomingCall.value = {
          'id': data['call_id'],
          'caller_id': data['caller_id'],
          'channel_name': data['channel_name'],
          'status': 'ringing',
        };
        currentCallId.value = data['call_id'];
        playRinging();
      }
    }
  }

  Future<void> fetchUsers() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      final response = await Supabase.instance.client
          .from(AppConstants.tableUserStations)
          .select();

      final List<dynamic> data = response;
      final fetched =
          data.map((json) => StationModelCall.fromJson(json)).where((user) {
        final name = user.stationName ?? '';
        return !_excludedStations.any(
            (excluded) => name.contains(excluded) || excluded.contains(name));
      }).toList();

      fetched
          .sort((a, b) => (a.stationName ?? '').compareTo(b.stationName ?? ''));

      for (var u in fetched) {
        debugPrint('Fetched User: ${u.stationName}, ID: ${u.id}');
      }

      users.assignAll(fetched);
    } catch (e) {
      errorMessage.value = 'Failed to load users: $e';
      users.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> checkAccess() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || user.email == null) {
      isAccessDenied.value = true;
      return;
    }

    try {
      final email = user.email!;
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

      final inTop = results[0].isNotEmpty;
      final inCrcc = results[1].isNotEmpty;
      final inStations = results[2].isNotEmpty;

      isAccessDenied.value = !inTop && !inCrcc && !inStations;
      canInitiateCalls.value = inTop || inCrcc;
    } catch (e) {
      isAccessDenied.value = true;
      debugPrint('Error checking GoLive access: $e');
    }
  }

  Future<void> initializeAgora() async {
    try {
      final statuses =
          await [Permission.microphone, Permission.camera].request();

      if (statuses[Permission.microphone] != PermissionStatus.granted ||
          statuses[Permission.camera] != PermissionStatus.granted) {
        throw 'يجب منح صلاحيات الميكروفون والكاميرا لبدء البث';
      }

      if (_appId.isEmpty) {
        throw 'Agora App ID is missing. Please check your .env file.';
      }

      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: _appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint("local user ${connection.localUid} joined");
            localUserJoined.value = true;
          },
          onUserJoined: (RtcConnection connection, int uid, int elapsed) {
            debugPrint("remote user $uid joined");
            remoteUid.value = uid;

            // Initialize persistent remote controller
            remoteViewController.value = VideoViewController.remote(
              rtcEngine: _engine!,
              canvas: VideoCanvas(uid: uid),
              connection: connection,
            );

            stopRinging();
            playConnect();
          },
          onUserOffline: (RtcConnection connection, int uid,
              UserOfflineReasonType reason) {
            debugPrint("remote user $uid left channel");
            remoteUid.value = null;
            remoteViewController.value = null;
          },
          onError: (ErrorCodeType err, String msg) {
            debugPrint('Agora Error: $err, $msg');
          },
        ),
      );

      await _engine!.enableVideo();
      await _engine!.enableLocalVideo(true);
      await _engine!.startPreview();

      await _engine!
          .setLocalVideoMirrorMode(VideoMirrorModeType.videoMirrorModeEnabled);

      localViewController.value = VideoViewController(
        rtcEngine: _engine!,
        canvas: const VideoCanvas(
          uid: 0,
          renderMode: RenderModeType.renderModeFit,
        ),
      );

      debugPrint("Agora Quality Config: Default Auto Configured.");
    } catch (e) {
      debugPrint('Error initializing Agora: $e');
      rethrow;
    }
  }

  Future<String> _fetchSecureToken(String channelName) async {
    return '';
  }

  Future<void> joinChannel(String channelName) async {
    try {
      if (_engine == null) {
        await initializeAgora();
      } else {
        await _engine!.enableVideo();
        await _engine!.enableLocalVideo(true);
        await _engine!.startPreview();

        localViewController.value = VideoViewController(
          rtcEngine: _engine!,
          canvas: const VideoCanvas(
            uid: 0,
            renderMode: RenderModeType.renderModeFit,
          ),
        );
      }

      // Re-ensure role for stability
      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

      final token = await _fetchSecureToken(channelName);

      await _engine!.joinChannel(
        token: token,
        channelId: channelName,
        uid: 0,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          publishCameraTrack: true,
          publishMicrophoneTrack: true,
        ),
      );
    } catch (e) {
      debugPrint('Error joining channel: $e');
      rethrow;
    }
  }

  Future<void> leaveChannel() async {
    try {
      if (_engine != null) {
        await _engine!.stopPreview();
        await _engine!.leaveChannel();
        localUserJoined.value = false;
        remoteUid.value = null;
        remoteViewController.value = null;
        localViewController.value = null;
      }
    } catch (e) {
      debugPrint('Error leaving channel: $e');
    }
  }

  Future<void> toggleVideo() async {
    if (_engine == null) return;

    isVideoEnabled.value = !isVideoEnabled.value;

    if (isVideoEnabled.value) {
      await _engine!.enableLocalVideo(true);
      await _engine!.startPreview();
      localViewController.value = VideoViewController(
        rtcEngine: _engine!,
        canvas: const VideoCanvas(
          uid: 0,
          renderMode: RenderModeType.renderModeFit,
        ),
      );
    } else {
      await _engine!.enableLocalVideo(false);
      await _engine!.stopPreview();
      localViewController.value = null;
    }
    // Update publishing state if we are already in a channel (currentCallId exists)
    if (currentCallId.value != null) {
      await _engine!.updateChannelMediaOptions(
        ChannelMediaOptions(
          publishCameraTrack: isVideoEnabled.value,
        ),
      );
    }
  }

  Future<void> toggleAudio() async {
    if (_engine == null) return;
    isAudioEnabled.value = !isAudioEnabled.value;
    await _engine!.enableLocalAudio(isAudioEnabled.value);

    if (currentCallId.value != null) {
      await _engine!.updateChannelMediaOptions(
        ChannelMediaOptions(
          publishMicrophoneTrack: isAudioEnabled.value,
        ),
      );
    }
  }

  Future<void> switchCamera() async {
    if (_engine == null) return;
    await _engine!.switchCamera();
  }

  String? get currentUserId => Supabase.instance.client.auth.currentUser?.id;

  Future<String?> _getReceiverToken(String receiverId) async {
    final supabase = Supabase.instance.client;
    const tables = [
      AppConstants.tableUserStations,
      AppConstants.tableUserCrcc,
      AppConstants.tableUserTop,
      'user_others',
      'user_cm',
    ];

    for (final table in tables) {
      try {
        final data = await supabase
            .from(table)
            .select('user_token')
            .eq('id', receiverId)
            .maybeSingle();

        if (data != null && data['user_token'] != null) {
          return data['user_token'] as String;
        }
      } catch (e) {
        continue;
      }
    }
    return null;
  }

  Future<String> _getUserName(String userId) async {
    final supabase = Supabase.instance.client;
    const tables = [
      AppConstants.tableUserStations,
      AppConstants.tableUserCrcc,
      AppConstants.tableUserTop,
      'user_others',
      'user_cm',
    ];

    for (final table in tables) {
      try {
        final data = await supabase
            .from(table)
            .select('station_name')
            .eq('id', userId)
            .maybeSingle();

        if (data != null && data['station_name'] != null) {
          return data['station_name'] as String;
        }
      } catch (e) {
        continue;
      }
    }
    return 'محطة مجهولة';
  }

  /*
  Future<void> startSignaling() async {
    // Logic moved to GlobalCallService
  }
  */

  Future<void> makeCall(String receiverId) async {
    final userId = currentUserId;
    if (userId == null) {
      throw 'يجب تسجيل الدخول أولاً';
    }

    debugPrint('Initiating call: Caller=$userId, Receiver=$receiverId');

    try {
      // 1. Get receiver token
      final receiverToken = await _getReceiverToken(receiverId);

      // 2. Insert signaling record
      final response = await Supabase.instance.client
          .from(AppConstants.tableCallsSignaling)
          .insert({
            'caller_id': userId,
            'receiver_id': receiverId,
            'channel_name': userId,
            'status': 'ringing',
          })
          .select()
          .single();

      currentCallId.value = response['id'];

      // 3. Send Dedicated Call Push Notification
      if (receiverToken != null) {
        final callerName = await _getUserName(userId);
        await CallNotificationService.sendCallNotification(
          deviceToken: receiverToken,
          title: 'مكالمة واردة 📞',
          body: 'مكالمة فيديو واردة',
          callId: response['id'],
          callerName: callerName,
          channelName: userId,
        );
      }

      await joinChannel(userId);

      _timeoutTimer?.cancel();
      _timeoutTimer = Timer(const Duration(seconds: 30), () {
        if (currentCallId.value != null &&
            (incomingCall.value == null ||
                incomingCall.value!['status'] == 'ringing')) {
          debugPrint('Call timed out after 30 seconds');
          endCall();
        }
      });

      Supabase.instance.client
          .from(AppConstants.tableCallsSignaling)
          .stream(primaryKey: ['id'])
          .eq('id', currentCallId.value!)
          .listen((data) {
            if (data.isNotEmpty) {
              final status = data.first['status'];
              if (status == 'rejected' || status == 'ended') {
                stopRinging();
                playHangup();
                leaveChannel();
                currentCallId.value = null;
              } else if (status == 'accepted') {
                stopRinging();
              }
            }
          });
    } catch (e) {
      debugPrint('Error making call: $e');
      rethrow;
    }
  }

  Future<void> respondToCall(String callId, bool accept) async {
    try {
      await Supabase.instance.client
          .from(AppConstants.tableCallsSignaling)
          .update({'status': accept ? 'accepted' : 'rejected'}).eq(
              'id', callId);

      if (accept) {
        stopRinging();
        final call = incomingCall.value;
        if (call != null) {
          await joinChannel(call['channel_name']);
        }
      } else {
        stopRinging();
        playHangup();
        incomingCall.value = null;
        currentCallId.value = null;
      }
    } catch (e) {
      debugPrint('Error responding to call: $e');
    }
  }

  Future<void> endCall() async {
    _timeoutTimer?.cancel();
    if (currentCallId.value != null) {
      try {
        await Supabase.instance.client
            .from(AppConstants.tableCallsSignaling)
            .update({'status': 'ended'}).eq('id', currentCallId.value!);
      } catch (e) {
        debugPrint('Error ending call record: $e');
      }
    }
    stopRinging();
    playHangup();
    await leaveChannel();
    currentCallId.value = null;
    incomingCall.value = null;
  }

  Future<void> disposeAgora() async {
    try {
      if (_engine != null) {
        await _engine!.release();
        _engine = null;
      }
      localViewController.value = null;
      remoteViewController.value = null;
    } catch (e) {
      debugPrint('Error disposing Agora: $e');
    }
  }

  // Sound helpers
  void playRinging() {
    try {
      AudioCache.instance.prefix = '';
      _ringPlayer.setReleaseMode(ReleaseMode.loop);
      _ringPlayer.play(AssetSource(ringSound));
    } catch (e) {
      debugPrint('Error playing ring sound: $e');
    }
  }

  void stopRinging() {
    try {
      _ringPlayer.stop();
    } catch (e) {
      debugPrint('Error stopping ring sound: $e');
    }
  }

  void playConnect() {
    try {
      AudioCache.instance.prefix = '';
      _effectPlayer.play(AssetSource(connectSound));
    } catch (e) {
      debugPrint('Error playing connect sound: $e');
    }
  }

  void playHangup() {
    try {
      AudioCache.instance.prefix = '';
      _effectPlayer.play(AssetSource(hangupSound));
    } catch (e) {
      debugPrint('Error playing hangup sound: $e');
    }
  }

  @override
  void onClose() {
    _ringPlayer.stop();
    _ringPlayer.dispose();
    _effectPlayer.stop();
    _effectPlayer.dispose();
    _signalingSubscription?.cancel();
    disposeAgora();
    super.onClose();
  }
}

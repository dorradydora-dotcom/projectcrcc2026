import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:amiraly/app/common/models/appmodels.dart' hide Event;
import 'package:amiraly/app/common/widgets/appbar.dart';
import 'package:amiraly/app/util/constant/constants.dart';
import 'package:amiraly/app/util/validators/validator_helper.dart';

// --- Services Consolidated Here ---

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
          // We remove the high-level 'notification' block to make it a 'data-only' message.
          // This prevents the OS from showing a simple text notification and lets our
          // background handler trigger CallKit.
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

class GlobalCallService extends GetxService {
  static GlobalCallService get to => Get.find();

  StreamSubscription? _signalingSubscription;
  final Rx<String?> currentCallId = Rx<String?>(null);

  @override
  void onInit() {
    super.onInit();
    startListening();
    _listenToCallkitEvents();
  }

  void _listenToCallkitEvents() {
    FlutterCallkitIncoming.onEvent.listen((event) async {
      switch (event!.event) {
        case Event.actionCallIncoming:
          // Received incoming call
          break;
        case Event.actionCallAccept:
          // User accepted the call from native UI
          final data = event.body['extra'];
          if (data != null && data['route'] == 'call') {
            _navigateToCall({...data, 'accepted': true});
          }
          break;
        case Event.actionCallDecline:
          // User declined the call from native UI
          final data = event.body['extra'];
          if (data != null && data['call_id'] != null) {
            await Supabase.instance.client
                .from(AppConstants.tableCallsSignaling)
                .update({'status': 'rejected'}).eq('id', data['call_id']);
          }
          break;
        case Event.actionCallEnded:
          // Call ended from native UI
          break;
        case Event.actionCallTimeout:
          // Call timed out
          break;
        default:
          break;
      }
    });
  }

  void startListening() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
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

// --- Controller and UI ---

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
        currentCallId.value = data['call_id'];
        if (data['accepted'] == true) {
          // If already accepted via CallKit, just join
          respondToCall(data['call_id'], true);
        } else {
          // Pre-fill incoming call to show the overlay
          incomingCall.value = {
            'id': data['call_id'],
            'caller_id': data['caller_id'],
            'channel_name': data['channel_name'],
            'status': 'ringing',
          };
          playRinging();
        }
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

      // Set high quality video configuration
      await _engine!.setVideoEncoderConfiguration(
        const VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 640, height: 480),
          frameRate: 15,
          bitrate: 800,
          orientationMode: OrientationMode.orientationModeAdaptive,
        ),
      );

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
    // IMPORTANT: For production, you MUST use a token server to generate
    // secure tokens. Agora tokens are required by default for new projects.
    // To test WITHOUT tokens during development:
    // 1. Go to Agora Console (console.agora.io)
    // 2. Select your Project -> Features -> Primary Certificate -> "No certificate" or "Disable".
    // 3. This will allow joining channels with an empty string ('') as token.

    // If you have a token server, implement the fetch logic here:
    /*
    final response = await http.get(Uri.parse('YOUR_TOKEN_SERVER_URL/token?channel=$channelName'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['token'];
    }
    */
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

      debugPrint('Fetching token for channel: $channelName');
      final token = await _fetchSecureToken(channelName);

      debugPrint(
          'Joining channel: $channelName with token length: ${token.length}');
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
    } catch (e, stack) {
      debugPrint('Error joining channel: $e');
      AppLogger.logError('Agora Join Error', e, stack);
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

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(GoLiveController());

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
                                                                            .ChangaBold,
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
                                                                          .ChangaBold,
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
                                                              'مجهول',
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
            Obx(() => _buildIncomingCallOverlay(context, controller)),
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: SpinKitCubeGrid(color: Appcolors.secondaryColor, size: 50.r),
      ),
    );

    try {
      await controller.makeCall(receiverId);

      if (context.mounted) {
        Navigator.pop(context);
        controller.playRinging();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoCallPage(
                controller: controller,
                channelName: controller.currentUserId ?? 'g-live'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start call: $e')),
        );
      }
    }
  }

  Widget _buildIncomingCallOverlay(
      BuildContext context, GoLiveController controller) {
    final call = controller.incomingCall.value;
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
                            onPressed: () =>
                                controller.respondToCall(call['id'], false),
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
                              controller.respondToCall(call['id'], true);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => VideoCallPage(
                                      controller: controller,
                                      channelName: call['channel_name']),
                                ),
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) {
            return;
          }
          await _onWillPop(context);
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: _remoteVideo(controller),
            ),
            // Header Positioned
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: FadeInDown(
                child: Container(
                  padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 10,
                      bottom: 15,
                      left: 20,
                      right: 20),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios,
                            color: Colors.white),
                        onPressed: () => _onWillPop(context),
                      ),
                      const Spacer(),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('بث مباشر',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12.sp,
                                        fontFamily: Appfontstring.ChangaLight)),
                                SizedBox(width: 8.w),
                                Pulse(
                                    infinite: true,
                                    child: Container(
                                        width: 8.w,
                                        height: 8.w,
                                        decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle))),
                              ],
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text("Connection Secured by (RtcEngine)",
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 10.sp)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Local Video Preview
            Obx(() {
              if (controller.isVideoEnabled.value &&
                  controller.localViewController.value != null) {
                return Positioned(
                  top: 100,
                  right: 20,
                  child: Container(
                    width: 110.w,
                    height: 160.h,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3), width: 2),
                    ),
                    child: AgoraVideoView(
                      controller: controller.localViewController.value!,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),

            // Controls
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: FadeInUp(
                child: _buildControls(context, controller),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context, GoLiveController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Obx(() => _buildControlButton(
              icon: controller.isAudioEnabled.value
                  ? Iconsax.microphone_2
                  : Iconsax.microphone_slash,
              color: controller.isAudioEnabled.value
                  ? Colors.white24
                  : Colors.redAccent.withValues(alpha: 0.8),
              onPressed: () => controller.toggleAudio(),
            )),
        SizedBox(width: 15.w),
        _buildControlButton(
          icon: Iconsax.refresh,
          color: Colors.white24,
          onPressed: () => controller.switchCamera(),
        ),
        SizedBox(width: 15.w),
        _buildControlButton(
          icon: Iconsax.call_remove5,
          color: Colors.redAccent,
          isLarge: true,
          onPressed: () => _onWillPop(context),
        ),
        SizedBox(width: 15.w),
        Obx(() => _buildControlButton(
              icon: controller.isVideoEnabled.value
                  ? Iconsax.camera5
                  : Iconsax.camera_slash,
              color: controller.isVideoEnabled.value
                  ? Colors.white24
                  : Colors.redAccent.withValues(alpha: 0.8),
              onPressed: () => controller.toggleVideo(),
            )),
      ],
    );
  }

  Widget _buildControlButton(
      {required IconData icon,
      required Color color,
      bool isLarge = false,
      required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: isLarge ? 70.w : 55.w,
        height: isLarge ? 70.w : 55.w,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: isLarge ? 32.sp : 24.sp),
      ),
    );
  }

  Future<void> _onWillPop(BuildContext context) async {
    await controller.endCall();
    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  Widget _remoteVideo(GoLiveController controller) {
    return Obx(() {
      if (controller.remoteViewController.value != null &&
          controller.remoteUid.value != null) {
        return SizedBox.expand(
          child: AgoraVideoView(
            controller: controller.remoteViewController.value!,
          ),
        );
      } else {
        return Container(
          color: const Color(0xFF0F172A),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SpinKitRipple(
                color: Colors.white.withValues(alpha: 0.3),
                size: 100.r,
              ),
              SizedBox(height: 20.h),
              Text(
                'بانتظار انضمام المحــطة',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14.sp,
                  fontFamily: Appfontstring.ChangaLight,
                ),
              ),
            ],
          ),
        );
      }
    });
  }
}

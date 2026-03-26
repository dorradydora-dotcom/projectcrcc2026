import 'dart:async' show StreamSubscription, Timer, unawaited;
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
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:amiraly/core/services/call_service.dart';
import 'package:amiraly/app/common/models/appmodels.dart' hide Event;
import 'package:amiraly/app/common/widgets/appbar.dart';
import 'package:amiraly/app/util/constant/constants.dart';
import 'package:amiraly/app/util/validators/validator_helper.dart';

// --- Services Consolidated Here ---

// --- Services moved to call_service.dart ---

// --- Controller and UI ---

class GoLiveController extends GetxController {
  final RxList<StationModelCall> users = <StationModelCall>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isAccessDenied = false.obs;
  final RxBool canInitiateCalls = false.obs;
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
  // incomingCall removed - now handled by GlobalCallService
  StreamSubscription? _signalingSubscription;
  Timer? _timeoutTimer;

  RtcEngine? _engine;

  RtcEngine? get engine => _engine;

  // Persistent Controllers to prevent flickering/noise on rebuild
  final localUserJoined = false.obs;
  final remoteUid = Rxn<int>();
  final localViewController = Rxn<VideoViewController>();
  final remoteViewController = Rxn<VideoViewController>();
  final isLocalVideoReady = false.obs;
  final isRemoteVideoReady = false.obs;
  final isAudioEnabled = true.obs;
  final isVideoEnabled = true.obs;

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
          // Immediately respond and navigate
          unawaited(respondToCall(data['call_id'], true));
          Get.to(
            () => VideoCallPage(
              controller: this,
              channelName: data['channel_name'],
            ),
          );
        } else {
          playRinging();
        }
      }
    }
    
    // Listen to global incoming calls reactively
    ever(GlobalCallService.to.incomingCall, (call) {
      if (call != null && call['status'] == 'ringing') {
        playRinging();
      } else {
        stopRinging();
      }
    });
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
    isLocalVideoReady.value = false;
    isRemoteVideoReady.value = false;
    try {
      // 1. Request permissions first
      final status = await [Permission.camera, Permission.microphone].request();
      if (status[Permission.camera] != PermissionStatus.granted ||
          status[Permission.microphone] != PermissionStatus.granted) {
        debugPrint("!!! Permissions Denied: $status !!!");
        throw 'يجب منح صلاحيات الكاميرا والميكروفون لبدء المكالمة';
      }

      if (_engine == null) {
        debugPrint("Creating new Agora engine...");
        _engine = createAgoraRtcEngine();
        await _engine!.initialize(RtcEngineContext(
          appId: _appId,
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        ));

        _engine!.registerEventHandler(
          RtcEngineEventHandler(
            onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
              debugPrint("local user ${connection.localUid} joined");
              localUserJoined.value = true;
            },
            onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
              debugPrint("Remote user $remoteUid joined");
              this.remoteUid.value = remoteUid;
              remoteViewController.value = VideoViewController.remote(
                rtcEngine: _engine!,
                canvas: VideoCanvas(
                  uid: remoteUid,
                  renderMode: RenderModeType.renderModeHidden,
                ),
                connection: connection,
              );
              stopRinging();
            },
            onUserOffline: (RtcConnection connection, int uid,
                UserOfflineReasonType reason) {
              debugPrint("Remote user $uid left: $reason");
              remoteUid.value = null;
              remoteViewController.value = null;
              isRemoteVideoReady.value = false;
            },
            onError: (ErrorCodeType err, String msg) {
              debugPrint('Agora Error: $err, $msg');
              String userFriendlyError = 'حدث خطأ في مكالمة الفيديو ($err)';
              if (err == ErrorCodeType.errInvalidAppId) {
                userFriendlyError = 'خطأ في الـ Agora App ID. يرجى التحقق من لوحة التحكم.';
              } else if (err == ErrorCodeType.errInvalidToken || err == ErrorCodeType.errTokenExpired) {
                userFriendlyError = 'انتهت صلاحية الـ Token أو غير صالح. التطبيق يحتاج لـ Token جديد.';
              } else if (err == ErrorCodeType.errConnectionLost) {
                userFriendlyError = 'فقد الاتصال بالشبكة.';
              }
              
              Get.snackbar(
                'خطأ في الاتصال',
                userFriendlyError,
                snackPosition: SnackPosition.TOP,
                backgroundColor: Colors.red.withOpacity(0.8),
                colorText: Colors.white,
                duration: const Duration(seconds: 5),
              );
            },
            onLocalVideoStateChanged: (VideoSourceType source, LocalVideoStreamState state, LocalVideoStreamReason reason) {
              debugPrint('Local Video State: $state, Reason: $reason');
            },
            onFirstLocalVideoFrame: (VideoSourceType source, int width, int height, int elapsed) {
              debugPrint('First local video frame: ${width}x${height}');
            },
          ),
        );
      }

      // 2. Configure video/audio
      await _engine!.enableVideo();
      await _engine!.enableLocalVideo(true);
      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

      // --- Optimization for Noise/Quality ---
      // 1. Explicitly set video encoder configuration
      await _engine!.setVideoEncoderConfiguration(
        const VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 640, height: 480),
          frameRate: 15,
          bitrate: 1000,
          orientationMode: OrientationMode.orientationModeAdaptive,
          degradationPreference: DegradationPreference.maintainQuality,
        ),
      );

      // 4. Enable Color Enhancement
      await _engine!.setColorEnhanceOptions(
        enabled: true,
        options: const ColorEnhanceOptions(
          strengthLevel: 0.5,
          skinProtectLevel: 0.5,
        ),
      );

      // 5. Set Camera Capturer Configuration to match encoder
      await _engine!.setCameraCapturerConfiguration(
        const CameraCapturerConfiguration(
          cameraDirection: CameraDirection.cameraRear,
          format: VideoFormat(width: 640, height: 480, fps: 15),
        ),
      );
      // --------------------------------------

      // Stop preview if already running to avoid "stale" preview locks
      try {
        await _engine!.stopPreview();
      } catch (_) {}

      // 6. Start preview FIRST to prime the camera
      await _engine!.startPreview();

      // 7. Explicitly setup local video
      await _engine!.setupLocalVideo(const VideoCanvas(
          uid: 0,
          renderMode: RenderModeType.renderModeHidden,
          mirrorMode: VideoMirrorModeType.videoMirrorModeAuto,
      ));

      // 8. Setup local view controller (SurfaceView is more stable for full-screen)
      localViewController.value = VideoViewController(
        rtcEngine: _engine!,
        canvas: const VideoCanvas(
          uid: 0,
          renderMode: RenderModeType.renderModeHidden,
        ),
        useAndroidSurfaceView: true,
      );
      
      // Give the hardware a moment to stabilize the frame
      await Future.delayed(const Duration(milliseconds: 300));
      
      debugPrint("!!! Agora preview started and primed successfully !!!");
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
      await initializeAgora();

      debugPrint('Joining channel: $channelName');
      await _engine!.joinChannel(
        token: await _fetchSecureToken(channelName),
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
        await _engine!.leaveChannel();
        localUserJoined.value = false;
        remoteUid.value = null;
        remoteViewController.value = null;
      }
    } catch (e) {
      debugPrint('Error leaving channel: $e');
    }
  }

  Future<void> toggleAudio() async {
    if (_engine == null) return;
    debugPrint('Toggle Audio: Current value = ${isAudioEnabled.value}');
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
    debugPrint('!!! TRIGGER: switchCamera() called !!!');
    if (_engine == null) {
      debugPrint('!!! ERROR: switchCamera failed - Engine is NULL !!!');
      return;
    }
    try {
      await _engine!.switchCamera();
      debugPrint('!!! SUCCESS: switchCamera completed !!!');
    } catch (e) {
      debugPrint('!!! EXCEPTION in switchCamera: $e');
      Get.snackbar(
        'خطأ',
        'فشل تحويل الكاميرا: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.7),
        colorText: Colors.white,
      );
    }
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
    return 'محطة ';
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
          body: 'مكالمة فيديو واردة من $callerName',
          callId: response['id'],
          callerName: callerName,
          channelName: userId,
        );
      }

      _timeoutTimer?.cancel();
      _timeoutTimer = Timer(const Duration(seconds: 30), () {
        if (currentCallId.value != null &&
            (GlobalCallService.to.incomingCall.value == null ||
                GlobalCallService.to.incomingCall.value!['status'] == 'ringing')) {
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
        final call = GlobalCallService.to.incomingCall.value;
        if (call != null) {
          await joinChannel(call['channel_name']);
        } else if (Get.arguments is Map &&
            Get.arguments['channel_name'] != null) {
          // Fallback to arguments if incomingCall is null (e.g. cold start)
          await joinChannel(Get.arguments['channel_name']);
        }
      } else {
        stopRinging();
        playHangup();
        GlobalCallService.to.incomingCall.value = null;
        currentCallId.value = null;
      }
    } catch (e) {
      debugPrint('Error responding to call: $e');
    }
  }

  Future<void> endCall() async {
    debugPrint('Ending Call...');
    _timeoutTimer?.cancel();
    if (currentCallId.value != null) {
      try {
        // Find if we were the caller and notify receiver to stop ringing
        final callRecord = await Supabase.instance.client
            .from(AppConstants.tableCallsSignaling)
            .select('caller_id, receiver_id')
            .eq('id', currentCallId.value!)
            .maybeSingle();

        if (callRecord != null && callRecord['caller_id'] == currentUserId) {
          final receiverToken =
              await _getReceiverToken(callRecord['receiver_id']);
          if (receiverToken != null) {
            await CallNotificationService.sendCancelNotification(
              deviceToken: receiverToken,
              callId: currentCallId.value!,
            );
          }
        }

        await Supabase.instance.client
            .from(AppConstants.tableCallsSignaling)
            .update({'status': 'ended'}).eq('id', currentCallId.value!);
        debugPrint('Signaling record updated to ended');
      } catch (e) {
        debugPrint('Error ending call record: $e');
      }
    }
    stopRinging();
    playHangup();
    await leaveChannel();
    localViewController.value = null; // Essential cleanup
    remoteViewController.value = null; // Essential cleanup
    currentCallId.value = null;
    GlobalCallService.to.incomingCall.value = null;
    debugPrint('Call Ended Cleanly');
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
    debugPrint('GoLiveController onClose called!');
    debugPrint(StackTrace.current.toString());
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
    final controller = Get.put(GoLiveController(), permanent: true);

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
                                                                .withOpacity(
                                                                    0.2),
                                                            shape:
                                                                BoxShape.circle,
                                                            border: Border.all(
                                                                color: Colors
                                                                    .blue
                                                                    .withOpacity(
                                                                        0.5),
                                                                width: 1),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: Colors
                                                                    .blue
                                                                    .withOpacity(
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
            Obx(() => _buildIncomingCallOverlay(context, controller, GlobalCallService.to.incomingCall.value)),
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
            border:
                Border.all(color: Colors.orange.withValues(alpha: 0.5), width: 1.5.w),
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
      () => VideoCallPage(
          controller: controller,
          channelName: controller.currentUserId ?? 'g-live'),
    );

    try {
      // 2. Initialize Agora in the background while the user is on the VideoCallPage
      await controller.initializeAgora();
      
      // 3. Start ringing and trigger the call
      controller.playRinging();
      await controller.makeCall(receiverId);
      await controller.joinChannel(controller.currentUserId ?? 'g-live');
    } catch (e) {
      Get.back(); // Return to users page on failure
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل بدء المكالمة: $e')),
        );
      }
    }
  }

  Widget _buildIncomingCallOverlay(
      BuildContext context, GoLiveController controller, Map<String, dynamic>? call) {
    if (call == null) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: FadeIn(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: ZoomIn(
                child: Container(
                  width: 0.8.sw,
                  padding: EdgeInsets.all(25.r),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(30.r),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
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
    debugPrint('Building VideoCallPage for channel: $channelName');
    debugPrint(
        '!!! VideoCallPage localViewController: ${controller.localViewController.value != null} !!!');
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
              // Only show the small box if remote user IS present
              if (controller.localViewController.value != null &&
                  controller.isRemoteVideoReady.value) {
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
                      key: ValueKey('corner_preview_${controller.localViewController.value.hashCode}'),
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
              label: 'صوت',
              color: controller.isAudioEnabled.value
                  ? Colors.white24
                  : Colors.redAccent.withValues(alpha: 0.8),
              onPressed: () => controller.toggleAudio(),
            )),
        SizedBox(width: 40.w),
        _buildControlButton(
          icon: Iconsax.refresh,
          label: 'تبديل',
          color: Colors.white24,
          onPressed: () => controller.switchCamera(),
        ),
        SizedBox(width: 40.w),
        _buildControlButton(
          icon: Iconsax.call_remove5,
          label: 'إنهاء',
          color: Colors.redAccent,
          isLarge: true,
          onPressed: () => _onWillPop(context),
        ),
      ],
    );
  }

  Widget _buildControlButton(
      {required IconData icon,
      required String label,
      required Color color,
      bool isLarge = false,
      required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isLarge ? 65.w : 50.w,
            height: isLarge ? 65.w : 50.w,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child:
                Icon(icon, color: Colors.white, size: isLarge ? 28.sp : 20.sp),
          ),
          SizedBox(height: 5.h),
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10.sp,
              fontFamily: Appfontstring.ChangaLight,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onWillPop(BuildContext context) async {
    debugPrint('_onWillPop triggered');
    await controller.endCall();
    if (context.mounted) {
      Get.back();
    }
  }

  Widget _remoteVideo(GoLiveController controller) {
    return Obx(() {
      // 1. Show Remote Video if it's joined AND starting to stream
      if (controller.remoteViewController.value != null &&
          controller.isRemoteVideoReady.value) {
        return SizedBox.expand(
          child: AgoraVideoView(
            key: ValueKey('remote_bg_${controller.remoteViewController.value.hashCode}'),
            controller: controller.remoteViewController.value!,
          ),
        );
      }
      
      // 2. Otherwise show Local Video full screen (as background) 
      // ONLY if the engine says the local frame is ready
      if (controller.localViewController.value != null && 
          controller.isLocalVideoReady.value) {
        return SizedBox.expand(
          child: AgoraVideoView(
            key: ValueKey('local_bg_${controller.localViewController.value.hashCode}'),
            controller: controller.localViewController.value!,
          ),
        );
      }
      
      // 3. Last fallback: Premium Gradient Background
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
              color: Colors.white.withOpacity(0.3),
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
    });
  }
}

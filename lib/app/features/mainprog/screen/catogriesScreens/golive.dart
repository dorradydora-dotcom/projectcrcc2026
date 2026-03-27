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
import 'package:amiraly/app/common/models/appmodels.dart';
import 'package:amiraly/app/common/widgets/appbar.dart';
import 'package:amiraly/app/util/constant/constants.dart';
import 'package:amiraly/core/services/call_service.dart';

class GoLiveController extends GetxController {
  final RxList<StationModelCall> users = <StationModelCall>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isAccessDenied = false.obs;
  final RxBool canInitiateCalls = false.obs;
  final Rx<String?> errorMessage = Rx<String?>(null);

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

  final Rx<String?> currentCallId = Rx<String?>(null);

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

  @override
  void onInit() {
    super.onInit();

    ever(GlobalCallService.to.incomingCall, (call) {
      if (call != null && call['status'] == 'ringing') {
        playRinging();
      } else {
        stopRinging();
      }
    });
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
      final status = await [Permission.camera, Permission.microphone].request();
      if (status[Permission.camera] != PermissionStatus.granted) {
        throw 'صلاحية الكاميرا مطلوبة';
      }
      if (status[Permission.microphone] != PermissionStatus.granted) {
        throw 'صلاحية الميكروفون مطلوبة';
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
              localUserJoined.value = true;
              isLocalVideoReady.value = true;
            },
            onUserJoined: (connection, uid, elapsed) {
              remoteUid.value = uid;
              isRemoteVideoReady.value = true;
              stopRinging();
              playConnect();
            },
            onUserOffline: (connection, uid, reason) {
              remoteUid.value = null;
              isRemoteVideoReady.value = false;
            },
          ),
        );
      }

      await _engine!.enableVideo();
      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      await _engine!.startPreview();

      localViewController.value = VideoViewController(
        rtcEngine: _engine!,
        canvas: const VideoCanvas(uid: 0),
        useFlutterTexture: true,
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
    return 'محطة';
  }

  Future<void> makeCall(String receiverId) async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      final callerToken = await _getReceiverToken(userId);
      final receiverToken = await _getReceiverToken(receiverId);

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

      currentCallId.value = response['id'];

      if (receiverToken != null) {
        final callerName = await _getUserName(userId);
        await CallNotificationService.sendCallNotification(
          deviceToken: receiverToken,
          title: 'مكالمة واردة 📞',
          body: 'مكالمة فيديو واردة من $callerName',
          callId: response['id'],
          callerName: callerName,
          channelName: receiverId,
        );
      }
      await joinChannel(receiverId, callerToken);
    } catch (e) {
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
          final myToken = await _getReceiverToken(currentUserId!);
          await joinChannel(call['channel_name'], myToken);
        }
      } else {
        stopRinging();
        currentCallId.value = null;
      }
    } catch (_) {}
  }

  Future<void> endCall() async {
    if (currentCallId.value != null) {
      await Supabase.instance.client
          .from(AppConstants.tableCallsSignaling)
          .update({'status': 'ended'}).eq('id', currentCallId.value!);
    }
    stopRinging();
    playHangup();
    await leaveChannel();
    currentCallId.value = null;
    GlobalCallService.to.incomingCall.value = null;
    localViewController.value = null;
    remoteViewController.value = null;
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
    return Scaffold(
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
                    connection: RtcConnection(channelId: channelName),
                    useFlutterTexture: true,
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
                    Text(
                      'جاري الاتصال...',
                      style: TextStyle(
                        fontFamily: Appfontstring.ChangaLight,
                        fontSize: 18.sp,
                        color: Colors.white70,
                      ),
                    ),
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
                  height: controller.remoteUid.value != null ? 180.h : 220.h,
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
                        style:
                            TextStyle(color: Colors.white54, fontSize: 10.sp),
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
    );
  }

  void _handleBack() {
    Get.back();
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
          onPressed: () async {
            await controller.endCall();
            Get.back();
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

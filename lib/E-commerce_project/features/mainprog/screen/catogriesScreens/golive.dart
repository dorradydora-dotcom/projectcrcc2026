import 'package:amiraly/E-commerce_project/common/widgets/appbar.dart';
import 'package:amiraly/E-commerce_project/util/constant/constants.dart';
import 'package:amiraly/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GoliveScreen extends StatelessWidget {
  const GoliveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(GoLiveController());

    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: const Color(0xFF0F172A),
      appBar: const CustomAppBar(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        heroTag: 'refresh_btn',
        onPressed: () {
          controller.fetchStations();
        },
        backgroundColor: C.blue,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Appcolors.primaryColor,
                Appcolors.primaryColor,
                Color(0xFF163C5E),
                Color(0xFF0F2B44),
                Color(0xFF081A2A)
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Obx(() {
            if (controller.isLoading.value) {
              return _buildShimmer();
            }

            if (!controller.hasAccess.value) {
              return _buildAccessDenied();
            }

            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  child: Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                          color: const Color.fromARGB(120, 255, 153, 0),
                          width: 1.w),
                      color: const Color.fromARGB(110, 0, 0, 0),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.video_call,
                            color: Colors.orange, size: 18.sp),
                        SizedBox(width: 8.w),
                        Text(
                          'مكالمات فيديو المحطات (${controller.stations.length})',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.orange,
                            fontFamily: Appfontstring.ChangaLight,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: controller.stations.isEmpty
                      ? _buildEmptyState()
                      : _buildStationsTable(controller),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildStationsTable(GoLiveController controller) {
    return LayoutBuilder(builder: (context, constraints) {
      final tableWidth = constraints.maxWidth;
      final col1 = tableWidth * 0.15; // Status
      final col2 = tableWidth * 0.40; // User Email
      final col3 = tableWidth * 0.30; // Action Button

      return Obx(() {
        return Container(
          margin: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                DataTable(
                  headingRowColor:
                      MaterialStateProperty.all(Colors.white.withOpacity(0.1)),
                  dataRowColor: MaterialStateProperty.all(Colors.transparent),
                  dataRowMinHeight: 35.h,
                  dataRowMaxHeight: 35.h,
                  columnSpacing: 0,
                  horizontalMargin: 8.w,
                  columns: [
                    DataColumn(
                      label: SizedBox(
                        width: col1,
                        child: Row(
                          children: [
                            Icon(Icons.circle, size: 10.sp, color: C.gold),
                            SizedBox(width: 4.w),
                            Text('الحالة',
                                style: TextStyle(
                                    fontSize: 11.sp,
                                    color: C.gold,
                                    fontFamily: Appfontstring.ChangaLight)),
                          ],
                        ),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: col2,
                        child: Row(
                          children: [
                            Icon(Icons.person, size: 12.sp, color: C.gold),
                            SizedBox(width: 4.w),
                            Text('المحطة',
                                style: TextStyle(
                                    fontSize: 11.sp,
                                    color: C.gold,
                                    fontFamily: Appfontstring.ChangaLight)),
                          ],
                        ),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: col3,
                        child: Row(
                          children: [
                            Icon(Icons.video_call,
                                size: 12.sp, color: Colors.white70),
                            SizedBox(width: 4.w),
                            Text('الإجراء',
                                style: TextStyle(
                                    fontSize: 11.sp,
                                    color: Colors.white,
                                    fontFamily: Appfontstring.ChangaLight)),
                          ],
                        ),
                      ),
                    ),
                  ],
                  rows: controller.stations.map((station) {
                    final isOnline = station.status == 'online';

                    return DataRow(
                      cells: [
                        // Status Cell
                        DataCell(
                          SizedBox(
                            width: col1,
                            child: Row(
                              children: [
                                Container(
                                  width: 8.w,
                                  height: 8.w,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        isOnline ? Colors.green : Colors.grey,
                                    boxShadow: [
                                      BoxShadow(
                                        color: (isOnline
                                                ? Colors.green
                                                : Colors.grey)
                                            .withOpacity(0.5),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // User Email Cell
                        DataCell(
                          SizedBox(
                            width: col2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  station.displayName,
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: Appfontstring.ChangaLight,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  station.userEmail,
                                  style: TextStyle(
                                    fontSize: 9.sp,
                                    color: Colors.white60,
                                    fontFamily: Appfontstring.ChangaLight,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Action Button Cell
                        DataCell(
                          SizedBox(
                            width: col3,
                            child: ElevatedButton.icon(
                              onPressed: isOnline
                                  ? () => controller.initiateVideoCall(station)
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isOnline
                                    ? Colors.green.withOpacity(0.8)
                                    : Colors.grey.withOpacity(0.3),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12.w, vertical: 8.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                elevation: isOnline ? 3 : 0,
                              ),
                              icon: Icon(
                                isOnline ? Icons.videocam : Icons.videocam_off,
                                size: 16.sp,
                              ),
                              label: Text(
                                isOnline ? 'اتصال' : 'غير متاح',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: Appfontstring.ChangaLight,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
                SizedBox(height: 80.h),
              ],
            ),
          ),
        );
      });
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_call_outlined,
                color: Colors.white.withOpacity(0.3), size: 80),
            const SizedBox(height: 16),
            Text(
              'لا توجد محطات',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: Appfontstring.ChangaLight),
            ),
            const SizedBox(height: 8),
            Text(
              'لم يتم العثور على أي محطات متاحة للاتصال',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 13,
                  fontFamily: Appfontstring.ChangaLight),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessDenied() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, color: Colors.red, size: 80),
          const SizedBox(height: 16),
          const Text(
            'دخول غير مصرح',
            style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: Appfontstring.ChangaLight),
          ),
          const SizedBox(height: 8),
          Text(
            'هذا القسم مخصص للمستخدمين المصرح لهم فقط',
            style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 13,
                fontFamily: Appfontstring.ChangaLight),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.white.withOpacity(0.1),
      highlightColor: Colors.white.withOpacity(0.3),
      child: ListView.builder(
        itemCount: 10,
        itemBuilder: (_, __) => Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          height: 40.h,
          color: Colors.white,
        ),
      ),
    );
  }
}

class GoLiveController extends GetxController {
  final RxList<StationModel> stations = <StationModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasAccess = false.obs;

  static const String agoraAppId = '2d65dc58bba24b468ea290a7e59c663e';

  // You'll need a token server for production
  // For testing, you can use Agora's temporary token generator
  static const String agoraToken = ''; // Leave empty for testing mode

  @override
  void onInit() {
    super.onInit();
    checkAccessAndFetch();
  }

  Future<void> checkAccessAndFetch() async {
    isLoading.value = true;
    try {
      final email = Get.find<AuthService>().getCurrentUserEmail();
      if (email == null) {
        hasAccess.value = false;
        return;
      }

      // Check if user has access (from user_top or user_crcc)
      final client = Supabase.instance.client;
      final topRes = await client
          .from('user_top')
          .select()
          .eq('user_email', email)
          .limit(1);

      if (topRes.isNotEmpty) {
        hasAccess.value = true;
      } else {
        final crccRes = await client
            .from('user_crcc')
            .select()
            .eq('user_email', email)
            .limit(1);
        if (crccRes.isNotEmpty) {
          hasAccess.value = true;
        }
      }

      if (hasAccess.value) {
        await fetchStations();
      }
    } catch (e) {
      debugPrint('Error checking access: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchStations() async {
    isLoading.value = true;
    try {
      final response = await Supabase.instance.client
          .from('user_stations')
          .select()
          .order('user_email', ascending: true);

      stations.assignAll((response as List<dynamic>)
          .map((json) => StationModel.fromJson(json as Map<String, dynamic>))
          .toList());
    } catch (e) {
      debugPrint('Error fetching stations: $e');
      Get.snackbar('خطأ', 'فشل تحميل المحطات');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> initiateVideoCall(StationModel station) async {
    try {
      // Check permissions first
      final cameraStatus = await Permission.camera.request();
      final micStatus = await Permission.microphone.request();

      if (!cameraStatus.isGranted || !micStatus.isGranted) {
        Get.snackbar(
          'تحذير',
          'يجب السماح بالوصول للكاميرا والميكروفون',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.withOpacity(0.8),
          colorText: Colors.white,
        );
        return;
      }

      // Generate unique channel name (call ID)
      final channelName = 'call_${DateTime.now().millisecondsSinceEpoch}';
      final callerEmail = Get.find<AuthService>().getCurrentUserEmail();

      if (callerEmail == null) {
        Get.snackbar('خطأ', 'فشل في الحصول على معلومات المستخدم');
        return;
      }

      // Send notification to the receiver
      final notificationSent = await _sendCallNotification(
        receiverToken: station.userToken,
        receiverEmail: station.userEmail,
        callerEmail: callerEmail,
        channelName: channelName,
      );

      if (notificationSent) {
        // Navigate to video call screen
        Get.to(
          () => AgoraVideoCallScreen(
            channelName: channelName,
            userEmail: callerEmail,
            isReceiver: false,
          ),
        );
      } else {
        Get.snackbar(
          'خطأ',
          'فشل في إرسال إشعار المكالمة',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('Error initiating call: $e');
      Get.snackbar(
        'خطأ',
        'فشل في بدء المكالمة',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  // استبدال بـ Firebase Project ID الفعلي
  static const String firebaseProjectId = 'crccproject-98fb0';

  Future<bool> _sendCallNotification({
    required String receiverToken,
    required String receiverEmail,
    required String callerEmail,
    required String channelName,
  }) async {
    try {
      debugPrint('🔔 Sending call notification via Cloud Function...');

      // استدعاء الـ Cloud Function المسؤولة عن إرسال الإشعارات
      final callable =
          FirebaseFunctions.instance.httpsCallable('sendVideoCallNotification');

      final result = await callable.call({
        'receiverToken': receiverToken,
        'receiverEmail': receiverEmail,
        'callerEmail': callerEmail,
        'channelName': channelName,
      });

      if (result.data['success'] == true) {
        debugPrint('✅ تم إرسال الإشعار بنجاح عبر السيرفر');
        return true;
      } else {
        debugPrint('❌ فشل إرسال الإشعار: ${result.data['message']}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ خطأ في استدعاء Cloud Function: $e');
      Get.snackbar(
        'خطأ في الاتصال',
        'تأكد من إعداد Cloud Functions بشكل صحيح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return false;
    }
  }
}

class StationModel {
  final String id;
  final String userEmail;
  final String userToken;

  StationModel({
    required this.id,
    required this.userEmail,
    required this.userToken,
  });

  // Generate display name from email
  String get displayName {
    final parts = userEmail.split('@');
    return parts.isNotEmpty ? parts[0] : userEmail;
  }

  // Status is now always online (since they have a token and are in the table)
  String get status => 'online';

  factory StationModel.fromJson(Map<String, dynamic> json) {
    return StationModel(
      id: json['id']?.toString() ?? '',
      userEmail: json['user_email'] ?? '',
      userToken: json['user_token'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_email': userEmail,
      'user_token': userToken,
    };
  }
}

class AgoraVideoCallScreen extends StatefulWidget {
  final String channelName;
  final String userEmail;
  final bool isReceiver;

  const AgoraVideoCallScreen({
    super.key,
    required this.channelName,
    required this.userEmail,
    required this.isReceiver,
  });

  @override
  State<AgoraVideoCallScreen> createState() => _AgoraVideoCallScreenState();
}

class _AgoraVideoCallScreenState extends State<AgoraVideoCallScreen> {
  int? _remoteUid;
  bool _localUserJoined = false;
  bool _isMuted = false;
  bool _isVideoOff = false;
  late RtcEngine _engine;

  @override
  void initState() {
    super.initState();
    initAgora();
  }

  Future<void> initAgora() async {
    // Create RTC engine
    _engine = createAgoraRtcEngine();

    await _engine.initialize(RtcEngineContext(
      appId: GoLiveController.agoraAppId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint('Local user ${connection.localUid} joined');
          setState(() {
            _localUserJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint('Remote user $remoteUid joined');
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          debugPrint('Remote user $remoteUid left channel');
          setState(() {
            _remoteUid = null;
          });
        },
        onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
          debugPrint('Token expiring soon');
          // TODO: Fetch new token from your server
        },
      ),
    );

    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine.enableVideo();
    await _engine.startPreview();

    // Join channel
    await _engine.joinChannel(
      token: GoLiveController.agoraToken,
      channelId: widget.channelName,
      uid: 0, // Agora will auto-assign
      options: const ChannelMediaOptions(),
    );
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  Future<void> _dispose() async {
    await _engine.leaveChannel();
    await _engine.release();
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    _engine.muteLocalAudioStream(_isMuted);
  }

  void _toggleVideo() {
    setState(() {
      _isVideoOff = !_isVideoOff;
    });
    _engine.muteLocalVideoStream(_isVideoOff);
  }

  void _endCall() {
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Remote video (full screen)
          Center(
            child: _remoteUid != null
                ? AgoraVideoView(
                    controller: VideoViewController.remote(
                      rtcEngine: _engine,
                      canvas: VideoCanvas(uid: _remoteUid),
                      connection: RtcConnection(channelId: widget.channelName),
                    ),
                  )
                : Container(
                    color: const Color(0xFF163C5E),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            color: Colors.white,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            widget.isReceiver
                                ? 'جاري الانتظار...'
                                : 'جاري الاتصال...',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontFamily: Appfontstring.ChangaLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),

          // Local video (small preview in corner)
          Positioned(
            top: 50,
            right: 16,
            child: Container(
              width: 120,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _localUserJoined
                    ? AgoraVideoView(
                        controller: VideoViewController(
                          rtcEngine: _engine,
                          canvas: const VideoCanvas(uid: 0),
                        ),
                      )
                    : Container(
                        color: Colors.grey[800],
                        child: const Center(
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
              ),
            ),
          ),

          // Top info bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.userEmail,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: Appfontstring.ChangaLight,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            _remoteUid != null ? Colors.green : Colors.orange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _remoteUid != null ? Icons.videocam : Icons.pending,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _remoteUid != null ? 'متصل' : 'انتظار',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: Appfontstring.ChangaLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Mute button
                    _buildControlButton(
                      icon: _isMuted ? Icons.mic_off : Icons.mic,
                      onPressed: _toggleMute,
                      isActive: !_isMuted,
                      label: 'الصوت',
                    ),

                    // Video toggle button
                    _buildControlButton(
                      icon: _isVideoOff ? Icons.videocam_off : Icons.videocam,
                      onPressed: _toggleVideo,
                      isActive: !_isVideoOff,
                      label: 'الكاميرا',
                    ),

                    // End call button
                    _buildControlButton(
                      icon: Icons.call_end,
                      onPressed: _endCall,
                      isActive: false,
                      label: 'إنهاء',
                      color: Colors.red,
                    ),

                    // Switch camera button
                    _buildControlButton(
                      icon: Icons.flip_camera_ios,
                      onPressed: () => _engine.switchCamera(),
                      isActive: true,
                      label: 'تبديل',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isActive,
    required String label,
    Color? color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color ?? (isActive ? Colors.white24 : Colors.white12),
              ),
              child: Icon(
                icon,
                color: color ?? Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontFamily: Appfontstring.ChangaLight,
          ),
        ),
      ],
    );
  }
}

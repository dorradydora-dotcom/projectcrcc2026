import 'dart:ui';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:amiraly/app/features/mainprog/screen/catogriesScreens/golive_controller.dart';
import 'package:amiraly/app/common/widgets/appbar.dart';
import 'package:amiraly/app/util/constant/constants.dart';

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
        SizedBox(width: 25.w),
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

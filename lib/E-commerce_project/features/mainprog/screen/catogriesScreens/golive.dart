import 'dart:ui';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shimmer/shimmer.dart';
import 'package:amiraly/E-commerce_project/features/mainprog/screen/catogriesScreens/golive_controller.dart';
import 'package:amiraly/E-commerce_project/common/widgets/appbar.dart';
import 'package:amiraly/E-commerce_project/util/constant/constants.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GoLiveController()
        ..fetchUsers()
        ..startSignaling(),
      child: Scaffold(
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
                        child: Consumer<GoLiveController>(
                          builder: (context, controller, child) {
                            if (controller.isLoading) {
                              return _buildShimmerLoading();
                            }

                            if (controller.errorMessage != null) {
                              return Center(
                                child: FadeIn(
                                  child: Text(
                                    controller.errorMessage!,
                                    style:
                                        const TextStyle(color: Colors.white70),
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
                                        color: Colors.white.withOpacity(0.2),
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

                            return LayoutBuilder(
                                builder: (context, constraints) {
                              final tableWidth = constraints.maxWidth;
                              final col1 = tableWidth * 0.60; // Station Name
                              final col2 = tableWidth * 0.28; // Action

                              return FadeInUp(
                                duration: const Duration(milliseconds: 1000),
                                child: Container(
                                  margin: EdgeInsets.all(15.w),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(20.r),
                                    border: Border.all(
                                        color: Colors.white.withOpacity(0.15),
                                        width: 1.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20.r),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                          sigmaX: 10, sigmaY: 10),
                                      child: RefreshIndicator(
                                        color: Appcolors.secondaryColor,
                                        onRefresh: controller.fetchUsers,
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.vertical,
                                          physics:
                                              const AlwaysScrollableScrollPhysics(
                                                  parent:
                                                      BouncingScrollPhysics()),
                                          child: Column(
                                            children: [
                                              DataTable(
                                                headingRowColor:
                                                    WidgetStateProperty.all(
                                                        Colors.white
                                                            .withOpacity(0.12)),
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
                                                            child: Row(
                                                              children: [
                                                                Icon(
                                                                    Icons
                                                                        .location_city,
                                                                    size: 16.sp,
                                                                    color:
                                                                        C.gold),
                                                                SizedBox(
                                                                    width:
                                                                        10.w),
                                                                Text('المحطة',
                                                                    style: TextStyle(
                                                                        fontSize: 13
                                                                            .sp,
                                                                        fontFamily:
                                                                            Appfontstring
                                                                                .ChangaBold,
                                                                        color: C
                                                                            .gold)),
                                                              ],
                                                            ),
                                                          ))),
                                                  DataColumn(
                                                      label: SizedBox(
                                                          width: col2,
                                                          child: Row(
                                                            children: [
                                                              Icon(
                                                                  Iconsax
                                                                      .video5,
                                                                  size: 16.sp,
                                                                  color: Colors
                                                                      .white70),
                                                              SizedBox(
                                                                  width: 10.w),
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
                                                rows: controller.users
                                                    .map((user) {
                                                  return DataRow(cells: [
                                                    DataCell(SizedBox(
                                                        width: col1,
                                                        child: Padding(
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                                  horizontal:
                                                                      10.w),
                                                          child: Text(
                                                              user.stationName ??
                                                                  'مجهول',
                                                              style: TextStyle(
                                                                  fontSize:
                                                                      12.sp,
                                                                  fontFamily:
                                                                      Appfontstring
                                                                          .ChangaLight,
                                                                  color: Colors
                                                                      .white)),
                                                        ))),
                                                    DataCell(SizedBox(
                                                      width: col2,
                                                      child: ZoomIn(
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
                                                              color: C.blue
                                                                  .withOpacity(
                                                                      0.2),
                                                              shape: BoxShape
                                                                  .circle,
                                                              border: Border.all(
                                                                  color: C.blue
                                                                      .withOpacity(
                                                                          0.5),
                                                                  width: 1),
                                                              boxShadow: [
                                                                BoxShadow(
                                                                  color: C.blue
                                                                      .withOpacity(
                                                                          0.3),
                                                                  blurRadius: 8,
                                                                  spreadRadius:
                                                                      1,
                                                                ),
                                                              ],
                                                            ),
                                                            child: Icon(
                                                                Iconsax.video5,
                                                                size: 18.sp,
                                                                color: Colors
                                                                    .white),
                                                          ),
                                                          onPressed: () async {
                                                            await _handleStartCall(
                                                                context,
                                                                controller,
                                                                user.id);
                                                          },
                                                        ),
                                                      ),
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
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Incoming Call Overlay
              Consumer<GoLiveController>(
                builder: (context, controller, _) {
                  return _buildIncomingCallOverlay(context, controller);
                },
              ),
            ],
          ),
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
                Border.all(color: Colors.orange.withOpacity(0.5), width: 1.5.w),
            color: Colors.black.withOpacity(0.4),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.1),
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
            Text(
              'مركز الاتصال المرئي للمحطات',
              style: TextStyle(
                fontSize: 15.sp,
                color: Colors.orange,
                fontFamily: Appfontstring.ChangaBold,
                letterSpacing: 0.5,
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
        Navigator.pop(context); // Dismiss loading
        controller.playRinging(); // Start ringback as we navigate
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
        Navigator.pop(context); // Dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start call: $e')),
        );
      }
    }
  }

  Widget _buildIncomingCallOverlay(
      BuildContext context, GoLiveController controller) {
    final call = controller.incomingCall;
    if (call == null) return const SizedBox.shrink();

    return Positioned.fill(
      child: FadeIn(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: ZoomIn(
                child: Container(
                  width: 280.w,
                  padding: EdgeInsets.all(25.r),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30.r),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
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
                              fontFamily: Appfontstring.ChangaBold)),
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
      baseColor: Colors.white.withOpacity(0.05),
      highlightColor: Colors.white.withOpacity(0.12),
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
}

// Video Call Page
class VideoCallPage extends StatelessWidget {
  final GoLiveController controller;
  final String channelName;

  const VideoCallPage(
      {super.key, required this.controller, required this.channelName});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: controller,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            await _onWillPop(context);
          },
          child: Consumer<GoLiveController>(
            builder: (context, controller, child) {
              return Stack(
                children: [
                  Positioned.fill(
                    child: _remoteVideo(controller),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: FadeInDown(
                      child: ClipRRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: EdgeInsets.only(
                                top: MediaQuery.of(context).padding.top + 10,
                                bottom: 15,
                                left: 20,
                                right: 20),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back_ios,
                                      color: Colors.white),
                                  onPressed: () => _onWillPop(context),
                                ),
                                const Spacer(),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Row(
                                      children: [
                                        Text('بث مباشر',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12.sp,
                                                fontFamily:
                                                    Appfontstring.ChangaBold)),
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
                                    Text("Connection Secured by (RtcEngine)",
                                        style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 10.sp)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Local Video Preview
                  if (controller.localUserJoined)
                    Positioned(
                      top: 100,
                      right: 20,
                      child: FadeInRight(
                        child: Container(
                          width: 110.w,
                          height: 160.h,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.3), width: 2),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 15,
                                  spreadRadius: 2),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18.r),
                            child: AgoraVideoView(
                              controller: VideoViewController(
                                rtcEngine: controller.engine!,
                                canvas: const VideoCanvas(uid: 0),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

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
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context, GoLiveController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildControlButton(
          icon: Iconsax.microphone_slash,
          color: Colors.white24,
          onPressed: () {},
        ),
        SizedBox(width: 25.w),
        _buildControlButton(
          icon: Iconsax.call_remove5,
          color: Colors.redAccent,
          isLarge: true,
          onPressed: () => _onWillPop(context),
        ),
        SizedBox(width: 25.w),
        _buildControlButton(
          icon: Iconsax.camera5,
          color: Colors.white24,
          onPressed: () {},
        ),
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
              color: color.withOpacity(0.3),
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
    if (controller.remoteUid != null) {
      return FadeIn(
        child: AgoraVideoView(
          controller: VideoViewController.remote(
            rtcEngine: controller.engine!,
            canvas: VideoCanvas(uid: controller.remoteUid),
            connection: RtcConnection(channelId: channelName),
          ),
        ),
      );
    } else {
      return Container(
        color: const Color(0xFF0F172A),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SpinKitRipple(
              color: Colors.white.withOpacity(0.3),
              size: 100.r,
            ),
            SizedBox(height: 20.h),
            Text(
              'بانتظار انضمام المحــطة ...',
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
  }
}

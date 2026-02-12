import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:amiraly/E-commerce_project/common/models/appmodels.dart';

class GoLiveController extends ChangeNotifier {
  List<StationModelCall> users = [];
  bool isLoading = true;
  bool isAccessDenied = false;
  String? errorMessage;

  // Audio players
  final AudioPlayer _ringPlayer = AudioPlayer();
  final AudioPlayer _effectPlayer = AudioPlayer();

  // Constants
  static const String _appId = '7b78219d5722456bb4c997f28dc6f672';
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
  String? currentCallId;
  Map<String, dynamic>? incomingCall;
  StreamSubscription? _signalingSubscription;
  Timer? _timeoutTimer;

  RtcEngine? _engine;
  RtcEngine? get engine => _engine;

  Future<void> fetchUsers() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final response =
          await Supabase.instance.client.from('user_stations').select();

      final List<dynamic> data = response;
      users = data.map((json) => StationModelCall.fromJson(json)).where((user) {
        final name = user.stationName ?? '';
        return !_excludedStations.any(
            (excluded) => name.contains(excluded) || excluded.contains(name));
      }).toList();

      // Sort alphabetically by station name
      users
          .sort((a, b) => (a.stationName ?? '').compareTo(b.stationName ?? ''));
    } catch (e) {
      errorMessage = 'Failed to load users: $e';
      users = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> checkAccess() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || user.email == null) {
      isAccessDenied = true;
      notifyListeners();
      return;
    }

    try {
      final email = user.email!;
      final client = Supabase.instance.client;

      final results = await Future.wait([
        client.from('user_top').select().eq('user_email', email).limit(1),
        client.from('user_crcc').select().eq('user_email', email).limit(1),
      ]);

      isAccessDenied = results[0].isEmpty && results[1].isEmpty;
    } catch (e) {
      isAccessDenied = true;
      debugPrint('Error checking GoLive access: $e');
    }
    notifyListeners();
  }

  int? remoteUid;
  bool localUserJoined = false;

  Future<void> initializeAgora() async {
    try {
      final statuses =
          await [Permission.microphone, Permission.camera].request();

      if (statuses[Permission.microphone] != PermissionStatus.granted ||
          statuses[Permission.camera] != PermissionStatus.granted) {
        throw 'يجب منح صلاحيات الميكروفون والكاميرا لبدء البث';
      }

      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: _appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint("local user ${connection.localUid} joined");
            localUserJoined = true;
            notifyListeners();
          },
          onUserJoined: (RtcConnection connection, int uid, int elapsed) {
            debugPrint("remote user $uid joined");
            remoteUid = uid;
            stopRinging();
            playConnect();
            notifyListeners();
          },
          onUserOffline: (RtcConnection connection, int uid,
              UserOfflineReasonType reason) {
            debugPrint("remote user $uid left channel");
            remoteUid = null;
            notifyListeners();
          },
          onError: (ErrorCodeType err, String msg) {
            debugPrint('Agora Error: $err, $msg');
          },
        ),
      );

      await _engine!.enableVideo();
      await _engine!.startPreview();
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
      if (_engine == null) await initializeAgora();

      final token = await _fetchSecureToken(channelName);

      await _engine!.joinChannel(
        token: token,
        channelId: channelName,
        uid: 0,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
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
        await _engine!.leaveChannel();
        localUserJoined = false;
        remoteUid = null;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error leaving channel: $e');
    }
  }

  String? get currentUserId => Supabase.instance.client.auth.currentUser?.id;

  Future<void> startSignaling() async {
    final userId = currentUserId;
    if (userId == null) return;

    // Listen for incoming calls where the current user is the receiver
    _signalingSubscription?.cancel();
    _signalingSubscription = Supabase.instance.client
        .from('calls_signaling')
        .stream(primaryKey: ['id'])
        .eq('receiver_id', userId)
        .listen((List<Map<String, dynamic>> data) {
          if (data.isNotEmpty) {
            final now = DateTime.now();
            final activeCall = data.firstWhere(
              (call) {
                if (call['status'] != 'ringing') return false;

                // Freshness check: only ring if the call was created in the last 60 seconds
                final createdAtStr = call['created_at'];
                if (createdAtStr != null) {
                  final createdAt = DateTime.parse(createdAtStr);
                  if (now.difference(createdAt).inSeconds > 60) return false;
                }
                return true;
              },
              orElse: () => {},
            );

            if (activeCall.isNotEmpty) {
              incomingCall = activeCall;
              currentCallId = activeCall['id'];
              playRinging();
              notifyListeners();
            } else {
              // If the current call was ended or rejected by the other side
              final updatedCall = data.firstWhere(
                (call) => call['id'] == currentCallId,
                orElse: () => {},
              );

              if (updatedCall.isNotEmpty &&
                  (updatedCall['status'] == 'ended' ||
                      updatedCall['status'] == 'rejected')) {
                incomingCall = null;
                currentCallId = null;
                stopRinging();
                playHangup();
                leaveChannel();
                notifyListeners();
              }
            }
          }
        });
  }

  Future<void> makeCall(String receiverId) async {
    final userId = currentUserId;
    if (userId == null) throw 'يجب تسجيل الدخول أولاً';

    try {
      final response = await Supabase.instance.client
          .from('calls_signaling')
          .insert({
            'caller_id': userId,
            'receiver_id': receiverId,
            'channel_name': userId, // Use caller ID as channel name
            'status': 'ringing',
          })
          .select()
          .single();

      currentCallId = response['id'];
      // Ringing will be started by the UI when the call page opens
      await joinChannel(userId);
      notifyListeners();

      // Start 30-second timeout
      _timeoutTimer?.cancel();
      _timeoutTimer = Timer(const Duration(seconds: 30), () {
        if (currentCallId != null &&
            (incomingCall == null || incomingCall!['status'] == 'ringing')) {
          debugPrint('Call timed out after 30 seconds');
          endCall();
        }
      });

      // Listen for the receiver's response
      Supabase.instance.client
          .from('calls_signaling')
          .stream(primaryKey: ['id'])
          .eq('id', currentCallId!)
          .listen((data) {
            if (data.isNotEmpty) {
              final status = data.first['status'];
              if (status == 'rejected' || status == 'ended') {
                stopRinging();
                playHangup();
                leaveChannel();
                currentCallId = null;
                notifyListeners();
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
      await Supabase.instance.client.from('calls_signaling').update(
          {'status': accept ? 'accepted' : 'rejected'}).eq('id', callId);

      if (accept) {
        stopRinging();
        final call = incomingCall;
        if (call != null) {
          await joinChannel(call['channel_name']);
        }
      } else {
        stopRinging();
        playHangup();
        incomingCall = null;
        currentCallId = null;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error responding to call: $e');
    }
  }

  Future<void> endCall() async {
    _timeoutTimer?.cancel();
    if (currentCallId != null) {
      try {
        await Supabase.instance.client
            .from('calls_signaling')
            .update({'status': 'ended'}).eq('id', currentCallId!);
      } catch (e) {
        debugPrint('Error ending call record: $e');
      }
    }
    stopRinging();
    playHangup();
    await leaveChannel();
    currentCallId = null;
    incomingCall = null;
    notifyListeners();
  }

  Future<void> disposeAgora() async {
    try {
      if (_engine != null) {
        await _engine!.release();
        _engine = null;
      }
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
  void dispose() {
    _ringPlayer.stop();
    _ringPlayer.dispose();
    _effectPlayer.stop();
    _effectPlayer.dispose();
    _signalingSubscription?.cancel();
    disposeAgora();
    super.dispose();
  }
}

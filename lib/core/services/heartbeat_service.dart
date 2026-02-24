import 'dart:async';
import 'package:get/get.dart';
import 'package:amiraly/app/util/validators/validator_helper.dart';

/// A central service that provides a single master timer (heartbeat).
/// Other components subscribe to this "heartbeat" instead of creating their own timers.
class HeartbeatService extends GetxService {
  static HeartbeatService get instance => Get.find<HeartbeatService>();

  final _tickController = StreamController<int>.broadcast();
  Stream<int> get onTick => _tickController.stream;

  Timer? _timer;
  int _currentTick = 0;

  @override
  void onInit() {
    super.onInit();
    _startHeartbeat();
    AppLogger.logInfo('💓 HeartbeatService started');
  }

  void _startHeartbeat() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _currentTick++;
      _tickController.add(_currentTick);
    });
  }

  /// Helper to get a stream that fires every N seconds
  Stream<int> every(int seconds) {
    return onTick.where((tick) => tick % seconds == 0);
  }

  @override
  void onClose() {
    _timer?.cancel();
    _tickController.close();
    AppLogger.logInfo('💔 HeartbeatService stopped');
    super.onClose();
  }
}

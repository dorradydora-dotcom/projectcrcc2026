import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:amiraly/E-commerce_project/common/services/cache_service.dart';
import 'package:amiraly/main.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:amiraly/E-commerce_project/common/models/appmodels.dart';

const double maxStationLoad = 700.0;

class StationLoadController extends GetxController {
  StreamSubscription<AuthState>? _authSubscription;

  // Reactive state
  final RxList<StationLoad> stationLoads = <StationLoad>[].obs;
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;
  final RxBool hasError = false.obs;
  final RxMap<String, String> specificStations = <String, String>{}.obs;
  final RxBool isCrccUser = false.obs;
  final RxInt retryCountdown = 0.obs;
  final RxBool isFromCache = false.obs;
  final RxMap<String, bool> directions = <String, bool>{}.obs;

  // Services
  final SupabaseService _supabaseService = SupabaseService();
  final CacheService _cacheService = CacheService();

  // Timers & Realtime
  Timer? _updateTimer;
  Timer? _retryTimer;
  RealtimeChannel? _realtimeChannel;

  // Constants
  static const _updateInterval = Duration(seconds: 7);
  static const _maxRetries = 5; // Increased from 3
  int _retryAttempts = 0;
  int _consecutiveFailures = 0; // Track consecutive failures

  String? get userEmail => Supabase.instance.client.auth.currentUser?.email;

  // Total load computed property (signed)
  double get totalLoad {
    return stationLoads.fold(0.0, (sum, station) {
      bool isPositive = directions[station.stationName] ?? true;
      return sum + (isPositive ? station.load : -station.load);
    });
  }

  double getStationLoad(String stationName) {
    try {
      final station =
          stationLoads.firstWhere((s) => s.stationName == stationName);
      bool isPositive = directions[stationName] ?? true;
      return isPositive ? station.load : -station.load;
    } catch (_) {
      return 0.0;
    }
  }

  @override
  void onInit() {
    super.onInit();
    _checkPermissions();
    _loadDirections();
    _initializeData();
    _startAutoUpdate();
    _initRealtimeSubscription();
    _initAuthListener(); // Add auth state listener
  }

  void _initAuthListener() {
    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.signedOut ||
          event == AuthChangeEvent.userUpdated) {
        debugPrint('🔐 Auth state changed: $event. Refreshing permissions...');
        _checkPermissions();
      }
    });
  }

  Future<void> _loadDirections() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (var key in keys) {
        if (key.startsWith('dir_')) {
          final stationName = key.replaceFirst('dir_', '');
          directions[stationName] = prefs.getBool(key) ?? true;
        }
      }
    } catch (e) {
      debugPrint('Error loading directions: $e');
    }
  }

  void _initRealtimeSubscription() {
    try {
      _realtimeChannel = Supabase.instance.client
          .channel('public:station_table')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'station_table',
            callback: (payload) {
              debugPrint('🔔 Realtime change received: ${payload.eventType}');
              _handleRealtimePayload(payload);
            },
          )
          .subscribe();
      debugPrint('🛰️ Supabase Realtime subscribed to station_table');
    } catch (e) {
      debugPrint('❌ Error setting up Realtime: $e');
    }
  }

  void _handleRealtimePayload(PostgresChangePayload payload) {
    if (payload.newRecord.isEmpty) return;

    try {
      final newRecord = payload.newRecord;
      final stationName = newRecord['station_name'] as String?;

      if (stationName == null) return;

      // Update in stationLoads list
      final index =
          stationLoads.indexWhere((s) => s.stationName == stationName);

      if (index != -1) {
        final currentStation = stationLoads[index];

        // Merge with existing data to handle potential partial updates
        // Note: Realtime usually sends full row for UPDATE, but good to be safe
        double parseSafe(dynamic value, double fallback) {
          if (value == null) return fallback;
          if (value is num) return value.toDouble();
          if (value is String) return double.tryParse(value) ?? fallback;
          return fallback;
        }

        final updatedStation = StationLoad(
          stationName: stationName,
          load: parseSafe(newRecord['station_load'], currentStation.load),
          baseLoad:
              parseSafe(newRecord['station_load'], currentStation.baseLoad),
          minVariation: parseSafe(
              newRecord['min_variation'], currentStation.minVariation),
          maxVariation: parseSafe(
              newRecord['max_variation'], currentStation.maxVariation),
          isPositive:
              (newRecord['station_sign'] as bool?) ?? currentStation.isPositive,
          lastUpdated: newRecord['updated_at'] != null
              ? (DateTime.tryParse(newRecord['updated_at'].toString()))
                  ?.toLocal()
              : DateTime.now(),
        );

        stationLoads[index] = updatedStation;

        // Sync directions map
        directions[stationName] = updatedStation.isPositive;

        // Sync last update time
        lastUpdateTimes[stationName] = updatedStation.lastUpdated!;

        stationLoads.refresh();
      } else {
        // New station added?
        try {
          final newStation = StationLoad.fromJson(newRecord);
          stationLoads.add(newStation);
          directions[stationName] = newStation.isPositive;
          lastUpdateTimes[stationName] =
              newStation.lastUpdated ?? DateTime.now();
        } catch (e) {
          debugPrint('Error parsing new station payload: $e');
        }
      }
    } catch (e) {
      debugPrint('Error handling realtime payload: $e');
    }
  }

  Future<void> toggleDirection(String stationName) async {
    final current = directions[stationName] ?? true;
    final newValue = !current;

    // Update locally first for immediate UI responsiveness
    directions[stationName] = newValue;
    stationLoads.refresh(); // Trigger totalLoad recalculation

    try {
      // 1. Update Supabase
      await _supabaseService.updateStationSign(stationName, newValue);

      // 2. Update the StationLoad object in the list
      final index =
          stationLoads.indexWhere((s) => s.stationName == stationName);
      if (index != -1) {
        stationLoads[index].isPositive = newValue;
      }

      // 3. Update SharedPreferences (Offline fallback)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dir_$stationName', newValue);
    } catch (e) {
      debugPrint('Error syncing direction: $e');
      // Note: We don't revert local state to avoid flickering on slow connections
    }
  }

  @override
  void onClose() {
    _updateTimer?.cancel();
    _retryTimer?.cancel();
    _realtimeChannel?.unsubscribe();
    _authSubscription?.cancel(); // Cancel auth listener
    super.onClose();
  }

  /// Initialize data - Start with fresh fetch, fallback to cache on error
  Future<void> _initializeData() async {
    // Load persisted timestamps
    final cachedTimestamps = await _cacheService.getUpdateTimestamps();
    if (cachedTimestamps != null) {
      lastUpdateTimes.assignAll(cachedTimestamps);
    }

    // Fetch fresh data immediately
    // usage of cache will happen inside _fetchData on failure
    await _fetchData();
  }

  /// Check if user has CRCC permissions
  Future<void> _checkPermissions() async {
    final email = userEmail;
    if (email == null) {
      // If email is not available yet, retry later
      _retryPermissionsCheck();
      return;
    }

    try {
      final hasPermission = await _supabaseService.checkCrccPermission(email);
      isCrccUser.value = hasPermission;
      debugPrint('🛡️ CRCC Permission status for $email: $hasPermission');
    } catch (e) {
      debugPrint('Error checking permissions: $e');
      _retryPermissionsCheck();
    }
  }

  /// Retry permissions check silently
  Future<void> _retryPermissionsCheck() async {
    // If already checking/scheduled, don't schedule another one
    await Future.delayed(const Duration(seconds: 5));
    _checkPermissions();
  }

  /// Fetch data from server
  Future<void> fetchData() async {
    _retryAttempts = 0;
    retryCountdown.value = 0;
    await _fetchData();
  }

  Future<void> _fetchData({bool showLoading = true}) async {
    if (showLoading) {
      isLoading.value = true;
    }
    hasError.value = false;
    errorMessage.value = '';

    try {
      final loads = await _supabaseService.fetchStationLoads();
      final stations = await _supabaseService.fetchSpecificStations();

      stationLoads.value = loads;
      specificStations.value = stations;

      // Sync directions map with fetched station signals
      for (var station in loads) {
        directions[station.stationName] = station.isPositive;
        // Sync last update time if available from server (convert to local)
        if (station.lastUpdated != null) {
          lastUpdateTimes[station.stationName] = station.lastUpdated!.toLocal();
        }
      }

      isLoading.value = false;
      isFromCache.value = false;
      _retryAttempts = 0;
      _consecutiveFailures = 0; // Reset on success

      // Cache the data
      await _cacheService.saveStationLoads(loads);
    } catch (e) {
      debugPrint('Error fetching data: $e');
      _consecutiveFailures++;

      // Check if it's a HandshakeException or network error
      final errorStr = e.toString().toLowerCase();
      final isNetworkError = errorStr.contains('handshake') ||
          errorStr.contains('socket') ||
          errorStr.contains('connection') ||
          errorStr.contains('timeout');

      // If stationLoads is empty, show error (cache fallback removed as per user request to avoid stale data jumping)
      if (stationLoads.isEmpty) {
        // Only show error if we have no data
        hasError.value = true;
        errorMessage.value = _getErrorMessage(e);
        isLoading.value = false;

        // Auto-retry logic - more aggressive for network errors
        if (isNetworkError) {
          // For network errors, keep retrying with longer delays
          if (_retryAttempts < _maxRetries) {
            _scheduleRetry();
          } else {
            // After max retries, wait longer and retry anyway
            _scheduleExtendedRetry();
          }
        } else if (_retryAttempts < _maxRetries) {
          _scheduleRetry();
        }
      } else {
        // We have data (maybe from cache just now, or previous), retry silently in background
        isLoading.value = false;
        if (isNetworkError && _consecutiveFailures < 10) {
          // Silent retry for network errors
          _scheduleSilentRetry();
        }
      }
    }
  }

  /// Get user-friendly error message
  String _getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('handshake')) {
      return 'مشكلة في الاتصال الآمن\nجاري إعادة المحاولة تلقائياً...';
    } else if (errorString.contains('socket') ||
        errorString.contains('network') ||
        errorString.contains('connection')) {
      return 'فشل الاتصال بالخادم\nجاري إعادة المحاولة...';
    } else if (errorString.contains('timeout')) {
      return 'انتهت مهلة الاتصال\nجاري المحاولة مرة أخرى...';
    } else if (errorString.contains('unauthorized') ||
        errorString.contains('forbidden')) {
      return 'خطأ في الصلاحيات\nيرجى تسجيل الدخول مجدداً';
    } else {
      return 'حدث خطأ غير متوقع\nجاري إعادة المحاولة...';
    }
  }

  /// Schedule automatic retry
  void _scheduleRetry() {
    _retryAttempts++;
    final retryDelay = pow(2, _retryAttempts).toInt(); // Exponential backoff
    retryCountdown.value = retryDelay;

    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (retryCountdown.value > 0) {
        retryCountdown.value--;
      } else {
        timer.cancel();
        _fetchData();
      }
    });
  }

  /// Schedule extended retry for persistent errors
  void _scheduleExtendedRetry() {
    const retryDelay = 15; // 15 seconds
    retryCountdown.value = retryDelay;
    _retryAttempts = 0; // Reset attempts

    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (retryCountdown.value > 0) {
        retryCountdown.value--;
      } else {
        timer.cancel();
        _fetchData();
      }
    });
  }

  /// Schedule silent background retry
  void _scheduleSilentRetry() {
    Future.delayed(const Duration(seconds: 5), () {
      if (_consecutiveFailures < 10) {
        _fetchData(showLoading: false);
      }
    });
  }

  /// Start automatic load updates (simulation)
  void _startAutoUpdate() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(_updateInterval, (_) => _updateLoads());
  }

  /// Update station loads with random variations
  void _updateLoads() {
    if (stationLoads.isEmpty) return;

    final random = Random();
    final updatedLoads = stationLoads.map((station) {
      final variationRange = station.maxVariation - station.minVariation;
      final randomVariation =
          station.minVariation + random.nextDouble() * variationRange;
      station.load =
          (station.baseLoad + randomVariation).clamp(0.0, double.infinity);
      return station;
    }).toList();

    stationLoads.value = updatedLoads;
  }

  // Track last update times locally
  final RxMap<String, DateTime> lastUpdateTimes = <String, DateTime>{}.obs;

  /// Update a specific station's load
  Future<bool> updateStationLoad(String stationName, double newLoad) async {
    try {
      await _supabaseService.updateStationLoad(stationName, newLoad);

      // Update locally
      final index =
          stationLoads.indexWhere((s) => s.stationName == stationName);
      if (index != -1) {
        stationLoads[index].load = newLoad;
        stationLoads.refresh();
      }

      // Update timestamp
      lastUpdateTimes[stationName] = DateTime.now();

      // Update cache
      await _cacheService.saveStationLoads(stationLoads);

      return true;
    } catch (e) {
      debugPrint('Error updating station load: $e');
      return false;
    }
  }

  /// Check if station was updated in the current hour
  bool wasUpdatedThisHour(String stationName) {
    if (!lastUpdateTimes.containsKey(stationName)) return false;

    final lastUpdate = lastUpdateTimes[stationName]!.toLocal();
    final now = DateTime.now();

    return lastUpdate.year == now.year &&
        lastUpdate.month == now.month &&
        lastUpdate.day == now.day &&
        lastUpdate.hour == now.hour;
  }

  /// Check if user can edit a station
  bool canEditStation(String stationName) {
    if (isCrccUser.value) return true;

    final requiredEmail = specificStations[stationName];
    if (requiredEmail != null && userEmail == requiredEmail) {
      return true;
    }

    return false;
  }

  /// Check if user is assigned to a station
  bool isUserAssignedToStation(String stationName) {
    final requiredEmail = specificStations[stationName];
    return userEmail != null &&
        requiredEmail != null &&
        userEmail == requiredEmail;
  }
}

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:amiraly/app/common/models/appmodels.dart';
import 'package:amiraly/app/util/constant/constants.dart';
import 'package:amiraly/app/util/validators/validatorHeper.dart';

class CacheService {
  static const String _stationLoadsKey = CacheConstants.stationLoadsKey;
  static const String _timestampKey = CacheConstants.timestampKey;
  static const String _updateTimestampsKey = CacheConstants.updateTimestampsKey;
  static const int _cacheValidityMinutes = CacheConstants.cacheValidityMinutes;

  // ✅ SharedPreferences singleton — يُهيَّأ مرة واحدة فقط
  SharedPreferences? _prefs;

  Future<SharedPreferences> get _getPrefs async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  /// Save station loads to local cache
  Future<void> saveStationLoads(List<StationLoad> loads) async {
    try {
      final prefs = await _getPrefs;
      final jsonList = loads.map((load) => load.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await prefs.setString(_stationLoadsKey, jsonString);
      await prefs.setInt(_timestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      AppLogger.logError('Cache save error', e);
    }
  }

  /// Get cached station loads if valid
  Future<List<StationLoad>?> getStationLoads() async {
    try {
      final prefs = await _getPrefs;
      if (!isCacheValid(prefs)) return null;

      final jsonString = prefs.getString(_stationLoadsKey);
      if (jsonString == null) return null;

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => StationLoad.fromJson(json)).toList();
    } catch (e) {
      AppLogger.logError('Cache load error', e);
      return null;
    }
  }

  /// Check if cache is still valid
  bool isCacheValid(SharedPreferences prefs) {
    final timestamp = prefs.getInt(_timestampKey);
    if (timestamp == null) return false;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final difference = DateTime.now().difference(cacheTime);
    return difference.inMinutes < _cacheValidityMinutes;
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    try {
      final prefs = await _getPrefs;
      await prefs.remove(_stationLoadsKey);
      await prefs.remove(_timestampKey);
    } catch (e) {
      AppLogger.logError('Cache clear error', e);
    }
  }

  /// Get cache age in minutes
  Future<int?> getCacheAgeMinutes() async {
    try {
      final prefs = await _getPrefs;
      final timestamp = prefs.getInt(_timestampKey);
      if (timestamp == null) return null;

      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return DateTime.now().difference(cacheTime).inMinutes;
    } catch (e) {
      return null;
    }
  }

  /// Save update timestamps to local cache
  Future<void> saveUpdateTimestamps(Map<String, DateTime> timestamps) async {
    try {
      final prefs = await _getPrefs;
      final Map<String, int> encoded = timestamps
          .map((key, value) => MapEntry(key, value.millisecondsSinceEpoch));
      await prefs.setString(_updateTimestampsKey, jsonEncode(encoded));
    } catch (e) {
      AppLogger.logError('Timestamps cache save error', e);
    }
  }

  /// Get cached update timestamps
  Future<Map<String, DateTime>?> getUpdateTimestamps() async {
    try {
      final prefs = await _getPrefs;
      final jsonString = prefs.getString(_updateTimestampsKey);
      if (jsonString == null) return null;

      final Map<String, dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((key, value) =>
          MapEntry(key, DateTime.fromMillisecondsSinceEpoch(value as int)));
    } catch (e) {
      AppLogger.logError('Timestamps cache load error', e);
      return null;
    }
  }

  /// Save hourly max loads (Today & Yesterday)
  Future<void> saveHourlyMaxLoads(List<Map<String, dynamic>> today,
      List<Map<String, dynamic>> yesterday) async {
    try {
      final prefs = await _getPrefs;
      final data = {
        'today': today,
        'yesterday': yesterday,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString(CacheConstants.hourlyMaxLoadsKey, jsonEncode(data));
    } catch (e) {
      AppLogger.logError('Cache hourly save error', e);
    }
  }

  /// Get cached hourly max loads
  Future<Map<String, List<Map<String, dynamic>>>?> getHourlyMaxLoads() async {
    try {
      final prefs = await _getPrefs;
      final jsonString = prefs.getString(CacheConstants.hourlyMaxLoadsKey);
      if (jsonString == null) return null;

      final Map<String, dynamic> decoded = jsonDecode(jsonString);
      final int? timestamp = decoded['timestamp'];
      if (timestamp == null) return null;

      // Validate cache age (1 hour)
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (DateTime.now().difference(cacheTime).inMinutes > 60) return null;

      return {
        'today': List<Map<String, dynamic>>.from(decoded['today'] ?? []),
        'yesterday':
            List<Map<String, dynamic>>.from(decoded['yesterday'] ?? []),
      };
    } catch (e) {
      AppLogger.logError('Cache hourly load error', e);
      return null;
    }
  }

  /// Save international loads to local cache
  Future<void> saveIntlLoads(Map<String, double?> loads) async {
    try {
      final prefs = await _getPrefs;
      await prefs.setString(CacheConstants.intlLoadsKey, jsonEncode(loads));
      await prefs.setInt(CacheConstants.intlCacheTimestampKey,
          DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      AppLogger.logError('Intl cache save error', e);
    }
  }

  /// Get cached international loads
  Future<Map<String, double?>?> getIntlLoads() async {
    try {
      final prefs = await _getPrefs;
      final jsonString = prefs.getString(CacheConstants.intlLoadsKey);
      if (jsonString == null) return null;

      final Map<String, dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((key, value) =>
          MapEntry(key, value != null ? (value as num).toDouble() : null));
    } catch (e) {
      AppLogger.logError('Intl cache load error', e);
      return null;
    }
  }
}

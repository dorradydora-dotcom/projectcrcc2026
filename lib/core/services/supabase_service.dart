import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:amiraly/app/common/models/appmodels.dart';
import 'package:amiraly/app/util/constant/constants.dart';
import 'package:amiraly/app/util/validators/validatorHeper.dart';

class SupabaseService {
  SupabaseClient get _client => Supabase.instance.client;

  final Map<String, CachedData> _cache = {};
  static const Duration cacheDuration = Duration(minutes: 5);

  Future<List<StationLoad>> fetchStationLoads({
    int limit = AppConstants.defaultFetchLimit,
    bool forceRefresh = false,
  }) async {
    const cacheKey = 'station_loads';

    if (!forceRefresh && _cache.containsKey(cacheKey)) {
      final cached = _cache[cacheKey]!;
      if (!cached.isExpired) {
        AppLogger.logInfo('📦 Returning cached data');
        return cached.data as List<StationLoad>;
      }
    }

    try {
      final response = await _client
          .from(AppConstants.tableStation)
          .select()
          .order('station_name', ascending: true)
          .limit(limit)
          .timeout(AppConstants.timeoutDuration);

      final stations = (response as List<dynamic>)
          .map((json) => StationLoad.fromJson(json))
          .toList();

      _cache[cacheKey] = CachedData(data: stations, timestamp: DateTime.now());
      AppLogger.logSuccess('✅ Data fetched and cached');
      return stations;
    } on TimeoutException {
      if (_cache.containsKey(cacheKey)) {
        AppLogger.logWarning('⚠️ Timeout - using old cache');
        return _cache[cacheKey]!.data as List<StationLoad>;
      }
      throw Exception('انتهت مهلة الطلب. تحقق من اتصالك بالإنترنت');
    } catch (e, stackTrace) {
      AppLogger.logError('Failed to fetch station loads', e, stackTrace);
      if (_cache.containsKey(cacheKey)) {
        AppLogger.logWarning('Using cached data due to error');
        return _cache[cacheKey]!.data as List<StationLoad>;
      }
      throw Exception('فشل في جلب بيانات المحطات');
    }
  }

  Future<Map<String, String>> fetchSpecificStations() async {
    const cacheKey = 'specific_stations';

    if (_cache.containsKey(cacheKey)) {
      final cached = _cache[cacheKey]!;
      if (!cached.isExpired) {
        AppLogger.logInfo('📦 Returning cached specific stations');
        return cached.data as Map<String, String>;
      }
    }

    try {
      final response = await _client
          .from(AppConstants.tableStationsAuth)
          .select('st_name, st_email');

      final Map<String, String> specificStations = {};
      for (final row in response) {
        specificStations[row['st_name'] as String] = row['st_email'] as String;
      }

      _cache[cacheKey] =
          CachedData(data: specificStations, timestamp: DateTime.now());
      return specificStations;
    } catch (e, stackTrace) {
      AppLogger.logError('Failed to fetch specific stations', e, stackTrace);
      if (_cache.containsKey(cacheKey)) {
        return _cache[cacheKey]!.data as Map<String, String>;
      }
      return {};
    }
  }

  void clearCacheKey(String key) {
    _cache.remove(key);
    AppLogger.logInfo('🗑️ Cache key cleared: $key');
  }

  Future<void> updateStationLoad(String stationName, double newLoad) async {
    final now = DateTime.now();
    final hourStr = 'hour_${now.hour.toString().padLeft(2, '0')}';
    try {
      await _client
          .from(AppConstants.tableStation)
          .update({
            'station_load': newLoad,
            hourStr: newLoad,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('station_name', stationName)
          .timeout(AppConstants.timeoutDuration);
      _cache.remove('station_loads');
      AppLogger.logSuccess('✅ Station load updated: $stationName = $newLoad');
    } on PostgrestException catch (e) {
      AppLogger.logError('Database error while updating station', e);
      throw Exception('خطأ في قاعدة البيانات: ${e.message}');
    } catch (e, stackTrace) {
      AppLogger.logError('Failed to update station load', e, stackTrace);
      throw Exception('فشل في تحديث حمل المحطة');
    }
  }

  Future<void> updateStationSign(String stationName, bool isPositive) async {
    try {
      await _client
          .from(AppConstants.tableStation)
          .update({'station_sign': isPositive})
          .eq('station_name', stationName)
          .timeout(AppConstants.timeoutDuration);
      _cache.remove('station_loads');
      AppLogger.logSuccess(
          '✅ Station sign updated: $stationName = $isPositive');
    } on PostgrestException catch (e) {
      AppLogger.logError('Database error while updating station sign', e);
      throw Exception('خطأ في قاعدة البيانات: ${e.message}');
    } catch (e, stackTrace) {
      AppLogger.logError('Failed to update station sign', e, stackTrace);
      throw Exception('فشل في تحديث إشارة المحطة');
    }
  }

  Future<bool> checkCrccPermission(String email) async {
    try {
      final response = await _client
          .from(AppConstants.tableUserCrcc)
          .select()
          .ilike('user_email', email.trim())
          .maybeSingle();
      return response != null;
    } catch (e) {
      AppLogger.logError('Error checking CRCC permissions', e);
      return false;
    }
  }

  Future<void> upsertHourlyMaxLoad(
      int hour, DateTime date, double maxLoad) async {
    try {
      final formattedDate = date.toIso8601String().split('T')[0];
      await _client.from(AppConstants.tableHourlyMaxLoads).upsert({
        'hour': hour,
        'date': formattedDate,
        'max_load': maxLoad,
      }, onConflict: 'hour,date').timeout(AppConstants.timeoutDuration);
      AppLogger.logSuccess('✅ Hourly max load upserted: Hour $hour = $maxLoad');
    } on PostgrestException catch (e) {
      AppLogger.logError('Database error while upserting', e);
      throw Exception('خطأ في قاعدة البيانات: ${e.message}');
    } catch (e, stackTrace) {
      AppLogger.logError('Failed to upsert hourly max load', e, stackTrace);
      throw Exception('فشل في تحديث الحمل الأقصى للساعة');
    }
  }

  Future<List<Map<String, dynamic>>> fetchHourlyMaxLoads(DateTime date) async {
    try {
      final formattedDate = date.toIso8601String().split('T')[0];
      return await _client
          .from(AppConstants.tableHourlyMaxLoads)
          .select()
          .eq('date', formattedDate)
          .order('hour', ascending: true)
          .timeout(AppConstants.timeoutDuration);
    } on PostgrestException catch (e) {
      AppLogger.logError('Database error while fetching hourly loads', e);
      throw Exception('خطأ في قاعدة البيانات: ${e.message}');
    } catch (e, stackTrace) {
      AppLogger.logError('Failed to fetch hourly max loads', e, stackTrace);
      throw Exception('فشل في جلب الأحمال الأقصى للساعات');
    }
  }

  Future<void> clearCache() async {
    _cache.clear();
    AppLogger.logInfo('🗑️ Cache cleared');
  }
}

// ---------------------------------------------------------------------------

class SupabaseServiceHourly {
  SupabaseClient get _client => Supabase.instance.client;

  Future<List<StationHourlyLoad>> fetchStationHourlyLoads({
    int limit = AppConstants.hourlyFetchLimit,
  }) async {
    try {
      final response = await _client
          .from(AppConstants.tableStation)
          .select(
            'station_name, hour_00, hour_01, hour_02, hour_03, hour_04, '
            'hour_05, hour_06, hour_07, hour_08, hour_09, hour_10, hour_11, '
            'hour_12, hour_13, hour_14, hour_15, hour_16, hour_17, hour_18, '
            'hour_19, hour_20, hour_21, hour_22, hour_23',
          )
          .limit(limit)
          .timeout(AppConstants.timeoutDuration);

      return (response as List<dynamic>)
          .map((json) => StationHourlyLoad.fromJson(json))
          .toList();
    } on TimeoutException {
      AppLogger.logError('Request timed out');
      throw Exception('انتهت مهلة الطلب. تحقق من اتصالك بالإنترنت');
    } on PostgrestException catch (e) {
      AppLogger.logError('Database error', e);
      throw Exception('خطأ في قاعدة البيانات: ${e.message}');
    } catch (e, stackTrace) {
      AppLogger.logError('Failed to fetch station hourly loads', e, stackTrace);
      throw Exception('فشل في جلب الأحمال الساعية للمحطات');
    }
  }
}

// ---------------------------------------------------------------------------

class CachedData {
  final dynamic data;
  final DateTime timestamp;

  CachedData({required this.data, required this.timestamp});

  bool get isExpired =>
      DateTime.now().difference(timestamp) > SupabaseService.cacheDuration;
}

import 'dart:convert';
import 'package:amiraly/app/common/models/appmodels.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesController extends GetxController {
  static FavoritesController get instance => Get.find();
  final RxList<StationDetialesModel> favorites = <StationDetialesModel>[].obs;

  // استخدام Set للتحقق السريع من المفضلات (Lookup Optimization O(1))
  final RxSet<String> _favoriteNames = <String>{}.obs;

  static const String _favoritesKey = 'favorites';

  @override
  void onInit() {
    super.onInit();
    _loadFavorites();
  }

  bool isFavorite(StationDetialesModel station) {
    return _favoriteNames.contains(station.name);
  }

  Future<void> toggleFavorite(StationDetialesModel station) async {
    try {
      if (isFavorite(station)) {
        favorites.removeWhere((fav) => fav.name == station.name);
        _favoriteNames.remove(station.name);
      } else {
        favorites.add(station);
        _favoriteNames.add(station.name);
      }
      await _saveFavorites();
    } catch (e) {
      debugPrint('Error toggling favorite');
      Get.snackbar('خطأ', 'فشل في تحديث المفضلات');
    }
  }

  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoriteJsons =
          favorites.map((fav) => jsonEncode(fav.toJson())).toList();
      await prefs.setStringList(_favoritesKey, favoriteJsons);
    } catch (e) {
      debugPrint('Error saving');
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoriteJsons = prefs.getStringList(_favoritesKey) ?? [];

      favorites.clear();
      _favoriteNames.clear();

      for (var jsonStr in favoriteJsons) {
        try {
          final station = StationDetialesModel.fromJson(jsonDecode(jsonStr));
          if (station.name.isNotEmpty) {
            favorites.add(station);
            _favoriteNames.add(station.name);
          }
        } catch (e) {
          debugPrint('Error parsing favorite');
        }
      }
    } catch (e) {
      debugPrint('Error loading');
    }
  }
}

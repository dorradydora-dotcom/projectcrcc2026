import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:amiraly/app/util/constant/constants.dart';

class ZoneController extends GetxController {
  final RxMap<String, String> zonePhotos = <String, String>{}.obs;
  final RxMap<String, String?> zoneErrors = <String, String?>{}.obs;
  final RxMap<String, bool> isLoading = <String, bool>{}.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAllZonePhotos();
  }

  Future<void> fetchAllZonePhotos() async {
    const zones = ['north', 'east', 'south', 'west'];
    final zonesToFetch = zones.where((z) => !(zonePhotos.containsKey(z) && zonePhotos[z]!.isNotEmpty)).toList();
    
    if (zonesToFetch.isEmpty) return;

    try {
      Future.microtask(() {
        for (var z in zonesToFetch) {
          isLoading[z] = true;
          zoneErrors[z] = null;
        }
      });

      final supabase = Supabase.instance.client;
      final response = await supabase
          .from(AppConstants.tableZone)
          .select('name, image_url')
          .inFilter('name', zonesToFetch);

      for (var row in response) {
        final zoneName = row['name'] as String;
        final String photoUrl = row['image_url'] as String? ?? '';
        
        if (photoUrl.isEmpty) {
          zoneErrors[zoneName] = 'No photo available';
        } else {
          zonePhotos[zoneName] = photoUrl;
        }
      }

      for (var z in zonesToFetch) {
        if (!zonePhotos.containsKey(z) && zoneErrors[z] == null) {
          zoneErrors[z] = 'No $z zone found';
        }
      }
    } catch (e) {
      for (var z in zonesToFetch) {
        zoneErrors[z] = 'Error: $e';
      }
    } finally {
      for (var z in zonesToFetch) {
        isLoading[z] = false;
      }
    }
  }

  Future<void> fetchZonePhoto(String zoneName) async {
    if (zonePhotos.containsKey(zoneName) && zonePhotos[zoneName]!.isNotEmpty) {
      return;
    }

    try {
      Future.microtask(() {
        isLoading[zoneName] = true;
        zoneErrors[zoneName] = null;
      });

      final supabase = Supabase.instance.client;

      final response = await supabase
          .from(AppConstants.tableZone)
          .select('image_url')
          .eq('name', zoneName)
          .maybeSingle();

      if (response == null) {
        zoneErrors[zoneName] = 'No $zoneName zone found';
        return;
      }

      String photoUrl = response['image_url'] as String? ?? '';

      if (photoUrl.isEmpty) {
        zoneErrors[zoneName] = 'No photo available';
      } else {
        zonePhotos[zoneName] = photoUrl;
      }
    } catch (e) {
      zoneErrors[zoneName] = 'Error: $e';
    } finally {
      isLoading[zoneName] = false;
    }
  }
}

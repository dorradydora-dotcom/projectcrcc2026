import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    await Future.wait(zones.map((zone) => fetchZonePhoto(zone)));
  }

  Future<void> fetchZonePhoto(String zoneName) async {
    if (zonePhotos.containsKey(zoneName) && zonePhotos[zoneName]!.isNotEmpty) {
      return;
    }

    try {
      // Use microtask to avoid "setState() or markNeedsBuild() called during build"
      // when multiple screens are initializing in the same frame (e.g. TabBarView)
      Future.microtask(() {
        isLoading[zoneName] = true;
        zoneErrors[zoneName] = null;
      });

      final supabase = Supabase.instance.client;

      final response = await supabase
          .from('zone')
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

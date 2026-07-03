import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../hive/hive_boxes.dart';

/// Resolves device coordinates for prayer-time calculation. Falls back to the
/// last known (cached) position when permission is denied or the location
/// service is off, so the prayer times card still has something to show.
class LocationRepository {
  ({double lat, double lng})? getCachedLocation() {
    final lat = HiveBoxes.location.get('lat');
    final lng = HiveBoxes.location.get('lng');
    if (lat == null || lng == null) return null;
    return (lat: lat, lng: lng);
  }

  Future<({double lat, double lng})?> resolveLocation() async {
    try {
      debugPrint('[PrayerTimes][Location] checking service');
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        final cached = getCachedLocation();
        debugPrint('[PrayerTimes][Location] service disabled cached=$cached');
        return cached;
      }

      var permission = await Geolocator.checkPermission();
      debugPrint('[PrayerTimes][Location] permission=$permission');
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        debugPrint('[PrayerTimes][Location] requested permission=$permission');
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        final cached = getCachedLocation();
        debugPrint('[PrayerTimes][Location] permission denied cached=$cached');
        return cached;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.reduced,
        ),
      );
      await HiveBoxes.location.put('lat', position.latitude);
      await HiveBoxes.location.put('lng', position.longitude);
      debugPrint(
        '[PrayerTimes][Location] current lat=${position.latitude} lng=${position.longitude}',
      );
      return (lat: position.latitude, lng: position.longitude);
    } catch (error, stackTrace) {
      final cached = getCachedLocation();
      debugPrint('[PrayerTimes][Location] error=$error cached=$cached');
      debugPrint('$stackTrace');
      return cached;
    }
  }
}

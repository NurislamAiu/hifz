import 'dart:convert';

import '../hive/hive_boxes.dart';

class PrayerTimesCacheRepository {
  String key({
    required double lat,
    required double lng,
    required int method,
    required int month,
    required int year,
  }) {
    final roundedLat = lat.toStringAsFixed(4);
    final roundedLng = lng.toStringAsFixed(4);
    return '$roundedLat:$roundedLng:$method:${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';
  }

  Future<void> saveRawMonth({
    required String key,
    required List<Map<String, dynamic>> days,
  }) async {
    await HiveBoxes.prayerScheduleCache.put(
      key,
      jsonEncode({'cachedAt': DateTime.now().toIso8601String(), 'days': days}),
    );
  }

  List<Map<String, dynamic>>? getRawMonth(String key) {
    final encoded = HiveBoxes.prayerScheduleCache.get(key);
    if (encoded == null) return null;
    final decoded = jsonDecode(encoded) as Map<String, dynamic>;
    return (decoded['days'] as List<dynamic>)
        .cast<Map<dynamic, dynamic>>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }
}

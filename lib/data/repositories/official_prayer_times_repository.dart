import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/daily_prayer_times.dart';
import '../models/prayer_calculation_method.dart';
import '../models/prayer_city.dart';
import '../models/prayer_schedule.dart';
import 'next_prayer_service.dart';

void debugPrint(String? message, {int? wrapWidth}) {}

/// Serves the official Kazakhstan (ҚМДБ / muftyat.kz) prayer times bundled as a
/// JSON asset — one entry per day for the major cities, ~2 years ahead. These
/// match the official published times exactly, avoiding the 2–5 min drift of a
/// generic calculation. Returns `null` when the city or date isn't covered so
/// the caller can fall back to the computed schedule.
class OfficialPrayerTimesRepository {
  OfficialPrayerTimesRepository({NextPrayerService? nextPrayerService})
    : _nextPrayerService = nextPrayerService ?? const NextPrayerService();

  static const _assetPath = 'assets/prayer_times/muftyat.json';
  static const _labels = <String, String>{
    'fajr': 'Фаджр',
    'sunrise': 'Восход',
    'dhuhr': 'Зухр',
    'asr': 'Аср',
    'maghrib': 'Магриб',
    'isha': 'Иша',
  };

  final NextPrayerService _nextPrayerService;

  List<String>? _keys;
  Map<String, dynamic>? _cities;
  bool _loadFailed = false;
  bool _tzInitialized = false;

  Future<void> _ensureLoaded() async {
    if (_cities != null || _loadFailed) return;
    try {
      final raw = await rootBundle.loadString(_assetPath);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _keys = (decoded['keys'] as List<dynamic>).cast<String>();
      _cities = decoded['cities'] as Map<String, dynamic>;
      debugPrint('[Prayer][Official] loaded cities=${_cities!.keys.length}');
    } catch (error, stackTrace) {
      debugPrint('[Prayer][Official] load failed: $error\n$stackTrace');
      _loadFailed = true;
    }
  }

  void _ensureTimeZones() {
    if (_tzInitialized) return;
    tzdata.initializeTimeZones();
    _tzInitialized = true;
  }

  /// Returns the official schedule for [city] today, or `null` if the city or
  /// today's date is not in the bundled data.
  Future<DailyPrayerTimes?> getSchedule({
    required PrayerCity city,
    required PrayerTimeAdjustments adjustments,
    DateTime? now,
  }) async {
    await _ensureLoaded();
    final cities = _cities;
    final keys = _keys;
    if (cities == null || keys == null) return null;

    final cityDays = cities[city.id] as Map<String, dynamic>?;
    if (cityDays == null) return null;

    _ensureTimeZones();
    final location = tz.getLocation(city.timeZone);
    final current = tz.TZDateTime.from(now ?? DateTime.now(), location);

    final todayRaw = (cityDays[_dateKey(current)] as List<dynamic>?)
        ?.cast<String>();
    if (todayRaw == null) {
      return null; // outside bundled range → let caller fall back
    }

    final tomorrow = current.add(const Duration(days: 1));
    final tomorrowRaw = (cityDays[_dateKey(tomorrow)] as List<dynamic>?)
        ?.cast<String>();

    List<PrayerScheduleEntry> build(List<String> raw, tz.TZDateTime day) {
      final entries = <PrayerScheduleEntry>[];
      for (var i = 0; i < keys.length && i < raw.length; i++) {
        final key = keys[i];
        final parts = raw[i].split(':');
        final time = tz.TZDateTime(
          location,
          day.year,
          day.month,
          day.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        ).add(Duration(minutes: adjustments.forKey(key)));
        entries.add(
          PrayerScheduleEntry(key: key, label: _labels[key] ?? key, time: time),
        );
      }
      return entries;
    }

    final todayEntries = build(todayRaw, current);
    final tomorrowEntries = tomorrowRaw == null
        ? null
        : build(tomorrowRaw, tomorrow);

    final next = _nextPrayerService.nextPrayer(
      todayEntries,
      tomorrowEntries: tomorrowEntries,
      now: current,
    );

    return DailyPrayerTimes(
      entries: todayEntries
          .map((e) => PrayerTimeEntry(key: e.key, label: e.label, time: e.time))
          .toList(),
      next: PrayerTimeEntry(key: next.key, label: next.label, time: next.time),
      cityName: city.name,
      dateLabel:
          '${current.day.toString().padLeft(2, '0')}.${current.month.toString().padLeft(2, '0')}.${current.year}',
      methodName: 'ҚМДБ · muftyat.kz',
      fromCache: true,
    );
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

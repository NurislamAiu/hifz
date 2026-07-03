import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../api/aladhan_api_client.dart';
import '../models/daily_prayer_times.dart';
import '../models/prayer_calculation_method.dart';
import '../models/prayer_schedule.dart';
import 'next_prayer_service.dart';
import 'prayer_times_cache_repository.dart';

class PrayerTimesRepository {
  PrayerTimesRepository({
    AladhanApiClient? apiClient,
    PrayerTimesCacheRepository? cacheRepository,
    NextPrayerService? nextPrayerService,
  }) : _apiClient = apiClient ?? AladhanApiClient(),
       _cacheRepository = cacheRepository ?? PrayerTimesCacheRepository(),
       _nextPrayerService = nextPrayerService ?? const NextPrayerService();

  final AladhanApiClient _apiClient;
  final PrayerTimesCacheRepository _cacheRepository;
  final NextPrayerService _nextPrayerService;
  bool _timeZonesInitialized = false;

  void _ensureTimeZonesInitialized() {
    if (_timeZonesInitialized) return;
    tzdata.initializeTimeZones();
    _timeZonesInitialized = true;
    debugPrint('[PrayerTimes][Repo] timezone database initialized');
  }

  Future<DailyPrayerTimes> getTodaySchedule({
    required double lat,
    required double lng,
    required String cityName,
    required String? timeZone,
    required PrayerCalculationMethod method,
    required PrayerTimeAdjustments adjustments,
    DateTime? now,
  }) async {
    _ensureTimeZonesInitialized();
    final current = now ?? DateTime.now();
    debugPrint(
      '[PrayerTimes][Repo] getTodaySchedule city=$cityName lat=$lat lng=$lng '
      'tz=$timeZone method=${method.label}/${method.apiId} now=$current',
    );
    final cacheKey = _cacheRepository.key(
      lat: lat,
      lng: lng,
      method: method.apiId,
      month: current.month,
      year: current.year,
    );

    // Cache first: a month's timings are fixed, so once we have them for this
    // location/method/month we serve them straight from Hive and never touch
    // the network again — no more re-fetch (and reload flicker) on every launch.
    var fromCache = false;
    List<Map<String, dynamic>>? month = _cacheRepository.getRawMonth(cacheKey);
    if (month != null) {
      fromCache = true;
      debugPrint(
        '[PrayerTimes][Repo] cache hit days=${month.length}, skipping API',
      );
    } else {
      try {
        debugPrint(
          '[PrayerTimes][Repo] cache miss, fetching API cacheKey=$cacheKey',
        );
        month = await _apiClient.fetchMonthlyTimings(
          latitude: lat,
          longitude: lng,
          method: method.apiId,
          month: current.month,
          year: current.year,
        );
        await _cacheRepository.saveRawMonth(key: cacheKey, days: month);
        debugPrint('[PrayerTimes][Repo] API success days=${month.length}');
      } catch (error, stackTrace) {
        debugPrint('[PrayerTimes][Repo] API error=$error');
        debugPrint('$stackTrace');
        debugPrint('[PrayerTimes][Repo] no cache, using local fallback');
        return _calculateLocally(
          lat: lat,
          lng: lng,
          cityName: cityName,
          timeZone: timeZone,
          method: method,
          adjustments: adjustments,
          now: current,
        );
      }
    }

    final days = month;
    final todayKey = _dateKey(current);
    debugPrint('[PrayerTimes][Repo] todayKey=$todayKey');
    final rawToday = days.firstWhere(
      (item) => _dateKeyFromAladhan(item) == todayKey,
      orElse: () => days.first,
    );
    final today = PrayerScheduleDay.fromAladhanJson(
      rawToday,
      timeZone: timeZone,
      method: method,
      adjustments: adjustments,
    );
    debugPrint(
      '[PrayerTimes][Repo] parsed today=${today.dateKey} '
      'entries=${today.entries.map((e) => '${e.key}:${e.time.hour}:${e.time.minute.toString().padLeft(2, '0')}').join(', ')}',
    );
    final tomorrowKey = _dateKey(current.add(const Duration(days: 1)));
    final rawTomorrow = _firstWhereOrNull(
      days,
      (item) => _dateKeyFromAladhan(item) == tomorrowKey,
    );
    final tomorrow = rawTomorrow == null
        ? null
        : PrayerScheduleDay.fromAladhanJson(
            rawTomorrow,
            timeZone: timeZone,
            method: method,
            adjustments: adjustments,
          );
    final next = _nextPrayerService.nextPrayer(
      today.entries,
      tomorrowEntries: tomorrow?.entries,
      now: current,
    );
    debugPrint('[PrayerTimes][Repo] next=${next.label} time=${next.time}');

    return DailyPrayerTimes(
      entries: today.entries
          .map(
            (entry) => PrayerTimeEntry(
              key: entry.key,
              label: entry.label,
              time: entry.time,
            ),
          )
          .toList(),
      next: PrayerTimeEntry(key: next.key, label: next.label, time: next.time),
      cityName: cityName,
      dateLabel: today.dateLabel,
      methodName: method.label,
      fromCache: fromCache,
    );
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _dateKeyFromAladhan(Map<String, dynamic> item) {
    final date = item['date'] as Map<String, dynamic>;
    final gregorian = date['gregorian'] as Map<String, dynamic>;
    final parts = (gregorian['date'] as String).split('-');
    return '${parts[2]}-${parts[1]}-${parts[0]}';
  }

  Map<String, dynamic>? _firstWhereOrNull(
    List<Map<String, dynamic>> items,
    bool Function(Map<String, dynamic>) test,
  ) {
    for (final item in items) {
      if (test(item)) return item;
    }
    return null;
  }

  DailyPrayerTimes _calculateLocally({
    required double lat,
    required double lng,
    required String cityName,
    required String? timeZone,
    required PrayerCalculationMethod method,
    required PrayerTimeAdjustments adjustments,
    required DateTime now,
  }) {
    debugPrint(
      '[PrayerTimes][Repo] local fallback city=$cityName lat=$lat lng=$lng '
      'tz=$timeZone method=${method.label}',
    );
    final location = timeZone == null ? null : tz.getLocation(timeZone);
    final current = location == null ? now : tz.TZDateTime.from(now, location);
    final coordinates = Coordinates(lat, lng);
    final params = _localParamsFor(method);
    final todayTimes = PrayerTimes(
      date: current,
      coordinates: coordinates,
      calculationParameters: params,
    );
    final tomorrowTimes = PrayerTimes(
      date: current.add(const Duration(days: 1)),
      coordinates: coordinates,
      calculationParameters: params,
    );
    final todayEntries = _localEntriesFor(
      todayTimes,
      location: location,
      adjustments: adjustments,
    );
    final tomorrowEntries = _localEntriesFor(
      tomorrowTimes,
      location: location,
      adjustments: adjustments,
    );
    final next = _nextPrayerService.nextPrayer(
      todayEntries,
      tomorrowEntries: tomorrowEntries,
      now: current,
    );
    debugPrint(
      '[PrayerTimes][Repo] local entries=${todayEntries.map((e) => '${e.key}:${e.time.hour}:${e.time.minute.toString().padLeft(2, '0')}').join(', ')}',
    );
    debugPrint(
      '[PrayerTimes][Repo] local next=${next.label} time=${next.time}',
    );

    return DailyPrayerTimes(
      entries: todayEntries
          .map(
            (entry) => PrayerTimeEntry(
              key: entry.key,
              label: entry.label,
              time: entry.time,
            ),
          )
          .toList(),
      next: PrayerTimeEntry(key: next.key, label: next.label, time: next.time),
      cityName: cityName,
      dateLabel:
          '${current.day.toString().padLeft(2, '0')}.${current.month.toString().padLeft(2, '0')}.${current.year}',
      methodName: '${method.label} • локально',
    );
  }

  List<PrayerScheduleEntry> _localEntriesFor(
    PrayerTimes times, {
    required tz.Location? location,
    required PrayerTimeAdjustments adjustments,
  }) {
    PrayerScheduleEntry entry(String key, String label, DateTime time) {
      final displayTime = location == null
          ? time.toLocal()
          : tz.TZDateTime.from(time, location);
      return PrayerScheduleEntry(
        key: key,
        label: label,
        time: displayTime.add(Duration(minutes: adjustments.forKey(key))),
      );
    }

    return [
      entry('fajr', 'Фаджр', times.fajr),
      entry('sunrise', 'Восход', times.sunrise),
      entry('dhuhr', 'Зухр', times.dhuhr),
      entry('asr', 'Аср', times.asr),
      entry('maghrib', 'Магриб', times.maghrib),
      entry('isha', 'Иша', times.isha),
    ];
  }

  CalculationParameters _localParamsFor(PrayerCalculationMethod method) {
    return switch (method) {
      PrayerCalculationMethod.muslimWorldLeague =>
        CalculationMethodParameters.muslimWorldLeague(),
      PrayerCalculationMethod.ummAlQura =>
        CalculationMethodParameters.ummAlQura(),
      PrayerCalculationMethod.egyptian =>
        CalculationMethodParameters.egyptian(),
      PrayerCalculationMethod.karachi => CalculationMethodParameters.karachi(),
      PrayerCalculationMethod.dubai => CalculationMethodParameters.dubai(),
      PrayerCalculationMethod.kuwait => CalculationMethodParameters.kuwait(),
      PrayerCalculationMethod.qatar => CalculationMethodParameters.qatar(),
      PrayerCalculationMethod.turkeyDiyanet =>
        CalculationMethodParameters.turkiye(),
    };
  }
}

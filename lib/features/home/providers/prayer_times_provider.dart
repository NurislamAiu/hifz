import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/daily_prayer_times.dart';
import '../../../data/models/prayer_city.dart';
import '../../../data/providers.dart';
import '../../settings/providers/settings_provider.dart';

/// Also refreshes notification schedules when they're enabled. Repentance
/// reminders don't need location, but prayer-time notifications do.
final prayerTimesProvider = FutureProvider<DailyPrayerTimes?>((ref) async {
  final settings = ref.watch(settingsControllerProvider);
  debugPrint(
    '[PrayerTimes][Provider] start cityId=${settings.selectedCityId} '
    'method=${settings.prayerMethod.label}',
  );
  final notificationsEnabled = settings.notificationsEnabled ?? false;
  final notificationRepository = ref.read(notificationRepositoryProvider);
  if (notificationsEnabled) {
    unawaited(notificationRepository.scheduleHourlyRepentanceReminders());
  }

  final selectedCity = PrayerCities.byId(settings.selectedCityId);

  // Prefer the official Kazakhstan (muftyat.kz) times bundled for the built-in
  // cities — they match the published schedule exactly (no 2–5 min drift).
  if (selectedCity != null) {
    final official = await ref.read(officialPrayerTimesRepositoryProvider).getSchedule(
          city: selectedCity,
          adjustments: settings.prayerAdjustments,
        );
    if (official != null) {
      debugPrint('[PrayerTimes][Provider] using official muftyat data for ${selectedCity.name}');
      if (notificationsEnabled) {
        unawaited(notificationRepository.scheduleTodayPrayerNotifications(
          official,
          disabledKeys: settings.disabledPrayerKeys,
        ));
      }
      return official;
    }
  }

  PrayerCity? effectiveCity = selectedCity;
  ({double lat, double lng})? coords;

  if (effectiveCity == null) {
    debugPrint('[PrayerTimes][Provider] no selected city, resolving location');
    coords = await ref.watch(locationRepositoryProvider).resolveLocation();
    if (coords == null) {
      effectiveCity = PrayerCities.defaultCity;
      coords = (lat: effectiveCity.lat, lng: effectiveCity.lng);
      debugPrint(
        '[PrayerTimes][Provider] location unavailable, fallback city=${effectiveCity.name}',
      );
    } else {
      debugPrint(
        '[PrayerTimes][Provider] location resolved lat=${coords.lat} lng=${coords.lng}',
      );
    }
  } else {
    coords = (lat: effectiveCity.lat, lng: effectiveCity.lng);
    debugPrint(
      '[PrayerTimes][Provider] selected city=${effectiveCity.name} '
      'lat=${coords.lat} lng=${coords.lng} tz=${effectiveCity.timeZone}',
    );
  }

  debugPrint(
    '[PrayerTimes][Provider] loading schedule city=${effectiveCity?.name ?? 'Моя геолокация'} '
    'lat=${coords.lat} lng=${coords.lng} tz=${effectiveCity?.timeZone}',
  );
  final prayerTimes = await ref
      .watch(prayerTimesRepositoryProvider)
      .getTodaySchedule(
        lat: coords.lat,
        lng: coords.lng,
        cityName: effectiveCity?.name ?? 'Моя геолокация',
        timeZone: effectiveCity?.timeZone,
        method: settings.prayerMethod,
        adjustments: settings.prayerAdjustments,
      );
  debugPrint(
    '[PrayerTimes][Provider] loaded next=${prayerTimes.next.label} '
    'at=${prayerTimes.next.time} entries=${prayerTimes.entries.length} '
    'fromCache=${prayerTimes.fromCache} method=${prayerTimes.methodName}',
  );

  if (notificationsEnabled) {
    unawaited(
      notificationRepository.scheduleTodayPrayerNotifications(
        prayerTimes,
        disabledKeys: settings.disabledPrayerKeys,
      ),
    );
  }

  return prayerTimes;
});

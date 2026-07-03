import '../models/prayer_schedule.dart';

class NextPrayerService {
  const NextPrayerService();

  PrayerScheduleEntry nextPrayer(
    List<PrayerScheduleEntry> entries, {
    List<PrayerScheduleEntry>? tomorrowEntries,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    for (final entry in entries) {
      if (entry.key == 'sunrise') continue;
      if (entry.time.isAfter(current)) return entry;
    }

    final source = tomorrowEntries ?? entries;
    final fajr = source.firstWhere((entry) => entry.key == 'fajr');
    return PrayerScheduleEntry(
      key: fajr.key,
      label: fajr.label,
      time: tomorrowEntries == null
          ? fajr.time.add(const Duration(days: 1))
          : fajr.time,
    );
  }
}

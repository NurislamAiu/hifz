class PrayerTimeEntry {
  final String key;
  final String label;
  final DateTime time;

  const PrayerTimeEntry({
    required this.key,
    required this.label,
    required this.time,
  });
}

class DailyPrayerTimes {
  /// Fajr, sunrise, dhuhr, asr, maghrib, isha — in that order.
  final List<PrayerTimeEntry> entries;

  /// The next upcoming prayer (rolls over to tomorrow's Fajr after Isha).
  final PrayerTimeEntry next;

  final String cityName;
  final String dateLabel;
  final String methodName;
  final bool fromCache;

  const DailyPrayerTimes({
    required this.entries,
    required this.next,
    required this.cityName,
    required this.dateLabel,
    required this.methodName,
    this.fromCache = false,
  });

  Duration get timeUntilNext => next.time.difference(DateTime.now());
}

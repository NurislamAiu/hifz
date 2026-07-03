import 'package:timezone/timezone.dart' as tz;

import 'prayer_calculation_method.dart';

class PrayerScheduleDay {
  const PrayerScheduleDay({
    required this.dateKey,
    required this.dateLabel,
    this.timeZone,
    required this.entries,
    required this.method,
    required this.fetchedAt,
  });

  final String dateKey;
  final String dateLabel;
  final String? timeZone;
  final List<PrayerScheduleEntry> entries;
  final PrayerCalculationMethod method;
  final DateTime fetchedAt;

  factory PrayerScheduleDay.fromAladhanJson(
    Map<String, dynamic> json, {
    required String? timeZone,
    required PrayerCalculationMethod method,
    required PrayerTimeAdjustments adjustments,
    DateTime? fetchedAt,
  }) {
    final date = json['date'] as Map<String, dynamic>;
    final gregorian = date['gregorian'] as Map<String, dynamic>;
    final timings = json['timings'] as Map<String, dynamic>;
    final dateParts = (gregorian['date'] as String).split('-');
    final day = int.parse(dateParts[0]);
    final month = int.parse(dateParts[1]);
    final year = int.parse(dateParts[2]);
    final location = timeZone == null ? null : tz.getLocation(timeZone);

    PrayerScheduleEntry entry(String key, String label, String apiKey) {
      final baseTime = _parseTime(
        timings[apiKey] as String,
        location: location,
        year: year,
        month: month,
        day: day,
      );
      return PrayerScheduleEntry(
        key: key,
        label: label,
        time: baseTime.add(Duration(minutes: adjustments.forKey(key))),
      );
    }

    return PrayerScheduleDay(
      dateKey:
          '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}',
      dateLabel: date['readable'] as String? ?? gregorian['date'] as String,
      timeZone: timeZone,
      method: method,
      fetchedAt: fetchedAt ?? DateTime.now(),
      entries: [
        entry('fajr', 'Фаджр', 'Fajr'),
        entry('sunrise', 'Восход', 'Sunrise'),
        entry('dhuhr', 'Зухр', 'Dhuhr'),
        entry('asr', 'Аср', 'Asr'),
        entry('maghrib', 'Магриб', 'Maghrib'),
        entry('isha', 'Иша', 'Isha'),
      ],
    );
  }

  factory PrayerScheduleDay.fromCacheJson(
    Map<String, dynamic> json, {
    required PrayerTimeAdjustments adjustments,
  }) {
    final method = PrayerCalculationMethod.byApiId(json['methodId'] as int?);
    return PrayerScheduleDay(
      dateKey: json['dateKey'] as String,
      dateLabel: json['dateLabel'] as String,
      timeZone: json['timeZone'] as String,
      method: method,
      fetchedAt: DateTime.parse(json['fetchedAt'] as String),
      entries: (json['entries'] as List<dynamic>)
          .cast<Map<dynamic, dynamic>>()
          .map((item) => item.cast<String, dynamic>())
          .map(
            (entry) => PrayerScheduleEntry.fromCacheJson(
              entry,
              adjustmentMinutes: adjustments.forKey(entry['key'] as String),
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toCacheJson() => {
    'dateKey': dateKey,
    'dateLabel': dateLabel,
    'timeZone': timeZone,
    'methodId': method.apiId,
    'methodName': method.label,
    'fetchedAt': fetchedAt.toIso8601String(),
    'entries': entries.map((entry) => entry.toCacheJson()).toList(),
  };

  static DateTime _parseTime(
    String raw, {
    required tz.Location? location,
    required int year,
    required int month,
    required int day,
  }) {
    final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(raw);
    if (match == null) {
      throw FormatException('Unsupported AlAdhan time format: $raw');
    }
    if (location == null) {
      return DateTime(
        year,
        month,
        day,
        int.parse(match.group(1)!),
        int.parse(match.group(2)!),
      );
    }
    return tz.TZDateTime(
      location,
      year,
      month,
      day,
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
    );
  }
}

class PrayerScheduleEntry {
  const PrayerScheduleEntry({
    required this.key,
    required this.label,
    required this.time,
  });

  final String key;
  final String label;
  final DateTime time;

  factory PrayerScheduleEntry.fromCacheJson(
    Map<String, dynamic> json, {
    required int adjustmentMinutes,
  }) {
    return PrayerScheduleEntry(
      key: json['key'] as String,
      label: json['label'] as String,
      time: DateTime.parse(
        json['time'] as String,
      ).add(Duration(minutes: adjustmentMinutes)),
    );
  }

  Map<String, dynamic> toCacheJson() => {
    'key': key,
    'label': label,
    'time': time.toIso8601String(),
  };
}

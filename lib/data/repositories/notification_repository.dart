import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/daily_prayer_times.dart';

/// Schedules local, on-device prayer-time reminders — nothing leaves the
/// device, no push service involved.
class NotificationRepository {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _pluginInitialized = false;
  static const _prayerNotificationStartId = 100;
  static const _prayerNotificationCount = 10;
  static const _repentanceNotificationStartId = 1000;
  static const _repentanceNotificationCount = 24;

  static const _repentanceReminders = [
    _RepentanceReminder(
      reference: '39:53',
      text: 'Не отчаивайтесь в милости Аллаха: Он прощает грехи полностью.',
    ),
    _RepentanceReminder(
      reference: '66:8',
      text:
          'Обратитесь к Аллаху с искренним покаянием, и Он исправит ваши дела.',
    ),
    _RepentanceReminder(
      reference: '25:70',
      text:
          'Кто покается, уверует и творит добро, тому Аллах заменит зло добром.',
    ),
    _RepentanceReminder(
      reference: '3:135',
      text: 'Когда оступились, поминайте Аллаха и просите прощения за грехи.',
    ),
    _RepentanceReminder(
      reference: '4:110',
      text:
          'Кто совершил зло, а потом попросил прощения, найдёт Аллаха Прощающим.',
    ),
    _RepentanceReminder(
      reference: '11:3',
      text: 'Просите прощения у Господа и возвращайтесь к Нему.',
    ),
    _RepentanceReminder(
      reference: '24:31',
      text: 'Обращайтесь к Аллаху с покаянием все вместе, чтобы обрести успех.',
    ),
    _RepentanceReminder(
      reference: '42:25',
      text: 'Аллах принимает покаяние Своих рабов и прощает дурные поступки.',
    ),
    _RepentanceReminder(
      reference: '6:54',
      text: 'Кто покаялся после ошибки и исправился, тому Господь Милостив.',
    ),
    _RepentanceReminder(
      reference: '7:153',
      text: 'После раскаяния и веры Господь прощает и проявляет милость.',
    ),
    _RepentanceReminder(
      reference: '2:222',
      text: 'Аллах любит кающихся и любит очищающихся.',
    ),
    _RepentanceReminder(
      reference: '110:3',
      text:
          'Прославляйте Господа и просите у Него прощения: Он принимает покаяние.',
    ),
  ];

  Future<void> _ensureInitialized() async {
    if (_pluginInitialized) return;
    tzdata.initializeTimeZones();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      ),
    );
    _pluginInitialized = true;
  }

  /// Requests OS notification permission. Returns whether it was granted.
  Future<bool> requestPermission() async {
    await _ensureInitialized();
    if (Platform.isIOS) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }
    if (Platform.isAndroid) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      // null means the check doesn't apply on this Android version (pre-13) —
      // notifications are allowed by default there.
      return granted ?? true;
    }
    return true;
  }

  static const _prayerDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'prayer_times',
      'Время намаза',
      channelDescription: 'Напоминания о наступлении времени намаза',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  static const _repentanceDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'repentance_reminders',
      'Напоминания о покаянии',
      channelDescription: 'Ежечасные аяты о покаянии с русским переводом',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
    iOS: DarwinNotificationDetails(),
  );

  /// Replaces any previously scheduled prayer reminders with today's
  /// remaining ones.
  Future<void> scheduleTodayPrayerNotifications(
    DailyPrayerTimes prayerTimes,
  ) async {
    await _ensureInitialized();
    await cancelPrayerNotifications();

    final now = DateTime.now();
    var id = _prayerNotificationStartId;
    for (final entry in prayerTimes.entries) {
      if (entry.key == 'sunrise') continue;
      if (!entry.time.isAfter(now)) continue;

      await _plugin.zonedSchedule(
        id: id++,
        title: entry.label,
        body: 'Наступило время намаза — ${entry.label}',
        // `.from` preserves the exact instant (epoch millis) regardless of
        // the Location label, so this fires at the correct real-world time
        // without needing the device's IANA timezone name.
        scheduledDate: tz.TZDateTime.from(entry.time, tz.UTC),
        notificationDetails: _prayerDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  /// Schedules one recurring repentance reminder for each hour of the day.
  ///
  /// Local notifications can't rotate content inside a single repeating
  /// notification, so every hour gets its own daily notification with a
  /// different ayah.
  Future<void> scheduleHourlyRepentanceReminders() async {
    await _ensureInitialized();
    await cancelRepentanceNotifications();

    final now = DateTime.now();

    for (var i = 0; i < _repentanceNotificationCount; i++) {
      final reminder = _repentanceReminders[i % _repentanceReminders.length];
      final todayAtHour = DateTime(now.year, now.month, now.day, i);
      final scheduledAt = todayAtHour.isAfter(now)
          ? todayAtHour
          : todayAtHour.add(const Duration(days: 1));
      await _plugin.zonedSchedule(
        id: _repentanceNotificationStartId + i,
        title: 'Покаяние • Коран ${reminder.reference}',
        body: reminder.text,
        scheduledDate: tz.TZDateTime.from(scheduledAt, tz.UTC),
        notificationDetails: _repentanceDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> cancelPrayerNotifications() async {
    await _ensureInitialized();
    for (var i = 0; i < _prayerNotificationCount; i++) {
      await _plugin.cancel(id: _prayerNotificationStartId + i);
    }
  }

  Future<void> cancelRepentanceNotifications() async {
    await _ensureInitialized();
    for (var i = 0; i < _repentanceNotificationCount; i++) {
      await _plugin.cancel(id: _repentanceNotificationStartId + i);
    }
  }

  Future<void> cancelAll() async {
    await _ensureInitialized();
    await _plugin.cancelAll();
  }
}

class _RepentanceReminder {
  const _RepentanceReminder({required this.reference, required this.text});

  final String reference;
  final String text;
}

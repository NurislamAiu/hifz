import 'dart:io';
import 'dart:math';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/app_settings.dart';
import '../models/daily_prayer_times.dart';
import '../../core/localization/app_strings.dart';

/// Schedules local, on-device prayer-time reminders — nothing leaves the
/// device, no push service involved.
class NotificationRepository {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _pluginInitialized = false;
  static const _prayerNotificationStartId = 100;
  static const _prayerNotificationCount = 10;
  static const _repentanceNotificationStartId = 1000;
  static const _repentanceNotificationCount = 6;
  static const _repentanceWindowStartHour = 8;
  static const _repentanceWindowEndHour = 23;

  static const _gentleRepentanceReminders = [
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

  static const _firmRepentanceReminders = [
    _RepentanceReminder(
      reference: '4:56',
      text:
          'Тех, кто отверг Наши знамения, Мы сожжём в Огне. Едва их кожа сготовится, Мы заменим её новой, чтобы они вкусили мучения.',
    ),
    _RepentanceReminder(
      reference: '66:6',
      text:
          'Оберегайте себя и свои семьи от Огня, растопкой которого будут люди и камни.',
    ),
    _RepentanceReminder(
      reference: '22:19-20',
      text:
          'Для неверующих скроят одежды из Огня, а на головы им будут лить кипяток, расплавляющий их внутренности и кожу.',
    ),
    _RepentanceReminder(
      reference: '14:49-50',
      text:
          'В тот День ты увидишь грешников, закованных в цепи, в одеяниях из смолы, и Огонь будет покрывать их лица.',
    ),
    _RepentanceReminder(
      reference: '69:30-32',
      text:
          'Схватите его и закуйте, потом бросьте в Ад, потом стяните цепью длиной в семьдесят локтей.',
    ),
    _RepentanceReminder(
      reference: '50:19',
      text: 'Опьянение смертью явится с истиной. Вот то, от чего ты убегал!',
    ),
    _RepentanceReminder(
      reference: '23:99-100',
      text:
          'Когда к нему приходит смерть, он молит: «Господи, верни меня!» Но нет — позади них преграда до Дня воскрешения.',
    ),
    _RepentanceReminder(
      reference: '40:18',
      text:
          'Предупреди их о приближающемся Дне, когда сердца подступят к горлу и они будут задыхаться от скорби.',
    ),
    _RepentanceReminder(
      reference: '79:37-39',
      text:
          'Тому, кто преступил границы и предпочёл мирскую жизнь, пристанищем будет Ад.',
    ),
    _RepentanceReminder(
      reference: '101:6-9',
      text:
          'Чья чаша дел перевесит — тот в блаженстве. А чья окажется лёгкой — матерью его станет Бездна огня.',
    ),
    _RepentanceReminder(
      reference: '78:40',
      text:
          'Мы предостерегли вас о близком наказании. В тот День человек увидит то, что уготовили его руки.',
    ),
    _RepentanceReminder(
      reference: '89:23-24',
      text:
          'В тот День приведут Ад. Тогда человек опомнится, но какая польза от позднего раскаяния?',
    ),
  ];

  static const _gentleRepentanceRemindersKk = [
    _RepentanceReminder(
      reference: '39:53',
      text: 'Алланың рақымынан үміт үзбеңіз: Ол күнәларды толық кешіреді.',
    ),
    _RepentanceReminder(
      reference: '66:8',
      text: 'Аллаға шынайы тәубе етіңіз, Ол істеріңізді түзетеді.',
    ),
    _RepentanceReminder(
      reference: '25:70',
      text:
          'Кім тәубе етіп, иман келтіріп, ізгі амал жасаса, Алла жамандықтарын жақсылыққа ауыстырады.',
    ),
    _RepentanceReminder(
      reference: '3:135',
      text: 'Қателескенде Алланы еске алып, күнәларыңыз үшін кешірім сұраңыз.',
    ),
    _RepentanceReminder(
      reference: '4:110',
      text:
          'Кім жамандық жасап, кейін кешірім сұраса, Алланы Кешірімді табады.',
    ),
    _RepentanceReminder(
      reference: '11:3',
      text: 'Раббыңыздан кешірім сұрап, Оған қайтыңыз.',
    ),
    _RepentanceReminder(
      reference: '24:31',
      text: 'Табысқа жету үшін бәріңіз Аллаға тәубе етіңіздер.',
    ),
    _RepentanceReminder(
      reference: '42:25',
      text: 'Алла құлдарының тәубесін қабыл етіп, жамандықтарын кешіреді.',
    ),
  ];

  static const _firmRepentanceRemindersKk = [
    _RepentanceReminder(
      reference: '4:56',
      text:
          'Аяттарымызды терістегендерді Отқа саламыз. Терілері күйіп біткен сайын, азапты татуы үшін жаңа теріге ауыстырамыз.',
    ),
    _RepentanceReminder(
      reference: '66:6',
      text:
          'Өздеріңді және үй-іштеріңді отыны адамдар мен тастар болатын Оттан сақтаңдар.',
    ),
    _RepentanceReminder(
      reference: '22:19-20',
      text:
          'Кәпірлерге оттан киім пішіледі, бастарына қайнаған су құйылып, ішек-қарны мен терісі ериді.',
    ),
    _RepentanceReminder(
      reference: '14:49-50',
      text:
          'Ол күні күнәкарларды кісендеулі, шайыр киім киген, беттерін От жалмаған күйде көресің.',
    ),
    _RepentanceReminder(
      reference: '69:30-32',
      text:
          'Оны ұстаңдар да кісендеңдер, сосын Тозаққа тастаңдар, содан кейін жетпіс кез шынжырмен байлаңдар.',
    ),
    _RepentanceReminder(
      reference: '50:19',
      text: 'Өлім мастығы шындықпен келеді. Міне, сен қашқан нәрсе — осы!',
    ),
    _RepentanceReminder(
      reference: '23:99-100',
      text:
          'Оған өлім келгенде: «Раббым, мені қайтаршы!» — дейді. Жоқ! Артында қайта тірілу Күніне дейін тосқауыл бар.',
    ),
    _RepentanceReminder(
      reference: '40:18',
      text:
          'Оларды жақындаған Күннен сақтандыр: жүректер тамаққа тығылып, қайғыдан тұншығады.',
    ),
    _RepentanceReminder(
      reference: '79:37-39',
      text: 'Шектен шығып, дүние тіршілігін артық көргеннің барар жері — Тозақ.',
    ),
    _RepentanceReminder(
      reference: '101:6-9',
      text:
          'Амал таразысы ауыр болған рахатта болады. Жеңіл болғанның мекені — жалынды тұңғиық.',
    ),
    _RepentanceReminder(
      reference: '78:40',
      text:
          'Сендерді жақын азаптан сақтандырдық. Ол күні адам қолымен не жібергенін көреді.',
    ),
    _RepentanceReminder(
      reference: '89:23-24',
      text:
          'Ол күні Тозақ әкелінеді. Сонда адам есіне алады, бірақ кеш өкініштен қандай пайда?',
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

  NotificationDetails _prayerDetailsFor(AppLanguage language) =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          'prayer_times',
          language == AppLanguage.kk ? 'Намаз уақыты' : 'Время намаза',
          channelDescription: language == AppLanguage.kk
              ? 'Намаз уақыты кіргені туралы ескертулер'
              : 'Напоминания о наступлении времени намаза',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      );

  NotificationDetails _repentanceDetailsFor(
    AppLanguage language,
    RepentanceReminderTone tone,
    String bodyText,
  ) {
    // The "firm" tone is meant to jolt the reader — surface it as a high-
    // priority heads-up alert rather than a quiet notification.
    final firm = tone == RepentanceReminderTone.firm;
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'repentance_reminders',
        language == AppLanguage.kk
            ? 'Тәубе ескертулері'
            : 'Напоминания о покаянии',
        channelDescription: language == AppLanguage.kk
            ? 'Тәубе туралы аяттар және қазақша мағынасы'
            : 'Аяты о покаянии с русским переводом',
        importance: firm ? Importance.high : Importance.defaultImportance,
        priority: firm ? Priority.high : Priority.defaultPriority,
        // Show the full verse instead of truncating it in the collapsed row.
        styleInformation: BigTextStyleInformation(bodyText),
      ),
      iOS: DarwinNotificationDetails(
        interruptionLevel: firm
            ? InterruptionLevel.timeSensitive
            : InterruptionLevel.active,
      ),
    );
  }

  /// Replaces any previously scheduled prayer reminders with today's
  /// remaining ones.
  Future<void> scheduleTodayPrayerNotifications(
    DailyPrayerTimes prayerTimes, {
    Set<String> disabledKeys = const {},
    AppLanguage language = AppLanguage.ru,
  }) async {
    await _ensureInitialized();
    await cancelPrayerNotifications();

    final now = DateTime.now();
    var id = _prayerNotificationStartId;
    for (final entry in prayerTimes.entries) {
      if (entry.key == 'sunrise') continue;
      if (disabledKeys.contains(entry.key)) continue;
      if (!entry.time.isAfter(now)) continue;

      await _plugin.zonedSchedule(
        id: id++,
        title: _prayerName(entry.key, language),
        body: language == AppLanguage.kk
            ? '${_prayerName(entry.key, language)} намазының уақыты кірді'
            : 'Наступило время намаза — ${_prayerName(entry.key, language)}',
        // `.from` preserves the exact instant (epoch millis) regardless of
        // the Location label, so this fires at the correct real-world time
        // without needing the device's IANA timezone name.
        scheduledDate: tz.TZDateTime.from(entry.time, tz.UTC),
        notificationDetails: _prayerDetailsFor(language),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  /// Schedules a small set of daily repentance reminders at randomized times.
  ///
  /// The random seed includes the date, so each day gets a fresh spread while
  /// re-scheduling during the same day keeps replacing the same notification ids.
  Future<void> scheduleDailyRepentanceReminders({
    RepentanceReminderTone tone = RepentanceReminderTone.gentle,
    AppLanguage language = AppLanguage.ru,
  }) async {
    await _ensureInitialized();
    await cancelRepentanceNotifications();

    final now = DateTime.now();
    final reminders = _repentanceReminders(tone: tone, language: language);
    final seed =
        now.year * 10000 + now.month * 100 + now.day + tone.index * 100000;
    final random = Random(seed);
    final scheduledTimes = _randomReminderTimes(now, random);

    for (var i = 0; i < scheduledTimes.length; i++) {
      final reminder = reminders[random.nextInt(reminders.length)];
      await _plugin.zonedSchedule(
        id: _repentanceNotificationStartId + i,
        title: language == AppLanguage.kk
            ? 'Тәубе • Құран ${reminder.reference}'
            : 'Покаяние • Коран ${reminder.reference}',
        body: reminder.text,
        scheduledDate: tz.TZDateTime.from(scheduledTimes[i], tz.UTC),
        notificationDetails: _repentanceDetailsFor(language, tone, reminder.text),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  String _prayerName(String key, AppLanguage language) =>
      AppStrings(language).prayerName(key);

  List<_RepentanceReminder> _repentanceReminders({
    required RepentanceReminderTone tone,
    required AppLanguage language,
  }) {
    if (language == AppLanguage.ru) {
      return tone == RepentanceReminderTone.firm
          ? _firmRepentanceReminders
          : _gentleRepentanceReminders;
    }
    return tone == RepentanceReminderTone.firm
        ? _firmRepentanceRemindersKk
        : _gentleRepentanceRemindersKk;
  }

  List<DateTime> _randomReminderTimes(DateTime now, Random random) {
    final windowStart = DateTime(
      now.year,
      now.month,
      now.day,
      _repentanceWindowStartHour,
    );
    final windowEnd = DateTime(
      now.year,
      now.month,
      now.day,
      _repentanceWindowEndHour,
    );
    final windowMinutes = windowEnd.difference(windowStart).inMinutes;
    final offsets = <int>{};
    while (offsets.length < _repentanceNotificationCount) {
      offsets.add(random.nextInt(windowMinutes));
    }

    return offsets
        .map((offset) => windowStart.add(Duration(minutes: offset)))
        .map(
          (time) =>
              time.isAfter(now) ? time : time.add(const Duration(days: 1)),
        )
        .toList()
      ..sort();
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

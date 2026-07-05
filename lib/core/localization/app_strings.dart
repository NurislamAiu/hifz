import 'package:flutter/material.dart';

enum AppLanguage {
  ru('ru'),
  kk('kk');

  const AppLanguage(this.code);

  final String code;

  Locale get locale => Locale(code);

  static AppLanguage fromCode(String? code) => switch (code) {
    'ru' => AppLanguage.ru,
    'kk' => AppLanguage.kk,
    _ => AppLanguage.kk,
  };
}

class AppStrings {
  const AppStrings(this.language);

  final AppLanguage language;

  bool get isKk => language == AppLanguage.kk;

  static AppStrings of(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return AppStrings(AppLanguage.fromCode(locale.languageCode));
  }

  String get appTitle => 'Hifz';

  String get navHome => isKk ? 'Басты' : 'Главная';
  String get navStats => isKk ? 'Статистика' : 'Статистика';
  String get navReciters => isKk ? 'Қарилар' : 'Чтецы';
  String get navFavorites => isKk ? 'Таңдаулы' : 'Избранное';
  String get navZikr => isKk ? 'Зікір' : 'Зикры';
  String get navSettings => isKk ? 'Баптаулар' : 'Настройки';

  String get zikrTitle => isKk ? 'Зікірлер' : 'Зикры';
  String get zikrSubtitle => isKk ? 'Күнделікті тәсбих' : 'Ежедневный тасбих';
  String get zikrReset => isKk ? 'Қайта бастау' : 'Сбросить';
  String get zikrToday => isKk ? 'Бүгін' : 'Сегодня';
  String get zikrStreakDays => isKk ? 'Күн қатарынан' : 'Дней подряд';

  List<String> get weekdayShort => isKk
      ? const ['Дс', 'Сс', 'Ср', 'Бс', 'Жм', 'Сб', 'Жс']
      : const ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

  String get play => isKk ? 'Тыңдау' : 'Слушать';
  String get selectAyahToPlay =>
      isKk ? 'Тыңдау үшін аятты таңдаңыз' : 'Выберите аят для прослушивания';

  String get onboardingListenTitle =>
      isKk ? 'Құран тыңдаңыз' : 'Слушайте Коран';
  String get onboardingListenSubtitle => isKk
      ? 'Үздік қарилардың оқуындағы аяттар. Қай жерде болсаңыз да офлайн тыңдаңыз.'
      : 'Аяты в исполнении лучших чтецов. Слушайте офлайн — где бы вы ни были.';
  String get onboardingMemorizeTitle =>
      isKk ? 'Аяттарды жаттаңыз' : 'Учите аяты наизусть';
  String get onboardingMemorizeSubtitle => isKk
      ? 'Кез келген аятты қайталап қойып, хифз үшін қанша қажет болса сонша тыңдаңыз.'
      : 'Зацикливайте любой аят и повторяйте столько раз, сколько нужно для хифза.';
  String get onboardingFreeTitle =>
      isKk ? 'Толығымен тегін' : 'Полностью бесплатно';
  String get onboardingFreeSubtitle => isKk
      ? 'Жарнамасыз және жазылымсыз. Қолданба пайдалы болса, еңбекті садақа арқылы қолдай аласыз.'
      : 'Без рекламы и подписок — и всегда будет так. Если приложение помогло, вы можете сделать садака в поддержку труда команды.';
  String get skip => isKk ? 'Өткізу' : 'Пропустить';
  String get start => isKk ? 'Бастау' : 'Начать';
  String get next => isKk ? 'Келесі' : 'Далее';

  String greetingForHour(int hour) {
    if (isKk) {
      if (hour < 6) return 'Қайырлы түн';
      if (hour < 12) return 'Қайырлы таң';
      if (hour < 18) return 'Қайырлы күн';
      return 'Қайырлы кеш';
    }
    if (hour < 6) return 'Доброй ночи';
    if (hour < 12) return 'Доброе утро';
    if (hour < 18) return 'Добрый день';
    return 'Добрый вечер';
  }

  String get geo => isKk ? 'Гео' : 'Гео';
  String get prayerCity => isKk ? 'Намаз қаласы' : 'Город для намаза';
  String get myLocation => isKk ? 'Менің геолокациям' : 'Моя геолокация';
  String get useCurrentLocation => isKk
      ? 'Ағымдағы орынды пайдалану'
      : 'Использовать текущее местоположение';
  String get currentLocationName =>
      isKk ? 'Менің геолокациям' : 'Моя геолокация';

  String get prayerTimes => isKk ? 'Намаз уақыты' : 'Время намаза';
  String get retry => isKk ? 'Қайталау' : 'Повторить';
  String get enable => isKk ? 'Қосу' : 'Включить';
  String get locationPermissionMessage => isKk
      ? 'Намаз уақытын көру үшін геолокацияға рұқсат беріңіз'
      : 'Разрешите доступ к геолокации, чтобы увидеть время намазов';
  String prayerCountdown(String label, String countdown) =>
      isKk ? '$label: $countdown қалды' : '$label через $countdown';
  String get prayerError => isKk
      ? 'Намаз уақытын көрсету мүмкін болмады. Қайталап көріңіз'
      : 'Не удалось показать время намаза. Попробуйте ещё раз';
  String get prayerSettings => isKk ? 'Намаз баптаулары' : 'Настройки намаза';
  String get prayerNotifications =>
      isKk ? 'Намаз хабарламалары' : 'Уведомления о намазе';
  String get disablePrayerHint => isKk
      ? 'Қажет емес намаз ескертулерін өшіріңіз'
      : 'Выключите намазы, о которых не нужно напоминать';
  String get prayerSettingsTooltip =>
      isKk ? 'Намаз баптаулары' : 'Настройки намаза';

  String durationHoursMinutes(int hours, int minutes) =>
      isKk ? '$hours сағ $minutes мин' : '$hours ч $minutes мин';
  String durationMinutes(int minutes) => '$minutes ${isKk ? 'мин' : 'мин'}';
  String daysShort(int days) => isKk ? '$days күн' : '$days дн';
  String ayahCount(int count) => isKk ? '$count аят' : '$count аятов';
  String ayah(int number) => isKk ? '$number-аят' : 'Аят $number';

  String prayerName(String key) => switch (key) {
    'fajr' => isKk ? 'Таң' : 'Фаджр',
    'sunrise' => isKk ? 'Күн шығу' : 'Восход',
    'dhuhr' => isKk ? 'Бесін' : 'Зухр',
    'asr' => isKk ? 'Екінті' : 'Аср',
    'maghrib' => isKk ? 'Ақшам' : 'Магриб',
    'isha' => isKk ? 'Құптан' : 'Иша',
    _ => key,
  };

  String get statistics => isKk ? 'Статистика' : 'Статистика';
  String get details => isKk ? 'Толығырақ' : 'Подробнее';
  String get streak => isKk ? 'Стрик' : 'Стрик';
  String get record => isKk ? 'Рекорд' : 'Рекорд';
  String get thisWeek => isKk ? 'Осы апта' : 'Эта неделя';
  String get listen => isKk ? 'Тыңдау' : 'Слушать';
  String get listeningToday => isKk ? 'Бүгін тыңдалды' : 'Слушание сегодня';
  String goalMinutes(int minutes) =>
      isKk ? 'мақсат $minutes мин' : 'цель $minutes мин';
  String get dailyGoals => isKk ? 'Күндік мақсаттар' : 'Цели на день';
  String get listenPerDay => isKk ? 'Күніне тыңдау' : 'Слушать в день';
  String get save => isKk ? 'Сақтау' : 'Сохранить';
  String get editGoals => isKk ? 'Мақсаттарды өзгерту' : 'Изменить цели';
  String weekMinuteValue(int minutes) => '$minutes мин';
  List<String> get weekLabels => isKk
      ? const ['Дс', 'Сс', 'Ср', 'Бс', 'Жм', 'Сб', 'Жс']
      : const ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

  String get reciters => isKk ? 'Қарилар' : 'Чтецы';
  String get chooseReciter => isKk
      ? 'Сүрелерді ашу үшін қариды таңдаңыз'
      : 'Выберите чтеца, чтобы открыть список сур';
  String get searchReciter => isKk ? 'Қари іздеу' : 'Поиск чтеца';
  String get nothingFound => isKk ? 'Ештеңе табылмады' : 'Ничего не найдено';

  String get surahs => isKk ? 'Сүрелер' : 'Суры';
  String get searchSurah => isKk ? 'Сүре іздеу' : 'Поиск суры';
  String get quranLoadError => isKk
      ? 'Құранды жүктеу мүмкін болмады.\nИнтернет байланысын тексеріңіз.'
      : 'Не удалось загрузить Коран.\nПроверьте подключение к интернету.';
  String get lastReading => isKk ? 'Соңғы оқу' : 'Последнее чтение';
  String surahMeta(String revelationType, int ayahs) {
    final place = revelationType == 'Meccan'
        ? (isKk ? 'МЕККЕЛІК' : 'МЕККАНСКАЯ')
        : (isKk ? 'МЕДИНАЛЫҚ' : 'МЕДИНСКАЯ');
    return '$place • ${ayahCount(ayahs).toUpperCase()}';
  }

  String get favorites => isKk ? 'Таңдаулы' : 'Избранное';
  String get recentlyPlayed =>
      isKk ? 'Жақында тыңдалған' : 'Недавно прослушано';
  String get saved => isKk ? 'Сақталған' : 'Сохранённое';
  String get emptyCategory =>
      isKk ? 'Бұл санатта ештеңе жоқ' : 'Ничего нет в этой категории';
  String get all => isKk ? 'Барлығы' : 'Все';
  String get favoriteSurahs => isKk ? 'Сүрелер' : 'Суры';
  String get favoriteAyahs => isKk ? 'Аяттар' : 'Аяты';
  String get noFavorites =>
      isKk ? 'Әзірге таңдаулы жоқ' : 'Пока нет избранного';
  String get favoritesHint => isKk
      ? 'Сүрелер мен аяттарды жұлдызшамен белгілеңіз — олар осында шығады'
      : 'Отмечайте суры и аяты звёздочкой — они появятся здесь';

  String get continueListening => isKk ? 'Жалғастыру' : 'Продолжить';
  String reciterAyah(String reciter, int ayahNumber) =>
      isKk ? '$reciter · ${ayah(ayahNumber)}' : '$reciter · Аят $ayahNumber';

  String get progress => isKk ? 'Статистика' : 'Статистика';
  String get totalDays => isKk ? 'Жалпы күн' : 'Дней всего';
  String get searchJuz => isKk ? 'Жүз іздеу' : 'Поиск джуза';
  String juz(int number) => isKk ? '$number-жүз' : 'Джуз $number';
  String get bySurahs => isKk ? 'Сүрелер' : 'По сурам';
  String get byJuz => isKk ? 'Жүздер' : 'По джузам';
  String juzSurahsCount(int count) => isKk ? '$count сүре' : '$count сур';
  String juzStartsAt(String surah, int ayah) => isKk
      ? '$surah · $ayah-аяттан'
      : '$surah · с аята $ayah';
  String overviewDays(int days) =>
      isKk ? '$days күндік шолу' : 'Обзор за $days дней';
  String activeDaysSummary(int active, int total, int percent) => isKk
      ? '$total күннің $active күні тыңдалды — $percent%'
      : 'Слушали $active из $total дн. — $percent%';
  String get wholeQuranProgress =>
      isKk ? 'Бүкіл Құран бойынша прогресс' : 'Прогресс по всему Корану';
  String memorizedAyahs(int memorized) => isKk
      ? '6236 аяттың $memorized жатталды'
      : 'Заучено $memorized из 6236 аятов';

  String get settings => isKk ? 'Баптаулар' : 'Настройки';
  String get readingSection => isKk ? 'ОҚУ' : 'ЧТЕНИЕ';
  String get notificationsSection => isKk ? 'ХАБАРЛАМАЛАР' : 'УВЕДОМЛЕНИЯ';
  String get storageSection => isKk ? 'САҚТАУ ОРНЫ' : 'ХРАНИЛИЩЕ';
  String get supportSection => isKk ? 'ЖОБАНЫ ҚОЛДАУ' : 'ПОДДЕРЖКА ПРОЕКТА';
  String get aboutSection => isKk ? 'ҚОЛДАНБА ТУРАЛЫ' : 'О ПРИЛОЖЕНИИ';
  String get appLanguage => isKk ? 'Қолданба тілі' : 'Язык приложения';
  String get appLanguageSubtitle =>
      isKk ? 'Қазақша немесе орысша' : 'Казахский или русский';
  String get russian => 'Русский';
  String get kazakh => 'Қазақша';
  String get displayText => isKk ? 'Мәтінді көрсету' : 'Отображение текста';
  String get defaultSpeed =>
      isKk ? 'Әдепкі жылдамдық' : 'Скорость по умолчанию';
  String get normal => isKk ? 'қалыпты' : 'обычно';
  String get arabicShort => isKk ? 'Араб.' : 'Араб.';
  String get transliterationShort => isKk ? 'Транслит.' : 'Транслит.';
  String get both => isKk ? 'Екеуі' : 'Оба';
  String get reminders => isKk ? 'Ескертулер' : 'Напоминания';
  String get remindersSubtitle => isKk
      ? 'Намаз және тәубе аяттары кездейсоқ уақытта'
      : 'Намазы и аяты о покаянии в случайное время';
  String get allowNotifications => isKk
      ? 'Құрылғы баптауларында хабарламаларға рұқсат беріңіз'
      : 'Разрешите уведомления в настройках устройства';
  String get repentanceTone => isKk ? 'Тәубе тоны' : 'Тон покаяния';
  String get repentanceToneSubtitle => isKk
      ? 'Жұмсақ немесе қатаң аят-ескертулер'
      : 'Мягкие или строгие аяты-напоминания';
  String get gentle => isKk ? 'Жұмсақ' : 'Мягко';
  String get firm => isKk ? 'Қатаң' : 'Жёстко';
  String get downloadedAyahs => isKk ? 'Жүктелген аяттар' : 'Скачанные аяты';
  String get counting => isKk ? 'Есептелуде...' : 'Подсчёт...';
  String get clear => isKk ? 'Тазалау' : 'Очистить';
  String get version => isKk ? 'Нұсқа' : 'Версия';
  String get darkTheme => isKk ? 'Қараңғы тақырып' : 'Тёмная тема';
  String get lightLater =>
      isKk ? 'Жарық тақырып кейін қосылады' : 'Светлая появится позже';
  String get makeSadaqa => isKk ? 'Садақа беру' : 'Сделать садака';
  String get supportTeam => isKk
      ? 'Команданың еңбегін ерікті қолдау'
      : 'Поддержать труд команды — по желанию';
  String get shareApp => isKk ? 'Қолданбамен бөлісу' : 'Поделиться приложением';
  String get rateApp => isKk ? 'Қолданбаны бағалау' : 'Оценить приложение';
  String get appNotPublished => isKk
      ? 'Қолданба әзірге сторда жарияланбаған'
      : 'Приложение пока не опубликовано в сторе';
  String get linkNotConfigured =>
      isKk ? 'Сілтеме әзірге бапталмаған' : 'Ссылка пока не настроена';
  String get shareText => isKk
      ? 'Hifz — Құранды тыңдап жаттауға арналған тегін қолданба. Жарнамасыз, жазылымсыз.'
      : 'Hifz — бесплатное приложение для заучивания Корана на слух. Без рекламы, без подписок.';

  String get sadaqa => isKk ? 'Садақа' : 'Садака';
  String get sadaqaFooter => isKk
      ? 'Қолданба толық тегін және жарнамасыз. Садақа — тек өз қалауыңызбен, кез келген сома жобаның дамуына көмектеседі. Алла қабыл етіп, сауабын берсін.'
      : 'Приложение полностью бесплатно и без рекламы. Садака — исключительно по желанию, и любая сумма поддерживает развитие проекта. Пусть Аллах примет и вознаградит вас.';
  String get supportProject => isKk ? 'Жобаны қолдау' : 'Поддержать проект';
  String get sadaqaHeroText => isKk
      ? 'Садақаңыз қолданбаны жақсартып, оны бәріне тегін ұстауға көмектеседі.'
      : 'Ваша садака помогает делать приложение лучше и держать его бесплатным для всех.';
  String get sadaqaAyahTranslation => isKk
      ? '«Алла жолында мал-мүлкін жұмсағандардың мысалы: жеті масақ шығарған бір дән сияқты, әр масақта жүз дән бар».'
      : '«Те, кто расходует своё имущество на пути Аллаха, подобны зерну, из которого выросло семь колосьев, и в каждом колосе — сто зёрен».';
  String get baqarahReference =>
      isKk ? 'Әл-Бақара, 2:261' : 'Аль-Бакара, 2:261';
  String get recipient => isKk ? 'Алушы' : 'Получатель';
  String get phoneTransfer =>
      isKk ? 'Нөмір арқылы аудару' : 'Перевод по номеру';
  String get bankCard => isKk ? 'Банк картасы' : 'Банковская карта';
  String get openKaspi => isKk ? 'Kaspi-де ашу' : 'Открыть в Kaspi';
  String get requisitesSoon => isKk
      ? 'Садақа реквизиттері жақында қосылады.'
      : 'Реквизиты для садака скоро появятся.';
  String copied(String label) =>
      isKk ? '$label көшірілді' : '$label скопирован';

  String get background => isKk ? 'Фон' : 'Фон';
  String get off => isKk ? 'Өшіру' : 'Выключить';
  String get disabled => isKk ? 'Өшірулі' : 'Выключено';
  String repeatTimes(int count) =>
      isKk ? '$count рет қайталау' : 'Повторить $count раза';
  String repeatAyahTimes(int count) =>
      isKk ? 'Аятты $count рет қайталау' : 'Повторить аят $count раза';
  String repeatSurahTimes(int count) =>
      isKk ? 'Сүрені $count рет қайталау' : 'Повторить суру $count раза';
  String get repeatAyahInfinite =>
      isKk ? 'Аятты шексіз қайталау' : 'Повторять аят бесконечно';
  String get repeatSurahInfinite =>
      isKk ? 'Сүрені шексіз қайталау' : 'Повторять суру бесконечно';
  String get infinite => isKk ? 'Шексіз' : 'Бесконечно';
  String get arabic => isKk ? 'Арабша' : 'Арабский';
  String get arabicTranscription =>
      isKk ? 'Арабша + транскрипция' : 'Арабский + Транскрипция';
  String get transcription => isKk ? 'Транскрипция' : 'Транскрипция';
  String get nothing => isKk ? 'Ештеңе' : 'Ничего';
  String get quran => isKk ? 'Құран' : 'Коран';
  String get ambientNoise => isKk ? 'Фондық дыбыс' : 'Фоновый шум';
  String get fire => isKk ? 'От' : 'Огонь';
  String get rain => isKk ? 'Жаңбыр' : 'Дождь';
  String get bird => isKk ? 'Құс' : 'Птица';
  String get wind => isKk ? 'Жел' : 'Ветер';

  String reciterBio(String id) {
    final kk = switch (id) {
      'alafasy' => 'Кувейттік қари, әлемдегі ең танымал қарилардың бірі',
      'husary' => 'Мысырлық қари, классикалық тәжуид үлгісі',
      'minshawi' => 'Мысырлық қари, әсерлі оқу мәнерімен белгілі',
      'abdul_basit' => 'Мысырлық қари, XX ғасырдың ұлы қариларының бірі',
      'sudais' => 'Меккедегі әл-Харам мешітінің имамы',
      'ghamdi' => 'Саудиялық қари, сабырлы әрі өлшемді оқуымен белгілі',
      'muaiqly' => 'Меккедегі әл-Харам мешітінің имамы',
      'shuraym' => 'Меккедегі әл-Харам мешітінің бұрынғы имамы, қазы',
      'ayyoub' => 'Мәдинадағы Пайғамбар мешітінің имамы',
      'hudhaify' => 'Мәдинадағы Пайғамбар мешітінің имамы',
      'shaatree' => 'Ашық әрі әсерлі дауысты саудиялық қари',
      'dussary' => 'Саудиялық имам, жастар арасында танымал',
      'jibreel' => 'Классикалық мектептің мысырлық қариі',
      'rifai' => 'Саудиялық қари, таза айтылуымен белгілі',
      'alqatami' => 'Саудиялық қари және имам',
      _ => '',
    };
    return isKk ? kk : '';
  }
}

extension AppStringsX on BuildContext {
  AppStrings get s => AppStrings.of(this);
}

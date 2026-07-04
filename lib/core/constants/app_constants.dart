/// Al Quran Cloud (https://alquran.cloud/api) — text source, fetched once
/// and cached locally in Hive.
abstract final class QuranApiConstants {
  static const String baseUrl = 'https://api.alquran.cloud/v1';
  static const String surahListPath = '/surah';
  static const String arabicEditionPath = '/quran/quran-uthmani';
  static const String transliterationEditionPath = '/quran/en.transliteration';
}

/// EveryAyah.com — per-ayah audio, downloaded on demand and cached to disk.
abstract final class EveryAyahConstants {
  static const String baseUrl = 'https://everyayah.com/data';

  static String audioUrl({
    required String reciterFolder,
    required int surahNumber,
    required int ayahNumber,
  }) {
    final s = surahNumber.toString().padLeft(3, '0');
    final a = ayahNumber.toString().padLeft(3, '0');
    return '$baseUrl/$reciterFolder/$s$a.mp3';
  }
}

class ReciterInfo {
  final String id;
  final String folder;
  final String name;
  final String nameArabic;

  /// One-line fact shown under the reciter's name (mosque/role, style, etc.).
  final String bio;

  const ReciterInfo({
    required this.id,
    required this.folder,
    required this.name,
    required this.nameArabic,
    required this.bio,
  });
}

/// A curated subset of reciters available on EveryAyah.com.
abstract final class AppConstants {
  static const String hiveBoxSettings = 'settings_box';
  static const String hiveBoxSurahs = 'surahs_box';
  static const String hiveBoxAyahs = 'ayahs_box';
  static const String hiveBoxFavorites = 'favorites_box';
  static const String hiveBoxProgress = 'progress_box';
  static const String hiveBoxRecent = 'recent_box';
  static const String hiveBoxLocation = 'location_box';
  static const String hiveBoxStats = 'stats_box';
  static const String hiveBoxZikrStats = 'zikr_stats_box';
  static const String hiveBoxPrayerScheduleCache = 'prayer_schedule_cache_box';

  static const List<ReciterInfo> reciters = [
    ReciterInfo(
      id: 'alafasy',
      folder: 'Alafasy_128kbps',
      name: 'Mishary Rashid Alafasy',
      nameArabic: 'مشاري راشد العفاسي',
      bio: 'Кувейтский чтец, один из самых популярных в мире',
    ),
    ReciterInfo(
      id: 'husary',
      folder: 'Husary_128kbps',
      name: 'Mahmoud Khalil Al-Husary',
      nameArabic: 'محمود خليل الحصري',
      bio: 'Египетский чтец, эталон классического таджвида',
    ),
    ReciterInfo(
      id: 'minshawi',
      folder: 'Minshawy_Murattal_128kbps',
      name: 'Mohamed Siddiq Al-Minshawi',
      nameArabic: 'محمد صديق المنشاوي',
      bio: 'Египетский чтец, известен проникновенной манерой чтения',
    ),
    ReciterInfo(
      id: 'abdul_basit',
      folder: 'Abdul_Basit_Murattal_192kbps',
      name: 'Abdul Basit Abdul Samad',
      nameArabic: 'عبد الباسط عبد الصمد',
      bio: 'Египетский чтец, один из величайших чтецов XX века',
    ),
    ReciterInfo(
      id: 'sudais',
      folder: 'Abdurrahmaan_As-Sudais_192kbps',
      name: 'Abdurrahman As-Sudais',
      nameArabic: 'عبد الرحمن السديس',
      bio: 'Имам Великой мечети Мекки (аль-Харам)',
    ),
    ReciterInfo(
      id: 'ghamdi',
      folder: 'Ghamadi_40kbps',
      name: 'Saad Al-Ghamdi',
      nameArabic: 'سعد الغامدي',
      bio: 'Саудовский чтец, известен спокойной размеренной манерой',
    ),
    ReciterInfo(
      id: 'muaiqly',
      folder: 'MaherAlMuaiqly128kbps',
      name: 'Maher Al Muaiqly',
      nameArabic: 'ماهر المعيقلي',
      bio: 'Имам Великой мечети Мекки (аль-Харам)',
    ),
    ReciterInfo(
      id: 'shuraym',
      folder: 'Saood_ash-Shuraym_128kbps',
      name: 'Saud Ash-Shuraym',
      nameArabic: 'سعود الشريم',
      bio: 'Бывший имам Великой мечети Мекки, судья',
    ),
    ReciterInfo(
      id: 'ayyoub',
      folder: 'Muhammad_Ayyoub_128kbps',
      name: 'Muhammad Ayyoub',
      nameArabic: 'محمد أيوب',
      bio: 'Имам Мечети Пророка в Медине',
    ),
    ReciterInfo(
      id: 'hudhaify',
      folder: 'Hudhaify_128kbps',
      name: 'Ali Al-Hudhaify',
      nameArabic: 'علي الحذيفي',
      bio: 'Имам Мечети Пророка в Медине',
    ),
    ReciterInfo(
      id: 'shaatree',
      folder: 'Abu_Bakr_Ash-Shaatree_128kbps',
      name: 'Abu Bakr Ash-Shaatree',
      nameArabic: 'أبو بكر الشاطري',
      bio: 'Саудовский чтец с ярким, выразительным голосом',
    ),
    ReciterInfo(
      id: 'dussary',
      folder: 'Yasser_Ad-Dussary_128kbps',
      name: 'Yasser Ad-Dussary',
      nameArabic: 'ياسر الدوسري',
      bio: 'Саудовский имам, популярен у молодой аудитории',
    ),
    ReciterInfo(
      id: 'jibreel',
      folder: 'Muhammad_Jibreel_128kbps',
      name: 'Muhammad Jibreel',
      nameArabic: 'محمد جبريل',
      bio: 'Египетский чтец классической школы',
    ),
    ReciterInfo(
      id: 'rifai',
      folder: 'Hani_Rifai_192kbps',
      name: 'Hani Ar-Rifai',
      nameArabic: 'هاني الرفاعي',
      bio: 'Саудовский чтец, известен чистым произношением',
    ),
    ReciterInfo(
      id: 'alqatami',
      folder: 'Nasser_Alqatami_128kbps',
      name: 'Nasser Alqatami',
      nameArabic: 'ناصر القطامي',
      bio: 'Саудовский чтец и имам',
    ),
  ];

  static const Duration networkTimeout = Duration(seconds: 20);
}

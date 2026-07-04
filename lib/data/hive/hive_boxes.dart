import 'package:hive_flutter/hive_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../models/app_settings.dart';
import '../models/ayah.dart';
import '../models/ayah_progress.dart';
import '../models/favorite_item.dart';
import '../models/surah.dart';
import 'hive_registrar.dart';

/// Opens every Hive box the app needs and exposes typed accessors.
///
/// Call [init] once at startup, after which the `*Box` getters are safe to
/// use anywhere synchronously.
abstract final class HiveBoxes {
  static late Box<Surah> surahs;
  static late Box<Ayah> ayahs;
  static late Box<FavoriteItem> favorites;
  static late Box<AyahProgress> progress;
  static late Box<AppSettings> settings;

  /// Recently opened `"surahNumber:ayahNumberInSurah"` entries, most recent first.
  static late Box<String> recent;

  /// Last known device coordinates, keyed `'lat'` / `'lng'`, used to compute
  /// prayer times without re-requesting location on every launch.
  static late Box<double> location;

  /// Seconds listened per day, keyed `"yyyy-MM-dd"`.
  static late Box<int> stats;

  /// Dhikr counts, keyed `"z:<transliteration>:yyyy-MM-dd"` — one entry per
  /// zikr per day. The day's total is the sum of that day's entries.
  static late Box<int> zikrStats;

  /// Monthly AlAdhan schedules encoded as JSON strings.
  static late Box<String> prayerScheduleCache;

  static Future<void> init() async {
    await Hive.initFlutter();
    registerHiveAdapters();

    surahs = await Hive.openBox<Surah>(AppConstants.hiveBoxSurahs);
    ayahs = await Hive.openBox<Ayah>(AppConstants.hiveBoxAyahs);
    favorites = await Hive.openBox<FavoriteItem>(AppConstants.hiveBoxFavorites);
    progress = await Hive.openBox<AyahProgress>(AppConstants.hiveBoxProgress);
    settings = await Hive.openBox<AppSettings>(AppConstants.hiveBoxSettings);
    recent = await Hive.openBox<String>(AppConstants.hiveBoxRecent);
    location = await Hive.openBox<double>(AppConstants.hiveBoxLocation);
    stats = await Hive.openBox<int>(AppConstants.hiveBoxStats);
    zikrStats = await Hive.openBox<int>(AppConstants.hiveBoxZikrStats);
    prayerScheduleCache = await Hive.openBox<String>(
      AppConstants.hiveBoxPrayerScheduleCache,
    );
  }
}

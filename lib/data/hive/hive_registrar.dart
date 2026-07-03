import 'package:hive_flutter/hive_flutter.dart';

import '../models/app_settings.dart';
import '../models/ayah.dart';
import '../models/ayah_progress.dart';
import '../models/display_mode.dart';
import '../models/favorite_item.dart';
import '../models/memorization_status.dart';
import '../models/reciter.dart';
import '../models/surah.dart';

/// Registers every Hive [TypeAdapter] used by the app. Call once, before
/// opening any box.
void registerHiveAdapters() {
  Hive
    ..registerAdapter(SurahAdapter())
    ..registerAdapter(AyahAdapter())
    ..registerAdapter(ReciterAdapter())
    ..registerAdapter(MemorizationStatusAdapter())
    ..registerAdapter(AyahProgressAdapter())
    ..registerAdapter(FavoriteTypeAdapter())
    ..registerAdapter(FavoriteItemAdapter())
    ..registerAdapter(DisplayModeAdapter())
    ..registerAdapter(AppSettingsAdapter());
}

import '../hive/hive_boxes.dart';
import '../models/app_settings.dart';

class SettingsRepository {
  static const _key = 'settings';

  AppSettings get() => HiveBoxes.settings.get(_key) ?? const AppSettings();

  Future<void> save(AppSettings settings) => HiveBoxes.settings.put(_key, settings);
}

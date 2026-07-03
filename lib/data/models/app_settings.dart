import 'package:hive/hive.dart';
import 'display_mode.dart';
import 'prayer_calculation_method.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 8)
class AppSettings {
  static const defaultListeningGoalMinutes = 5;
  static const defaultReadingGoalMinutes = 10;

  @HiveField(0)
  final String reciterId;

  @HiveField(1)
  final DisplayMode displayMode;

  @HiveField(2)
  final double playbackSpeed;

  // Nullable fields below so the generated adapter reads them as `as bool?` —
  // existing installs upgrading from before a field existed have no byte at
  // that index, and a non-nullable cast would crash on that legacy data.
  @HiveField(3)
  final bool? hasCompletedOnboarding;

  @HiveField(4)
  final bool? notificationsEnabled;

  @HiveField(5)
  final int? dailyListeningGoalMinutes;

  @HiveField(6)
  final int? dailyReadingGoalMinutes;

  @HiveField(7)
  final String? selectedCityId;

  @HiveField(8)
  final int? prayerMethodId;

  @HiveField(9)
  final int? fajrAdjustmentMinutes;

  @HiveField(10)
  final int? dhuhrAdjustmentMinutes;

  @HiveField(11)
  final int? asrAdjustmentMinutes;

  @HiveField(12)
  final int? maghribAdjustmentMinutes;

  @HiveField(13)
  final int? ishaAdjustmentMinutes;

  int get listeningGoalMinutes =>
      dailyListeningGoalMinutes ?? defaultListeningGoalMinutes;

  int get readingGoalMinutes =>
      dailyReadingGoalMinutes ?? defaultReadingGoalMinutes;

  PrayerCalculationMethod get prayerMethod =>
      PrayerCalculationMethod.byApiId(prayerMethodId);

  PrayerTimeAdjustments get prayerAdjustments => PrayerTimeAdjustments(
    fajr: fajrAdjustmentMinutes ?? 0,
    dhuhr: dhuhrAdjustmentMinutes ?? 0,
    asr: asrAdjustmentMinutes ?? 0,
    maghrib: maghribAdjustmentMinutes ?? 0,
    isha: ishaAdjustmentMinutes ?? 0,
  );

  const AppSettings({
    this.reciterId = 'alafasy',
    this.displayMode = DisplayMode.both,
    this.playbackSpeed = 1.0,
    this.hasCompletedOnboarding = false,
    this.notificationsEnabled = false,
    this.dailyListeningGoalMinutes,
    this.dailyReadingGoalMinutes,
    this.selectedCityId,
    this.prayerMethodId,
    this.fajrAdjustmentMinutes,
    this.dhuhrAdjustmentMinutes,
    this.asrAdjustmentMinutes,
    this.maghribAdjustmentMinutes,
    this.ishaAdjustmentMinutes,
  });

  AppSettings copyWith({
    String? reciterId,
    DisplayMode? displayMode,
    double? playbackSpeed,
    bool? hasCompletedOnboarding,
    bool? notificationsEnabled,
    int? dailyListeningGoalMinutes,
    int? dailyReadingGoalMinutes,
    Object? selectedCityId = _unset,
    int? prayerMethodId,
    int? fajrAdjustmentMinutes,
    int? dhuhrAdjustmentMinutes,
    int? asrAdjustmentMinutes,
    int? maghribAdjustmentMinutes,
    int? ishaAdjustmentMinutes,
  }) => AppSettings(
    reciterId: reciterId ?? this.reciterId,
    displayMode: displayMode ?? this.displayMode,
    playbackSpeed: playbackSpeed ?? this.playbackSpeed,
    hasCompletedOnboarding:
        hasCompletedOnboarding ?? this.hasCompletedOnboarding,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    dailyListeningGoalMinutes:
        dailyListeningGoalMinutes ?? this.dailyListeningGoalMinutes,
    dailyReadingGoalMinutes:
        dailyReadingGoalMinutes ?? this.dailyReadingGoalMinutes,
    selectedCityId: selectedCityId == _unset
        ? this.selectedCityId
        : selectedCityId as String?,
    prayerMethodId: prayerMethodId ?? this.prayerMethodId,
    fajrAdjustmentMinutes: fajrAdjustmentMinutes ?? this.fajrAdjustmentMinutes,
    dhuhrAdjustmentMinutes:
        dhuhrAdjustmentMinutes ?? this.dhuhrAdjustmentMinutes,
    asrAdjustmentMinutes: asrAdjustmentMinutes ?? this.asrAdjustmentMinutes,
    maghribAdjustmentMinutes:
        maghribAdjustmentMinutes ?? this.maghribAdjustmentMinutes,
    ishaAdjustmentMinutes: ishaAdjustmentMinutes ?? this.ishaAdjustmentMinutes,
  );
}

const _unset = Object();

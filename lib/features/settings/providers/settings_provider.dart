import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/app_settings.dart';
import '../../../data/models/display_mode.dart';
import '../../../data/models/prayer_calculation_method.dart';
import '../../../data/providers.dart';

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.read(settingsRepositoryProvider).get();

  Future<void> _persist(AppSettings next) async {
    state = next;
    await ref.read(settingsRepositoryProvider).save(next);
  }

  Future<void> setReciter(String reciterId) =>
      _persist(state.copyWith(reciterId: reciterId));

  Future<void> setDisplayMode(DisplayMode mode) =>
      _persist(state.copyWith(displayMode: mode));

  Future<void> setPlaybackSpeed(double speed) =>
      _persist(state.copyWith(playbackSpeed: speed));

  Future<void> setDailyListeningGoalMinutes(int minutes) =>
      _persist(state.copyWith(dailyListeningGoalMinutes: minutes));

  Future<void> setDailyReadingGoalMinutes(int minutes) =>
      _persist(state.copyWith(dailyReadingGoalMinutes: minutes));

  Future<void> setSelectedCityId(String? cityId) =>
      _persist(state.copyWith(selectedCityId: cityId));

  Future<void> setPrayerMethod(PrayerCalculationMethod method) =>
      _persist(state.copyWith(prayerMethodId: method.apiId));

  Future<void> setPrayerAdjustment(String key, int minutes) {
    final clamped = minutes.clamp(-10, 10);
    return switch (key) {
      'fajr' => _persist(state.copyWith(fajrAdjustmentMinutes: clamped)),
      'dhuhr' => _persist(state.copyWith(dhuhrAdjustmentMinutes: clamped)),
      'asr' => _persist(state.copyWith(asrAdjustmentMinutes: clamped)),
      'maghrib' => _persist(state.copyWith(maghribAdjustmentMinutes: clamped)),
      'isha' => _persist(state.copyWith(ishaAdjustmentMinutes: clamped)),
      _ => Future.value(),
    };
  }

  Future<void> completeOnboarding() =>
      _persist(state.copyWith(hasCompletedOnboarding: true));

  Future<void> setNotificationsEnabled(bool enabled) =>
      _persist(state.copyWith(notificationsEnabled: enabled));
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

final selectedReciterProvider = Provider<ReciterInfo>((ref) {
  final id = ref.watch(settingsControllerProvider).reciterId;
  return AppConstants.reciters.firstWhere(
    (r) => r.id == id,
    orElse: () => AppConstants.reciters.first,
  );
});

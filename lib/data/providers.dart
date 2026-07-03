import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'repositories/audio_repository.dart';
import 'repositories/favorites_repository.dart';
import 'repositories/listening_stats_repository.dart';
import 'repositories/location_repository.dart';
import 'repositories/notification_repository.dart';
import 'repositories/prayer_times_repository.dart';
import 'repositories/progress_repository.dart';
import 'repositories/quran_repository.dart';
import 'repositories/recently_played_repository.dart';
import 'repositories/settings_repository.dart';

final quranRepositoryProvider = Provider<QuranRepository>((ref) => QuranRepository());

final audioRepositoryProvider = Provider<AudioRepository>((ref) => AudioRepository());

final favoritesRepositoryProvider =
    Provider<FavoritesRepository>((ref) => FavoritesRepository());

final progressRepositoryProvider =
    Provider<ProgressRepository>((ref) => ProgressRepository());

final settingsRepositoryProvider =
    Provider<SettingsRepository>((ref) => SettingsRepository());

final recentlyPlayedRepositoryProvider =
    Provider<RecentlyPlayedRepository>((ref) => RecentlyPlayedRepository());

final locationRepositoryProvider = Provider<LocationRepository>((ref) => LocationRepository());

final prayerTimesRepositoryProvider =
    Provider<PrayerTimesRepository>((ref) => PrayerTimesRepository());

final listeningStatsRepositoryProvider =
    Provider<ListeningStatsRepository>((ref) => ListeningStatsRepository());

final notificationRepositoryProvider =
    Provider<NotificationRepository>((ref) => NotificationRepository());

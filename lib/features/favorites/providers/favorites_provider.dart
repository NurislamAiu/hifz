import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/favorite_item.dart';
import '../../../data/providers.dart';

class FavoritesController extends Notifier<List<FavoriteItem>> {
  @override
  List<FavoriteItem> build() => ref.read(favoritesRepositoryProvider).getAll();

  void _refresh() => state = ref.read(favoritesRepositoryProvider).getAll();

  bool isFavoriteSurah(int surahNumber) => state.any(
    (f) => f.type == FavoriteType.surah && f.surahNumber == surahNumber,
  );

  bool isFavoriteAyah(int surahNumber, int ayahNumberInSurah) => state.any(
    (f) =>
        f.type == FavoriteType.ayah &&
        f.surahNumber == surahNumber &&
        f.ayahNumberInSurah == ayahNumberInSurah,
  );

  Future<void> toggleSurah(int surahNumber) async {
    await ref.read(favoritesRepositoryProvider).toggleSurah(surahNumber);
    _refresh();
  }

  Future<void> toggleAyah(int surahNumber, int ayahNumberInSurah) async {
    await ref
        .read(favoritesRepositoryProvider)
        .toggleAyah(surahNumber, ayahNumberInSurah);
    _refresh();
  }
}

final favoritesControllerProvider =
    NotifierProvider<FavoritesController, List<FavoriteItem>>(
      FavoritesController.new,
    );

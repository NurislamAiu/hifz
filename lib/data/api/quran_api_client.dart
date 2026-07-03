import 'package:dio/dio.dart';

import '../../core/constants/app_constants.dart';
import '../models/ayah.dart';
import '../models/surah.dart';

/// Thin wrapper around the Al Quran Cloud REST API (https://alquran.cloud/api).
/// Every call here is meant to run once; results are cached locally in Hive
/// by [QuranRepository].
class QuranApiClient {
  QuranApiClient({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: QuranApiConstants.baseUrl,
              connectTimeout: AppConstants.networkTimeout,
              receiveTimeout: AppConstants.networkTimeout,
            ));

  final Dio _dio;

  Future<List<Surah>> fetchSurahList() async {
    final response = await _dio.get(QuranApiConstants.surahListPath);
    final list = response.data['data'] as List<dynamic>;
    return list
        .map((json) => Surah.fromApiJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Returns every ayah of the Quran (Uthmani script), grouped by surah number.
  Future<Map<int, List<Ayah>>> fetchFullQuranArabic() async {
    final response = await _dio.get(QuranApiConstants.arabicEditionPath);
    final surahs = response.data['data']['surahs'] as List<dynamic>;
    final result = <int, List<Ayah>>{};
    for (final surahJson in surahs) {
      final surahMap = surahJson as Map<String, dynamic>;
      final surahNumber = surahMap['number'] as int;
      final ayahsJson = surahMap['ayahs'] as List<dynamic>;
      result[surahNumber] = ayahsJson
          .map((a) => Ayah.fromApiJson(a as Map<String, dynamic>, surahNumber: surahNumber))
          .toList();
    }
    return result;
  }

  /// Returns transliteration text for every ayah, grouped by surah number,
  /// in `numberInSurah` order.
  Future<Map<int, List<String>>> fetchFullQuranTransliteration() async {
    final response = await _dio.get(QuranApiConstants.transliterationEditionPath);
    final surahs = response.data['data']['surahs'] as List<dynamic>;
    final result = <int, List<String>>{};
    for (final surahJson in surahs) {
      final surahMap = surahJson as Map<String, dynamic>;
      final surahNumber = surahMap['number'] as int;
      final ayahsJson = surahMap['ayahs'] as List<dynamic>;
      result[surahNumber] = ayahsJson
          .map((a) => (a as Map<String, dynamic>)['text'] as String)
          .toList();
    }
    return result;
  }
}

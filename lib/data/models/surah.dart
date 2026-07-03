import 'package:hive/hive.dart';

part 'surah.g.dart';

@HiveType(typeId: 0)
class Surah {
  @HiveField(0)
  final int number;

  @HiveField(1)
  final String nameArabic;

  /// Transliterated name, e.g. "Al-Fatihah".
  @HiveField(2)
  final String nameTransliteration;

  /// English translation of the meaning, e.g. "The Opener".
  @HiveField(3)
  final String nameTranslationEn;

  /// "Meccan" or "Medinan".
  @HiveField(4)
  final String revelationType;

  @HiveField(5)
  final int numberOfAyahs;

  const Surah({
    required this.number,
    required this.nameArabic,
    required this.nameTransliteration,
    required this.nameTranslationEn,
    required this.revelationType,
    required this.numberOfAyahs,
  });

  factory Surah.fromApiJson(Map<String, dynamic> json) => Surah(
    number: json['number'] as int,
    nameArabic: json['name'] as String,
    nameTransliteration: json['englishName'] as String,
    nameTranslationEn: json['englishNameTranslation'] as String,
    revelationType: json['revelationType'] as String,
    numberOfAyahs: json['numberOfAyahs'] as int,
  );
}

enum PrayerCalculationMethod {
  muslimWorldLeague(3, 'Muslim World League'),
  ummAlQura(4, 'Umm Al-Qura'),
  egyptian(5, 'Egyptian'),
  karachi(1, 'Karachi'),
  dubai(14, 'Dubai'),
  kuwait(9, 'Kuwait'),
  qatar(10, 'Qatar'),
  turkeyDiyanet(13, 'Turkey Diyanet');

  const PrayerCalculationMethod(this.apiId, this.label);

  final int apiId;
  final String label;

  static PrayerCalculationMethod byApiId(int? apiId) {
    for (final method in values) {
      if (method.apiId == apiId) return method;
    }
    return PrayerCalculationMethod.muslimWorldLeague;
  }
}

class PrayerTimeAdjustments {
  const PrayerTimeAdjustments({
    this.fajr = 0,
    this.dhuhr = 0,
    this.asr = 0,
    this.maghrib = 0,
    this.isha = 0,
  });

  final int fajr;
  final int dhuhr;
  final int asr;
  final int maghrib;
  final int isha;

  int forKey(String key) => switch (key) {
    'fajr' => fajr,
    'dhuhr' => dhuhr,
    'asr' => asr,
    'maghrib' => maghrib,
    'isha' => isha,
    _ => 0,
  };
}

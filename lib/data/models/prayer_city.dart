class PrayerCity {
  const PrayerCity({
    required this.id,
    required this.name,
    required this.region,
    required this.lat,
    required this.lng,
    required this.timeZone,
  });

  final String id;
  final String name;
  final String region;
  final double lat;
  final double lng;
  final String timeZone;
}

abstract final class PrayerCities {
  static const defaultCity = PrayerCity(
    id: 'almaty',
    name: 'Алматы',
    region: 'Казахстан',
    lat: 43.2389,
    lng: 76.8897,
    timeZone: 'Asia/Almaty',
  );

  static const List<PrayerCity> all = [
    defaultCity,
    PrayerCity(
      id: 'astana',
      name: 'Астана',
      region: 'Казахстан',
      lat: 51.1694,
      lng: 71.4491,
      timeZone: 'Asia/Almaty',
    ),
    PrayerCity(
      id: 'shymkent',
      name: 'Шымкент',
      region: 'Казахстан',
      lat: 42.3417,
      lng: 69.5901,
      timeZone: 'Asia/Almaty',
    ),
    PrayerCity(
      id: 'taraz',
      name: 'Тараз',
      region: 'Казахстан',
      lat: 42.9000,
      lng: 71.3667,
      timeZone: 'Asia/Almaty',
    ),
    PrayerCity(
      id: 'aktobe',
      name: 'Актобе',
      region: 'Казахстан',
      lat: 50.2839,
      lng: 57.1670,
      timeZone: 'Asia/Aqtobe',
    ),
    PrayerCity(
      id: 'karaganda',
      name: 'Караганда',
      region: 'Казахстан',
      lat: 49.8060,
      lng: 73.0850,
      timeZone: 'Asia/Almaty',
    ),
    PrayerCity(
      id: 'atyrau',
      name: 'Атырау',
      region: 'Казахстан',
      lat: 47.0945,
      lng: 51.9238,
      timeZone: 'Asia/Atyrau',
    ),
    PrayerCity(
      id: 'oral',
      name: 'Орал',
      region: 'Казахстан',
      lat: 51.2278,
      lng: 51.3865,
      timeZone: 'Asia/Oral',
    ),
    PrayerCity(
      id: 'oskemen',
      name: 'Оскемен',
      region: 'Казахстан',
      lat: 49.9483,
      lng: 82.6275,
      timeZone: 'Asia/Almaty',
    ),
    PrayerCity(
      id: 'semey',
      name: 'Семей',
      region: 'Казахстан',
      lat: 50.4111,
      lng: 80.2275,
      timeZone: 'Asia/Almaty',
    ),
  ];

  static PrayerCity? byId(String? id) {
    if (id == null) return null;
    for (final city in all) {
      if (city.id == id) return city;
    }
    return null;
  }
}

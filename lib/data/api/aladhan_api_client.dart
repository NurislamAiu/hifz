import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

class AladhanApiClient {
  AladhanApiClient({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://api.aladhan.com/v1',
              connectTimeout: const Duration(seconds: 12),
              receiveTimeout: const Duration(seconds: 12),
            ),
          );

  final Dio _dio;

  Future<List<Map<String, dynamic>>> fetchMonthlyTimings({
    required double latitude,
    required double longitude,
    required int method,
    required int month,
    required int year,
  }) async {
    debugPrint(
      '[PrayerTimes][API] GET /calendar/$year/$month '
      'lat=$latitude lng=$longitude method=$method',
    );
    final response = await _dio.get<Map<String, dynamic>>(
      '/calendar/$year/$month',
      queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'method': method,
      },
    );

    final body = response.data;
    debugPrint(
      '[PrayerTimes][API] status=${response.statusCode} '
      'code=${body?['code']} dataType=${body?['data']?.runtimeType}',
    );
    if (body == null || body['code'] != 200 || body['data'] is! List) {
      throw AladhanApiException('Некорректный ответ AlAdhan API');
    }

    final days = (body['data'] as List<dynamic>)
        .cast<Map<dynamic, dynamic>>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
    debugPrint('[PrayerTimes][API] parsed days=${days.length}');
    return days;
  }
}

class AladhanApiException implements Exception {
  const AladhanApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

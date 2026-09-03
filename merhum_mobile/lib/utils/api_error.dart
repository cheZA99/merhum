import 'package:dio/dio.dart';

String parseApiError(Object error, [String fallback = 'Greška pri učitavanju podataka. Pokušajte ponovo.']) {
  if (error is! DioException) return fallback;

  final data = error.response?.data;
  if (data is Map && data['message'] is String) {
    return data['message'] as String;
  }

  switch (error.response?.statusCode) {
    case 401:
      return 'Sesija je istekla. Prijavite se ponovo.';
    case 403:
      return 'Nemate ovlaštenja za ovu akciju.';
    case 404:
      return 'Zapis nije pronađen.';
  }

  if (error.type == DioExceptionType.connectionError ||
      error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout) {
    return 'Nema konekcije sa serverom.';
  }

  return fallback;
}

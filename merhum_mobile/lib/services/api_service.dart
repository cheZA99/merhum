import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class ApiService {
  static final _storage = FlutterSecureStorage();
  static Dio? _dio;

  static Dio get dio {
    _dio ??= Dio(BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ))
      ..interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'jwt_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ))
      ..interceptors.add(LogInterceptor(
        requestBody: false,
        responseBody: true,
        error: true,
        logPrint: (obj) => debugPrint('[DIO] $obj'),
      ));
    return _dio!;
  }

  static Future<Response> get(String path, {Map<String, dynamic>? queryParams}) =>
      dio.get(path, queryParameters: queryParams);

  static Future<Response> post(String path, dynamic data) =>
      dio.post(path, data: data);

  static Future<Response> put(String path, dynamic data) =>
      dio.put(path, data: data);

  static Future<Response> delete(String path) => dio.delete(path);

  static Future<Response> patch(String path, dynamic data) =>
      dio.patch(path, data: data);
}

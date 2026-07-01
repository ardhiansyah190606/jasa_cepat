import 'package:dio/dio.dart';

class ApiClient {
  static const String _baseUrl = 'https://api.jasacepat.com/v1'; 
  final Dio _dio;

  ApiClient()
      : _dio = Dio(
          BaseOptions(
            baseUrl: _baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );

  // Fungsi HTTP GET
  Future<Response> getRequest(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Fungsi HTTP POST
  Future<Response> postRequest(String path, Map<String, dynamic> data) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Koneksi lambat, silakan coba lagi.';
      case DioExceptionType.badResponse:
        return error.response?.data['message'] ?? 'Terjadi kesalahan pada server.';
      case DioExceptionType.connectionError:
        return 'Tidak ada koneksi internet.';
      default:
        return 'Terjadi kesalahan tidak terduga.';
    }
  }
}
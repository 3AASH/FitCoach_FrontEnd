import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/config/api_config.dart';

class ProgressRepository {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  static const String _tokenKey = 'fitcoach_auth_token';

  ProgressRepository()
      : _dio = Dio(BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: ApiConfig.connectTimeout,
          receiveTimeout: ApiConfig.receiveTimeout,
        )),
        _secureStorage = const FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  Future<Options> _getAuthOptions() async {
    final token = await _getToken();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<List<Map<String, dynamic>>> getEntries({int limit = 50, int offset = 0}) async {
    try {
      final response = await _dio.get(
        '/progress',
        queryParameters: {'limit': limit, 'offset': offset},
        options: await _getAuthOptions(),
      );

      final data = response.data as Map<String, dynamic>;
      return List<Map<String, dynamic>>.from(data['entries'] as List? ?? []);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load progress');
    }
  }

  Future<Map<String, dynamic>> createEntry(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post(
        '/progress',
        data: payload,
        options: await _getAuthOptions(),
      );

      final data = response.data as Map<String, dynamic>;
      return data['entry'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to create progress entry');
    }
  }

  Future<Map<String, dynamic>> updateEntry(String id, Map<String, dynamic> payload) async {
    try {
      final response = await _dio.put(
        '/progress/$id',
        data: payload,
        options: await _getAuthOptions(),
      );

      final data = response.data as Map<String, dynamic>;
      return data['entry'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to update progress entry');
    }
  }

  Future<void> deleteEntry(String id) async {
    try {
      await _dio.delete(
        '/progress/$id',
        options: await _getAuthOptions(),
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to delete progress entry');
    }
  }
}

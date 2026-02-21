import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/config/api_config.dart';

class RatingRepository {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  static const String _tokenKey = 'fitcoach_auth_token';

  RatingRepository()
      : _dio = Dio(
          BaseOptions(
            baseUrl: ApiConfig.baseUrl,
            connectTimeout: ApiConfig.connectTimeout,
            receiveTimeout: ApiConfig.receiveTimeout,
          ),
        ),
        _secureStorage = const FlutterSecureStorage();

  Future<Options> _getAuthOptions() async {
    final token = await _secureStorage.read(key: _tokenKey);
    return Options(
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  Future<void> submitVideoCallRating({
    required String coachId,
    required String appointmentId,
    required int rating,
    String? feedback,
  }) async {
    try {
      await _dio.post(
        '/ratings',
        data: {
          'coachId': coachId,
          'context': 'video_call',
          'referenceId': appointmentId,
          'rating': rating,
          if (feedback != null && feedback.isNotEmpty) 'feedback': feedback,
        },
        options: await _getAuthOptions(),
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to submit rating');
    }
  }
}

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/config/api_config.dart';

class BookingRepository {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  static const String _tokenKey = 'fitcoach_auth_token';

  BookingRepository()
      : _dio = Dio(
          BaseOptions(
            baseUrl: ApiConfig.baseUrl,
            connectTimeout: ApiConfig.connectTimeout,
            receiveTimeout: ApiConfig.receiveTimeout,
          ),
        ),
        _secureStorage = const FlutterSecureStorage();

  Future<Map<String, List<String>>> getAvailableSlots({
    DateTime? startDate,
    DateTime? endDate,
    String? coachId,
  }) async {
    final queryParams = {
      if (startDate != null) 'startDate': startDate.toIso8601String(),
      if (endDate != null) 'endDate': endDate.toIso8601String(),
      if (coachId != null) 'coachId': coachId,
    };

    final response = await _dio.get(
      '/bookings/available-slots',
      queryParameters: queryParams,
      options: await _getAuthOptions(),
    );

    final data = response.data as Map<String, dynamic>;
    final rawSlots = (data['slots'] as List?) ?? [];

    final Map<String, List<String>> slotsByDate = {};
    for (final entry in rawSlots) {
      final map = entry as Map<String, dynamic>;
      final date = map['date']?.toString();
      final times = (map['times'] as List?)?.map((t) => t.toString()).toList() ?? <String>[];
      if (date != null) {
        slotsByDate[date] = times;
      }
    }

    return slotsByDate;
  }

  Future<void> createBooking({
    required DateTime scheduledDate,
    required String scheduledTime,
    String? notes,
    String? coachId,
  }) async {
    final payload = {
      'scheduledDate': scheduledDate.toIso8601String().split('T')[0],
      'scheduledTime': scheduledTime,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      if (coachId != null) 'coachId': coachId,
    };

    await _dio.post(
      '/bookings',
      data: payload,
      options: await _getAuthOptions(),
    );
  }

  Future<Options> _getAuthOptions() async {
    final token = await _secureStorage.read(key: _tokenKey);
    return Options(headers: {'Authorization': 'Bearer $token'});
  }
}

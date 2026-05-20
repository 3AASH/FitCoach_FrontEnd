import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/config/api_config.dart';
import '../models/appointment.dart';

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

  String _dateOnly(DateTime value) => value.toIso8601String().split('T').first;

  Future<Map<String, List<String>>> getAvailableSlots({
    DateTime? startDate,
    DateTime? endDate,
    String? coachId,
  }) async {
    final queryParams = {
      if (startDate != null) 'startDate': _dateOnly(startDate),
      if (endDate != null) 'endDate': _dateOnly(endDate),
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
      final times =
          (map['times'] as List?)?.map((t) => t.toString()).toList() ??
              <String>[];
      if (date != null) {
        slotsByDate[date] = times;
      }
    }

    return slotsByDate;
  }

  Future<Appointment?> createBooking({
    required DateTime scheduledDate,
    required String scheduledTime,
    int durationMinutes = 60,
    String? notes,
    String? coachId,
  }) async {
    final payload = {
      'scheduledDate': _dateOnly(scheduledDate),
      'scheduledTime': scheduledTime,
      'durationMinutes': durationMinutes,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      if (coachId != null) 'coachId': coachId,
    };

    final response = await _dio.post(
      '/bookings',
      data: payload,
      options: await _getAuthOptions(),
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final appointment = data['appointment'];
      if (appointment is Map<String, dynamic>) {
        return Appointment.fromJson(appointment);
      }
      final booking = data['booking'];
      if (booking is Map<String, dynamic> &&
          booking['appointment'] is Map<String, dynamic>) {
        return Appointment.fromJson(
            booking['appointment'] as Map<String, dynamic>);
      }
    }
    return null;
  }

  Future<Options> _getAuthOptions() async {
    final token = await _secureStorage.read(key: _tokenKey);
    return Options(headers: {'Authorization': 'Bearer $token'});
  }
}

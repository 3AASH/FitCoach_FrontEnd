import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/config/api_config.dart';
import '../models/appointment.dart';

class AppointmentRepository {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  static const String _tokenKey = 'fitcoach_auth_token';

  AppointmentRepository()
      : _dio = Dio(
          BaseOptions(
            baseUrl: ApiConfig.baseUrl,
            connectTimeout: ApiConfig.connectTimeout,
            receiveTimeout: ApiConfig.receiveTimeout,
          ),
        ),
        _secureStorage = const FlutterSecureStorage();

  Future<List<Appointment>> getUserAppointments({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) async {
    final queryParams = {
      if (startDate != null) 'startDate': startDate.toIso8601String(),
      if (endDate != null) 'endDate': endDate.toIso8601String(),
      if (status != null) 'status': status,
    };

    final response = await _dio.get(
      '/users/$userId/appointments',
      queryParameters: queryParams,
      options: await _getAuthOptions(),
    );

    final data = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : <String, dynamic>{'appointments': response.data};
    final list = (data['appointments'] as List?) ?? [];

    return list
        .map((json) => Appointment.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Options> _getAuthOptions() async {
    final token = await _secureStorage.read(key: _tokenKey);
    return Options(
      headers: {'Authorization': 'Bearer $token'},
    );
  }
}

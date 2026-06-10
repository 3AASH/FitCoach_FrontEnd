import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/config/api_config.dart';
import '../models/subscription_plan.dart';

class SubscriptionPlanRepository {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;
  final Future<String?> Function()? _tokenReader;
  static const String _tokenKey = 'fitcoach_auth_token';

  SubscriptionPlanRepository({
    Dio? dio,
    FlutterSecureStorage? secureStorage,
    Future<String?> Function()? tokenReader,
  })
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConfig.baseUrl,
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 30),
              ),
            ),
        _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _tokenReader = tokenReader;

  Future<Options> _getAuthOptions() async {
    final token = _tokenReader != null
        ? await _tokenReader()
        : await _secureStorage.read(key: _tokenKey);
    return Options(
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  Map<String, dynamic> _toBackendPayload(SubscriptionPlan plan) {
    return {
      'name': plan.name,
      'description': plan.description,
      'price': plan.monthlyPrice,
      'currency': plan.currency,
      'features': plan.features.map((feature) => feature.toJson()).toList(),
      'messageQuota': plan.metadata['messagesLimit'],
      'callQuota': plan.metadata['videoCallsLimit'],
      'hasNutritionAccess': plan.metadata['nutritionAccess'],
      'hasChatAttachments': plan.metadata['chatAttachments'],
    };
  }

  Future<List<SubscriptionPlan>> getPlans() async {
    try {
      final response = await _dio.get('/subscriptions/plans');
      final data = response.data as Map<String, dynamic>;
      final plans = data['plans'] as List? ?? [];
      return plans
          .map((json) => SubscriptionPlan.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load plans');
    }
  }

  Future<SubscriptionPlan> createPlan(SubscriptionPlan plan) async {
    try {
      final response = await _dio.post(
        '/admin/subscriptions/plans',
        data: _toBackendPayload(plan),
        options: await _getAuthOptions(),
      );
      final data = response.data as Map<String, dynamic>;
      return SubscriptionPlan.fromJson(data['plan'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to create plan');
    }
  }

  Future<SubscriptionPlan> updatePlan(SubscriptionPlan plan) async {
    try {
      final response = await _dio.put(
        '/admin/subscriptions/plans/${plan.id}',
        data: _toBackendPayload(plan),
        options: await _getAuthOptions(),
      );
      final data = response.data as Map<String, dynamic>;
      return SubscriptionPlan.fromJson(data['plan'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to update plan');
    }
  }

  Future<void> deletePlan(String id) async {
    try {
      await _dio.delete(
        '/admin/subscriptions/plans/$id',
        options: await _getAuthOptions(),
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to delete plan');
    }
  }

  /// Current user's subscription state plus their latest request, if any.
  Future<Map<String, dynamic>> getMySubscription() async {
    try {
      final response = await _dio.get(
        '/subscriptions/me',
        options: await _getAuthOptions(),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load subscription');
    }
  }

  /// Submit a subscription request; the admin settles payment manually and
  /// approves or rejects it.
  Future<Map<String, dynamic>> requestSubscription(String planId) async {
    try {
      final response = await _dio.post(
        '/subscriptions/requests',
        data: {'planId': planId},
        options: await _getAuthOptions(),
      );
      final data = response.data as Map<String, dynamic>;
      return data['request'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to submit subscription request');
    }
  }

  Future<void> cancelRequest(String requestId) async {
    try {
      await _dio.delete(
        '/subscriptions/requests/$requestId',
        options: await _getAuthOptions(),
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to cancel subscription request');
    }
  }

  /// Admin: list subscription requests, optionally filtered by status.
  Future<List<Map<String, dynamic>>> getRequests({String status = 'pending'}) async {
    try {
      final response = await _dio.get(
        '/admin/subscription-requests',
        queryParameters: {'status': status},
        options: await _getAuthOptions(),
      );
      final data = response.data as Map<String, dynamic>;
      final requests = data['requests'] as List? ?? [];
      return requests.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load subscription requests');
    }
  }

  Future<void> approveRequest(String requestId, {String? adminNotes}) async {
    try {
      await _dio.put(
        '/admin/subscription-requests/$requestId/approve',
        data: {if (adminNotes != null) 'adminNotes': adminNotes},
        options: await _getAuthOptions(),
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to approve request');
    }
  }

  Future<void> rejectRequest(String requestId, {String? adminNotes}) async {
    try {
      await _dio.put(
        '/admin/subscription-requests/$requestId/reject',
        data: {if (adminNotes != null) 'adminNotes': adminNotes},
        options: await _getAuthOptions(),
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to reject request');
    }
  }
}

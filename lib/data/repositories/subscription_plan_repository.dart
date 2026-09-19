import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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

  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  String _errorMessage(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    final status = e.response?.statusCode;
    return status != null ? '$fallback (status $status)' : fallback;
  }

  Map<String, dynamic> _toBackendPayload(SubscriptionPlan plan) {
    return {
      'name': plan.name,
      'description': plan.description,
      'price': plan.monthlyPrice,
      'yearlyPrice': plan.yearlyPrice,
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
      throw Exception(_errorMessage(e, 'Failed to load plans'));
    }
  }

  Future<SubscriptionPlan> createPlan(SubscriptionPlan plan) async {
    const endpoint = '/admin/subscriptions/plans';
    _debugLog('[SubscriptionPlanRepository] POST ${_dio.options.baseUrl}$endpoint');
    try {
      final response = await _dio.post(
        endpoint,
        data: _toBackendPayload(plan),
        options: await _getAuthOptions(),
      );
      _debugLog(
          '[SubscriptionPlanRepository] $endpoint status=${response.statusCode ?? 'unknown'} body=${response.data}');
      final data = response.data as Map<String, dynamic>;
      return SubscriptionPlan.fromJson(data['plan'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _debugLog(
          '[SubscriptionPlanRepository] $endpoint failed type=${e.type} status=${e.response?.statusCode ?? 'unknown'} body=${e.response?.data}');
      throw Exception(_errorMessage(e, 'Failed to create plan'));
    }
  }

  Future<SubscriptionPlan> updatePlan(SubscriptionPlan plan) async {
    final endpoint = '/admin/subscriptions/plans/${plan.id}';
    _debugLog('[SubscriptionPlanRepository] PUT ${_dio.options.baseUrl}$endpoint');
    try {
      final response = await _dio.put(
        endpoint,
        data: _toBackendPayload(plan),
        options: await _getAuthOptions(),
      );
      _debugLog(
          '[SubscriptionPlanRepository] $endpoint status=${response.statusCode ?? 'unknown'} body=${response.data}');
      final data = response.data as Map<String, dynamic>;
      return SubscriptionPlan.fromJson(data['plan'] as Map<String, dynamic>);
    } on DioException catch (e) {
      _debugLog(
          '[SubscriptionPlanRepository] $endpoint failed type=${e.type} status=${e.response?.statusCode ?? 'unknown'} body=${e.response?.data}');
      throw Exception(_errorMessage(e, 'Failed to update plan'));
    }
  }

  Future<void> deletePlan(String id) async {
    try {
      await _dio.delete(
        '/admin/subscriptions/plans/$id',
        options: await _getAuthOptions(),
      );
    } on DioException catch (e) {
      throw Exception(_errorMessage(e, 'Failed to delete plan'));
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
      throw Exception(_errorMessage(e, 'Failed to load subscription'));
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
      throw Exception(_errorMessage(e, 'Failed to submit subscription request'));
    }
  }

  Future<void> cancelRequest(String requestId) async {
    try {
      await _dio.delete(
        '/subscriptions/requests/$requestId',
        options: await _getAuthOptions(),
      );
    } on DioException catch (e) {
      throw Exception(_errorMessage(e, 'Failed to cancel subscription request'));
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
      throw Exception(_errorMessage(e, 'Failed to load subscription requests'));
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
      throw Exception(_errorMessage(e, 'Failed to approve request'));
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
      throw Exception(_errorMessage(e, 'Failed to reject request'));
    }
  }
}

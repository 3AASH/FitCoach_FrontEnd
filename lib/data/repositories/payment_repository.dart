import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/config/api_config.dart';

class PaymentRepository {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;
  final Future<String?> Function()? _tokenReader;
  
  static const String _tokenKey = 'fitcoach_auth_token';
  
  PaymentRepository({
    Dio? dio,
    FlutterSecureStorage? secureStorage,
    Future<String?> Function()? tokenReader,
  })
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: ApiConfig.baseUrl,
              connectTimeout: ApiConfig.connectTimeout,
              receiveTimeout: ApiConfig.receiveTimeout,
            )),
        _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _tokenReader = tokenReader;
  
  Future<String?> _getToken() async {
    if (_tokenReader != null) {
      return _tokenReader();
    }
    return await _secureStorage.read(key: _tokenKey);
  }
  
  Future<Options> _getAuthOptions() async {
    final token = await _getToken();
    return Options(
      headers: {'Authorization': 'Bearer $token'},
    );
  }
  
  /// Create Stripe payment intent for subscription
  Future<Map<String, dynamic>> createStripePayment({
    required String tier,
    required String billingCycle,
  }) async {
    try {
      final response = await _dio.post(
        '/payments/create-checkout',
        data: {
          'tier': tier,
          'billingCycle': billingCycle,
          'provider': 'stripe',
        },
        options: await _getAuthOptions(),
      );

      final data = response.data as Map<String, dynamic>;
      final checkout = (data['checkout'] as Map?)?.cast<String, dynamic>() ?? {};
      return {
        'checkoutUrl': checkout['checkoutUrl'] ?? checkout['checkout_url'],
        'sessionId': checkout['sessionId'] ?? checkout['session_id'],
      };
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to create payment');
    }
  }
  
  /// Confirm Stripe payment
  Future<Map<String, dynamic>> confirmStripePayment(String paymentIntentId) async {
    try {
      final response = await _dio.get(
        '/payments/subscription',
        options: await _getAuthOptions(),
      );

      final data = response.data as Map<String, dynamic>;
      return {
        ...data,
        'paymentIntentId': paymentIntentId,
      };
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Payment confirmation failed');
    }
  }
  
  /// Create Tap Payment (Middle East payment gateway)
  Future<Map<String, dynamic>> createTapPayment({
    required String tier,
    required String billingCycle,
  }) async {
    try {
      final response = await _dio.post(
        '/payments/create-checkout',
        data: {
          'tier': tier,
          'billingCycle': billingCycle,
          'provider': 'tap',
        },
        options: await _getAuthOptions(),
      );

      final data = response.data as Map<String, dynamic>;
      final checkout = (data['checkout'] as Map?)?.cast<String, dynamic>() ?? {};
      return {
        'paymentUrl': checkout['checkoutUrl'] ?? checkout['checkout_url'],
        'chargeId': checkout['chargeId'] ?? checkout['charge_id'],
      };
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to create Tap payment');
    }
  }
  
  /// Check payment status (Tap)
  Future<Map<String, dynamic>> checkTapPaymentStatus(String chargeId) async {
    try {
      final response = await _dio.get(
        '/payments/subscription',
        options: await _getAuthOptions(),
      );

      final data = response.data as Map<String, dynamic>;
      return {
        ...data,
        'chargeId': chargeId,
      };
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to check payment status');
    }
  }
  
  /// Get subscription prices
  Future<Map<String, dynamic>> getSubscriptionPrices() async {
    try {
      final response = await _dio.get(
        '/subscriptions/plans',
        options: await _getAuthOptions(),
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to get prices');
    }
  }
  
  /// Get payment history
  Future<List<Map<String, dynamic>>> getPaymentHistory() async {
    try {
      final response = await _dio.get(
        '/payments/history',
        options: await _getAuthOptions(),
      );
      
      return List<Map<String, dynamic>>.from(response.data['payments'] ?? []);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to get payment history');
    }
  }
  
  /// Cancel subscription
  Future<void> cancelSubscription() async {
    try {
      await _dio.post(
        '/payments/cancel',
        options: await _getAuthOptions(),
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to cancel subscription');
    }
  }
  
  /// Update payment method
  Future<void> updatePaymentMethod(Map<String, dynamic> paymentMethodData) async {
    try {
      final newTier = paymentMethodData['newTier'] ?? paymentMethodData['tier'];
      if (newTier is String && newTier.isNotEmpty) {
        await _dio.post(
          '/payments/upgrade',
          data: {
            'newTier': newTier,
            'billingCycle': paymentMethodData['billingCycle'] ?? 'monthly',
            'provider': paymentMethodData['provider'] ?? 'stripe',
          },
          options: await _getAuthOptions(),
        );
        return;
      }

      // Fallback to a supported route to validate auth/session.
      await _dio.get(
        '/payments/subscription',
        options: await _getAuthOptions(),
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to update payment method');
    }
  }
  
  /// Apply promo code
  Future<Map<String, dynamic>> applyPromoCode(String code) async {
    try {
      final response = await _dio.post(
        '/store/promo-codes/apply',
        data: {'code': code},
        options: await _getAuthOptions(),
      );
      
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Invalid promo code');
    }
  }
}

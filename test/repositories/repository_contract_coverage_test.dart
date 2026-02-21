import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitapp/data/models/message.dart';
import 'package:fitapp/data/models/subscription_plan.dart';
import 'package:fitapp/data/repositories/admin_repository.dart';
import 'package:fitapp/data/repositories/messaging_repository.dart';
import 'package:fitapp/data/repositories/payment_repository.dart';
import 'package:fitapp/data/repositories/store_repository.dart';
import 'package:fitapp/data/repositories/subscription_plan_repository.dart';
import 'package:fitapp/data/repositories/user_repository.dart';

void main() {
  group('Repository contract coverage', () {
    test('T-FE-01: UserRepository updateSubscription uses correct path and auth header', () async {
      final captured = <RequestOptions>[];
      final dio = _buildMockDio((options) async {
        captured.add(options);
        return Response<dynamic>(
          requestOptions: options,
          data: {
            'id': 'u-1',
            'name': 'Test User',
            'phoneNumber': '+966500000001',
            'subscriptionTier': 'Premium',
            'hasCompletedFirstIntake': true,
            'hasCompletedSecondIntake': false,
            'injuries': <String>[],
            'role': 'user',
          },
          statusCode: 200,
        );
      });
      final repo = UserRepository(
        dio: dio,
        tokenReader: () async => 'token-123',
      );

      await repo.updateSubscription('Premium');

      expect(captured.single.path, '/users/subscription');
      expect(captured.single.method, 'PATCH');
      expect(captured.single.headers['Authorization'], 'Bearer token-123');
      expect(captured.single.data, {'tier': 'Premium'});
    });

    test('T-FE-02: AdminRepository sends auth header on protected route', () async {
      final captured = <RequestOptions>[];
      final dio = _buildMockDio((options) async {
        captured.add(options);
        return Response<dynamic>(
          requestOptions: options,
          data: {
            'coach': {
              'id': 'coach-1',
              'user_id': 'user-1',
              'full_name': 'Coach Test',
              'email': 'coach@test.com',
              'phone_number': '+966500000002',
              'profile_photo_url': null,
              'specializations': <String>['weight_loss'],
              'client_count': 0,
              'total_earnings': 0,
              'average_rating': null,
              'is_approved': true,
              'is_active': true,
              'created_at': DateTime.now().toIso8601String(),
              'approved_at': DateTime.now().toIso8601String(),
            },
          },
          statusCode: 201,
        );
      });
      final repo = AdminRepository(
        dio: dio,
        tokenReader: () async => 'admin-token',
      );

      await repo.createCoach(
        fullName: 'Coach Test',
        email: 'coach@test.com',
      );

      expect(captured.single.path, '/admin/coaches');
      expect(captured.single.method, 'POST');
      expect(captured.single.headers['Authorization'], 'Bearer admin-token');
    });

    test('T-FE-03: SubscriptionPlanRepository uses auth header for admin create', () async {
      final captured = <RequestOptions>[];
      final dio = _buildMockDio((options) async {
        captured.add(options);
        return Response<dynamic>(
          requestOptions: options,
          data: {
            'plan': {
              'id': 'plan-1',
              'name': 'Premium',
              'description': 'Plan',
              'price': 299,
              'currency': 'SAR',
              'features': <Map<String, dynamic>>[],
            },
          },
          statusCode: 201,
        );
      });
      final repo = SubscriptionPlanRepository(
        dio: dio,
        tokenReader: () async => 'sub-token',
      );

      await repo.createPlan(
        const SubscriptionPlan(
          id: 'plan-1',
          name: 'Premium',
          description: 'Plan',
          monthlyPrice: 299,
        ),
      );

      expect(captured.single.path, '/admin/subscriptions/plans');
      expect(captured.single.method, 'POST');
      expect(captured.single.headers['Authorization'], 'Bearer sub-token');
    });

    test('T-FE-04: StoreRepository parses categories from name/category payloads', () async {
      final dio = _buildMockDio((options) async {
        return Response<dynamic>(
          requestOptions: options,
          data: {
            'categories': [
              {'name': 'Supplements'},
              {'category': 'Equipment'},
              'Accessories',
            ],
          },
          statusCode: 200,
        );
      });
      final repo = StoreRepository(
        dio: dio,
        tokenReader: () async => 'store-token',
      );

      final categories = await repo.getCategories();
      expect(categories, ['Supplements', 'Equipment', 'Accessories']);
    });

    test('T-FE-05: PaymentRepository uses supported paths and parses checkout payload', () async {
      final captured = <RequestOptions>[];
      final dio = _buildMockDio((options) async {
        captured.add(options);
        if (options.path == '/payments/create-checkout') {
          return Response<dynamic>(
            requestOptions: options,
            data: {
              'checkout': {
                'checkout_url': 'https://pay.example/checkout',
                'session_id': 'sess_1',
              },
            },
            statusCode: 200,
          );
        }
        if (options.path == '/payments/upgrade') {
          return Response<dynamic>(
            requestOptions: options,
            data: {'success': true},
            statusCode: 200,
          );
        }
        throw DioException(
          requestOptions: options,
          error: 'Unexpected route',
        );
      });
      final repo = PaymentRepository(
        dio: dio,
        tokenReader: () async => 'pay-token',
      );

      final checkout = await repo.createStripePayment(
        tier: 'premium',
        billingCycle: 'monthly',
      );
      await repo.updatePaymentMethod({
        'newTier': 'smart_premium',
        'billingCycle': 'yearly',
        'provider': 'tap',
      });

      expect(checkout['checkoutUrl'], 'https://pay.example/checkout');
      expect(checkout['sessionId'], 'sess_1');
      expect(captured[0].path, '/payments/create-checkout');
      expect(captured[0].method, 'POST');
      expect(captured[1].path, '/payments/upgrade');
      expect(captured[1].method, 'POST');
    });

    test('T-FE-06: MessagingRepository parses send wrapper after attachment upload', () async {
      final captured = <RequestOptions>[];
      final dio = _buildMockDio((options) async {
        captured.add(options);
        if (options.path == '/messages/upload') {
          return Response<dynamic>(
            requestOptions: options,
            data: {
              'attachment': {
                'url': 'https://cdn.example/file.png',
                'type': 'image',
                'name': 'file.png',
              },
            },
            statusCode: 200,
          );
        }
        if (options.path == '/messages/send') {
          return Response<dynamic>(
            requestOptions: options,
            data: {
              'message': {
                'id': 'msg-1',
                'conversationId': 'conv-1',
                'senderId': 'user-1',
                'receiverId': 'coach-1',
                'content': 'hello',
                'messageType': 'image',
                'attachmentUrl': 'https://cdn.example/file.png',
                'attachmentType': 'image',
                'isRead': false,
                'createdAt': DateTime.now().toIso8601String(),
              },
            },
            statusCode: 200,
          );
        }
        throw DioException(
          requestOptions: options,
          error: 'Unexpected route',
        );
      });
      final repo = MessagingRepository(
        dio: dio,
        tokenReader: () async => 'msg-token',
      );

      final tempFile = File('${Directory.systemTemp.path}/fitcoach_msg_test.png');
      await tempFile.writeAsBytes(const [1, 2, 3, 4]);
      addTearDown(() async {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      });

      final message = await repo.sendMessageWithAttachment(
        'conv-1',
        'hello',
        tempFile.path,
        type: MessageType.image,
      );

      expect(message.id, 'msg-1');
      expect(message.attachmentUrl, 'https://cdn.example/file.png');
      expect(captured[0].path, '/messages/upload');
      expect(captured[1].path, '/messages/send');
    });
  });
}

Dio _buildMockDio(Future<Response<dynamic>> Function(RequestOptions options) handler) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, requestHandler) async {
        try {
          final response = await handler(options);
          requestHandler.resolve(response);
        } on DioException catch (e) {
          requestHandler.reject(e);
        } catch (e) {
          requestHandler.reject(
            DioException(
              requestOptions: options,
              error: e,
            ),
          );
        }
      },
    ),
  );
  return dio;
}

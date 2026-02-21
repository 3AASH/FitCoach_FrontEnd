import 'package:flutter_test/flutter_test.dart';
import 'package:fitapp/presentation/providers/quota_provider.dart';
import 'package:fitapp/data/repositories/user_repository.dart';

void main() {
  group('QuotaProvider Tests', () {
    late QuotaProvider quotaProvider;
    late UserRepository userRepository;

    setUp(() {
      userRepository = UserRepository();
      quotaProvider = QuotaProvider(userRepository);
    });

    test('initial state should have zero usage', () {
      expect(quotaProvider.messagesUsed, 0);
      expect(quotaProvider.messagesLimit, 0);
      expect(quotaProvider.videoCallsUsed, 0);
      expect(quotaProvider.videoCallsLimit, 0);
      expect(quotaProvider.isLoading, false);
    });

    test('should have quota limits for different tiers', () {
      expect(QuotaProvider.quotaLimits['Freemium']?['messages'], 20);
      expect(QuotaProvider.quotaLimits['Freemium']?['videoCalls'], 1);
      
      expect(QuotaProvider.quotaLimits['Premium']?['messages'], 200);
      expect(QuotaProvider.quotaLimits['Premium']?['videoCalls'], 2);
      
      expect(QuotaProvider.quotaLimits['Smart Premium']?['messages'], -1); // Unlimited
      expect(QuotaProvider.quotaLimits['Smart Premium']?['videoCalls'], 4);
    });

    test('should check if has messages remaining', () {
      expect(quotaProvider.hasMessagesRemaining, isFalse);
    });

    test('should check if has video calls remaining', () {
      expect(quotaProvider.hasVideoCallsRemaining, isFalse);
    });

    test('should create QuotaProvider instance', () {
      expect(quotaProvider, isNotNull);
      expect(quotaProvider, isA<QuotaProvider>());
    });
  });
}
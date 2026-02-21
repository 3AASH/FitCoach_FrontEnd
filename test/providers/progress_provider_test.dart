import 'package:flutter_test/flutter_test.dart';
import 'package:fitapp/data/repositories/user_repository.dart';
import 'package:fitapp/presentation/providers/user_provider.dart';

void main() {
  group('UserProvider Tests', () {
    late UserProvider userProvider;
    late UserRepository userRepository;

    setUp(() {
      userRepository = UserRepository();
      userProvider = UserProvider(userRepository);
    });

    test('initial state should be empty', () {
      expect(userProvider.profile, isNull);
      expect(userProvider.isLoading, false);
      expect(userProvider.error, isNull);
    });

    test('should create UserProvider instance', () {
      expect(userProvider, isNotNull);
      expect(userProvider, isA<UserProvider>());
    });

    test('should have proper getters', () {
      expect(userProvider.profile, isNull);
      expect(userProvider.isLoading, isFalse);
      expect(userProvider.error, isNull);
    });
  });
}
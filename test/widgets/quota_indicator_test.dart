import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitapp/presentation/widgets/quota_indicator.dart';
import 'package:fitapp/presentation/providers/language_provider.dart';
import 'package:fitapp/presentation/providers/quota_provider.dart';
import 'package:fitapp/data/repositories/user_repository.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  Future<LanguageProvider> _createEnglishLanguageProvider() async {
    final provider = LanguageProvider();
    await provider.setLanguage('en');
    return provider;
  }

  Widget _wrapWithProviders({
    required Widget child,
    required QuotaProvider quotaProvider,
    required LanguageProvider languageProvider,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<QuotaProvider>.value(value: quotaProvider),
        ChangeNotifierProvider<LanguageProvider>.value(value: languageProvider),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: child,
        ),
      ),
    );
  }

  group('QuotaIndicator Widget Tests', () {
    testWidgets('renders message quota indicator (default)', (WidgetTester tester) async {
      final languageProvider = await _createEnglishLanguageProvider();
      final quotaProvider = QuotaProvider(UserRepository());
      await tester.pumpWidget(
        _wrapWithProviders(
          child: const QuotaIndicator(type: 'message'),
          quotaProvider: quotaProvider,
          languageProvider: languageProvider,
        ),
      );
      expect(find.byType(QuotaIndicator), findsOneWidget);
      expect(find.byIcon(Icons.message), findsOneWidget);
    });

    testWidgets('renders video call quota indicator', (WidgetTester tester) async {
      final languageProvider = await _createEnglishLanguageProvider();
      final quotaProvider = QuotaProvider(UserRepository());
      await tester.pumpWidget(
        _wrapWithProviders(
          child: const QuotaIndicator(type: 'videoCall'),
          quotaProvider: quotaProvider,
          languageProvider: languageProvider,
        ),
      );
      expect(find.byType(QuotaIndicator), findsOneWidget);
      expect(find.byIcon(Icons.videocam), findsOneWidget);
    });

    testWidgets('renders with showDetails true', (WidgetTester tester) async {
      final languageProvider = await _createEnglishLanguageProvider();
      final quotaProvider = QuotaProvider(UserRepository());
      await tester.pumpWidget(
        _wrapWithProviders(
          child: const QuotaIndicator(type: 'message', showDetails: true),
          quotaProvider: quotaProvider,
          languageProvider: languageProvider,
        ),
      );
      expect(find.byType(QuotaIndicator), findsOneWidget);
      // Should find a column or more detailed info
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('renders with showDetails false (compact)', (WidgetTester tester) async {
      final languageProvider = await _createEnglishLanguageProvider();
      final quotaProvider = QuotaProvider(UserRepository());
      await tester.pumpWidget(
        _wrapWithProviders(
          child: const QuotaIndicator(type: 'message', showDetails: false),
          quotaProvider: quotaProvider,
          languageProvider: languageProvider,
        ),
      );
      expect(find.byType(QuotaIndicator), findsOneWidget);
      // Should find a row for compact info
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('renders unlimited state for Smart Premium', (WidgetTester tester) async {
      final languageProvider = await _createEnglishLanguageProvider();
      final quotaProvider = QuotaProvider(UserRepository());
      quotaProvider.setLimitsForTier('Smart Premium');
      // This test assumes the provider is mocked to return limit == -1 for messages
      // In a real test, you would use a mock provider or test harness
      // Here, we just check the widget builds without error
      await tester.pumpWidget(
        _wrapWithProviders(
          child: const QuotaIndicator(type: 'message'),
          quotaProvider: quotaProvider,
          languageProvider: languageProvider,
        ),
      );
      expect(find.byType(QuotaIndicator), findsOneWidget);
      expect(find.byIcon(Icons.all_inclusive), findsOneWidget);
    });
  });
}
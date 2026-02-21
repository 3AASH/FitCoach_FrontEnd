import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitapp/presentation/providers/language_provider.dart';
import 'package:fitapp/presentation/screens/store/store_intro_screen.dart';
import 'package:fitapp/presentation/screens/nutrition/nutrition_intro_screen.dart';
import 'package:fitapp/presentation/screens/messaging/coach_intro_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('StoreIntroScreen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => LanguageProvider(),
        child: MaterialApp(
          home: StoreIntroScreen(onGetStarted: () {}),
        ),
      ),
    );

    expect(find.byType(StoreIntroScreen), findsOneWidget);
  });

  testWidgets('NutritionIntroScreen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => LanguageProvider(),
        child: MaterialApp(
          home: NutritionIntroScreen(onGetStarted: () {}),
        ),
      ),
    );

    expect(find.byType(NutritionIntroScreen), findsOneWidget);
  });

  testWidgets('CoachIntroScreen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => LanguageProvider(),
        child: MaterialApp(
          home: CoachIntroScreen(onGetStarted: () {}),
        ),
      ),
    );

    expect(find.byType(CoachIntroScreen), findsOneWidget);
  });
}

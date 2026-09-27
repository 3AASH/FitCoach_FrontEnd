/// The coach nutrition editor had a meal picker that recorded a name and
/// nothing else: no portion to choose, no macros filled in, and a recipe
/// reference that was dropped on the way to the server and again on the way
/// back. These cover the behaviour the admin plan editor already had — pick a
/// meal, pick a size, and let the size decide the numbers.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitapp/data/models/nutrition_plan.dart';
import 'package:fitapp/data/models/user_profile.dart';
import 'package:fitapp/data/repositories/auth_repository.dart';
import 'package:fitapp/data/repositories/coach_repository.dart';
import 'package:fitapp/presentation/providers/auth_provider.dart';
import 'package:fitapp/presentation/providers/coach_provider.dart';
import 'package:fitapp/presentation/providers/language_provider.dart';
import 'package:fitapp/presentation/screens/coach/nutrition_plan_editor_screen.dart';

/// Five portions of one dish, the shape the engine seeds them in.
List<Map<String, dynamic>> _koshariVariants() => [
      {
        'variant_id': 'EG_MAIN_012_S',
        'recipe_id': 'EG_MAIN_012',
        'portion_code': 'S',
        'name_en': 'Koshari',
        'name_ar': 'كشري',
        'meal_types': ['lunch'],
        'market_tags': ['EG'],
        'nutrition': {
          'calories': 420,
          'protein_g': 12.5,
          'carbs_g': 70,
          'fat_g': 8
        },
      },
      {
        'variant_id': 'EG_MAIN_012_M',
        'recipe_id': 'EG_MAIN_012',
        'portion_code': 'M',
        'name_en': 'Koshari',
        'name_ar': 'كشري',
        'meal_types': ['lunch'],
        'market_tags': ['EG'],
        'nutrition': {
          'calories': 620,
          'protein_g': 18.5,
          'carbs_g': 104,
          'fat_g': 12
        },
      },
      {
        'variant_id': 'EG_MAIN_012_L',
        'recipe_id': 'EG_MAIN_012',
        'portion_code': 'L',
        'name_en': 'Koshari',
        'name_ar': 'كشري',
        'meal_types': ['lunch'],
        'market_tags': ['EG'],
        'nutrition': {
          'calories': 820,
          'protein_g': 24.5,
          'carbs_g': 138,
          'fat_g': 16
        },
      },
    ];

Map<String, dynamic> _grilledChicken() => {
      'variant_id': 'SA_MAIN_004_M',
      'recipe_id': 'SA_MAIN_004',
      'portion_code': 'M',
      'name_en': 'Grilled Chicken',
      'name_ar': 'دجاج مشوي',
      'meal_types': ['dinner'],
      'market_tags': ['SA'],
      'nutrition': {
        'calories': 330,
        'protein_g': 48,
        'carbs_g': 2,
        'fat_g': 14
      },
    };

class _FakeCoachRepository extends CoachRepository {
  _FakeCoachRepository({
    required this.variants,
    this.plan,
  });

  final List<Map<String, dynamic>> variants;
  final NutritionPlan? plan;

  /// The mealPlan of the last save, so a test can assert what left the screen.
  Map<String, dynamic>? savedMealPlan;

  @override
  Future<List<Map<String, dynamic>>> getExerciseLibrary({
    String? search,
    int limit = 200,
  }) async =>
      const [];

  @override
  Future<List<Map<String, dynamic>>> getRecipeLibrary({
    String? search,
    int limit = 200,
  }) async =>
      const [];

  @override
  Future<List<Map<String, dynamic>>> getRecipeVariantLibrary({
    String? search,
    int limit = 2000,
  }) async =>
      variants;

  @override
  Future<NutritionPlan?> getClientNutritionPlan({
    required String coachId,
    required String clientId,
  }) async =>
      plan;

  @override
  Future<void> updateClientNutritionPlan({
    required String coachId,
    required String clientId,
    required int dailyCalories,
    required Map<String, dynamic> macros,
    required Map<String, dynamic> mealPlan,
    required String notes,
  }) async {
    savedMealPlan = mealPlan;
  }
}

class _StubAuthRepository implements AuthRepositoryBase {
  @override
  dynamic noSuchMethod(Invocation invocation) async => null;
}

Future<LanguageProvider> _englishLanguage() async {
  final lang = LanguageProvider();
  await lang.setLanguage('en');
  return lang;
}

/// Signed in as a coach, which is what makes the editor editable at all.
AuthProvider _coachAuth() {
  final auth = AuthProvider(_StubAuthRepository());
  auth.updateUser(UserProfile(
    id: 'coach-user-1',
    name: 'Coach',
    phoneNumber: '+966500001001',
    role: 'coach',
  ));
  return auth;
}

Future<void> _pumpEditor(
  WidgetTester tester,
  _FakeCoachRepository repository,
  LanguageProvider lang,
) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<LanguageProvider>.value(value: lang),
        ChangeNotifierProvider<AuthProvider>.value(value: _coachAuth()),
        ChangeNotifierProvider<CoachProvider>(
          create: (_) => CoachProvider(repository),
        ),
      ],
      child: const MaterialApp(
        home: NutritionPlanEditorScreen(
          clientId: 'client-1',
          coachId: 'coach-1',
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Each meal macro field carries its own value in its key
/// (`<prefix>:<day>:<meal>:<value>:<derived>`), so matching the key is the same
/// as reading what the field displays - and it cannot be confused with the
/// day's calorie target at the top of the screen, which shares the label.
Finder _macroField(String prefix, String value) =>
    find.byWidgetPredicate((widget) {
      final key = widget.key;
      if (key is! ValueKey<String>) return false;
      final parts = key.value.split(':');
      return parts.length > 3 && parts.first == prefix && parts[3] == value;
    });

/// The app bar's save button. The one at the bottom of the form sits below the
/// fold in a test-sized window.
Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.descendant(
    of: find.byType(AppBar),
    matching: find.byIcon(Icons.save),
  ));
  await tester.pumpAndSettle();
}

/// The editor opens with no days when the client has no plan yet, so a meal row
/// needs a day to live in first.
Future<void> _addMealRow(WidgetTester tester) async {
  await tester.tap(find.text('Add day'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Add meal'));
  await tester.pumpAndSettle();
}

/// Types enough of a meal name to narrow the list, then picks it.
Future<void> _pickKoshari(WidgetTester tester) async {
  await tester.enterText(
      find.widgetWithText(TextFormField, 'Meal name'), 'Kosh');
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(ListTile, 'Koshari'));
  await tester.pumpAndSettle();
}

void main() {
  // LanguageProvider.setLanguage writes through to SharedPreferences, which
  // never completes in a widget test without mock values.
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('choosing a meal fills in the calories of its default portion',
      (tester) async {
    // This is the reported bug: the picker found the meal and left the
    // calories at whatever was in the box.
    final repository = _FakeCoachRepository(variants: _koshariVariants());
    final lang = await _englishLanguage();
    await _pumpEditor(tester, repository, lang);

    await _addMealRow(tester);
    await _pickKoshari(tester);

    // M is the default portion, and M is 620 kcal.
    expect(_macroField('cal', '620'), findsOneWidget);
    expect(_macroField('p', '18.5'), findsOneWidget);
    expect(_macroField('c', '104'), findsOneWidget);
    expect(_macroField('f', '12'), findsOneWidget);
  });

  testWidgets('the portion dropdown offers that meal\'s sizes and nothing else',
      (tester) async {
    final repository = _FakeCoachRepository(
      variants: [..._koshariVariants(), _grilledChicken()],
    );
    final lang = await _englishLanguage();
    await _pumpEditor(tester, repository, lang);

    await _addMealRow(tester);
    await _pickKoshari(tester);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();

    expect(find.textContaining('S · Small'), findsWidgets);
    expect(find.textContaining('L · Large'), findsWidgets);
    // The other dish's portion must not be offered here.
    expect(find.textContaining('330'), findsNothing);
  });

  testWidgets('switching to a larger portion updates the calories and macros',
      (tester) async {
    final repository = _FakeCoachRepository(variants: _koshariVariants());
    final lang = await _englishLanguage();
    await _pumpEditor(tester, repository, lang);

    await _addMealRow(tester);
    await _pickKoshari(tester);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('L · Large').last);
    await tester.pumpAndSettle();

    expect(_macroField('cal', '820'), findsOneWidget);
    expect(_macroField('p', '24.5'), findsOneWidget);
  });

  testWidgets('the meal list shows one entry per dish, not one per portion',
      (tester) async {
    // Five portions of one dish used to mean five identical-looking rows.
    final repository = _FakeCoachRepository(variants: _koshariVariants());
    final lang = await _englishLanguage();
    await _pumpEditor(tester, repository, lang);

    await _addMealRow(tester);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Meal name'), 'Kosh');
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ListTile, 'Koshari'), findsOneWidget);
  });

  testWidgets('saving sends the recipe, the variant and the portion macros',
      (tester) async {
    final repository = _FakeCoachRepository(variants: _koshariVariants());
    final lang = await _englishLanguage();
    await _pumpEditor(tester, repository, lang);

    // The daily target is the screen's first field, and a save with no target
    // is rejected before it reaches the repository.
    await tester.enterText(find.byType(TextField).first, '2000');
    await _addMealRow(tester);
    await _pickKoshari(tester);

    await _save(tester);

    final meal = ((repository.savedMealPlan!['days'] as List).first
        as Map<String, dynamic>)['meals'] as List;
    expect(meal.first, {
      'name': 'Koshari',
      'recipeId': 'EG_MAIN_012',
      'plannedRecipeId': 'EG_MAIN_012',
      'variantId': 'EG_MAIN_012_M',
      'plannedVariantId': 'EG_MAIN_012_M',
      'portionCode': 'M',
      'type': 'meal',
      'time': '',
      'calories': 620,
      'protein': 18.5,
      'carbs': 104,
      'fat': 12,
    });
  });

  testWidgets('a saved plan reopens on the portion it was saved with',
      (tester) async {
    // The reference used to be dropped by the model, so a reopened plan was
    // free text with no portion and the macros had to be retyped.
    final repository = _FakeCoachRepository(
      variants: _koshariVariants(),
      plan: NutritionPlan.fromJson({
        'id': 'plan-1',
        'dailyCalories': 2000,
        'macros': {'protein': 150, 'carbs': 200, 'fat': 60},
        'days': [
          {
            'dayNumber': 1,
            'dayName': 'Monday',
            'meals': [
              {
                'name': 'Koshari',
                'type': 'lunch',
                'plannedRecipeId': 'EG_MAIN_012',
                'plannedVariantId': 'EG_MAIN_012_L',
                'portionCode': 'L',
                'calories': 820,
                'protein': 24.5,
                'carbs': 138,
                'fat': 16,
              }
            ],
          }
        ],
      }),
    );
    final lang = await _englishLanguage();
    await _pumpEditor(tester, repository, lang);

    expect(_macroField('cal', '820'), findsOneWidget);
    expect(_macroField('p', '24.5'), findsOneWidget);

    await _save(tester);

    final meal = (((repository.savedMealPlan!['days'] as List).first
        as Map<String, dynamic>)['meals'] as List).first as Map;
    expect(meal['recipeId'], 'EG_MAIN_012');
    expect(meal['variantId'], 'EG_MAIN_012_L');
    expect(meal['portionCode'], 'L');
  });

  testWidgets('a day shows what its meals add up to', (tester) async {
    final repository = _FakeCoachRepository(variants: _koshariVariants());
    final lang = await _englishLanguage();
    await _pumpEditor(tester, repository, lang);

    await _addMealRow(tester);
    await _pickKoshari(tester);

    expect(find.textContaining('Day total: 620 kcal'), findsOneWidget);
  });
}

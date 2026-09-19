import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitapp/data/models/nutrition_plan.dart';
import 'package:fitapp/data/repositories/nutrition_repository.dart';
import 'package:fitapp/presentation/providers/language_provider.dart';
import 'package:fitapp/presentation/providers/nutrition_provider.dart';
import 'package:fitapp/presentation/screens/nutrition/meal_detail_screen.dart';

class _FakeNutritionRepository extends NutritionRepository {
  _FakeNutritionRepository({
    this.alternatives = const <MealAlternative>[],
    this.throwOnList = false,
    this.throwOnSwap = false,
  });

  final List<MealAlternative> alternatives;
  final bool throwOnList;
  final bool throwOnSwap;

  String? requestedMealId;
  String? swappedMealId;
  String? swappedVariantId;
  int loadActivePlanCalls = 0;

  @override
  Future<List<MealAlternative>> getMealAlternatives(String mealId) async {
    requestedMealId = mealId;
    if (throwOnList) throw Exception('network down');
    return alternatives;
  }

  @override
  Future<Map<String, dynamic>> swapMeal(String mealId, String variantId) async {
    swappedMealId = mealId;
    swappedVariantId = variantId;
    if (throwOnSwap) {
      throw Exception('This meal has already been logged and can no longer be swapped');
    }
    return {'success': true};
  }

  @override
  Future<NutritionPlan?> getPlanForDate(DateTime date) async {
    loadActivePlanCalls += 1;
    return null;
  }

  @override
  Future<NutritionAccessStatus> getAccessStatus() async {
    return NutritionAccessStatus.fromJson(const {'hasAccess': true});
  }
}

Meal _meal() => Meal(
      id: 'meal-1',
      name: 'Grilled Chicken Fillet',
      nameAr: 'صدور دجاج مشوية',
      nameEn: 'Grilled Chicken Fillet',
      type: 'lunch',
      time: '13:00',
      calories: 600,
      macros: MacroTargets(protein: 62, carbs: 55, fats: 14),
      foods: const [],
    );

MealAlternative _alternative({
  required String variantId,
  required String name,
  int calories = 580,
  int delta = -20,
  bool suggested = false,
}) =>
    MealAlternative(
      variantId: variantId,
      recipeId: variantId.replaceAll('_M', ''),
      nameEn: name,
      nameAr: name,
      portionCode: 'M',
      calories: calories,
      protein: 58,
      carbs: 50,
      fats: 13,
      calorieDelta: delta,
      suggestedByTemplate: suggested,
    );

Future<Widget> _wrap(_FakeNutritionRepository repo) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final lang = LanguageProvider();
  await lang.setLanguage('en');
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<LanguageProvider>.value(value: lang),
      ChangeNotifierProvider<NutritionProvider>(
        create: (_) => NutritionProvider(repo),
      ),
    ],
    child: MaterialApp(home: Scaffold(body: MealSwapSheet(meal: _meal()))),
  );
}

void main() {
  testWidgets('lists the alternatives the server offers, with calorie deltas',
      (tester) async {
    final repo = _FakeNutritionRepository(alternatives: [
      _alternative(
          variantId: 'EG_MAIN_040_M', name: 'Grilled Fish', suggested: true),
      _alternative(
          variantId: 'EG_MAIN_037_M',
          name: 'Grilled Shrimp',
          calories: 640,
          delta: 40),
    ]);

    await tester.pumpWidget(await _wrap(repo));
    await tester.pumpAndSettle();

    expect(repo.requestedMealId, 'meal-1');
    expect(find.text('Grilled Fish'), findsOneWidget);
    expect(find.text('Grilled Shrimp'), findsOneWidget);
    // The delta is signed so the client sees the direction, not two numbers.
    expect(find.textContaining('(-20)'), findsOneWidget);
    expect(find.textContaining('(+40)'), findsOneWidget);
    // The plan's own suggestion is marked.
    expect(find.byIcon(Icons.star), findsOneWidget);
  });

  testWidgets('tapping an alternative applies it and closes the sheet',
      (tester) async {
    final repo = _FakeNutritionRepository(alternatives: [
      _alternative(variantId: 'EG_MAIN_040_M', name: 'Grilled Fish'),
    ]);

    await tester.pumpWidget(await _wrap(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Grilled Fish'));
    await tester.pumpAndSettle();

    expect(repo.swappedMealId, 'meal-1');
    expect(repo.swappedVariantId, 'EG_MAIN_040_M');
    // The plan is reloaded so every screen shows the new meal.
    expect(repo.loadActivePlanCalls, greaterThan(0));
  });

  testWidgets('shows the server reason when a swap is refused', (tester) async {
    final repo = _FakeNutritionRepository(
      alternatives: [
        _alternative(variantId: 'EG_MAIN_040_M', name: 'Grilled Fish'),
      ],
      throwOnSwap: true,
    );

    await tester.pumpWidget(await _wrap(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Grilled Fish'));
    await tester.pumpAndSettle();

    // "Already logged" must not be flattened into a generic failure.
    expect(find.textContaining('already been logged'), findsOneWidget);
    // The sheet stays open so the client can pick something else.
    expect(find.text('Grilled Fish'), findsOneWidget);
  });

  testWidgets('says so plainly when there is nothing to swap to',
      (tester) async {
    final repo = _FakeNutritionRepository(alternatives: const []);

    await tester.pumpWidget(await _wrap(repo));
    await tester.pumpAndSettle();

    expect(find.text('No alternatives are available for this meal right now.'),
        findsOneWidget);
  });

  testWidgets('a failed lookup shows the empty state, not a broken screen',
      (tester) async {
    final repo = _FakeNutritionRepository(throwOnList: true);

    await tester.pumpWidget(await _wrap(repo));
    await tester.pumpAndSettle();

    expect(find.text('No alternatives are available for this meal right now.'),
        findsOneWidget);
  });
}

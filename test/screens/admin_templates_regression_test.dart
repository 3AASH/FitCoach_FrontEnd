import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitapp/data/models/admin_exercise.dart';
import 'package:fitapp/data/models/admin_workout_template.dart';
import 'package:fitapp/data/repositories/admin_repository.dart';
import 'package:fitapp/presentation/providers/admin_provider.dart';
import 'package:fitapp/presentation/providers/language_provider.dart';
import 'package:fitapp/presentation/screens/admin/admin_nutrition_templates_screen.dart';
import 'package:fitapp/presentation/screens/admin/admin_workout_templates_screen.dart';

class _FakeAdminRepository extends AdminRepository {
  _FakeAdminRepository({
    this.workoutTemplates = const <AdminWorkoutTemplate>[],
    this.workoutTemplateById = const <String, Map<String, dynamic>>{},
    this.exercises = const <AdminExercise>[],
    this.nutritionEngineRecipes = const <Map<String, dynamic>>[],
    this.nutritionEnginePlans = const <Map<String, dynamic>>[],
    this.nutritionIngredients = const <Map<String, dynamic>>[],
    this.nutritionRecipeVariants = const <Map<String, dynamic>>[],
    this.nutritionEngineImports = const <Map<String, dynamic>>[],
    this.nutritionEnginePlanById = const <String, Map<String, dynamic>>{},
  }) : super(tokenReader: _tokenReader);

  static Future<String?> _tokenReader() async => 'test-token';

  final List<AdminWorkoutTemplate> workoutTemplates;
  final Map<String, Map<String, dynamic>> workoutTemplateById;
  final List<AdminExercise> exercises;
  final List<Map<String, dynamic>> nutritionEngineRecipes;
  final List<Map<String, dynamic>> nutritionEnginePlans;
  final List<Map<String, dynamic>> nutritionIngredients;
  final List<Map<String, dynamic>> nutritionRecipeVariants;
  final List<Map<String, dynamic>> nutritionEngineImports;
  final Map<String, Map<String, dynamic>> nutritionEnginePlanById;

  @override
  Future<List<AdminWorkoutTemplate>> getWorkoutTemplates({
    String? type,
    String? goal,
    String? location,
  }) async {
    return workoutTemplates;
  }

  @override
  Future<Map<String, dynamic>> getWorkoutTemplate(String planId) async {
    return workoutTemplateById[planId] ?? const <String, dynamic>{};
  }

  @override
  Future<List<AdminExercise>> getExercises({
    String? search,
    String? category,
    String? difficulty,
    int limit = 100,
    int offset = 0,
  }) async {
    return exercises;
  }

  @override
  Future<List<Map<String, dynamic>>> getNutritionEngineRecipes({
    String? search,
    String? validationStatus,
    bool? active,
    int limit = 100,
    int offset = 0,
  }) async {
    return nutritionEngineRecipes;
  }

  @override
  Future<List<Map<String, dynamic>>> getNutritionEnginePlans({
    String? planType,
    String? market,
    int? calorieBand,
    String? macroProfile,
    String? validationStatus,
    int limit = 100,
    int offset = 0,
  }) async {
    return nutritionEnginePlans;
  }

  @override
  Future<List<Map<String, dynamic>>> getNutritionIngredients({
    String? search,
  }) async {
    return nutritionIngredients;
  }

  @override
  Future<List<Map<String, dynamic>>> getNutritionRecipeVariants() async {
    return nutritionRecipeVariants;
  }

  @override
  Future<List<Map<String, dynamic>>> getNutritionEngineImports() async {
    return nutritionEngineImports;
  }

  @override
  Future<Map<String, dynamic>> getNutritionEnginePlan(String planId) async {
    return nutritionEnginePlanById[planId] ?? const <String, dynamic>{};
  }

  final List<Map<String, dynamic>> createdIngredients = <Map<String, dynamic>>[];

  @override
  Future<Map<String, dynamic>> createNutritionIngredient(
      Map<String, dynamic> ingredient) async {
    createdIngredients.add(ingredient);
    return <String, dynamic>{...ingredient, 'ingredient_id': 'ingredient_new'};
  }
}

Future<LanguageProvider> _englishLanguageProvider() async {
  final languageProvider = LanguageProvider();
  await languageProvider.setLanguage('en');
  return languageProvider;
}

Widget _wrapWithProviders({
  required Widget child,
  required AdminProvider adminProvider,
  required LanguageProvider languageProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<LanguageProvider>.value(value: languageProvider),
      ChangeNotifierProvider<AdminProvider>.value(value: adminProvider),
    ],
    child: MaterialApp(home: child),
  );
}

Finder _macroValueKeyFinder(String valueSuffix) {
  return find.byWidgetPredicate((widget) {
    final key = widget.key;
    if (key is! ValueKey<String>) return false;
    return key.value.endsWith(':$valueSuffix');
  });
}

void main() {
  // LanguageProvider.setLanguage writes through to SharedPreferences, which
  // never completes in a widget test without mock values - the await would hang
  // before the first frame is ever pumped.
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('workout template editor resolves exercise name from ex_id fallback',
      (tester) async {
    final repo = _FakeAdminRepository(
      workoutTemplates: const [
        AdminWorkoutTemplate(
          planId: 'starter_plan_1',
          type: 'starter',
          nameEn: 'Starter Plan',
          trainingDays: 1,
          weeks: 4,
        ),
      ],
      workoutTemplateById: {
        'starter_plan_1': {
          'plan_id': 'starter_plan_1',
          'type': 'starter',
          'name_en': 'Starter Plan',
          'sessions': [
            {
              'day': 1,
              'name_en': 'Day 1',
              'work': [
                {
                  'ex_id': 'push_up',
                  'sets': 3,
                  'reps': '10',
                }
              ]
            }
          ]
        }
      },
      exercises: const [
        AdminExercise(
          id: 'exercise-1',
          exId: 'push_up',
          nameEn: 'Push Up',
          nameAr: 'ضغط',
        ),
      ],
    );
    final adminProvider = AdminProvider(repo);
    final languageProvider = await _englishLanguageProvider();

    await tester.pumpWidget(
      _wrapWithProviders(
        child: const AdminWorkoutTemplatesScreen(),
        adminProvider: adminProvider,
        languageProvider: languageProvider,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.data_object).first);
    await tester.pumpAndSettle();

    expect(find.text('Push Up'), findsWidgets);
  });

  testWidgets(
      'nutrition plan editor normalizes legacy macro keys for planned_nutrition',
      (tester) async {
    final repo = _FakeAdminRepository(
      nutritionEnginePlans: const [
        {
          'plan_id': 'plan_prof_2000',
          'plan_type': 'professional',
          'market': 'SA',
          'calorie_band': 2000,
          'macro_profile': 'balanced',
          'meal_count': 3,
          'rotation': 1,
          'validation_status': 'ok',
          'is_active': true,
        }
      ],
      nutritionEnginePlanById: {
        'plan_prof_2000': {
          'plan_id': 'plan_prof_2000',
          'schema_version': '1.0.0',
          'plan_type': 'professional',
          'market': 'SA',
          'calorie_band': 2000,
          'macro_profile': 'balanced',
          'meal_count': 3,
          'rotation': 1,
          'template_target': {},
          'assignment_rules': {},
          'validation': {'status': 'admin_edited'},
          'days': [
            {
              'day_number': 1,
              'meals': [
                {
                  'slot': 'lunch',
                  'planned_recipe_id': 'recipe_chicken',
                  'planned_meal_variant_id': 'variant_chicken_m',
                  'planned_nutrition': {
                    'calories': 450,
                    'protein': 25,
                    'carbs': 40,
                    'fat': 12,
                  },
                  'alternative_variant_ids': [],
                }
              ]
            }
          ]
        }
      },
      nutritionRecipeVariants: const [
        {
          'variant_id': 'variant_chicken_m',
          'recipe_id': 'recipe_chicken',
          'portion_code': 'M',
          'name_en': 'Chicken Bowl',
          'nutrition': {
            'calories': 450,
            'protein': 25,
            'carbs': 40,
            'fat': 12,
          }
        }
      ],
    );
    final adminProvider = AdminProvider(repo);
    final languageProvider = await _englishLanguageProvider();

    await tester.pumpWidget(
      _wrapWithProviders(
        child: const AdminNutritionTemplatesScreen(),
        adminProvider: adminProvider,
        languageProvider: languageProvider,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Tab).at(2));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.data_object).first);
    await tester.pumpAndSettle();

    expect(_macroValueKeyFinder('450'), findsWidgets);
    expect(_macroValueKeyFinder('25'), findsWidgets);
    expect(_macroValueKeyFinder('40'), findsWidgets);
    expect(_macroValueKeyFinder('12'), findsWidgets);
  });

  testWidgets('each nutrition tab offers only its own create action',
      (tester) async {
    final repo = _FakeAdminRepository(
      nutritionIngredients: const [
        {
          'ingredient_id': 'ingredient_oats',
          'name_en': 'Oats',
          'per_100g': {
            'calories': 389,
            'protein_g': 16.9,
            'carbs_g': 66.3,
            'fat_g': 6.9,
          },
          'is_active': true,
        }
      ],
    );
    await tester.pumpWidget(
      _wrapWithProviders(
        child: const AdminNutritionTemplatesScreen(),
        adminProvider: AdminProvider(repo),
        languageProvider: await _englishLanguageProvider(),
      ),
    );
    await tester.pumpAndSettle();

    Finder fab(String label) =>
        find.widgetWithText(FloatingActionButton, label);

    // Engine meals
    expect(fab('Add meal'), findsOneWidget);
    expect(fab('Add ingredient'), findsNothing);

    // Ingredients - used to show "Add meal", which opened the plan editor.
    await tester.tap(find.byType(Tab).at(1));
    await tester.pumpAndSettle();
    expect(fab('Add ingredient'), findsOneWidget);
    expect(fab('Add meal'), findsNothing);

    // Engine plans - used to have no button at all.
    await tester.tap(find.byType(Tab).at(2));
    await tester.pumpAndSettle();
    expect(fab('Add plan'), findsOneWidget);
    expect(fab('Add meal'), findsNothing);

    // Imports is read-only.
    await tester.tap(find.byType(Tab).at(3));
    await tester.pumpAndSettle();
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('ingredient form saves macros as a per-100g definition',
      (tester) async {
    final repo = _FakeAdminRepository();
    await tester.pumpWidget(
      _wrapWithProviders(
        child: const AdminNutritionTemplatesScreen(),
        adminProvider: AdminProvider(repo),
        languageProvider: await _englishLanguageProvider(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Tab).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FloatingActionButton, 'Add ingredient'));
    await tester.pumpAndSettle();

    final fields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    expect(fields, findsNWidgets(6));
    expect(find.text('Calories / 100 g'), findsOneWidget);

    await tester.enterText(fields.at(0), 'Rolled Oats');
    await tester.enterText(fields.at(2), '389');
    await tester.enterText(fields.at(3), '16.9');
    await tester.enterText(fields.at(4), '66.3');
    await tester.enterText(fields.at(5), '6.9');
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    expect(repo.createdIngredients, hasLength(1));
    expect(repo.createdIngredients.single['name_en'], 'Rolled Oats');
    // Per 100 g, not per gram - these are the values the engine stores.
    expect(repo.createdIngredients.single['per_100g'], {
      'calories': 389,
      'protein_g': 16.9,
      'carbs_g': 66.3,
      'fat_g': 6.9,
    });
  });

  testWidgets('plan meal picker lists meals only and scopes portions to them',
      (tester) async {
    final repo = _FakeAdminRepository(
      nutritionEnginePlans: const [
        {'plan_id': 'plan_1', 'plan_type': 'professional', 'market': 'SA'}
      ],
      nutritionEnginePlanById: const {
        'plan_1': {
          'plan_id': 'plan_1',
          'plan_type': 'professional',
          'market': 'SA',
          'calorie_band': 2000,
          'days': [
            {
              'day_number': 1,
              'meals': [
                {
                  'slot': 'lunch',
                  'planned_recipe_id': 'recipe_chicken',
                  'planned_meal_variant_id': 'variant_chicken_m',
                  'planned_nutrition': {'calories': 450},
                  'alternative_variant_ids': <String>[],
                }
              ]
            }
          ]
        }
      },
      // Two meals, one with two portions - the old picker listed all three
      // as if each portion were a separate meal.
      nutritionRecipeVariants: const [
        {
          'variant_id': 'variant_chicken_s',
          'recipe_id': 'recipe_chicken',
          'portion_code': 'S',
          'name_en': 'Chicken Bowl',
          'nutrition': {'calories': 300},
        },
        {
          'variant_id': 'variant_chicken_m',
          'recipe_id': 'recipe_chicken',
          'portion_code': 'M',
          'name_en': 'Chicken Bowl',
          'nutrition': {'calories': 450},
        },
        {
          'variant_id': 'variant_salad_m',
          'recipe_id': 'recipe_salad',
          'portion_code': 'M',
          'name_en': 'Garden Salad',
          'nutrition': {'calories': 180},
        },
      ],
    );
    await tester.pumpWidget(
      _wrapWithProviders(
        child: const AdminNutritionTemplatesScreen(),
        adminProvider: AdminProvider(repo),
        languageProvider: await _englishLanguageProvider(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Tab).at(2));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.data_object).first);
    await tester.pumpAndSettle();

    // The meal field shows the meal's name with no portion suffix.
    expect(find.text('Chicken Bowl'), findsWidgets);
    expect(find.text('Chicken Bowl (M)'), findsNothing);

    List<String?> portionValues() => tester
        .widget<DropdownButton<String>>(find.byType(DropdownButton<String>))
        .items!
        .map((item) => item.value)
        .toList();

    // Portions are scoped to the selected meal, smallest first.
    expect(portionValues(), ['variant_chicken_s', 'variant_chicken_m']);

    // Switching meal re-scopes the portions to that meal's variants.
    final mealField = find.widgetWithText(TextField, 'Chicken Bowl');
    await tester.ensureVisible(mealField);
    await tester.enterText(mealField, 'Garden');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Garden Salad').last);
    await tester.pumpAndSettle();

    expect(portionValues(), ['variant_salad_m']);
    // Macros follow the newly selected meal's default portion.
    expect(_macroValueKeyFinder('180'), findsWidgets);
  });

  testWidgets('plan editor scopes swap options to the slot, market and dish',
      (tester) async {
    // The picker used to list every variant in the catalogue, so it offered
    // breakfasts against a lunch, the other market's dishes, and the four
    // other portions of the meal already chosen.
    final repo = _FakeAdminRepository(
      nutritionEnginePlans: const [
        {'plan_id': 'plan_1', 'plan_type': 'professional', 'market': 'EG'}
      ],
      nutritionEnginePlanById: const {
        'plan_1': {
          'plan_id': 'plan_1',
          'plan_type': 'professional',
          'market': 'EG',
          'calorie_band': 2000,
          'days': [
            {
              'day_number': 1,
              'meals': [
                {
                  'slot': 'lunch',
                  'planned_recipe_id': 'recipe_chicken',
                  'planned_meal_variant_id': 'variant_chicken_m',
                  'planned_nutrition': {'calories': 450},
                  'alternative_variant_ids': <String>[],
                }
              ]
            }
          ]
        }
      },
      nutritionRecipeVariants: const [
        {
          'variant_id': 'variant_chicken_s', 'recipe_id': 'recipe_chicken',
          'portion_code': 'S', 'name_en': 'Chicken Bowl',
          'meal_types': ['lunch', 'dinner'], 'market_tags': ['EG'],
          'nutrition': {'calories': 300},
        },
        {
          'variant_id': 'variant_chicken_m', 'recipe_id': 'recipe_chicken',
          'portion_code': 'M', 'name_en': 'Chicken Bowl',
          'meal_types': ['lunch', 'dinner'], 'market_tags': ['EG'],
          'nutrition': {'calories': 450},
        },
        {
          'variant_id': 'variant_fish_m', 'recipe_id': 'recipe_fish',
          'portion_code': 'M', 'name_en': 'Grilled Fish',
          'meal_types': ['lunch', 'dinner'], 'market_tags': ['EG'],
          'nutrition': {'calories': 470},
        },
        {
          'variant_id': 'variant_oats_m', 'recipe_id': 'recipe_oats',
          'portion_code': 'M', 'name_en': 'Morning Oats',
          'meal_types': ['breakfast'], 'market_tags': ['EG'],
          'nutrition': {'calories': 440},
        },
        {
          'variant_id': 'variant_kabsa_m', 'recipe_id': 'recipe_kabsa',
          'portion_code': 'M', 'name_en': 'Saudi Only Dish',
          'meal_types': ['lunch', 'dinner'], 'market_tags': ['SA'],
          'nutrition': {'calories': 455},
        },
      ],
    );
    await tester.pumpWidget(
      _wrapWithProviders(
        child: const AdminNutritionTemplatesScreen(),
        adminProvider: AdminProvider(repo),
        languageProvider: await _englishLanguageProvider(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Tab).at(2));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.data_object).first);
    await tester.pumpAndSettle();

    final altField =
        find.widgetWithText(TextField, 'Alternative meals (swap options)');
    await tester.ensureVisible(altField);
    await tester.pumpAndSettle();
    await tester.tap(altField);
    await tester.enterText(altField, 'grill');
    await tester.pumpAndSettle();

    // Same slot and market, and a different dish, is offered.
    expect(find.text('Grilled Fish'), findsOneWidget);
    // A breakfast is not an alternative for lunch.
    expect(find.text('Morning Oats'), findsNothing);
    // Nor is a dish from the other market.
    expect(find.text('Saudi Only Dish'), findsNothing);
    // Nor another portion of the meal already selected.
    expect(find.text('Chicken Bowl (S)'), findsNothing);
  });

  testWidgets('plan editor can fill swap options in one tap', (tester) async {
    final repo = _FakeAdminRepository(
      nutritionEnginePlans: const [
        {'plan_id': 'plan_1', 'plan_type': 'professional', 'market': 'EG'}
      ],
      nutritionEnginePlanById: const {
        'plan_1': {
          'plan_id': 'plan_1',
          'plan_type': 'professional',
          'market': 'EG',
          'calorie_band': 2000,
          'days': [
            {
              'day_number': 1,
              'meals': [
                {
                  'slot': 'lunch',
                  'planned_recipe_id': 'recipe_chicken',
                  'planned_meal_variant_id': 'variant_chicken_m',
                  'planned_nutrition': {'calories': 450},
                  'alternative_variant_ids': <String>[],
                }
              ]
            }
          ]
        }
      },
      nutritionRecipeVariants: const [
        {
          'variant_id': 'variant_chicken_m', 'recipe_id': 'recipe_chicken',
          'portion_code': 'M', 'name_en': 'Chicken Bowl',
          'meal_types': ['lunch'], 'market_tags': ['EG'],
          'nutrition': {'calories': 450},
        },
        {
          'variant_id': 'variant_fish_m', 'recipe_id': 'recipe_fish',
          'portion_code': 'M', 'name_en': 'Grilled Fish',
          'meal_types': ['lunch'], 'market_tags': ['EG'],
          'nutrition': {'calories': 470},
        },
        {
          'variant_id': 'variant_beef_m', 'recipe_id': 'recipe_beef',
          'portion_code': 'M', 'name_en': 'Grilled Beef',
          'meal_types': ['lunch'], 'market_tags': ['EG'],
          'nutrition': {'calories': 430},
        },
        {
          'variant_id': 'variant_shrimp_m', 'recipe_id': 'recipe_shrimp',
          'portion_code': 'M', 'name_en': 'Grilled Shrimp',
          'meal_types': ['lunch'], 'market_tags': ['EG'],
          'nutrition': {'calories': 500},
        },
      ],
    );
    await tester.pumpWidget(
      _wrapWithProviders(
        child: const AdminNutritionTemplatesScreen(),
        adminProvider: AdminProvider(repo),
        languageProvider: await _englishLanguageProvider(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Tab).at(2));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.data_object).first);
    await tester.pumpAndSettle();

    final suggest = find.widgetWithText(OutlinedButton, 'Suggest');
    await tester.ensureVisible(suggest);
    await tester.pumpAndSettle();
    await tester.tap(suggest);
    await tester.pumpAndSettle();

    // Three swaps filled in, closest calories first, shown by meal name.
    expect(find.widgetWithText(InputChip, 'Grilled Beef (M)'), findsOneWidget);
    expect(find.widgetWithText(InputChip, 'Grilled Fish (M)'), findsOneWidget);
    expect(find.widgetWithText(InputChip, 'Grilled Shrimp (M)'), findsOneWidget);
  });
}

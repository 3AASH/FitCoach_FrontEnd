/// Search boxes on the admin catalogue screens.
///
/// Three of the four had no search at all, and the one that did (the exercise
/// library) only ran on the keyboard's submit key and never showed its clear
/// button, because nothing rebuilt the field as the text changed.
///
/// These screens are also paginated, so each one has to say how many rows match
/// as well as how many it is showing. Without that, a first page of 100 out of
/// 380 nutrition plans — which the ordering makes all one market — reads as a
/// catalogue that only has that market in it.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitapp/data/models/admin_exercise.dart';
import 'package:fitapp/data/models/admin_workout_template.dart';
import 'package:fitapp/data/repositories/admin_repository.dart';
import 'package:fitapp/presentation/providers/admin_provider.dart';
import 'package:fitapp/presentation/providers/language_provider.dart';
import 'package:fitapp/presentation/screens/admin/admin_exercises_screen.dart';
import 'package:fitapp/presentation/screens/admin/admin_nutrition_templates_screen.dart';
import 'package:fitapp/presentation/screens/admin/admin_workout_templates_screen.dart';
import 'package:fitapp/presentation/widgets/catalog_search_field.dart';

class _RecordingAdminRepository extends AdminRepository {
  _RecordingAdminRepository({
    this.exercises = const <AdminExercise>[],
    this.exerciseTotal,
    this.workoutTemplates = const <AdminWorkoutTemplate>[],
    this.plans = const <Map<String, dynamic>>[],
    this.planTotal,
    this.recipes = const <Map<String, dynamic>>[],
    this.ingredients = const <Map<String, dynamic>>[],
  }) : super(tokenReader: _tokenReader);

  static Future<String?> _tokenReader() async => 'test-token';

  final List<AdminExercise> exercises;
  final int? exerciseTotal;
  final List<AdminWorkoutTemplate> workoutTemplates;
  final List<Map<String, dynamic>> plans;
  final int? planTotal;
  final List<Map<String, dynamic>> recipes;
  final List<Map<String, dynamic>> ingredients;

  /// Every search term each catalogue was asked for, in order.
  final List<String?> exerciseSearches = <String?>[];
  final List<String?> templateSearches = <String?>[];
  final List<String?> planSearches = <String?>[];
  final List<String?> recipeSearches = <String?>[];
  final List<String?> ingredientSearches = <String?>[];

  @override
  Future<AdminPage<AdminExercise>> getExercises({
    String? search,
    String? category,
    String? difficulty,
    int limit = 200,
    int offset = 0,
  }) async {
    exerciseSearches.add(search);
    return AdminPage(
        items: exercises, total: exerciseTotal ?? exercises.length);
  }

  @override
  Future<List<AdminWorkoutTemplate>> getWorkoutTemplates({
    String? search,
    String? type,
    String? goal,
    String? location,
  }) async {
    templateSearches.add(search);
    return workoutTemplates;
  }

  @override
  Future<AdminPage<Map<String, dynamic>>> getNutritionEngineRecipes({
    String? search,
    String? validationStatus,
    bool? active,
    int limit = 500,
    int offset = 0,
  }) async {
    recipeSearches.add(search);
    return AdminPage(items: recipes, total: recipes.length);
  }

  @override
  Future<AdminPage<Map<String, dynamic>>> getNutritionEnginePlans({
    String? search,
    String? planType,
    String? market,
    int? calorieBand,
    String? macroProfile,
    String? validationStatus,
    int limit = 500,
    int offset = 0,
  }) async {
    planSearches.add(search);
    return AdminPage(items: plans, total: planTotal ?? plans.length);
  }

  @override
  Future<List<Map<String, dynamic>>> getNutritionIngredients({
    String? search,
  }) async {
    ingredientSearches.add(search);
    return ingredients;
  }

  @override
  Future<List<Map<String, dynamic>>> getNutritionRecipeVariants() async =>
      const [];

  @override
  Future<List<Map<String, dynamic>>> getNutritionEngineImports() async =>
      const [];
}

Future<LanguageProvider> _english() async {
  final lang = LanguageProvider();
  await lang.setLanguage('en');
  return lang;
}

Future<void> _pump(
  WidgetTester tester,
  Widget screen,
  _RecordingAdminRepository repo,
  LanguageProvider lang,
) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<LanguageProvider>.value(value: lang),
        ChangeNotifierProvider<AdminProvider>(create: (_) => AdminProvider(repo)),
      ],
      child: MaterialApp(home: screen),
    ),
  );
  await tester.pumpAndSettle();
}

/// Types into the catalogue search box and waits out its debounce.
Future<void> _search(WidgetTester tester, String query) async {
  await tester.enterText(
    find.descendant(
      of: find.byType(CatalogSearchField),
      matching: find.byType(TextField),
    ),
    query,
  );
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
}

AdminExercise _exercise(String id, String name) =>
    AdminExercise(id: id, exId: id, nameEn: name);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('exercise library', () {
    testWidgets('searches as you type instead of only on submit',
        (tester) async {
      final repo = _RecordingAdminRepository(
        exercises: [_exercise('bench_press', 'Bench Press')],
      );
      await _pump(tester, const AdminExercisesScreen(), repo, await _english());

      await _search(tester, 'chest');

      expect(repo.exerciseSearches.last, 'chest');
    });

    testWidgets('shows a clear button once there is something to clear',
        (tester) async {
      // The button was wired up but never appeared: the field had no onChanged,
      // so nothing rebuilt it after the first character.
      final repo = _RecordingAdminRepository(
        exercises: [_exercise('bench_press', 'Bench Press')],
      );
      await _pump(tester, const AdminExercisesScreen(), repo, await _english());

      expect(find.byIcon(Icons.clear), findsNothing);

      await _search(tester, 'chest');
      expect(find.byIcon(Icons.clear), findsOneWidget);

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.clear), findsNothing);
      expect(repo.exerciseSearches.last, isNull);
    });

    testWidgets('says how many exercises match, not just how many are shown',
        (tester) async {
      final repo = _RecordingAdminRepository(
        exercises: [_exercise('bench_press', 'Bench Press')],
        exerciseTotal: 109,
      );
      await _pump(tester, const AdminExercisesScreen(), repo, await _english());

      expect(find.textContaining('Showing 1 of 109'), findsOneWidget);
    });
  });

  group('workout templates', () {
    testWidgets('offers a search that reaches the server', (tester) async {
      // This screen had no search box at all.
      final repo = _RecordingAdminRepository(
        workoutTemplates: const [
          AdminWorkoutTemplate(
              planId: 'ST_GYM_3D', type: 'starter', nameEn: 'Starter Gym'),
        ],
      );
      await _pump(
          tester, const AdminWorkoutTemplatesScreen(), repo, await _english());

      expect(find.byType(CatalogSearchField), findsOneWidget);

      await _search(tester, 'gym');

      expect(repo.templateSearches.last, 'gym');
    });
  });

  group('nutrition catalogues', () {
    testWidgets('the meals tab searches the engine meals', (tester) async {
      final repo = _RecordingAdminRepository(
        recipes: const [
          {'recipe_id': 'EG_MAIN_012', 'name_en': 'Koshari'}
        ],
      );
      await _pump(tester, const AdminNutritionTemplatesScreen(), repo,
          await _english());

      await _search(tester, 'koshari');

      expect(repo.recipeSearches.last, 'koshari');
    });

    testWidgets('each tab searches its own catalogue', (tester) async {
      final repo = _RecordingAdminRepository(
        recipes: const [
          {'recipe_id': 'EG_MAIN_012', 'name_en': 'Koshari'}
        ],
        ingredients: const [
          {'ingredient_id': 'rice', 'name_en': 'Rice'}
        ],
        plans: const [
          {'plan_id': 'PRO_SA_2000_BALANCED_3M_R1', 'market': 'SA'}
        ],
      );
      await _pump(tester, const AdminNutritionTemplatesScreen(), repo,
          await _english());

      await tester.tap(find.text('Ingredients'));
      await tester.pumpAndSettle();
      await _search(tester, 'rice');
      expect(repo.ingredientSearches.last, 'rice');

      await tester.tap(find.text('Engine plans'));
      await tester.pumpAndSettle();
      await _search(tester, 'SA');
      expect(repo.planSearches.last, 'SA');

      // A term typed on one tab must not leak into another.
      expect(repo.recipeSearches, everyElement(isNull));
    });

    testWidgets('a tab remembers its own query when you come back',
        (tester) async {
      final repo = _RecordingAdminRepository(
        recipes: const [
          {'recipe_id': 'EG_MAIN_012', 'name_en': 'Koshari'}
        ],
        ingredients: const [
          {'ingredient_id': 'rice', 'name_en': 'Rice'}
        ],
      );
      await _pump(tester, const AdminNutritionTemplatesScreen(), repo,
          await _english());

      await _search(tester, 'koshari');

      await tester.tap(find.text('Ingredients'));
      await tester.pumpAndSettle();
      expect(find.text('koshari'), findsNothing);

      await tester.tap(find.text('Engine meals'));
      await tester.pumpAndSettle();
      expect(find.text('koshari'), findsOneWidget);
    });

    testWidgets('the plans tab says a first page is only a first page',
        (tester) async {
      // The whole point: 100 of 380 plans, all of one market, must not read as
      // a catalogue with one market in it.
      final repo = _RecordingAdminRepository(
        plans: List.generate(
          100,
          (i) => <String, dynamic>{'plan_id': 'PRO_EG_$i', 'market': 'EG'},
        ),
        planTotal: 380,
      );
      await _pump(tester, const AdminNutritionTemplatesScreen(), repo,
          await _english());

      await tester.tap(find.text('Engine plans'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Showing 100 of 380'), findsOneWidget);
    });
  });
}

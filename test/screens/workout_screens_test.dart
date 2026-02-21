import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitapp/data/models/workout_plan.dart';
import 'package:fitapp/data/repositories/workout_repository.dart';
import 'package:fitapp/presentation/providers/language_provider.dart';
import 'package:fitapp/presentation/providers/workout_provider.dart';
import 'package:fitapp/presentation/screens/workout/workout_exercise_detail_screen.dart';
import 'package:fitapp/presentation/screens/workout/workout_exercise_session_screen.dart';
import 'package:fitapp/presentation/screens/workout/workout_intro_screen.dart';

class FakeWorkoutRepository extends WorkoutRepository {}

Exercise _buildExercise() {
  return Exercise(
    id: 'ex-test',
    name: 'Push Up',
    nameAr: 'Push Up',
    nameEn: 'Push Up',
    sets: 3,
    reps: '12',
    restTime: '60s',
    thumbnailUrl: 'assets/placeholders/splash_onboarding/workout_onboarding.png',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('WorkoutIntroScreen renders correctly', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => LanguageProvider(),
        child: MaterialApp(
          home: WorkoutIntroScreen(onGetStarted: () {}),
        ),
      ),
    );

    expect(find.byType(WorkoutIntroScreen), findsOneWidget);
  });

  testWidgets('WorkoutExerciseSessionScreen renders correctly', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final exercises = [_buildExercise()];

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(create: (_) => WorkoutProvider(FakeWorkoutRepository())),
        ],
        child: MaterialApp(
          home: WorkoutExerciseSessionScreen(
            exercises: exercises,
            startIndex: 0,
            onShowSubstitute: (_) {},
          ),
        ),
      ),
    );

    expect(find.byType(WorkoutExerciseSessionScreen), findsOneWidget);
  });

  testWidgets('WorkoutExerciseDetailScreen renders correctly', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final exercise = _buildExercise();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(create: (_) => WorkoutProvider(FakeWorkoutRepository())),
        ],
        child: MaterialApp(
          home: WorkoutExerciseDetailScreen(
            exercise: exercise,
            onStartExercise: () {},
          ),
        ),
      ),
    );

    expect(find.byType(WorkoutExerciseDetailScreen), findsOneWidget);
  });
}

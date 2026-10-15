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
import 'package:fitapp/presentation/screens/workout/workout_screen.dart';

class FakeWorkoutRepository extends WorkoutRepository {}

class FakeScreenWorkoutProvider extends WorkoutProvider {
  final WorkoutPlan plan;

  FakeScreenWorkoutProvider(this.plan) : super(FakeWorkoutRepository());

  @override
  WorkoutPlan? get activePlan => plan;

  @override
  WorkoutDay? get currentDay =>
      plan.days == null || plan.days!.isEmpty ? null : plan.days!.first;

  @override
  bool get isLoading => false;

  @override
  Future<void> loadActivePlan() async {}

  @override
  Future<void> loadWorkoutCalendar({bool silent = false}) async {}

  @override
  bool isExerciseCompleted(String exerciseId) => false;
}

Exercise _buildExercise() {
  return Exercise(
    id: 'ex-test',
    name: 'Push Up',
    nameAr: 'Push Up',
    nameEn: 'Push Up',
    sets: 3,
    reps: '12',
    restTime: '60s',
    thumbnailUrl:
        'assets/placeholders/splash_onboarding/workout_onboarding.png',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('details loads the GIF before Start even with an old thumbnail',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    var started = false;
    final exercise = _buildExercise().copyWith(
      videoUrl: 'https://example.com/push_up.gif?version=2',
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(
              create: (_) => WorkoutProvider(FakeWorkoutRepository())),
        ],
        child: MaterialApp(
          home: WorkoutExerciseDetailScreen(
            exercise: exercise,
            onStartExercise: () => started = true,
          ),
        ),
      ),
    );
    final preview = find.byKey(const ValueKey('exercise-detail-demo'));
    expect(preview, findsOneWidget);
    final image = tester.widget<Image>(preview);
    expect((image.image as NetworkImage).url,
        'https://example.com/push_up.gif?version=2');
    expect(image.fit, BoxFit.contain);
    expect(tester.getSize(preview).height, 220);
    expect(started, isFalse);
  });

  testWidgets('WorkoutIntroScreen renders correctly',
      (WidgetTester tester) async {
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

  testWidgets('workout exercises are swipeable image-and-name cards',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'workout_intro_seen': true,
      'fitcoach_language': 'en',
    });
    final exercises = List.generate(
      5,
      (index) => Exercise(
        id: 'carousel-ex-$index',
        name: 'Exercise $index',
        nameAr: 'تمرين $index',
        nameEn: 'Exercise $index',
        sets: 3,
        reps: '12',
        restTime: '60s',
        thumbnailUrl:
            'assets/placeholders/splash_onboarding/workout_onboarding.png',
      ),
    );
    final workoutProvider = FakeScreenWorkoutProvider(
      WorkoutPlan(
        id: 'plan-carousel',
        userId: 'user-carousel',
        createdAt: DateTime(2024),
        days: [
          WorkoutDay(
            id: 'day-carousel',
            dayName: 'Day 1',
            dayNumber: 1,
            exercises: exercises,
          ),
        ],
      ),
    );

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider<WorkoutProvider>.value(
            value: workoutProvider,
          ),
        ],
        child: const MaterialApp(
          home: WorkoutScreen(isActive: false),
        ),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final carousel = find.byKey(const ValueKey('workout-exercise-carousel'));
    expect(carousel, findsOneWidget);
    expect(tester.widget<ListView>(carousel).scrollDirection, Axis.horizontal);

    final firstCard =
        find.byKey(const ValueKey('workout-exercise-card-carousel-ex-0'));
    expect(
      find.descendant(of: firstCard, matching: find.byType(Image)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: firstCard, matching: find.byType(Text)),
      findsOneWidget,
    );
    expect(find.text('3'), findsNothing);
    expect(find.text('12'), findsNothing);

    await tester.dragUntilVisible(
      find.byKey(const ValueKey('workout-exercise-card-carousel-ex-4')),
      carousel,
      const Offset(-240, 0),
    );
  });

  testWidgets('WorkoutExerciseSessionScreen renders correctly',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final exercises = [_buildExercise()];

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(
              create: (_) => WorkoutProvider(FakeWorkoutRepository())),
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

  testWidgets('WorkoutExerciseDetailScreen renders correctly',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final exercise = _buildExercise();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(
              create: (_) => WorkoutProvider(FakeWorkoutRepository())),
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
    // The preview is the only exercise image, never a full-screen background.
    final imageFinder = find.byType(Image);
    expect(imageFinder, findsOneWidget);
    expect(tester.widget<Image>(imageFinder).fit, BoxFit.contain);
    expect(tester.getSize(imageFinder).height, 220);
    expect(find.ancestor(of: imageFinder, matching: find.byType(InkWell)),
        findsOneWidget);
  });
}

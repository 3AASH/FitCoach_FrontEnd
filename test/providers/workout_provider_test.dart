import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fitapp/data/models/workout_calendar.dart';
import 'package:fitapp/presentation/providers/workout_provider.dart';
import 'package:fitapp/data/repositories/workout_repository.dart';
import 'package:fitapp/data/models/workout_plan.dart';

class FakeWorkoutRepository extends WorkoutRepository {
  WorkoutPlan? _plan;

  FakeWorkoutRepository() {
    _plan = buildPlan();
  }

  static WorkoutPlan buildPlan({
    String id = 'plan1',
    String name = 'Test Plan',
  }) {
    final exercise = Exercise(
      id: 'ex1',
      name: 'Push Up',
      nameAr: 'ضغط',
      nameEn: 'Push Up',
      sets: 3,
      reps: '10',
    );

    final day = WorkoutDay(
      id: 'day1',
      dayName: 'Day 1',
      dayNumber: 1,
      exercises: [exercise],
    );

    return WorkoutPlan(
      id: id,
      userId: 'user1',
      name: name,
      description: name,
      days: [day],
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<WorkoutPlan?> getActivePlan() async {
    return _plan;
  }

  @override
  Future<WorkoutCalendarResponse> getWorkoutCalendar() async {
    return WorkoutCalendarResponse(
      plan: WorkoutCalendarPlan(
        id: _plan?.id ?? 'plan1',
        name: _plan?.name ?? 'Test Plan',
        startDate: null,
        endDate: null,
        daysPerWeek: _plan?.days?.length ?? 0,
      ),
      previous: const [],
      today: null,
      upcoming: const [],
      allDays: const [],
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getExerciseLibrary({
    String? muscleGroup,
    String? equipment,
    String? difficulty,
    String? search,
    String? location,
  }) async {
    return [
      {
        'id': 'ex1',
        'name': 'Push Up',
        'nameAr': 'ضغط',
        'nameEn': 'Push Up',
        'sets': 3,
        'reps': '10',
      },
    ];
  }

  @override
  Future<WorkoutExerciseCompletionResult> markExerciseComplete(
      String exerciseId) async {
    return WorkoutExerciseCompletionResult(
      dayCompleted: false,
      nextDayNumber: null,
      planProgressPercent: null,
    );
  }
}

class QueuedWorkoutRepository extends WorkoutRepository {
  final List<Completer<WorkoutPlan?>> planRequests = [];
  final List<Completer<WorkoutCalendarResponse>> calendarRequests = [];

  @override
  Future<WorkoutPlan?> getActivePlan() {
    final completer = Completer<WorkoutPlan?>();
    planRequests.add(completer);
    return completer.future;
  }

  @override
  Future<WorkoutCalendarResponse> getWorkoutCalendar() {
    final completer = Completer<WorkoutCalendarResponse>();
    calendarRequests.add(completer);
    return completer.future;
  }
}

void main() {
  group('WorkoutProvider Tests', () {
    late WorkoutProvider workoutProvider;

    setUp(() {
      final repo = FakeWorkoutRepository();
      workoutProvider = WorkoutProvider(repo);
    });

    test('initial state should have no active plan', () {
      expect(workoutProvider.activePlan, null);
      expect(workoutProvider.isLoading, false);
    });

    test('loadActivePlan should fetch and set workout data', () async {
      await workoutProvider.loadActivePlan();
      expect(workoutProvider.activePlan, isNotNull);
      expect(workoutProvider.isLoading, false);
    });

    test('loadActivePlan keeps the newest overlapping response', () async {
      final repo = QueuedWorkoutRepository();
      final provider = WorkoutProvider(repo);

      final firstLoad = provider.loadActivePlan();
      final secondLoad = provider.loadActivePlan();

      expect(repo.planRequests.length, 2);
      repo.planRequests[1].complete(
        FakeWorkoutRepository.buildPlan(id: 'plan2', name: 'New Plan'),
      );
      await secondLoad;

      expect(provider.activePlan?.id, 'plan2');
      expect(provider.isLoading, false);

      repo.planRequests[0].complete(
        FakeWorkoutRepository.buildPlan(id: 'plan1', name: 'Old Plan'),
      );
      await firstLoad;

      expect(provider.activePlan?.id, 'plan2');
      expect(provider.isLoading, false);
    });

    test('loadWorkoutCalendar keeps the newest overlapping response', () async {
      final repo = QueuedWorkoutRepository();
      final provider = WorkoutProvider(repo);

      final firstLoad = provider.loadWorkoutCalendar();
      final secondLoad = provider.loadWorkoutCalendar();

      expect(repo.calendarRequests.length, 2);
      repo.calendarRequests[1].complete(
        WorkoutCalendarResponse(
          plan: WorkoutCalendarPlan(
            id: 'plan2',
            name: 'New Calendar',
            startDate: null,
            endDate: null,
            daysPerWeek: 1,
          ),
          previous: const [],
          today: null,
          upcoming: const [],
          allDays: const [],
        ),
      );
      await secondLoad;

      expect(provider.calendarPlan?.id, 'plan2');
      expect(provider.hasLoadedCalendar, true);
      expect(provider.isCalendarLoading, false);

      repo.calendarRequests[0].complete(
        WorkoutCalendarResponse(
          plan: WorkoutCalendarPlan(
            id: 'plan1',
            name: 'Old Calendar',
            startDate: null,
            endDate: null,
            daysPerWeek: 1,
          ),
          previous: const [],
          today: null,
          upcoming: const [],
          allDays: const [],
        ),
      );
      await firstLoad;

      expect(provider.calendarPlan?.id, 'plan2');
      expect(provider.isCalendarLoading, false);
    });

    test('completeExercise should mark exercise as completed', () async {
      await workoutProvider.loadActivePlan();
      final plan = workoutProvider.activePlan;
      if (plan != null && plan.days != null && plan.days!.isNotEmpty) {
        final firstDay = plan.days!.first;
        if (firstDay.exercises.isNotEmpty) {
          final exerciseId = firstDay.exercises.first.id;
          final result = await workoutProvider.completeExercise(exerciseId);
          expect(result, true);
          expect(workoutProvider.isExerciseCompleted(exerciseId), true);
        }
      }
    });

    test('setCurrentDay should update current day index', () async {
      workoutProvider.setCurrentDay(1);
      expect(workoutProvider.currentDayIndex, 1);
    });

    test('currentDay should return correct day', () async {
      await workoutProvider.loadActivePlan();
      workoutProvider.setCurrentDay(0);
      final day = workoutProvider.currentDay;
      expect(day, isNotNull);
    });

    test('loadExerciseLibrary should fetch exercises', () async {
      await workoutProvider.loadExerciseLibrary();
      expect(workoutProvider.exerciseLibrary, isA<List>());
    });

    test('clearError should reset error state', () async {
      workoutProvider.clearError();
      expect(workoutProvider.error, null);
    });
  });
}

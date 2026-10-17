// Exercises the server marks as done must still read as done after the app is
// relaunched. The completion map is in memory, so it has to be seeded from the
// plan on load; otherwise the workout starts again from the first exercise.
import 'package:flutter_test/flutter_test.dart';

import 'package:fitapp/data/models/workout_plan.dart';
import 'package:fitapp/data/repositories/workout_repository.dart';
import 'package:fitapp/presentation/providers/workout_provider.dart';

class _PlanRepository extends WorkoutRepository {
  _PlanRepository(this._plan);

  final WorkoutPlan _plan;

  @override
  Future<WorkoutPlan?> getActivePlan() async => _plan;
}

WorkoutPlan _planWithOneFinished() => WorkoutPlan.fromJson({
      'id': 'plan-1',
      'userId': 'user-1',
      'days': [
        {
          'id': 'day-1',
          'dayName': 'Day 1',
          'dayNumber': 1,
          'exercises': [
            {'id': 'ex-push', 'name': 'Push Up', 'isCompleted': true},
            {'id': 'ex-squat', 'name': 'Squat', 'isCompleted': false},
          ],
        },
      ],
    });

void main() {
  test('exercises the server marks done still read as done after a reload',
      () async {
    final provider = WorkoutProvider(_PlanRepository(_planWithOneFinished()));

    await provider.loadActivePlan();

    expect(provider.isExerciseCompleted('ex-push'), isTrue);
    expect(provider.isExerciseCompleted('ex-squat'), isFalse);
  });
}

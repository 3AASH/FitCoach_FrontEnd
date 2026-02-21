import '../../models/workout_plan.dart';
import '../demo_data.dart';

class DemoWorkoutRepository {
  Future<WorkoutPlan?> getActivePlan({required String userId}) async {
    return DemoData.workoutPlan(userId: userId);
  }

  Future<List<Exercise>> getExerciseLibrary() async {
    return DemoData.exerciseLibrary();
  }

  Future<List<Exercise>> getExerciseAlternatives(String exerciseId) async {
    final library = DemoData.exerciseLibrary();
    final source = library.firstWhere(
      (exercise) => exercise.id == exerciseId,
      orElse: () => library.isNotEmpty ? library.first : _fallbackExercise(),
    );
    final alternatives = source.alternatives
        .map((id) => library.firstWhere(
              (exercise) => exercise.id == id,
              orElse: () => _fallbackExercise(),
            ))
        .where((exercise) => exercise.id.isNotEmpty)
        .toList();
    if (alternatives.isNotEmpty) {
      return alternatives;
    }
    return library.where((exercise) => exercise.id != exerciseId).toList();
  }

  Exercise _fallbackExercise() {
    return Exercise(
      id: '',
      name: 'Demo',
      nameAr: 'Demo',
      nameEn: 'Demo',
      sets: 0,
      reps: '',
    );
  }
}

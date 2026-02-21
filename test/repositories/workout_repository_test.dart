import 'package:flutter_test/flutter_test.dart';
import 'package:fitapp/data/repositories/workout_repository.dart';

void main() {
  group('WorkoutRepository Tests', () {
    late WorkoutRepository workoutRepository;

    setUp(() {
      workoutRepository = WorkoutRepository();
    });

    test('should create WorkoutRepository instance', () {
      expect(workoutRepository, isNotNull);
      expect(workoutRepository, isA<WorkoutRepository>());
    });

    test('should have proper initialization', () {
      // Verify repository can be instantiated
      final repo = WorkoutRepository();
      expect(repo, isNotNull);
    });
  });
}
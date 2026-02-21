import 'package:flutter_test/flutter_test.dart';
import 'package:fitapp/data/models/workout_plan.dart';

void main() {
  group('WorkoutPlan Model Tests', () {
    test('should create WorkoutPlan from JSON', () {
      final json = {
        'id': 'plan_123',
        'userId': 'user_456',
        'coachId': 'coach_789',
        'name': 'Muscle Building Plan',
        'nameAr': 'خطة بناء العضلات',
        'description': '12-week muscle building program',
        'descriptionAr': 'برنامج 12 أسبوعاً لبناء العضلات',
        'days': [
          {
            'id': 'day_1',
            'dayName': 'Monday',
            'dayNameAr': 'الاثنين',
            'dayNumber': 1,
            'exercises': [
              {
                'id': 'ex_1',
                'name': 'Bench Press',
                'nameAr': 'ضغط الصدر',
                'nameEn': 'Bench Press',
                'category': 'Chest',
                'muscleGroup': 'Chest',
                'equipment': 'Barbell',
                'difficulty': 'Intermediate',
                'videoUrl': 'https://example.com/video.mp4',
                'thumbnailUrl': 'https://example.com/thumb.jpg',
                'instructions': 'Lie on bench and press',
                'instructionsAr': 'استلقي على المقعد واضغط',
                'instructionsEn': 'Lie on bench and press',
                'sets': 4,
                'reps': '8-10',
                'restTime': '90s',
                'tempo': '2-0-2-0',
                'notes': 'Focus on form',
                'contraindications': ['shoulder_injury'],
                'alternatives': ['dumbbell_press', 'machine_press'],
                'isCompleted': false,
                'order': 1,
              }
            ],
            'notes': 'Push day',
          }
        ],
        'startDate': '2024-01-01T00:00:00.000Z',
        'endDate': '2024-03-31T00:00:00.000Z',
        'isActive': true,
        'createdAt': '2024-01-01T00:00:00.000Z',
        'updatedAt': '2024-01-01T00:00:00.000Z',
      };

      final plan = WorkoutPlan.fromJson(json);

      expect(plan.id, 'plan_123');
      expect(plan.userId, 'user_456');
      expect(plan.coachId, 'coach_789');
      expect(plan.name, 'Muscle Building Plan');
      expect(plan.nameAr, 'خطة بناء العضلات');
      expect(plan.description, '12-week muscle building program');
      expect(plan.descriptionAr, 'برنامج 12 أسبوعاً لبناء العضلات');
      expect(plan.days?.length, 1);
      expect(plan.days?.first.dayNameAr, 'الاثنين');
      expect(plan.isActive, true);
      expect(plan.startDate?.year, 2024);
      expect(plan.endDate?.month, 3);
    });

    test('should convert WorkoutPlan to JSON', () {
      final exercise = Exercise(
        id: 'ex_1',
        name: 'Squat',
        nameAr: 'سكوات',
        nameEn: 'Squat',
        sets: 5,
        reps: '5',
        contraindications: ['knee_injury'],
        alternatives: ['leg_press'],
      );

      final day = WorkoutDay(
        id: 'day_1',
        dayName: 'Monday',
        dayNameAr: 'الأربعاء',
        dayNumber: 1,
        exercises: [exercise],
      );

      final plan = WorkoutPlan(
        id: 'plan_1',
        userId: 'user_1',
        coachId: 'coach_1',
        name: 'Test Plan',
        nameAr: 'خطة اختبار',
        description: 'Short test plan',
        descriptionAr: 'خطة اختبار قصيرة',
        days: [day],
        startDate: DateTime(2024, 1, 1),
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final json = plan.toJson();

      expect(json['id'], 'plan_1');
      expect(json['name'], 'Test Plan');
      expect(json['nameAr'], 'خطة اختبار');
      expect(json['descriptionAr'], 'خطة اختبار قصيرة');
      expect(json['days'], isA<List>());
      expect((json['days'] as List).length, 1);
      expect((json['days'] as List).first['dayNameAr'], 'الأربعاء');
    });

    test('should handle null optional fields', () {
      final json = {
        'id': 'plan_1',
        'userId': 'user_1',
        'coachId': 'coach_1',
        'name': 'Simple Plan',
        'days': [],
        'startDate': '2024-01-01T00:00:00.000Z',
        'createdAt': '2024-01-01T00:00:00.000Z',
        'updatedAt': '2024-01-01T00:00:00.000Z',
      };

      final plan = WorkoutPlan.fromJson(json);

      expect(plan.description, isNull);
      expect(plan.endDate, isNull);
      expect(plan.isActive, true); // default value
    });
  });

  group('WorkoutDay Model Tests', () {
    test('should create WorkoutDay from JSON', () {
      final json = {
        'id': 'day_1',
        'dayName': 'Tuesday',
        'dayNameAr': 'الثلاثاء',
        'dayNumber': 2,
        'exercises': [],
        'notes': 'Pull day',
      };

      final day = WorkoutDay.fromJson(json);

      expect(day.id, 'day_1');
      expect(day.dayName, 'Tuesday');
      expect(day.dayNameAr, 'الثلاثاء');
      expect(day.dayNumber, 2);
      expect(day.exercises, isEmpty);
      expect(day.notes, 'Pull day');
    });

    test('should convert WorkoutDay to JSON', () {
      final day = WorkoutDay(
        id: 'day_1',
        dayName: 'Wednesday',
        dayNameAr: 'الأربعاء',
        dayNumber: 3,
        exercises: [],
        notes: 'Leg day',
      );

      final json = day.toJson();

      expect(json['dayName'], 'Wednesday');
      expect(json['dayNameAr'], 'الأربعاء');
      expect(json['dayNumber'], 3);
      expect(json['notes'], 'Leg day');
    });
  });

  group('Exercise Model Tests', () {
    test('should create Exercise from JSON', () {
      final json = {
        'id': 'ex_1',
        'name': 'Deadlift',
        'nameAr': 'رفعة ميتة',
        'nameEn': 'Deadlift',
        'category': 'Back',
        'muscleGroup': 'Lower Back',
        'equipment': 'Barbell',
        'difficulty': 'Advanced',
        'sets': 3,
        'reps': '5',
        'restTime': '180s',
        'contraindications': ['lower_back_injury'],
        'alternatives': ['rack_pulls', 'trap_bar_deadlift'],
        'isCompleted': false,
        'order': 1,
      };

      final exercise = Exercise.fromJson(json);

      expect(exercise.id, 'ex_1');
      expect(exercise.name, 'Deadlift');
      expect(exercise.nameAr, 'رفعة ميتة');
      expect(exercise.sets, 3);
      expect(exercise.reps, '5');
      expect(exercise.contraindications.length, 1);
      expect(exercise.alternatives.length, 2);
      expect(exercise.isCompleted, false);
    });

    test('should convert Exercise to JSON', () {
      final exercise = Exercise(
        id: 'ex_1',
        name: 'Pull-up',
        nameAr: 'عقلة',
        nameEn: 'Pull-up',
        sets: 3,
        reps: '10',
        contraindications: [],
        alternatives: [],
      );

      final json = exercise.toJson();

      expect(json['name'], 'Pull-up');
      expect(json['sets'], 3);
      expect(json['contraindications'], isEmpty);
    });

    test('copyWith should update specified fields only', () {
      final original = Exercise(
        id: 'ex_1',
        name: 'Squat',
        nameAr: 'سكوات',
        nameEn: 'Squat',
        sets: 5,
        reps: '5',
        isCompleted: false,
        notes: 'Original note',
      );

      final updated = original.copyWith(isCompleted: true);

      expect(updated.isCompleted, true);
      expect(updated.notes, 'Original note'); // unchanged
      expect(updated.sets, 5); // unchanged
    });

    test('copyWith should handle notes update', () {
      final original = Exercise(
        id: 'ex_1',
        name: 'Squat',
        nameAr: 'سكوات',
        nameEn: 'Squat',
        sets: 5,
        reps: '5',
        notes: 'Old note',
      );

      final updated = original.copyWith(notes: 'New note');

      expect(updated.notes, 'New note');
      expect(updated.isCompleted, false); // unchanged
    });

    test('hasInjuryConflict should detect injury conflicts', () {
      final exercise = Exercise(
        id: 'ex_1',
        name: 'Shoulder Press',
        nameAr: 'ضغط كتف',
        nameEn: 'Shoulder Press',
        sets: 4,
        reps: '10',
        contraindications: ['shoulder_injury', 'rotator_cuff'],
      );

      final userInjuries1 = ['shoulder_injury', 'knee_pain'];
      final userInjuries2 = ['knee_pain', 'ankle_sprain'];
      final userInjuries3 = ['rotator cuff tear'];

      expect(exercise.hasInjuryConflict(userInjuries1), true);
      expect(exercise.hasInjuryConflict(userInjuries2), false);
      expect(exercise.hasInjuryConflict(userInjuries3), true); // case-insensitive match
    });

    test('hasInjuryConflict should handle empty lists', () {
      final exercise = Exercise(
        id: 'ex_1',
        name: 'Push-up',
        nameAr: 'ضغط',
        nameEn: 'Push-up',
        sets: 3,
        reps: '15',
        contraindications: [],
      );

      expect(exercise.hasInjuryConflict(['shoulder_injury']), false);
      expect(exercise.hasInjuryConflict([]), false);
    });

    test('should handle all optional fields as null', () {
      final json = {
        'id': 'ex_1',
        'name': 'Test',
        'nameAr': 'تجربة',
        'nameEn': 'Test',
        'sets': 3,
        'reps': '10',
      };

      final exercise = Exercise.fromJson(json);

      expect(exercise.category, isNull);
      expect(exercise.muscleGroup, isNull);
      expect(exercise.equipment, isNull);
      expect(exercise.difficulty, isNull);
      expect(exercise.videoUrl, isNull);
      expect(exercise.thumbnailUrl, isNull);
      expect(exercise.instructions, isNull);
      expect(exercise.restTime, isNull);
      expect(exercise.tempo, isNull);
      expect(exercise.notes, isNull);
      expect(exercise.contraindications, isEmpty);
      expect(exercise.alternatives, isEmpty);
      expect(exercise.isCompleted, false);
      expect(exercise.order, 0);
    });
  });
}

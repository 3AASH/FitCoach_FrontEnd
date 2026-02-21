import '../models/admin_analytics.dart';
import '../models/admin_coach.dart';
import '../models/admin_user.dart';
import '../models/audit_log.dart';
import '../models/appointment.dart';
import '../models/coach_analytics.dart';
import '../models/coach_client.dart';
import '../models/coach_earnings.dart';
import '../models/message.dart';
import '../models/nutrition_plan.dart';
import '../models/revenue_analytics.dart';
import '../models/user_profile.dart';
import '../models/workout_plan.dart';
import '../models/subscription_plan.dart';

class DemoData {
  static UserProfile userProfile({required String role}) {
    switch (role) {
      case 'coach':
        return UserProfile(
          id: 'demo-coach',
          name: 'Coach Sam',
          phoneNumber: '+10000000002',
          email: 'coach@fitcoach.com',
          subscriptionTier: 'Premium',
          hasCompletedFirstIntake: true,
          hasCompletedSecondIntake: true,
          role: 'coach',
        );
      case 'admin':
        return UserProfile(
          id: 'demo-admin',
          name: 'Admin Noor',
          phoneNumber: '+10000000003',
          email: 'admin@fitcoach.com',
          subscriptionTier: 'Smart Premium',
          hasCompletedFirstIntake: true,
          hasCompletedSecondIntake: true,
          role: 'admin',
        );
      default:
        return UserProfile(
          id: 'demo-user',
          name: 'Mina Faris',
          phoneNumber: '+10000000001',
          email: 'user.demo@fitcoach.app',
          age: 28,
          weight: 64.5,
          height: 168,
          gender: 'female',
          workoutFrequency: 4,
          workoutLocation: 'gym',
          experienceLevel: 'intermediate',
          mainGoal: 'strength',
          injuries: const ['knee'],
          subscriptionTier: 'Freemium',
          coachId: 'demo-coach',
          hasCompletedFirstIntake: false,
          hasCompletedSecondIntake: false,
          fitnessScore: 82,
          role: 'user',
        );
    }
  }

  static WorkoutPlan workoutPlan({required String userId}) {
    final exercisesDay1 = [
      Exercise(
        id: 'ex-squat',
        name: 'Barbell Squat',
        nameAr: 'القرفصاء بالبار',
        nameEn: 'Barbell Squat',
        category: 'strength',
        muscleGroup: 'legs',
        equipment: 'barbell',
        difficulty: 'Intermediate',
        videoUrl: 'https://example.com/videos/barbell_squat.mp4',
        thumbnailUrl:
            'assets/placeholders/splash_onboarding/workout_onboarding.png',
        instructions:
            '1. Set your stance shoulder-width.\n2. Brace your core and squat down.\n3. Drive through your heels to stand.',
        instructionsEn:
            '1. Set your stance shoulder-width.\n2. Brace your core and squat down.\n3. Drive through your heels to stand.',
        instructionsAr:
            '\u0661\u002e \u062b\u0628\u062a \u0627\u0644\u0642\u062f\u0645\u064a\u0646 \u0628\u0639\u0631\u0636 \u0627\u0644\u0643\u062a\u0641\u064a\u0646\u002e\n\u0662\u002e \u0634\u062f \u0627\u0644\u062c\u0630\u0639 \u0648\u0627\u0646\u0632\u0644 \u0628\u0627\u0644\u062a\u0639\u0631\u064a\u0629\u002e\n\u0663\u002e \u0627\u062f\u0641\u0639 \u0628\u0627\u0644\u0643\u0639\u0628\u064a\u0646 \u0644\u0644\u0639\u0648\u062f\u0629.',
        notes: 'Keep your chest lifted and knees tracking over toes.',
        alternatives: const ['ex-goblet-squat', 'ex-leg-press'],
        sets: 4,
        reps: '8',
        restTime: '90s',
        tempo: '3-1-1',
        isCompleted: true,
      ),
      Exercise(
        id: 'ex-bench',
        name: 'Bench Press',
        nameAr: 'الضغط على المقعد',
        nameEn: 'Bench Press',
        category: 'strength',
        muscleGroup: 'chest',
        equipment: 'barbell',
        difficulty: 'Intermediate',
        videoUrl: 'https://example.com/videos/bench_press.mp4',
        thumbnailUrl:
            'assets/placeholders/splash_onboarding/workout_onboarding.png',
        instructions:
            '1. Set your grip just outside shoulder-width.\n2. Lower the bar to mid-chest.\n3. Press back up with control.',
        instructionsEn:
            '1. Set your grip just outside shoulder-width.\n2. Lower the bar to mid-chest.\n3. Press back up with control.',
        instructionsAr:
            '\u0661\u002e \u0627\u0645\u0633\u0643 \u0627\u0644\u0628\u0627\u0631 \u0628\u0639\u0631\u0636 \u0623\u0643\u062a\u0627\u0641 \u0642\u0644\u064a\u0644\u0627\u064b\u002e\n\u0662\u002e \u0627\u0646\u0632\u0644 \u0628\u0627\u0644\u0628\u0627\u0631 \u0644\u0645\u0646\u062a\u0635\u0641 \u0627\u0644\u0635\u062f\u0631\u002e\n\u0663\u002e \u0627\u062f\u0641\u0639 \u0644\u0644\u0623\u0639\u0644\u0649 \u0628\u062b\u0628\u0627\u062a\u002e',
        notes: 'Keep your shoulders packed and wrists stacked.',
        alternatives: const ['ex-pushup', 'ex-dumbbell-press'],
        sets: 4,
        reps: '10',
        restTime: '90s',
        tempo: '2-1-1',
        isCompleted: true,
      ),
    ];

    final exercisesDay2 = [
      Exercise(
        id: 'ex-rows',
        name: 'Seated Row',
        nameAr: 'السحب الجالس',
        nameEn: 'Seated Row',
        category: 'strength',
        muscleGroup: 'back',
        equipment: 'machine',
        difficulty: 'Beginner',
        videoUrl: 'https://example.com/videos/seated_row.mp4',
        thumbnailUrl:
            'assets/placeholders/splash_onboarding/workout_onboarding.png',
        instructions:
            '1. Sit tall and grab the handles.\n2. Pull toward your ribcage.\n3. Control the return.',
        instructionsEn:
            '1. Sit tall and grab the handles.\n2. Pull toward your ribcage.\n3. Control the return.',
        instructionsAr:
            '\u0661\u002e \u0627\u062c\u0644\u0633 \u0645\u0633\u062a\u0642\u064a\u0645\u0627\u064b \u0648\u0627\u0645\u0633\u0643 \u0627\u0644\u0645\u0642\u0627\u0628\u0636\u002e\n\u0662\u002e \u0627\u0633\u062d\u0628 \u0646\u062d\u0648 \u0627\u0644\u0623\u0636\u0644\u0627\u0639\u002e\n\u0663\u002e \u0627\u0639\u062f \u0628\u062a\u062d\u0643\u0645\u002e',
        notes: 'Keep your chest open and squeeze the back.',
        alternatives: const ['ex-band-row', 'ex-lat-pulldown'],
        sets: 3,
        reps: '12',
        restTime: '60s',
        tempo: '2-0-2',
        isCompleted: true,
      ),
      Exercise(
        id: 'ex-press',
        name: 'Overhead Press',
        nameAr: 'الضغط فوق الرأس',
        nameEn: 'Overhead Press',
        category: 'strength',
        muscleGroup: 'shoulders',
        equipment: 'dumbbell',
        difficulty: 'Intermediate',
        videoUrl: 'https://example.com/videos/overhead_press.mp4',
        thumbnailUrl:
            'assets/placeholders/splash_onboarding/workout_onboarding.png',
        instructions:
            '1. Brace your core and press overhead.\n2. Keep ribs down and elbows under wrists.\n3. Lower with control.',
        instructionsEn:
            '1. Brace your core and press overhead.\n2. Keep ribs down and elbows under wrists.\n3. Lower with control.',
        instructionsAr:
            '\u0661\u002e \u0627\u0634\u062f \u0627\u0644\u062c\u0630\u0639 \u0648\u0627\u062f\u0641\u0639 \u0644\u0644\u0623\u0639\u0644\u0649\u002e\n\u0662\u002e \u062d\u0627\u0641\u0638 \u0639\u0644\u0649 \u0627\u0644\u0623\u0636\u0644\u0627\u0639 \u0645\u0646\u062e\u0641\u0636\u0629\u002e\n\u0663\u002e \u0627\u0639\u062f \u0628\u062a\u062d\u0643\u0645\u002e',
        notes: 'Lock out softly and avoid leaning back.',
        alternatives: const ['ex-landmine-press', 'ex-seated-db-press'],
        sets: 3,
        reps: '10',
        restTime: '75s',
        tempo: '2-1-1',
      ),
    ];

    return WorkoutPlan(
      id: 'demo-plan-1',
      userId: userId,
      name: 'Demo Strength Split',
      nameAr: 'خطة القوة التجريبية',
      description: '4-day strength split',
      descriptionAr: 'تقسيمة قوة لمدة 4 أيام',
      days: [
        WorkoutDay(
          id: 'day-1',
          dayName: 'Day 1 - Lower',
          dayNameAr: 'اليوم 1 - الجزء السفلي',
          dayNumber: 1,
          exercises: exercisesDay1,
        ),
        WorkoutDay(
          id: 'day-2',
          dayName: 'Day 2 - Upper',
          dayNameAr: 'اليوم 2 - الجزء العلوي',
          dayNumber: 2,
          exercises: exercisesDay2,
        ),
      ],
      startDate: DateTime.now().subtract(const Duration(days: 7)),
      createdAt: DateTime.now().subtract(const Duration(days: 14)),
    );
  }

  /// Minimal, lightweight demo plan (kept for demo-only builds).
  static WorkoutPlan fallbackWorkoutPlan({required String userId}) {
    final exercise = Exercise(
      id: 'ex1',
      name: 'Push Up',
      nameAr: 'تمرين الضغط',
      nameEn: 'Push Up',
      sets: 3,
      reps: '12',
    );

    final day = WorkoutDay(
      id: 'day1',
      dayName: 'Day 1',
      dayNameAr: 'اليوم 1',
      dayNumber: 1,
      exercises: [exercise],
    );

    return WorkoutPlan(
      id: 'fallback-plan',
      userId: userId,
      name: 'Fallback Plan',
      nameAr: 'خطة افتراضية',
      description: 'Single day fallback plan',
      descriptionAr: 'خطة تمرين افتراضية ليوم واحد',
      days: [day],
      startDate: DateTime.now(),
      createdAt: DateTime.now(),
    );
  }

  static List<Exercise> exerciseLibrary() {
    return [
      Exercise(
        id: 'ex-pushup',
        name: 'Push Up',
        nameAr: 'تمرين الضغط',
        nameEn: 'Push Up',
        category: 'strength',
        muscleGroup: 'chest',
        equipment: 'bodyweight',
        difficulty: 'Beginner',
        videoUrl: 'https://example.com/videos/push_up.mp4',
        thumbnailUrl:
            'assets/placeholders/splash_onboarding/workout_onboarding.png',
        instructions:
            '1. Set hands under shoulders.\n2. Lower with control.\n3. Press back up.',
        instructionsEn:
            '1. Set hands under shoulders.\n2. Lower with control.\n3. Press back up.',
        instructionsAr:
            '\u0661\u002e \u062b\u0628\u062a \u0627\u0644\u064a\u062f\u064a\u0646 \u062a\u062d\u062a \u0627\u0644\u0643\u062a\u0641\u064a\u0646\u002e\n\u0662\u002e \u0627\u0646\u0632\u0644 \u0628\u062b\u0628\u0627\u062a\u002e\n\u0663\u002e \u0627\u062f\u0641\u0639 \u0644\u0644\u0623\u0639\u0644\u0649\u002e',
        notes: 'Keep your body in a straight line.',
        sets: 3,
        reps: '12',
      ),
      Exercise(
        id: 'ex-lunge',
        name: 'Walking Lunge',
        nameAr: 'اندفاع المشي',
        nameEn: 'Walking Lunge',
        category: 'strength',
        muscleGroup: 'legs',
        equipment: 'bodyweight',
        difficulty: 'Beginner',
        videoUrl: 'https://example.com/videos/walking_lunge.mp4',
        thumbnailUrl:
            'assets/placeholders/splash_onboarding/workout_onboarding.png',
        instructions:
            '1. Step forward into a lunge.\n2. Keep front knee stacked.\n3. Drive through the front heel.',
        instructionsEn:
            '1. Step forward into a lunge.\n2. Keep front knee stacked.\n3. Drive through the front heel.',
        instructionsAr:
            '\u0661\u002e \u0627\u062e\u0637\u064f \u0642\u062f\u0645\u064b\u0627 \u0644\u0644\u0623\u0645\u0627\u0645 \u0641\u064a \u0648\u0636\u0639 \u0627\u0646\u062f\u0641\u0627\u0639\u002e\n\u0662\u002e \u062d\u0627\u0641\u0638 \u0639\u0644\u0649 \u0627\u0644\u0631\u0643\u0628\u0629 \u0641\u0648\u0642 \u0627\u0644\u0643\u0627\u062d\u0644\u002e\n\u0663\u002e \u0627\u062f\u0641\u0639 \u0628\u0627\u0644\u0643\u0639\u0628 \u0627\u0644\u0623\u0645\u0627\u0645\u064a\u002e',
        notes: 'Keep your torso tall and steady.',
        sets: 3,
        reps: '12',
        alternatives: const ['ex-goblet-squat'],
      ),
      Exercise(
        id: 'ex-goblet-squat',
        name: 'Goblet Squat',
        nameAr: 'القرفصاء بالدَلْو',
        nameEn: 'Goblet Squat',
        category: 'strength',
        muscleGroup: 'legs',
        equipment: 'dumbbell',
        difficulty: 'Beginner',
        videoUrl: 'https://example.com/videos/goblet_squat.mp4',
        thumbnailUrl:
            'assets/placeholders/splash_onboarding/workout_onboarding.png',
        instructions:
            '1. Hold a dumbbell at chest height.\n2. Sit into a squat.\n3. Drive back up with control.',
        instructionsEn:
            '1. Hold a dumbbell at chest height.\n2. Sit into a squat.\n3. Drive back up with control.',
        instructionsAr:
            '\u0661\u002e \u0623\u0645\u0633\u0643 \u0627\u0644\u062f\u0645\u0628\u0644 \u0623\u0645\u0627\u0645 \u0627\u0644\u0635\u062f\u0631\u002e\n\u0662\u002e \u0627\u0646\u0632\u0644 \u0628\u0627\u0644\u0642\u0631\u0641\u0635\u0627\u0621\u002e\n\u0663\u002e \u0627\u0635\u0639\u062f \u0628\u062a\u062d\u0643\u0645\u002e',
        notes: 'Elbows stay inside the knees at the bottom.',
        sets: 3,
        reps: '10',
      ),
      Exercise(
        id: 'ex-leg-press',
        name: 'Leg Press',
        nameAr: 'ضغط الأرجل',
        nameEn: 'Leg Press',
        category: 'strength',
        muscleGroup: 'legs',
        equipment: 'machine',
        difficulty: 'Intermediate',
        videoUrl: 'https://example.com/videos/leg_press.mp4',
        thumbnailUrl:
            'assets/placeholders/splash_onboarding/workout_onboarding.png',
        instructions:
            '1. Place feet shoulder-width on the platform.\n2. Lower until knees are at 90 degrees.\n3. Press back up without locking.',
        instructionsEn:
            '1. Place feet shoulder-width on the platform.\n2. Lower until knees are at 90 degrees.\n3. Press back up without locking.',
        instructionsAr:
            '\u0661\u002e \u0636\u0639 \u0627\u0644\u0642\u062f\u0645\u064a\u0646 \u0639\u0644\u0649 \u0627\u0644\u0645\u0646\u0635\u0629\u002e\n\u0662\u002e \u0627\u0646\u0632\u0644 \u062d\u062a\u0649 \u0632\u0627\u0648\u064a\u0629 \u0669\u0660 \u062f\u0631\u062c\u0629\u002e\n\u0663\u002e \u0627\u062f\u0641\u0639 \u0644\u0644\u0623\u0639\u0644\u0649 \u0628\u062f\u0648\u0646 \u0625\u0642\u0641\u0627\u0644\u002e',
        notes: 'Keep hips down and avoid bouncing.',
        sets: 3,
        reps: '12',
      ),
      Exercise(
        id: 'ex-dumbbell-press',
        name: 'Dumbbell Press',
        nameAr: 'ضغط الدمبل',
        nameEn: 'Dumbbell Press',
        category: 'strength',
        muscleGroup: 'chest',
        equipment: 'dumbbell',
        difficulty: 'Beginner',
        videoUrl: 'https://example.com/videos/dumbbell_press.mp4',
        thumbnailUrl:
            'assets/placeholders/splash_onboarding/workout_onboarding.png',
        instructions:
            '1. Press dumbbells above chest.\n2. Lower with elbows at 45 degrees.\n3. Drive up evenly.',
        instructionsEn:
            '1. Press dumbbells above chest.\n2. Lower with elbows at 45 degrees.\n3. Drive up evenly.',
        instructionsAr:
            '\u0661\u002e \u0627\u062f\u0641\u0639 \u0627\u0644\u062f\u0645\u0627\u0628\u0644 \u0641\u0648\u0642 \u0627\u0644\u0635\u062f\u0631\u002e\n\u0662\u002e \u0627\u0646\u0632\u0644 \u0628\u0627\u0644\u0645\u0631\u0627\u0641\u0642\u064a\u0646 \u0628\u0632\u0627\u0648\u064a\u0629 \u0664\u0665\u002e\n\u0663\u002e \u0627\u062f\u0641\u0639 \u0628\u062a\u0648\u0627\u0632\u0646\u002e',
        notes: 'Keep wrists stacked and control the descent.',
        sets: 3,
        reps: '10',
      ),
      Exercise(
        id: 'ex-band-row',
        name: 'Band Row',
        nameAr: 'سحب الحزام',
        nameEn: 'Band Row',
        category: 'strength',
        muscleGroup: 'back',
        equipment: 'band',
        difficulty: 'Beginner',
        videoUrl: 'https://example.com/videos/band_row.mp4',
        thumbnailUrl:
            'assets/placeholders/splash_onboarding/workout_onboarding.png',
        instructions:
            '1. Anchor the band and sit tall.\n2. Pull to the ribcage.\n3. Return slowly.',
        instructionsEn:
            '1. Anchor the band and sit tall.\n2. Pull to the ribcage.\n3. Return slowly.',
        instructionsAr:
            '\u0661\u002e \u062b\u0628\u062a \u0627\u0644\u0628\u0627\u0646\u062f \u0648\u0627\u062c\u0644\u0633 \u0628\u0627\u0633\u062a\u0642\u0627\u0645\u0629\u002e\n\u0662\u002e \u0627\u0633\u062d\u0628 \u0644\u0644\u0623\u0636\u0644\u0627\u0639\u002e\n\u0663\u002e \u0639\u062f \u0628\u0628\u0637\u0621\u002e',
        notes: 'Squeeze the shoulder blades together.',
        sets: 3,
        reps: '15',
      ),
      Exercise(
        id: 'ex-lat-pulldown',
        name: 'Lat Pulldown',
        nameAr: 'السحب الواسع',
        nameEn: 'Lat Pulldown',
        category: 'strength',
        muscleGroup: 'back',
        equipment: 'machine',
        difficulty: 'Beginner',
        videoUrl: 'https://example.com/videos/lat_pulldown.mp4',
        thumbnailUrl:
            'assets/placeholders/splash_onboarding/workout_onboarding.png',
        instructions:
            '1. Grip the bar wide.\n2. Pull toward the upper chest.\n3. Control the return.',
        instructionsEn:
            '1. Grip the bar wide.\n2. Pull toward the upper chest.\n3. Control the return.',
        instructionsAr:
            '\u0661\u002e \u0627\u0645\u0633\u0643 \u0627\u0644\u0628\u0627\u0631 \u0628\u0648\u0633\u0639 \u0639\u0631\u0636 \u0627\u0644\u0643\u062a\u0641\u064a\u0646\u002e\n\u0662\u002e \u0627\u0633\u062d\u0628 \u0646\u062d\u0648 \u0623\u0639\u0644\u0649 \u0627\u0644\u0635\u062f\u0631\u002e\n\u0663\u002e \u0639\u062f \u0628\u062a\u062d\u0643\u0645\u002e',
        notes: 'Keep shoulders down and avoid swinging.',
        sets: 3,
        reps: '12',
      ),
      Exercise(
        id: 'ex-landmine-press',
        name: 'Landmine Press',
        nameAr: 'ضغط اللاندماين',
        nameEn: 'Landmine Press',
        category: 'strength',
        muscleGroup: 'shoulders',
        equipment: 'barbell',
        difficulty: 'Intermediate',
        videoUrl: 'https://example.com/videos/landmine_press.mp4',
        thumbnailUrl:
            'assets/placeholders/splash_onboarding/workout_onboarding.png',
        instructions:
            '1. Hold the bar at shoulder.\n2. Press forward and up.\n3. Lower with control.',
        instructionsEn:
            '1. Hold the bar at shoulder.\n2. Press forward and up.\n3. Lower with control.',
        instructionsAr:
            '\u0661\u002e \u0623\u0645\u0633\u0643 \u0627\u0644\u0628\u0627\u0631 \u0628\u0642\u0631\u0628 \u0627\u0644\u0643\u062a\u0641\u002e\n\u0662\u002e \u0627\u062f\u0641\u0639 \u0644\u0644\u0623\u0645\u0627\u0645 \u0648\u0627\u0644\u0623\u0639\u0644\u0649\u002e\n\u0663\u002e \u0639\u062f \u0628\u062a\u062d\u0643\u0645\u002e',
        notes: 'Keep ribs down and core tight.',
        sets: 3,
        reps: '10',
      ),
      Exercise(
        id: 'ex-seated-db-press',
        name: 'Seated DB Press',
        nameAr: 'ضغط الدمبل الجالس',
        nameEn: 'Seated DB Press',
        category: 'strength',
        muscleGroup: 'shoulders',
        equipment: 'dumbbell',
        difficulty: 'Beginner',
        videoUrl: 'https://example.com/videos/seated_db_press.mp4',
        thumbnailUrl:
            'assets/placeholders/splash_onboarding/workout_onboarding.png',
        instructions:
            '1. Sit tall with dumbbells at shoulders.\n2. Press overhead.\n3. Lower with control.',
        instructionsEn:
            '1. Sit tall with dumbbells at shoulders.\n2. Press overhead.\n3. Lower with control.',
        instructionsAr:
            '\u0661\u002e \u0627\u062c\u0644\u0633 \u0628\u0627\u0633\u062a\u0642\u0627\u0645\u0629 \u0648\u0627\u0644\u062f\u0645\u0628\u0644 \u0639\u0646\u062f \u0627\u0644\u0643\u062a\u0641\u064a\u0646\u002e\n\u0662\u002e \u0627\u062f\u0641\u0639 \u0644\u0644\u0623\u0639\u0644\u0649\u002e\n\u0663\u002e \u0639\u062f \u0628\u062a\u062d\u0643\u0645\u002e',
        notes: 'Keep the neck relaxed and elbows under wrists.',
        sets: 3,
        reps: '12',
      ),
      Exercise(
        id: 'ex-bulgarian-split',
        name: 'Bulgarian Split Squat',
        nameAr: 'اندفاع بلغاري',
        nameEn: 'Bulgarian Split Squat',
        category: 'strength',
        muscleGroup: 'legs',
        equipment: 'dumbbell',
        difficulty: 'Intermediate',
        videoUrl: 'https://example.com/videos/bulgarian_split_squat.mp4',
        thumbnailUrl:
            'assets/placeholders/splash_onboarding/workout_onboarding.png',
        instructions:
            '1. Elevate back foot.\n2. Drop rear knee toward floor.\n3. Drive through the front heel.',
        instructionsEn:
            '1. Elevate back foot.\n2. Drop rear knee toward floor.\n3. Drive through the front heel.',
        instructionsAr:
            '١. ارفع القدم الخلفية على كرسي.\n٢. انزل بالركبة نحو الأرض دون اندفاع للأمام.\n٣. ادفع بالكعب الأمامي للعودة.',
        notes: 'Keep hips squared forward and core tight.',
        alternatives: const ['ex-goblet-squat', 'ex-leg-press'],
        sets: 3,
        reps: '10',
      ),
      Exercise(
        id: 'ex-rdl',
        name: 'Romanian Deadlift',
        nameAr: 'الرفعة الرومانية',
        nameEn: 'Romanian Deadlift',
        category: 'strength',
        muscleGroup: 'posterior chain',
        equipment: 'barbell',
        difficulty: 'Intermediate',
        videoUrl: 'https://example.com/videos/romanian_deadlift.mp4',
        thumbnailUrl:
            'assets/placeholders/splash_onboarding/workout_onboarding.png',
        instructions:
            '1. Hinge at the hips with soft knees.\n2. Lower the bar to mid-shin.\n3. Drive hips forward to stand tall.',
        instructionsEn:
            '1. Hinge at the hips with soft knees.\n2. Lower the bar to mid-shin.\n3. Drive hips forward to stand tall.',
        instructionsAr:
            '١. اثنِ الركبتين قليلاً وابدأ بالحركة من الورك.\n٢. اخفض البار حتى منتصف الساق.\n٣. ادفع الحوض للأمام للعودة.',
        notes: 'Maintain a neutral spine and feel the stretch in hamstrings.',
        alternatives: const ['ex-leg-press', 'ex-hip-thrust'],
        sets: 4,
        reps: '8',
      ),
      Exercise(
        id: 'ex-hip-thrust',
        name: 'Barbell Hip Thrust',
        nameAr: 'رفع الحوض بالبار',
        nameEn: 'Barbell Hip Thrust',
        category: 'strength',
        muscleGroup: 'glutes',
        equipment: 'barbell',
        difficulty: 'Intermediate',
        videoUrl: 'https://example.com/videos/barbell_hip_thrust.mp4',
        thumbnailUrl:
            'assets/placeholders/splash_onboarding/workout_onboarding.png',
        instructions:
            '1. Rest shoulders on a bench.\n2. Drive hips up until glutes squeeze.\n3. Lower with control.',
        instructionsEn:
            '1. Rest shoulders on a bench.\n2. Drive hips up until glutes squeeze.\n3. Lower with control.',
        instructionsAr:
            '١. اسند الكتفين على مقعد ثابت.\n٢. ارفع الحوض حتى تشعر بانقباض المؤخرة.\n٣. انزل ببطء مع الحفاظ على السيطرة.',
        notes: 'Chin stays tucked and ribs down.',
        alternatives: const ['ex-rdl', 'ex-leg-press'],
        sets: 4,
        reps: '12',
      ),
      Exercise(
        id: 'ex-incline-pushup',
        name: 'Incline Push Up',
        nameAr: 'ضغط مائل',
        nameEn: 'Incline Push Up',
        category: 'strength',
        muscleGroup: 'chest',
        equipment: 'bodyweight',
        difficulty: 'Beginner',
        videoUrl: 'https://example.com/videos/incline_pushup.mp4',
        thumbnailUrl:
            'assets/placeholders/splash_onboarding/workout_onboarding.png',
        instructions:
            '1. Place hands on an elevated surface.\n2. Lower chest toward the edge.\n3. Press back up keeping body rigid.',
        instructionsEn:
            '1. Place hands on an elevated surface.\n2. Lower chest toward the edge.\n3. Press back up keeping body rigid.',
        instructionsAr:
            '١. ضع اليدين على سطح مرتفع.\n٢. انزل بالصدر نحو الحافة.\n٣. ادفع للأعلى مع الحفاظ على الجسم مستقيمًا.',
        notes: 'Great option when wrists or shoulders need a lighter load.',
        alternatives: const ['ex-pushup', 'ex-dumbbell-press'],
        sets: 3,
        reps: '12',
      ),
      Exercise(
        id: 'ex-cable-fly',
        name: 'Cable Chest Fly',
        nameAr: 'تفتيح الصدر بالكابل',
        nameEn: 'Cable Chest Fly',
        category: 'strength',
        muscleGroup: 'chest',
        equipment: 'cable',
        difficulty: 'Intermediate',
        videoUrl: 'https://example.com/videos/cable_chest_fly.mp4',
        thumbnailUrl:
            'assets/placeholders/splash_onboarding/workout_onboarding.png',
        instructions:
            '1. Step forward with slight stagger.\n2. Hug the cable handles together.\n3. Control the stretch.',
        instructionsEn:
            '1. Step forward with slight stagger.\n2. Hug the cable handles together.\n3. Control the stretch.',
        instructionsAr:
            '١. تقدم خطوة صغيرة للأمام.\n٢. قرّب المقابض كما لو أنك تعانق.\n٣. عد ببطء إلى وضع البداية.',
        notes: 'Soft elbows and squeeze at the midline.',
        alternatives: const ['ex-bench', 'ex-dumbbell-press'],
        sets: 3,
        reps: '15',
      ),
      Exercise(
        id: 'ex-face-pull',
        name: 'Face Pull',
        nameAr: 'سحب الوجه',
        nameEn: 'Face Pull',
        category: 'strength',
        muscleGroup: 'upper back',
        equipment: 'cable',
        difficulty: 'Beginner',
        videoUrl: 'https://example.com/videos/face_pull.mp4',
        thumbnailUrl:
            'assets/placeholders/splash_onboarding/workout_onboarding.png',
        instructions:
            '1. Set cable at eye level.\n2. Pull toward the face with elbows high.\n3. Control the return.',
        instructionsEn:
            '1. Set cable at eye level.\n2. Pull toward the face with elbows high.\n3. Control the return.',
        instructionsAr:
            '١. ضع مستوى الكابل بمحاذاة العين.\n٢. اسحب نحو الوجه مع رفع المرفقين.\n٣. عد ببطء إلى الأمام.',
        notes: 'Great for posture and shoulder health.',
        alternatives: const ['ex-band-row', 'ex-lat-pulldown'],
        sets: 3,
        reps: '15',
      ),
      Exercise(
        id: 'ex-pike-press',
        name: 'Pike Push Up',
        nameAr: 'ضغط بايك',
        nameEn: 'Pike Push Up',
        category: 'strength',
        muscleGroup: 'shoulders',
        equipment: 'bodyweight',
        difficulty: 'Intermediate',
        videoUrl: 'https://example.com/videos/pike_pushup.mp4',
        thumbnailUrl:
            'assets/placeholders/splash_onboarding/workout_onboarding.png',
        instructions:
            '1. Form an inverted V shape.\n2. Lower head toward the floor.\n3. Press back through shoulders.',
        instructionsEn:
            '1. Form an inverted V shape.\n2. Lower head toward the floor.\n3. Press back through shoulders.',
        instructionsAr:
            '١. شكّل حرف V مقلوب مع رفع الحوض.\n٢. انزل بالرأس نحو الأرض.\n٣. ادفع بكتفيك للعودة إلى البداية.',
        notes: 'Mimics overhead press when equipment is limited.',
        alternatives: const ['ex-landmine-press', 'ex-seated-db-press'],
        sets: 3,
        reps: '8',
      ),
    ];
  }

  /// Minimal demo exercise library (kept for demo-only builds).
  static List<Exercise> fallbackExerciseLibrary() {
    return [
      Exercise(
        id: 'ex1',
        name: 'Push Up',
        nameAr: 'تمرين الضغط',
        nameEn: 'Push Up',
        sets: 3,
        reps: '12',
      ),
    ];
  }

  static NutritionPlan nutritionPlan({required String userId}) {
    List<Meal> buildMealsForDay(int dayNumber) {
      // Rotate proteins/carbs slightly across the week while keeping a consistent structure.
      final lunchProtein = <Map<String, String>>[
        {'en': 'Chicken Breast', 'ar': 'صدر الدجاج'},
        {'en': 'Turkey', 'ar': 'الديك الرومي'},
        {'en': 'Lean Beef', 'ar': 'لحم بقري قليل الدهن'},
        {'en': 'Tuna', 'ar': 'تونة'},
        {'en': 'Chicken Breast', 'ar': 'صدر الدجاج'},
        {'en': 'Salmon', 'ar': 'السلمون'},
        {'en': 'Shrimp', 'ar': 'روبيان'},
      ];

      final carb = <Map<String, String>>[
        {'en': 'Rice', 'ar': 'الأرز'},
        {'en': 'Quinoa', 'ar': 'كينوا'},
        {'en': 'Potato', 'ar': 'بطاطس'},
        {'en': 'Pasta', 'ar': 'مكرونة'},
        {'en': 'Rice', 'ar': 'الأرز'},
        {'en': 'Sweet Potato', 'ar': 'البطاطا الحلوة'},
        {'en': 'Couscous', 'ar': 'كسكس'},
      ];

      final proteinIndex = (dayNumber - 1) % lunchProtein.length;
      final carbIndex = (dayNumber - 1) % carb.length;

      final lunchProteinEn = lunchProtein[proteinIndex]['en']!;
      final lunchProteinAr = lunchProtein[proteinIndex]['ar']!;
      final carbEn = carb[carbIndex]['en']!;
      final carbAr = carb[carbIndex]['ar']!;

      return [
        Meal(
          id: 'meal-$dayNumber-1',
          name: 'Breakfast',
          nameAr: 'الإفطار',
          nameEn: 'Breakfast',
          type: 'breakfast',
          time: '08:00',
          foods: [
            FoodItem(
              id: 'food-$dayNumber-oats',
              name: 'Oats',
              nameAr: 'الشوفان',
              nameEn: 'Oats',
              quantity: 80,
              unit: 'g',
              macros: MacroTargets(protein: 10, carbs: 54, fats: 6),
              calories: 320,
            ),
            FoodItem(
              id: 'food-$dayNumber-eggs',
              name: 'Eggs',
              nameAr: 'البيض',
              nameEn: 'Eggs',
              quantity: 2,
              unit: 'pcs',
              macros: MacroTargets(protein: 12, carbs: 1, fats: 10),
              calories: 140,
            ),
          ],
          macros: MacroTargets(protein: 22, carbs: 55, fats: 16),
          calories: 460,
          completed: dayNumber <= 2,
        ),
        Meal(
          id: 'meal-$dayNumber-2',
          name: 'Lunch',
          nameAr: 'الغداء',
          nameEn: 'Lunch',
          type: 'lunch',
          time: '13:00',
          foods: [
            FoodItem(
              id: 'food-$dayNumber-protein',
              name: lunchProteinEn,
              nameAr: lunchProteinAr,
              nameEn: lunchProteinEn,
              quantity: 180,
              unit: 'g',
              macros: MacroTargets(protein: 40, carbs: 0, fats: 6),
              calories: 220,
            ),
            FoodItem(
              id: 'food-$dayNumber-carb',
              name: carbEn,
              nameAr: carbAr,
              nameEn: carbEn,
              quantity: 150,
              unit: 'g',
              macros: MacroTargets(protein: 4, carbs: 45, fats: 1),
              calories: 210,
            ),
          ],
          macros: MacroTargets(protein: 44, carbs: 45, fats: 7),
          calories: 430,
          completed: dayNumber == 1,
        ),
        Meal(
          id: 'meal-$dayNumber-3',
          name: 'Dinner',
          nameAr: 'العشاء',
          nameEn: 'Dinner',
          type: 'dinner',
          time: '19:30',
          foods: [
            FoodItem(
              id: 'food-$dayNumber-salmon',
              name: 'Salmon',
              nameAr: 'السلمون',
              nameEn: 'Salmon',
              quantity: 160,
              unit: 'g',
              macros: MacroTargets(protein: 34, carbs: 0, fats: 12),
              calories: 260,
            ),
            FoodItem(
              id: 'food-$dayNumber-sweet-potato',
              name: 'Sweet Potato',
              nameAr: 'البطاطا الحلوة',
              nameEn: 'Sweet Potato',
              quantity: 200,
              unit: 'g',
              macros: MacroTargets(protein: 4, carbs: 41, fats: 0),
              calories: 180,
            ),
          ],
          macros: MacroTargets(protein: 38, carbs: 41, fats: 12),
          calories: 440,
          completed: dayNumber == 1,
        ),
      ];
    }

    final days = List<DayMealPlan>.generate(
      7,
      (index) {
        final dayNumber = index + 1;
        return DayMealPlan(
          id: 'day-$dayNumber',
          dayName: 'Day $dayNumber',
          dayNumber: dayNumber,
          meals: buildMealsForDay(dayNumber),
        );
      },
    );

    final startDate =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final endDate = startDate.add(const Duration(days: 6));

    return NutritionPlan(
      id: 'demo-nutrition-1',
      userId: userId,
      name: 'Demo Nutrition Plan',
      description: 'Balanced macros for training days',
      days: days,
      macros: const {
        'protein': 150.0,
        'carbs': 260.0,
        'fats': 70.0,
      },
      dailyCalories: 2400,
      startDate: startDate,
      endDate: endDate,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      macroTargets: const {
        'calories': 2400,
        'protein': 150,
        'carbs': 260,
        'fat': 70,
      },
    );
  }

  /// Minimal, lightweight demo nutrition plan (kept for demo-only builds).
  static NutritionPlan fallbackNutritionPlan({required String userId}) {
    final macroTargets = {
      'calories': 2000,
      'protein': 150,
      'carbs': 250,
      'fat': 70,
    };

    final mealMacros = MacroTargets(protein: 30, carbs: 40, fats: 15);
    final meals = [
      Meal(
        id: 'meal1',
        name: 'Breakfast',
        nameAr: 'Breakfast',
        nameEn: 'Breakfast',
        type: 'breakfast',
        time: '08:00',
        foods: [],
        macros: mealMacros,
        calories: 400,
      ),
      Meal(
        id: 'meal2',
        name: 'Lunch',
        nameAr: 'Lunch',
        nameEn: 'Lunch',
        type: 'lunch',
        time: '13:00',
        foods: [],
        macros: mealMacros,
        calories: 700,
      ),
      Meal(
        id: 'meal3',
        name: 'Dinner',
        nameAr: 'Dinner',
        nameEn: 'Dinner',
        type: 'dinner',
        time: '19:00',
        foods: [],
        macros: mealMacros,
        calories: 900,
      ),
    ];

    final day = DayMealPlan(
      id: 'day1',
      dayName: 'Day 1',
      dayNumber: 1,
      meals: meals,
    );

    return NutritionPlan(
      id: 'fallback-nutrition-plan',
      userId: userId,
      name: 'Fallback Plan',
      days: [day],
      macros: {
        'protein': 150.0,
        'carbs': 250.0,
        'fats': 70.0,
      },
      dailyCalories: 2000,
      startDate: DateTime.now(),
      createdAt: DateTime.now(),
      macroTargets: macroTargets,
    );
  }

  static CoachAnalytics coachAnalytics() {
    return CoachAnalytics(
      activeClients: 18,
      upcomingAppointments: 3,
      todayEarnings: 180,
      monthEarnings: 2450,
      unreadMessages: 6,
    );
  }

  static List<CoachClient> coachClients() {
    final now = DateTime.now();
    return [
      CoachClient(
        id: 'client-1',
        fullName: 'Mina Faris',
        email: 'user.demo@fitcoach.app',
        phoneNumber: '+10000000001',
        subscriptionTier: 'Smart Premium',
        goal: 'Strength',
        isActive: true,
        assignedDate: now.subtract(const Duration(days: 40)),
        lastActivity: now.subtract(const Duration(days: 1)),
        fitnessScore: 82,
        workoutPlanId: 'demo-plan-1',
        workoutPlanName: 'Demo Strength Split',
        nutritionPlanId: 'demo-nutrition-1',
        nutritionPlanName: 'Demo Nutrition Plan',
        messageCount: 2,
      ),
      CoachClient(
        id: 'client-2',
        fullName: 'Omar Reed',
        email: 'omar.demo@fitcoach.app',
        phoneNumber: '+10000000004',
        subscriptionTier: 'Premium',
        goal: 'Fat loss',
        isActive: true,
        assignedDate: now.subtract(const Duration(days: 12)),
        lastActivity: now.subtract(const Duration(days: 3)),
        fitnessScore: 76,
        workoutPlanId: 'demo-plan-2',
        workoutPlanName: 'Fat Loss Starter',
        nutritionPlanId: 'demo-nutrition-2',
        nutritionPlanName: 'Cutting Plan',
        messageCount: 1,
      ),
    ];
  }

  static List<Appointment> coachAppointments({
    required String coachId,
    required String userId,
  }) {
    final today = DateTime.now();
    final later = today.add(const Duration(hours: 3));
    final tomorrow = today.add(const Duration(days: 1, hours: 2));
    return [
      Appointment(
        id: 'appt-1',
        coachId: coachId,
        userId: userId,
        scheduledAt: today.toIso8601String(),
        durationMinutes: 45,
        status: 'confirmed',
        type: 'video',
        notes: 'Weekly check-in',
        coachName: 'Coach Sam',
        userName: 'Mina Faris',
      ),
      Appointment(
        id: 'appt-2',
        coachId: coachId,
        userId: 'client-2',
        scheduledAt: later.toIso8601String(),
        durationMinutes: 30,
        status: 'pending',
        type: 'chat',
        notes: 'Macro review',
        coachName: 'Coach Sam',
        userName: 'Omar Reed',
      ),
      Appointment(
        id: 'appt-3',
        coachId: coachId,
        userId: 'client-3',
        scheduledAt: tomorrow.toIso8601String(),
        durationMinutes: 60,
        status: 'confirmed',
        type: 'assessment',
        notes: 'Initial assessment',
        coachName: 'Coach Sam',
        userName: 'Lina Park',
      ),
    ];
  }

  static CoachEarnings coachEarnings() {
    final now = DateTime.now();
    return CoachEarnings(
      summary: EarningsSummary(
        totalEarnings: 12450,
        totalCommission: 1860,
        totalTransactions: 42,
      ),
      periodBreakdown: [
        PeriodEarnings(
          period: DateTime(now.year, now.month - 2, 1),
          earnings: 3500,
          transactions: 12,
        ),
        PeriodEarnings(
          period: DateTime(now.year, now.month - 1, 1),
          earnings: 4100,
          transactions: 14,
        ),
        PeriodEarnings(
          period: DateTime(now.year, now.month, 1),
          earnings: 4850,
          transactions: 16,
        ),
      ],
      recentTransactions: [
        Transaction(
          id: 'txn-1',
          clientName: 'Mina Faris',
          amount: 120,
          coachCommission: 18,
          type: 'subscription',
          createdAt: now.subtract(const Duration(days: 2)),
        ),
        Transaction(
          id: 'txn-2',
          clientName: 'Omar Reed',
          amount: 80,
          coachCommission: 12,
          type: 'session',
          createdAt: now.subtract(const Duration(days: 5)),
        ),
      ],
    );
  }

  static AdminAnalytics adminAnalytics() {
    return AdminAnalytics(
      users: UserStats(total: 1240, active: 812),
      coaches: CoachStats(total: 68, active: 41),
      subscriptions: [
        SubscriptionDistribution(subscriptionTier: 'Freemium', count: 520),
        SubscriptionDistribution(subscriptionTier: 'Premium', count: 460),
        SubscriptionDistribution(subscriptionTier: 'Smart Premium', count: 260),
      ],
      revenue: RevenueStats(last30Days: 45200),
      growth: GrowthStats(newUsersLast7Days: 84),
      sessions: SessionStats(today: 214),
    );
  }

  static List<AdminUser> adminUsers() {
    final now = DateTime.now();
    return [
      AdminUser(
        id: 'user-1',
        fullName: 'Mina Faris',
        email: 'user.demo@fitcoach.app',
        phoneNumber: '+10000000001',
        subscriptionTier: 'Smart Premium',
        isActive: true,
        coachId: 'coach-1',
        coachName: 'Coach Sam',
        createdAt: now.subtract(const Duration(days: 200)),
        lastLogin: now.subtract(const Duration(hours: 3)),
      ),
      AdminUser(
        id: 'user-2',
        fullName: 'Omar Reed',
        email: 'omar.demo@fitcoach.app',
        phoneNumber: '+10000000004',
        subscriptionTier: 'Premium',
        isActive: true,
        coachId: 'coach-2',
        coachName: 'Coach Dana',
        createdAt: now.subtract(const Duration(days: 120)),
        lastLogin: now.subtract(const Duration(days: 1)),
      ),
    ];
  }

  static List<AdminCoach> adminCoaches() {
    final now = DateTime.now();
    return [
      AdminCoach(
        id: 'coach-1',
        userId: 'demo-coach',
        fullName: 'Coach Sam',
        email: 'coach@fitcoach.com',
        phoneNumber: '+10000000002',
        specializations: const ['Strength', 'Mobility'],
        clientCount: 18,
        totalEarnings: 12450,
        averageRating: 4.8,
        isApproved: true,
        isActive: true,
        createdAt: now.subtract(const Duration(days: 400)),
        approvedAt: now.subtract(const Duration(days: 380)),
      ),
      AdminCoach(
        id: 'coach-2',
        userId: 'coach-user-2',
        fullName: 'Coach Dana',
        email: 'dana.demo@fitcoach.app',
        phoneNumber: '+10000000005',
        specializations: const ['Nutrition', 'Endurance'],
        clientCount: 12,
        totalEarnings: 8400,
        averageRating: 4.6,
        isApproved: true,
        isActive: true,
        createdAt: now.subtract(const Duration(days: 250)),
        approvedAt: now.subtract(const Duration(days: 230)),
      ),
      AdminCoach(
        id: 'coach-3',
        userId: 'coach-user-3',
        fullName: 'Coach Lina',
        email: 'lina.demo@fitcoach.app',
        phoneNumber: '+10000000006',
        specializations: const ['Rehab', 'Mobility'],
        clientCount: 0,
        totalEarnings: 0,
        averageRating: 0,
        isApproved: false,
        isActive: false,
        createdAt: now.subtract(const Duration(days: 15)),
        approvedAt: null,
      ),
    ];
  }

  static RevenueAnalytics revenueAnalytics() {
    final now = DateTime.now();
    return RevenueAnalytics(
      total: 154200,
      transactionCount: 920,
      byPeriod: [
        RevenuePeriod(
          period: DateTime(now.year, now.month - 2, 1),
          revenue: 45200,
          transactions: 280,
        ),
        RevenuePeriod(
          period: DateTime(now.year, now.month - 1, 1),
          revenue: 51200,
          transactions: 310,
        ),
        RevenuePeriod(
          period: DateTime(now.year, now.month, 1),
          revenue: 57800,
          transactions: 330,
        ),
      ],
      byTier: [
        RevenueTier(subscriptionTier: 'Freemium', revenue: 12000, count: 520),
        RevenueTier(subscriptionTier: 'Premium', revenue: 62000, count: 460),
        RevenueTier(
            subscriptionTier: 'Smart Premium', revenue: 80200, count: 260),
      ],
    );
  }

  static List<AuditLog> auditLogs() {
    final now = DateTime.now();
    return [
      AuditLog(
        id: 'audit-1',
        userId: 'user-1',
        userName: 'Mina Faris',
        action: 'login_success',
        ipAddress: '192.168.1.10',
        userAgent: 'Chrome',
        metadata: const {'method': 'otp'},
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      AuditLog(
        id: 'audit-2',
        userId: 'coach-1',
        userName: 'Coach Sam',
        action: 'plan_updated',
        ipAddress: '192.168.1.12',
        userAgent: 'Chrome',
        metadata: const {'plan': 'demo-plan-1'},
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
    ];
  }

  static Conversation demoConversation({
    required String userId,
    required String coachId,
    bool isArabic = false,
  }) {
    final now = DateTime.now();
    return Conversation(
      id: '${userId}_$coachId',
      userId: userId,
      coachId: coachId,
      lastMessageContent: isArabic
          ? 'خطة التمرين جاهزة للمراجعة.'
          : 'Your plan is ready for review.',
      lastMessageAt: now.subtract(const Duration(minutes: 15)),
      unreadCount: 1,
      createdAt: now.subtract(const Duration(days: 30)),
      updatedAt: now.subtract(const Duration(minutes: 15)),
    );
  }

  static List<Message> chatMessages({
    required String conversationId,
    bool isArabic = false,
  }) {
    final now = DateTime.now();
    return [
      Message(
        id: 'msg-1',
        conversationId: conversationId,
        senderId: 'demo-coach',
        receiverId: 'demo-user',
        content: isArabic
            ? 'مرحباً! هل أنت مستعد لجلسة اليوم؟'
            : 'Welcome! Ready for today\'s session?',
        type: MessageType.text,
        isRead: true,
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
        readAt: now.subtract(const Duration(days: 1, hours: 2)),
      ),
      Message(
        id: 'msg-2',
        conversationId: conversationId,
        senderId: 'demo-user',
        receiverId: 'demo-coach',
        content: isArabic
            ? 'نعم، أشعر أني بخير. هل يمكننا مراجعة إشارات وضعية الجسم؟'
            : 'Yes, feeling good. Can we review my form cues?',
        type: MessageType.text,
        isRead: true,
        createdAt: now.subtract(const Duration(days: 1, hours: 1)),
        readAt: now.subtract(const Duration(days: 1, hours: 1)),
      ),
      Message(
        id: 'msg-3',
        conversationId: conversationId,
        senderId: 'demo-coach',
        receiverId: 'demo-user',
        content: isArabic
            ? 'بالتأكيد. أضفت ملاحظات داخل خطتك.'
            : 'Absolutely. I added notes in your plan.',
        type: MessageType.text,
        isRead: false,
        createdAt: now.subtract(const Duration(minutes: 20)),
      ),
      Message(
        id: 'msg-4',
        conversationId: conversationId,
        senderId: 'demo-user',
        receiverId: 'demo-coach',
        content: isArabic
            ? 'سأطلع عليها الليلة قبل الجلسة.'
            : 'I will review them tonight before the session.',
        type: MessageType.text,
        isRead: false,
        createdAt: now.subtract(const Duration(minutes: 8)),
      ),
      Message(
        id: 'msg-5',
        conversationId: conversationId,
        senderId: 'demo-coach',
        receiverId: 'demo-user',
        content: isArabic
            ? 'رائع، سأرسل لك أيضاً خطة المغذيات المحدثة.'
            : 'Great, I will also send the updated nutrition targets.',
        type: MessageType.text,
        isRead: false,
        createdAt: now.subtract(const Duration(minutes: 3)),
      ),
    ];
  }

  static List<SubscriptionPlan> subscriptionPlans() {
    return [
      SubscriptionPlan(
        id: 'freemium',
        name: 'Freemium',
        description: 'Starter access with guided onboarding and essential chat quotas.',
        monthlyPrice: 0,
        yearlyPrice: 0,
        currency: 'SAR',
        badge: 'Starter',
        accentColor: '#CBD5F5',
        metadata: const {
          'messagesLimit': 20,
          'videoCallsLimit': 1,
        },
        features: const [
          SubscriptionPlanFeature(
            id: 'feat_workouts_lite',
            label: 'Workout Library',
            value: 'Foundational templates',
            order: 0,
          ),
          SubscriptionPlanFeature(
            id: 'feat_messages_lite',
            label: 'Coach Messaging',
            value: '20 messages / month',
            order: 1,
          ),
          SubscriptionPlanFeature(
            id: 'feat_calls_lite',
            label: 'Video Calls',
            value: '1 call / month',
            order: 2,
          ),
          SubscriptionPlanFeature(
            id: 'feat_nutrition_trial',
            label: 'Nutrition Coaching',
            value: '14-day trial intake',
            order: 3,
          ),
        ],
      ),
      SubscriptionPlan(
        id: 'premium',
        name: 'Premium',
        description: 'On-demand messaging, adaptive programming, and priority support.',
        monthlyPrice: 199,
        yearlyPrice: 1990,
        currency: 'SAR',
        badge: 'Most Popular',
        accentColor: '#7C3AED',
        isRecommended: true,
        metadata: const {
          'messagesLimit': 200,
          'videoCallsLimit': 4,
        },
        features: const [
          SubscriptionPlanFeature(
            id: 'feat_workouts_custom',
            label: 'Workout Library',
            value: 'Custom weekly plans',
            order: 0,
          ),
          SubscriptionPlanFeature(
            id: 'feat_messages_plus',
            label: 'Coach Messaging',
            value: '200 messages / month',
            order: 1,
          ),
          SubscriptionPlanFeature(
            id: 'feat_calls_plus',
            label: 'Video Calls',
            value: '4 calls / month',
            order: 2,
          ),
          SubscriptionPlanFeature(
            id: 'feat_nutrition_full',
            label: 'Nutrition Coaching',
            value: 'Full meal plans & intake review',
            order: 3,
          ),
          SubscriptionPlanFeature(
            id: 'feat_injury_engine',
            label: 'Injury Substitutions',
            value: 'AI-generated swaps',
            order: 4,
          ),
          SubscriptionPlanFeature(
            id: 'feat_progress_analytics',
            label: 'Progress Analytics',
            value: 'Weekly readiness + body metrics',
            order: 5,
          ),
          SubscriptionPlanFeature(
            id: 'feat_priority_support',
            label: 'Priority Support',
            value: 'Under 2h response time',
            order: 6,
          ),
        ],
      ),
      SubscriptionPlan(
        id: 'smart_premium',
        name: 'Smart Premium',
        description: 'Unlimited concierge coaching with advanced automation for pros.',
        monthlyPrice: 399,
        yearlyPrice: 3990,
        currency: 'SAR',
        badge: 'Elite',
        accentColor: '#EC4899',
        metadata: const {
          'messagesLimit': -1,
          'videoCallsLimit': 12,
        },
        features: const [
          SubscriptionPlanFeature(
            id: 'feat_workouts_elite',
            label: 'Workout Library',
            value: 'Dynamic goal-based builder',
            order: 0,
          ),
          SubscriptionPlanFeature(
            id: 'feat_messages_unlimited',
            label: 'Coach Messaging',
            value: 'Unlimited conversations',
            order: 1,
          ),
          SubscriptionPlanFeature(
            id: 'feat_calls_unlimited',
            label: 'Video Calls',
            value: '12 calls / month',
            order: 2,
          ),
          SubscriptionPlanFeature(
            id: 'feat_nutrition_lab',
            label: 'Nutrition Coaching',
            value: 'Lab panels & Smart meal swaps',
            order: 3,
          ),
          SubscriptionPlanFeature(
            id: 'feat_injury_engine_max',
            label: 'Injury Substitutions',
            value: 'Predictive movement engine',
            order: 4,
          ),
          SubscriptionPlanFeature(
            id: 'feat_progress_ai',
            label: 'Progress Analytics',
            value: 'AI readiness + exports',
            order: 5,
          ),
          SubscriptionPlanFeature(
            id: 'feat_priority_concierge',
            label: 'Priority Support',
            value: 'Dedicated concierge line',
            order: 6,
          ),
          SubscriptionPlanFeature(
            id: 'feat_file_attachments',
            label: 'File Attachments',
            value: 'Send media, PDFs, and scans',
            order: 7,
          ),
        ],
      ),
    ];
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/colors.dart';
import '../../../data/models/workout_plan.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/services/exercise_catalog_service.dart';
import '../../providers/language_provider.dart';
import '../../providers/workout_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_card.dart';
import '../intake/second_intake_screen.dart';
import '../messaging/coach_messaging_screen.dart';
import './workout_intro_screen.dart';
import './workout_exercise_session_screen.dart';
import './workout_exercise_detail_screen.dart';

class WorkoutScreen extends StatefulWidget {
  final bool isActive;

  const WorkoutScreen({
    super.key,
    this.isActive = true,
  });

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  bool _promptedSecondIntake = false;
  bool _wasActive = true;
  bool _showIntro = false;
  bool _introLoaded = false;
  final ExerciseCatalogService _catalogService = ExerciseCatalogService.instance;

  @override
  void initState() {
    super.initState();
    _wasActive = widget.isActive;
    _loadIntroFlag();
    Future.microtask(() {
      context.read<WorkoutProvider>().loadActivePlan();
    });
    if (widget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybeShowSecondIntake();
      });
    }
  }

  Future<void> _loadIntroFlag() async {
    final prefs = await SharedPreferences.getInstance();
    final seenIntro = prefs.getBool('workout_intro_seen') ?? false;
    if (mounted) {
      setState(() {
        _showIntro = !seenIntro;
        _introLoaded = true;
      });
    }
    if (widget.isActive && seenIntro) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybeShowSecondIntake();
      });
    }
  }

  Future<void> _completeIntro() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('workout_intro_seen', true);
    if (mounted) {
      setState(() {
        _showIntro = false;
      });
    }
    _maybeShowSecondIntake();
  }

  @override
  void didUpdateWidget(covariant WorkoutScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_wasActive) {
      _promptedSecondIntake = false;
      if (!_showIntro && _introLoaded) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _maybeShowSecondIntake();
        });
      }
    }
    _wasActive = widget.isActive;
  }

  void _maybeShowSecondIntake() {
    if (_promptedSecondIntake) return;
    if (_showIntro) return;
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    if (user == null || user.hasCompletedSecondIntake) return;
    _promptedSecondIntake = true;
    _showSecondIntakePrompt(user.subscriptionTier);
  }

  void _showSecondIntakePrompt(String tier) {
    final lang = context.read<LanguageProvider>();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(lang.t('intake_prompt_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(lang.t('intake_prompt_description')),
            const SizedBox(height: 16),
            _buildPromptOption(
              icon: Icons.assignment_turned_in,
              title: lang.t('intake_prompt_option1_title'),
              description: lang.t('intake_prompt_option1_desc'),
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            _buildPromptOption(
              icon: Icons.video_call,
              title: lang.t('intake_prompt_option2_title'),
              description: lang.t('intake_prompt_option2_desc'),
              color: AppColors.secondary,
              badgeText: tier == 'Freemium' ? lang.t('intake_prompt_free_call') : null,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(lang.t('intake_prompt_later')),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _openCoachSessions();
            },
            icon: const Icon(Icons.video_call),
            label: Text(lang.t('intake_prompt_book_call')),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _openSecondIntake();
            },
            icon: const Icon(Icons.assignment_turned_in),
            label: Text(lang.t('intake_prompt_complete')),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptOption({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    String? badgeText,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (badgeText != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badgeText,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openSecondIntake() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SecondIntakeScreen(
          onComplete: () {
            if (mounted) {
              Navigator.of(context).pop();
              context.read<WorkoutProvider>().loadActivePlan();
            }
          },
        ),
      ),
    );
  }

  void _openCoachSessions() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CoachMessagingScreen(initialTabIndex: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final workoutProvider = context.watch<WorkoutProvider>();
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final isArabic = languageProvider.isArabic;

    if (_showIntro) {
      return WorkoutIntroScreen(
        onGetStarted: _completeIntro,
      );
    }
    
    if (workoutProvider.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (workoutProvider.activePlan == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(languageProvider.t('workout')),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.fitness_center_outlined,
                size: 80,
                color: AppColors.textDisabled,
              ),
              const SizedBox(height: 24),
              Text(
                languageProvider.t('no_active_workout_plan'),
                style: const TextStyle(
                  fontSize: 18,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                languageProvider.t('workout_plan_coming_soon'),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textDisabled,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    final plan = workoutProvider.activePlan!;
    final currentDay = workoutProvider.currentDay ??
        (plan.days != null && plan.days!.isNotEmpty ? plan.days!.first : null);
    final totalExercises = currentDay?.exercises.length ?? 0;
    final completedExercises = currentDay == null
        ? 0
        : currentDay.exercises
            .where((e) => workoutProvider.isExerciseCompleted(e.id))
            .length;
    final workoutProgress =
        totalExercises == 0 ? 0.0 : completedExercises / totalExercises;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.8,
              child: Image.network(
                'https://images.unsplash.com/photo-1717571209798-ac9312c2d3cc?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=1080',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWorkoutHeroHeader(
                    plan,
                    currentDay,
                    languageProvider,
                    completedExercises,
                    totalExercises,
                    workoutProgress,
                    isArabic,
                  ),
                  const SizedBox(height: 16),
                  if (user != null && !user.hasCompletedSecondIntake)
                    _buildSecondIntakeBanner(user, languageProvider),
                  const SizedBox(height: 16),
                  _buildWorkoutSummaryCard(
                    plan,
                    currentDay,
                    languageProvider,
                    workoutProgress,
                    isArabic,
                  ),
                  const SizedBox(height: 16),
                  if (currentDay != null)
                    _buildExerciseList(
                      currentDay,
                      workoutProvider,
                      languageProvider,
                      isArabic,
                    )
                  else
                    Center(
                      child: Text(
                        languageProvider.t('workout_select_day'),
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  const SizedBox(height: 16),
                  _buildWorkoutActionRow(
                    languageProvider,
                    workoutProgress,
                    currentDay,
                    workoutProvider,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutHeroHeader(
    WorkoutPlan plan,
    WorkoutDay? currentDay,
    LanguageProvider lang,
    int completedExercises,
    int totalExercises,
    double progress,
    bool isArabic,
  ) {
    final planTitle = _localizedPlanName(plan, lang, isArabic);
    final dayNumber = currentDay?.dayNumber ?? 1;
    final durationLabel = _estimateWorkoutDuration(currentDay, lang);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang.t('workouts_title'),
            style: AppTextStyles.small.copyWith(
              color: AppColors.textWhite.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      planTitle,
                      style: AppTextStyles.h3.copyWith(color: AppColors.textWhite),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${lang.t('workout_week', args: {'number': '1'})}, '
                      '${lang.t('workout_day_label', args: {'number': '$dayNumber'})}'
                      '${durationLabel.isEmpty ? '' : ' \u2022 $durationLabel'}',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.textWhite.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.textWhite.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: AppColors.textWhite),
                    const SizedBox(width: 6),
                    Text(
                      lang.t('today'),
                      style: AppTextStyles.small.copyWith(color: AppColors.textWhite),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.textWhite.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.textWhite),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            lang.t('workout_progress', args: {
              'completed': '$completedExercises',
              'total': '$totalExercises',
            }),
            style: AppTextStyles.small.copyWith(
              color: AppColors.textWhite.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondIntakeBanner(
    UserProfile user,
    LanguageProvider lang,
  ) {
    const totalSteps = 4;
    var completedSteps = 0;

    if (user.age != null) {
      completedSteps++;
    }
    if (user.weight != null && user.height != null) {
      completedSteps++;
    }
    if (user.experienceLevel != null && user.experienceLevel!.isNotEmpty) {
      completedSteps++;
    }
    if (user.workoutFrequency != null) {
      completedSteps++;
    }

    final isCompleted = completedSteps >= totalSteps;
    // Always show 30% progress if not completed
    final progress = isCompleted ? 1.0 : 0.3;
    final percent = (progress * 100).round();

    return CustomCard(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      color: AppColors.primary.withValues(alpha: 0.08),
      border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang.t('intake_banner_title'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lang.t('intake_banner_desc'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.info_outline, color: AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  lang.t('intake_banner_progress'),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                '$percent%',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.center,
            child: Text(
              lang.t('intake_banner_benefits'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _openSecondIntake,
                  icon: const Icon(Icons.assignment_turned_in, size: 16),
                  label: Text(lang.t('intake_banner_complete_now')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openCoachSessions,
                  icon: const Icon(Icons.video_call, size: 16),
                  label: Text(lang.t('intake_banner_book_call')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutSummaryCard(
    WorkoutPlan plan,
    WorkoutDay? currentDay,
    LanguageProvider lang,
    double progress,
    bool isArabic,
  ) {
    final totalExercises = currentDay?.exercises.length ?? 0;
    final durationLabel = _estimateWorkoutDuration(currentDay, lang);
    final planTitle = _localizedPlanName(plan, lang, isArabic);
    final difficultyLabel = _localizedPlanDifficulty(plan, lang, isArabic);

    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  planTitle,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  difficultyLabel,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(
                icon: Icons.track_changes,
                value: '$totalExercises',
                label: lang.t('exercises'),
              ),
              _buildSummaryItem(
                icon: Icons.schedule,
                value: durationLabel,
                label: lang.t('duration'),
              ),
              _buildSummaryItem(
                icon: Icons.check_circle_outline,
                value: '${(progress * 100).round()}%',
                label: lang.t('workout_complete_label'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildWorkoutActionRow(
    LanguageProvider lang,
    double progress,
    WorkoutDay? currentDay,
    WorkoutProvider provider,
  ) {
    final isCompleted = progress >= 1.0;

    void showMessage(String message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }

    void openExerciseAt(int index) {
      if (currentDay == null || currentDay.exercises.isEmpty) {
        showMessage(lang.t('no_active_workout_plan'));
        return;
      }
      final safeIndex = index.clamp(0, currentDay.exercises.length - 1);
      _openExerciseSession(currentDay, safeIndex);
    }

    int? lastCompletedIndex() {
      if (currentDay == null) return null;
      for (var i = currentDay.exercises.length - 1; i >= 0; i--) {
        if (provider.isExerciseCompleted(currentDay.exercises[i].id)) {
          return i;
        }
      }
      return null;
    }

    int? firstIncompleteIndex() {
      if (currentDay == null) return null;
      for (var i = 0; i < currentDay.exercises.length; i++) {
        if (!provider.isExerciseCompleted(currentDay.exercises[i].id)) {
          return i;
        }
      }
      return null;
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              final idx = lastCompletedIndex();
              if (idx == null) {
                showMessage(lang.t('workout_progress', args: {
                  'completed': '0',
                  'total': '${currentDay?.exercises.length ?? 0}',
                }));
                return;
              }
              openExerciseAt(idx);
            },
            child: Text(lang.t('workout_previous')),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: isCompleted
                ? null
                : () {
                    final nextIdx = firstIncompleteIndex() ?? lastCompletedIndex() ?? 0;
                    openExerciseAt(nextIdx);
                  },
            child: Text(
              isCompleted
                  ? lang.t('workout_completed')
                  : lang.t('workout_continue'),
            ),
          ),
        ),
      ],
    );
  }

  String _estimateWorkoutDuration(WorkoutDay? currentDay, LanguageProvider lang) {
    if (currentDay == null) {
      return '';
    }
    final exercisesCount = currentDay.exercises.length;
    if (exercisesCount == 0) {
      return '';
    }
    final minutes = (exercisesCount * 6).clamp(20, 90);
    return '${minutes.toInt()} ${lang.t('minute_short')}';
  }

  String _localizedPlanName(WorkoutPlan plan, LanguageProvider lang, bool isArabic) {
    final fallback = lang.t('workout');
    if (isArabic) {
      if (plan.nameAr?.isNotEmpty == true) {
        return plan.nameAr!;
      }
      if (plan.name?.isNotEmpty == true) {
        return plan.name!;
      }
      return fallback;
    }
    return plan.name ?? fallback;
  }

  String _localizedPlanDifficulty(WorkoutPlan plan, LanguageProvider lang, bool isArabic) {
    final englishDescription = plan.description ?? lang.t('workout_difficulty_intermediate');
    if (isArabic) {
      if (plan.descriptionAr?.isNotEmpty == true) {
        return plan.descriptionAr!;
      }
      return lang.t('workout_difficulty_intermediate');
    }
    return englishDescription;
  }

  Widget _buildExerciseList(
    WorkoutDay currentDay,
    WorkoutProvider provider,
    LanguageProvider lang,
    bool isArabic,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: currentDay.exercises.length,
      itemBuilder: (context, index) {
        final exercise = currentDay.exercises[index];
        return _buildExerciseCard(
          currentDay,
          exercise,
          provider,
          lang,
          isArabic,
          index,
        );
      },
    );
  }
  
  Widget _buildExerciseCard(
    WorkoutDay currentDay,
    Exercise exercise,
    WorkoutProvider provider,
    LanguageProvider lang,
    bool isArabic,
    int index,
  ) {
    final authProvider = context.watch<AuthProvider>();
    final userInjuries = authProvider.user?.injuries ?? [];
    final hasConflict = exercise.hasInjuryConflict(userInjuries);
    final isCompleted = provider.isExerciseCompleted(exercise.id);
    final muscleLabel = _localizeMuscles(exercise.muscleGroup, isArabic);
    
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      color: isCompleted
          ? AppColors.success.withValues(alpha: 0.06)
          : AppColors.background,
      border: isCompleted
          ? Border.all(color: AppColors.success.withValues(alpha: 0.4))
          : (hasConflict ? Border.all(color: AppColors.warning) : null),
      onTap: () => _openExerciseDetail(currentDay, index),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isArabic ? exercise.nameAr : exercise.nameEn,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isCompleted)
                        const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${exercise.sets} ${lang.t('sets')} \u2022 ${exercise.reps} ${lang.t('reps')}'
                    '${muscleLabel.isEmpty ? '' : ' \u2022 $muscleLabel'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (hasConflict) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        lang.t('workout_injury_conflict'),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_red_eye_outlined),
                  color: AppColors.textSecondary,
                  onPressed: () => _openExerciseDetail(currentDay, index),
                ),
                SizedBox(
                  width: 92,
                  child: ElevatedButton(
                    onPressed: () => _openExerciseSession(currentDay, index),
                    child: Text(
                      isCompleted
                          ? lang.t('workout_review')
                          : lang.t('start_workout'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _localizeMuscles(String? muscles, bool isArabic) {
    if (muscles == null || muscles.trim().isEmpty) {
      return '';
    }
    final parts = muscles.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
    final labels = parts.map((part) {
      return _catalogService.getMuscleLabel(part, isArabic: isArabic) ?? part;
    }).toList();
    return labels.join(', ');
  }

  void _openExerciseSession(WorkoutDay day, int startIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkoutExerciseSessionScreen(
          exercises: day.exercises,
          startIndex: startIndex,
          onShowSubstitute: (exercise) {
            final provider = context.read<WorkoutProvider>();
            final lang = context.read<LanguageProvider>();
            _showSubstituteDialog(exercise, provider, lang, lang.isArabic);
          },
        ),
      ),
    );
  }

  void _openExerciseDetail(WorkoutDay day, int index) {
    final exercise = day.exercises[index];
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkoutExerciseDetailScreen(
          exercise: exercise,
          onStartExercise: () => _openExerciseSession(day, index),
        ),
      ),
    );
  }
  
  Future<void> _showSubstituteDialog(
    Exercise exercise,
    WorkoutProvider provider,
    LanguageProvider lang,
    bool isArabic,
  ) async {
    final authProvider = context.read<AuthProvider>();
    final userInjuries = authProvider.user?.injuries ?? [];
    
      showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.t('substitute_exercise')),
        content: FutureBuilder<List<Exercise>>(
          future: provider.getExerciseAlternatives(exercise.id, userInjuries),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
              return Text(
                lang.t('no_alternatives_available'),
              );
            }
            
            final alternatives = snapshot.data!;
            
            return SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: alternatives.length,
                itemBuilder: (context, index) {
                  final alt = alternatives[index];
                  return ListTile(
                    title: Text(isArabic ? alt.nameAr : alt.nameEn),
                    subtitle: Text(alt.muscleGroup ?? ''),
                    trailing: Icon(isArabic ? Icons.chevron_left : Icons.chevron_right),
                    onTap: () async {
                      Navigator.pop(context);
                      final success = await provider.substituteExercise(
                        exercise.id,
                        alt.id,
                      );
                      
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              lang.t('exercise_substituted_successfully'),
                            ),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.t('cancel')),
          ),
        ],
      ),
    );
  }
}

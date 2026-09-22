import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/video_thumbnail_resolver.dart';
import '../../../data/models/workout_calendar.dart';
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
import '../../../core/theme/app_palette.dart';

class WorkoutScreen extends StatefulWidget {
  final bool isActive;
  final VoidCallback? onBack;

  const WorkoutScreen({
    super.key,
    this.isActive = true,
    this.onBack,
  });

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  bool _promptedSecondIntake = false;
  bool _wasActive = true;
  bool _showIntro = false;
  bool _introLoaded = false;
  final ExerciseCatalogService _catalogService =
      ExerciseCatalogService.instance;

  @override
  void initState() {
    super.initState();
    _wasActive = widget.isActive;
    _loadIntroFlag();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_loadWorkoutData());
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
      unawaited(_loadWorkoutData(silentCalendar: true));
      if (!_showIntro && _introLoaded) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _maybeShowSecondIntake();
        });
      }
    }
    _wasActive = widget.isActive;
  }

  Future<void> _loadWorkoutData({bool silentCalendar = false}) async {
    final workoutProvider = context.read<WorkoutProvider>();
    try {
      await workoutProvider.loadActivePlan();
      await workoutProvider.loadWorkoutCalendar(silent: silentCalendar);
    } catch (_) {
      // Provider methods own their error state; this prevents unhandled futures.
    }
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
              badgeText:
                  tier == 'Freemium' ? lang.t('intake_prompt_free_call') : null,
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
                    color: context.palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.palette.textSecondary,
                  ),
                ),
                if (badgeText != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              unawaited(_loadWorkoutData());
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

  Widget _buildWorkoutScreenShell({
    PreferredSizeWidget? appBar,
    required Widget child,
  }) {
    return Scaffold(
      backgroundColor: AppColors.workoutBackground,
      appBar: appBar,
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF071915),
                    Color(0xFF12362D),
                    Color(0xFF0B1F1B),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Image.asset(
              'assets/placeholders/splash_onboarding/workout_onboarding.png',
              fit: BoxFit.cover,
              color: Colors.black.withValues(alpha: 0.18),
              colorBlendMode: BlendMode.darken,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.workoutBackground.withValues(alpha: 0.28),
                    AppColors.workoutBackground.withValues(alpha: 0.62),
                    AppColors.workoutBackground.withValues(alpha: 0.86),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(child: child),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final workoutProvider = context.watch<WorkoutProvider>();
    final isArabic = languageProvider.isArabic;

    if (_showIntro) {
      return WorkoutIntroScreen(
        onGetStarted: _completeIntro,
      );
    }

    final hasPlan = workoutProvider.activePlan != null;
    final initialPlanLoading = workoutProvider.isLoading && !hasPlan;
    final initialCalendarLoading = workoutProvider.isCalendarLoading &&
        !workoutProvider.hasLoadedCalendar &&
        !hasPlan;
    if (initialPlanLoading || initialCalendarLoading) {
      return _buildWorkoutScreenShell(
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (workoutProvider.error != null && !hasPlan) {
      return _buildWorkoutScreenShell(
        appBar: AppBar(
          title: Text(languageProvider.t('workout')),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.error.withValues(alpha: 0.85),
                ),
                const SizedBox(height: 16),
                Text(
                  workoutProvider.error!,
                  style: TextStyle(
                    fontSize: 14,
                    color: context.palette.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    workoutProvider.clearError();
                    unawaited(_loadWorkoutData());
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text(languageProvider.t('retry')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!hasPlan &&
        workoutProvider.hasLoadedCalendar &&
        workoutProvider.calendarPlan == null) {
      return _buildWorkoutScreenShell(
        appBar: AppBar(
          title: Text(languageProvider.t('workout')),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.fitness_center_outlined,
                size: 80,
                color: context.palette.textDisabled,
              ),
              const SizedBox(height: 24),
              Text(
                languageProvider.t('no_active_workout_plan'),
                style: TextStyle(
                  fontSize: 18,
                  color: context.palette.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  unawaited(_loadWorkoutData());
                },
                icon: const Icon(Icons.refresh),
                label: Text(languageProvider.t('retry')),
              ),
            ],
          ),
        ),
      );
    }

    if (workoutProvider.activePlan == null) {
      return _buildWorkoutScreenShell(
        appBar: AppBar(
          title: Text(languageProvider.t('workout')),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.fitness_center_outlined,
                size: 80,
                color: context.palette.textDisabled,
              ),
              const SizedBox(height: 24),
              Text(
                languageProvider.t('no_active_workout_plan'),
                style: TextStyle(
                  fontSize: 18,
                  color: context.palette.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                languageProvider.t('workout_plan_coming_soon'),
                style: TextStyle(
                  fontSize: 14,
                  color: context.palette.textDisabled,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => unawaited(_loadWorkoutData()),
                icon: const Icon(Icons.refresh),
                label: Text(languageProvider.t('retry')),
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

    return _buildWorkoutScreenShell(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              32 + MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                const SizedBox(height: 14),
                _buildWorkoutCalendarSections(
                  workoutProvider,
                  languageProvider,
                  isArabic,
                ),
                const SizedBox(height: 14),
                _buildWorkoutSummaryCard(
                  plan,
                  currentDay,
                  languageProvider,
                  workoutProgress,
                  isArabic,
                ),
                const SizedBox(height: 14),
                if (currentDay != null && currentDay.exercises.isNotEmpty)
                  _buildExerciseList(
                    currentDay,
                    workoutProvider,
                    languageProvider,
                    isArabic,
                  )
                else
                  CustomCard(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      languageProvider.t('workout_select_day'),
                      style: TextStyle(color: context.palette.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
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
    final dayNumber = currentDay?.dayNumber ?? 1;
    final durationLabel = _estimateWorkoutDuration(currentDay, lang);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF030625),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                onPressed: () {
                  if (widget.onBack != null) {
                    widget.onBack!();
                  } else {
                    Navigator.maybePop(context);
                  }
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: isArabic
                      ? AlignmentDirectional.centerEnd
                      : AlignmentDirectional.centerStart,
                  child: Text(
                    lang.t('workouts_title'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                      height: 1.05,
                    ),
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () =>
                    context.read<WorkoutProvider>().goToCurrentDay(),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        lang.t('today'),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: isArabic
                  ? AlignmentDirectional.centerEnd
                  : AlignmentDirectional.centerStart,
              child: Text(
                '${lang.t('workout_week', args: {
                      'number': '1'
                    })}, ${lang.t('workout_day_label', args: {
                      'number': '$dayNumber'
                    })}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  height: 1.05,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (durationLabel.isNotEmpty)
            Text(
              durationLabel,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 18,
              ),
            ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: 0.24),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$completedExercises of $totalExercises ${lang.t('exercises')} ${lang.t('workout_completed').toLowerCase()}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
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
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: context.palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lang.t('intake_banner_desc'),
                      style: TextStyle(
                        fontSize: 12,
                        color: context.palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.info_outline, color: context.palette.textSecondary),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  lang.t('intake_banner_progress'),
                  style: TextStyle(
                    fontSize: 11,
                    color: context.palette.textSecondary,
                  ),
                ),
              ),
              Text(
                '$percent%',
                style: TextStyle(
                  fontSize: 11,
                  color: context.palette.textSecondary,
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
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.center,
            child: Text(
              lang.t('intake_banner_benefits'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: context.palette.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 360;
              if (compact) {
                return Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _openSecondIntake,
                        icon: const Icon(Icons.assignment_turned_in, size: 16),
                        label: Text(lang.t('intake_banner_complete_now')),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _openCoachSessions,
                        icon: const Icon(Icons.video_call, size: 16),
                        label: Text(lang.t('intake_banner_book_call')),
                      ),
                    ),
                  ],
                );
              }

              return Row(
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
              );
            },
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
      border: Border.all(color: const Color(0xFFDCDDE4)),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: isArabic
                      ? AlignmentDirectional.centerEnd
                      : AlignmentDirectional.centerStart,
                  child: Text(
                    planTitle,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF161827),
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F1F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    difficultyLabel,
                    style:
                        const TextStyle(fontSize: 15, color: Color(0xFF2A2C3A)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  icon: Icons.track_changes,
                  value: '$totalExercises',
                  label: lang.t('exercises'),
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  icon: Icons.schedule,
                  value: durationLabel,
                  label: lang.t('duration'),
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  icon: Icons.check_circle_outline,
                  value: '${(progress * 100).round()}%',
                  label: lang.t('workout_complete_label'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutCalendarSections(
    WorkoutProvider provider,
    LanguageProvider lang,
    bool isArabic,
  ) {
    final previous = provider.previousDays;
    final upcoming = provider.upcomingDays;
    final today = provider.todayDay;

    if (previous.isEmpty && upcoming.isEmpty && today == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (today != null) ...[
          _buildCalendarDayCard(
            day: today,
            label: lang.t('today'),
            isToday: true,
            isArabic: isArabic,
            onTap: () => _openCalendarDay(provider, today),
          ),
          const SizedBox(height: 10),
        ],
        if (previous.isNotEmpty)
          _buildCalendarSection(
            title: 'Previous',
            days: previous,
            isArabic: isArabic,
            onTap: (day) => _openCalendarDay(provider, day),
          ),
        if (previous.isNotEmpty && upcoming.isNotEmpty)
          const SizedBox(height: 10),
        if (upcoming.isNotEmpty)
          _buildCalendarSection(
            title: 'Upcoming',
            days: upcoming,
            isArabic: isArabic,
            onTap: (day) => _openCalendarDay(provider, day),
          ),
      ],
    );
  }

  Widget _buildCalendarSection({
    required String title,
    required List<WorkoutCalendarDayEntry> days,
    required bool isArabic,
    required void Function(WorkoutCalendarDayEntry day) onTap,
  }) {
    return CustomCard(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      border: Border.all(color: const Color(0xFFDCDDE4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF181A27),
            ),
          ),
          const SizedBox(height: 8),
          ...days.map(
            (day) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildCalendarDayCard(
                day: day,
                isToday: false,
                isArabic: isArabic,
                onTap: () => onTap(day),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarDayCard({
    required WorkoutCalendarDayEntry day,
    required bool isToday,
    required bool isArabic,
    required VoidCallback onTap,
    String? label,
  }) {
    final title = isArabic && (day.dayNameAr?.isNotEmpty == true)
        ? day.dayNameAr!
        : day.dayName;
    final subtitle =
        '${day.completedExercises}/${day.totalExercises} exercises';
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isToday ? const Color(0xFFEAF2FF) : const Color(0xFFF6F7FB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isToday ? const Color(0xFF8AB4F8) : const Color(0xFFE2E4EC),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF181A27),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (label != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDBEAFE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF1D4ED8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6C6F83),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 56,
              child: Text(
                '${day.progressPercent.round()}%',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2A2C3A),
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCalendarDay(
    WorkoutProvider provider,
    WorkoutCalendarDayEntry day,
  ) {
    provider.selectDayByWorkoutDayId(
      day.workoutDayId,
      fallbackDayNumber: day.dayNumber,
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, size: 26, color: const Color(0xFF7D8095)),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Color(0xFF272938),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
              fontSize: 14, color: Color(0xFF7C7F92), height: 1.1),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ignore: unused_element
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

    final previousButton = OutlinedButton(
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
      child: Text(
        lang.t('workout_previous'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );

    final continueButton = ElevatedButton(
      onPressed: isCompleted
          ? null
          : () {
              final nextIdx =
                  firstIncompleteIndex() ?? lastCompletedIndex() ?? 0;
              openExerciseAt(nextIdx);
            },
      child: Text(
        isCompleted ? lang.t('workout_completed') : lang.t('workout_continue'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        if (compact) {
          return Column(
            children: [
              SizedBox(width: double.infinity, child: previousButton),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: continueButton),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: previousButton),
            const SizedBox(width: 12),
            Expanded(child: continueButton),
          ],
        );
      },
    );
  }

  String _estimateWorkoutDuration(
      WorkoutDay? currentDay, LanguageProvider lang) {
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

  String _localizedPlanName(
      WorkoutPlan plan, LanguageProvider lang, bool isArabic) {
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

  String _localizedPlanDifficulty(
      WorkoutPlan plan, LanguageProvider lang, bool isArabic) {
    final englishDescription =
        plan.description ?? lang.t('workout_difficulty_intermediate');
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
      padding: const EdgeInsets.all(16),
      color: isCompleted ? const Color(0xFFEAF7EE) : Colors.white,
      border: Border.all(
        color: isCompleted
            ? const Color(0xFFA9E3B8)
            : (hasConflict ? AppColors.warning : const Color(0xFFDCDDE4)),
      ),
      onTap: () => _openExerciseDetail(currentDay, index),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 360;
          final actionButton = FilledButton(
            onPressed: () => _openExerciseSession(currentDay, index),
            style: FilledButton.styleFrom(
              backgroundColor: isCompleted
                  ? const Color(0xFF030625)
                  : const Color(0xFFE8EAF0),
              foregroundColor:
                  isCompleted ? Colors.white : const Color(0xFF272938),
              textStyle:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              minimumSize: const Size(74, 38),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            child: Text(isCompleted ? 'Done' : 'Start'),
          );

          final thumbnail = _buildExerciseThumbnail(exercise);

          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isArabic ? exercise.nameAr : exercise.nameEn,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF181A27),
                        height: 1.15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isCompleted)
                    const Icon(
                      Icons.check_circle_outline,
                      color: Color(0xFF1F9D4A),
                      size: 22,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 14,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '${exercise.sets}\n${lang.t('sets')}',
                    style:
                        const TextStyle(fontSize: 14, color: Color(0xFF6C6F83)),
                  ),
                  const Text('•', style: TextStyle(color: Color(0xFF6C6F83))),
                  Text(
                    '${exercise.reps}\n${lang.t('reps')}',
                    style:
                        const TextStyle(fontSize: 14, color: Color(0xFF6C6F83)),
                  ),
                  if (muscleLabel.isNotEmpty) ...[
                    const Text('•', style: TextStyle(color: Color(0xFF6C6F83))),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: compact ? constraints.maxWidth : 180,
                      ),
                      child: Text(
                        muscleLabel,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF6C6F83)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${isCompleted ? exercise.sets : 0}/${exercise.sets} sets logged',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF7D8095),
                  decoration: TextDecoration.none,
                ),
              ),
              if (hasConflict) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    thumbnail,
                    const SizedBox(width: 12),
                    Expanded(child: details),
                  ],
                ),
                const SizedBox(height: 10),
                Align(alignment: Alignment.centerRight, child: actionButton),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              thumbnail,
              const SizedBox(width: 12),
              Expanded(child: details),
              const SizedBox(width: 12),
              actionButton,
            ],
          );
        },
      ),
    );
  }

  String _localizeMuscles(String? muscles, bool isArabic) {
    if (muscles == null || muscles.trim().isEmpty) {
      return '';
    }
    final parts =
        muscles.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
    final labels = parts.map((part) {
      return _catalogService.getMuscleLabel(part, isArabic: isArabic) ?? part;
    }).toList();
    return labels.join(', ');
  }

  Widget _buildExerciseThumbnail(Exercise exercise) {
    final resolved = VideoThumbnailResolver.resolve(
      thumbnailUrl: exercise.thumbnailUrl,
      videoUrl: exercise.videoUrl,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 64,
        height: 64,
        child: resolved == null
            ? Container(
                color: const Color(0xFFE8EAF0),
                child: const Icon(
                  Icons.fitness_center,
                  color: Color(0xFF6C6F83),
                  size: 26,
                ),
              )
            : Image.network(
                resolved,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFE8EAF0),
                  child: const Icon(
                    Icons.fitness_center,
                    color: Color(0xFF6C6F83),
                    size: 26,
                  ),
                ),
              ),
      ),
    );
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
            // The button says "Report injury", so ask where the user is hurt.
            // It used to open the exercise-substitute list, which never
            // recorded the injury and only changed the current exercise.
            _showReportInjuryDialog(provider, lang);
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

  /// The body parts an injury can be reported against. These are the parts the
  /// injury-swap data is keyed on, so anything offered here can actually be
  /// acted upon.
  static const List<String> _reportableInjuries = [
    'shoulder',
    'knee',
    'lower_back',
    'neck',
    'ankle',
    'wrist',
    'elbow',
    'hip',
  ];

  Future<void> _showReportInjuryDialog(
    WorkoutProvider provider,
    LanguageProvider lang,
  ) async {
    final selected = <String>{};

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(lang.t('workouts_report_injury_title')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang.t('workouts_report_injury_desc'),
                  style: TextStyle(
                    fontSize: 13,
                    color: context.palette.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                for (final injury in _reportableInjuries)
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: selected.contains(injury),
                    title: Text(lang.t('injury_$injury')),
                    onChanged: (checked) => setDialogState(() {
                      if (checked == true) {
                        selected.add(injury);
                      } else {
                        selected.remove(injury);
                      }
                    }),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(lang.t('cancel')),
            ),
            FilledButton(
              onPressed: selected.isEmpty
                  ? null
                  : () => Navigator.pop(dialogContext, true),
              child: Text(lang.t('workouts_report_injury_submit')),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    final ok = await provider.reportInjury(selected.toList());
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? lang.t('workouts_report_injury_done')
            : provider.error ?? lang.t('workouts_report_injury_failed')),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }

}

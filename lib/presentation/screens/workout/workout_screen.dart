import '../../widgets/aash_backdrop.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/video_thumbnail_resolver.dart';
import '../../../data/models/workout_calendar.dart';
import '../../../data/models/workout_plan.dart';
import '../../../data/models/user_profile.dart';
import '../../providers/language_provider.dart';
import '../../providers/workout_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/animated_reveal.dart';
import '../../widgets/aash_motion.dart';
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
  final ScrollController _exerciseScroll = ScrollController();
  final ScrollController _calendarScroll = ScrollController();

  @override
  void dispose() {
    _exerciseScroll.dispose();
    _calendarScroll.dispose();
    super.dispose();
  }

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
              color: context.palette.primary,
            ),
            const SizedBox(height: 12),
            _buildPromptOption(
              icon: Icons.video_call,
              title: lang.t('intake_prompt_option2_title'),
              description: lang.t('intake_prompt_option2_desc'),
              color: context.palette.textSecondary,
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
                  style: AppTextStyles.caption.copyWith(
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
                      style: AppTextStyles.overline.copyWith(
                        color: AppColors.success,
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
      backgroundColor: context.palette.background,
      appBar: appBar,
      body: AashBackdrop(child: SafeArea(child: child)),
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
                  style: AppTextStyles.small.copyWith(
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
                style: AppTextStyles.h3.copyWith(
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
                style: AppTextStyles.h3.copyWith(
                  color: context.palette.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                languageProvider.t('workout_plan_coming_soon'),
                style: AppTextStyles.small.copyWith(
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
                AnimatedReveal(
                  offset: const Offset(0, -0.2),
                  child: _buildWorkoutHeroHeader(
                    plan,
                    currentDay,
                    languageProvider,
                    completedExercises,
                    totalExercises,
                    workoutProgress,
                    isArabic,
                  ),
                ),
                const SizedBox(height: 14),
                if (currentDay != null && currentDay.exercises.isNotEmpty)
                  _buildExerciseList(
                    currentDay,
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
                const SizedBox(height: 14),
                _buildWorkoutCalendarSections(
                  workoutProvider,
                  languageProvider,
                  isArabic,
                ),
                const SizedBox(height: 14),
                AnimatedReveal(
                  delay: const Duration(milliseconds: 520),
                  offset: const Offset(0, 0.25),
                  child: _buildWorkoutSummaryCard(
                    plan,
                    currentDay,
                    languageProvider,
                    workoutProgress,
                    isArabic,
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
        color: context.palette.surface,
        border: Border.all(color: context.palette.border),
        borderRadius: BorderRadius.circular(AppRadius.xlarge),
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
                icon: Icon(Icons.arrow_back,
                    color: context.palette.textPrimary, size: 18),
                tooltip: lang.t('back'),
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
                    style: AppTextStyles.h1.copyWith(
                      color: context.palette.textPrimary,
                      height: 1.05,
                    ),
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => context.read<WorkoutProvider>().goToCurrentDay(),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: context.palette.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today,
                          size: 14, color: context.palette.textPrimary),
                      const SizedBox(width: 6),
                      Text(
                        lang.t('today'),
                        style: AppTextStyles.small
                            .copyWith(color: context.palette.textPrimary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            [
              '${lang.t('workout_week', args: {
                    'number': '1'
                  })}, ${lang.t('workout_day_label', args: {
                    'number': '$dayNumber'
                  })}',
              if (durationLabel.isNotEmpty) durationLabel,
            ].join('  •  '),
            style: AppTextStyles.smallMedium.copyWith(
              color: context.palette.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedProgressBar(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: context.palette.surfaceVariant,
                    color: AppColors.cyan,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$completedExercises/$totalExercises',
                style: AppTextStyles.small.copyWith(
                  color: context.palette.textSecondary,
                ),
              ),
            ],
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
      color: context.palette.surfaceVariant,
      border: Border.all(color: context.palette.border),
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
                      style: AppTextStyles.caption.copyWith(
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
                  style: AppTextStyles.overline.copyWith(
                    color: context.palette.textSecondary,
                  ),
                ),
              ),
              Text(
                '$percent%',
                style: AppTextStyles.overline.copyWith(
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
              backgroundColor: context.palette.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.center,
            child: Text(
              lang.t('intake_banner_benefits'),
              textAlign: TextAlign.center,
              style: AppTextStyles.overline.copyWith(
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

  int _estimatedKcal(int exercises) {
    final weight = context.read<AuthProvider?>()?.user?.weight;
    final kg = (weight != null && weight > 20) ? weight : 75.0;
    // ~6 min per exercise at MET 5 (resistance training)
    return (exercises * 6 * 5 * 3.5 * kg / 200).round();
  }

  Widget _buildWorkoutSummaryCard(
    WorkoutPlan plan,
    WorkoutDay? currentDay,
    LanguageProvider lang,
    double progress,
    bool isArabic,
  ) {
    final totalExercises = currentDay?.exercises.length ?? 0;
    final provider = context.watch<WorkoutProvider>();
    final completed = currentDay == null
        ? 0
        : currentDay.exercises
            .where((e) => provider.isExerciseCompleted(e.id))
            .length;
    final durationLabel = _estimateWorkoutDuration(currentDay, lang);
    final burned = _estimatedKcal(completed);

    return CustomCard(
      padding: const EdgeInsets.all(16),
      border: Border.all(color: context.palette.border),
      color: context.palette.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedProgressBar(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: context.palette.surfaceVariant,
                    color: AppColors.cyan,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: progress * 100),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => Text(
                  '${v.round()}%',
                  style: AppTextStyles.smallMedium.copyWith(
                    color: context.palette.textPrimary,
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
                  value: '$completed/$totalExercises',
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
                  icon: Icons.local_fire_department_outlined,
                  value: '$burned ${lang.t('kcal_short')}',
                  label: lang.t('workout_calories_burned'),
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

    final entries = <(WorkoutCalendarDayEntry, String?)>[
      if (today != null) (today, lang.t('today')),
      for (final d in previous) (d, null),
      for (final d in upcoming) (d, null),
    ];

    return SizedBox(
      height: 64,
      child: ListView.separated(
        key: const ValueKey('workout-calendar-strip'),
        controller: _calendarScroll,
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (day, label) = entries[i];
          return AnimatedReveal(
            delay: Duration(milliseconds: i < 5 ? 80 * i : 0),
            offset: Offset(isArabic ? -0.4 : 0.4, 0),
            child: ScrollMotionItem(
              controller: _calendarScroll,
              index: i,
              extent: 148,
              minOpacity: 0.75,
              builder: (context, _) => SizedBox(
                width: 140,
                child: _buildCalendarDayCard(
                  day: day,
                  label: label,
                  isToday: label != null,
                  isArabic: isArabic,
                  onTap: () => _openCalendarDay(provider, day),
                ),
              ),
            ),
          );
        },
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
    final percent = day.progressPercent.round();
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isToday
              ? AppColors.cyan.withValues(alpha: 0.12)
              : context.palette.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isToday ? AppColors.cyan : context.palette.border,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.smallMedium
                  .copyWith(color: context.palette.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: AnimatedProgressBar(
                      value: (percent / 100).clamp(0.0, 1.0),
                      minHeight: 5,
                      backgroundColor: context.palette.surfaceVariant,
                      color: AppColors.cyan,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$percent%',
                  style: AppTextStyles.caption
                      .copyWith(color: context.palette.textSecondary),
                ),
              ],
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
        Icon(icon, size: 26, color: context.palette.textSecondary),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: AppTextStyles.h1.copyWith(
                color: context.palette.textPrimary,
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
          style: AppTextStyles.small.copyWith(
            color: context.palette.textSecondary,
            height: 1.1,
          ),
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

  Widget _buildExerciseList(
    WorkoutDay currentDay,
    bool isArabic,
  ) {
    return SizedBox(
      height: 210,
      child: ListView.separated(
        key: const ValueKey('workout-exercise-carousel'),
        controller: _exerciseScroll,
        scrollDirection: Axis.horizontal,
        reverse: isArabic,
        clipBehavior: Clip.none,
        physics: const BouncingScrollPhysics(),
        itemCount: currentDay.exercises.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final exercise = currentDay.exercises[index];
          return AnimatedReveal(
            delay: Duration(milliseconds: index < 4 ? 110 * index : 0),
            offset: Offset(isArabic ? -0.5 : 0.5, 0),
            initialScale: 0.88,
            duration: const Duration(milliseconds: 560),
            child: ScrollMotionItem(
              controller: _exerciseScroll,
              index: index,
              extent: 230,
              builder: (context, delta) => _buildExerciseCard(
                currentDay,
                exercise,
                isArabic,
                index,
                delta,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExerciseCard(
    WorkoutDay currentDay,
    Exercise exercise,
    bool isArabic,
    int index,
    double delta,
  ) {
    final localizedName = isArabic ? exercise.nameAr : exercise.nameEn;
    final name =
        localizedName.trim().isNotEmpty ? localizedName : exercise.name;
    const cardRadius = BorderRadius.all(Radius.circular(22));

    final locked = !context.watch<WorkoutProvider>().isDayStartable(currentDay);

    return PressScale(
      child: SizedBox(
        key: ValueKey('workout-exercise-card-${exercise.id}'),
        width: 218,
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: locked ? 0.7 : 1,
                child: _exerciseCardBody(
                    currentDay, exercise, name, index, delta, cardRadius),
              ),
            ),
            if (locked)
              PositionedDirectional(
                top: 10,
                end: 10,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_rounded,
                      size: 16, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _exerciseCardBody(
    WorkoutDay currentDay,
    Exercise exercise,
    String name,
    int index,
    double delta,
    BorderRadius cardRadius,
  ) {
    return CustomCard(
          padding: EdgeInsets.zero,
          margin: EdgeInsets.zero,
          borderRadius: cardRadius,
          color: context.palette.surface,
          border: Border.all(color: context.palette.border),
          onTap: () => _openExerciseDetail(currentDay, index),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildExerciseThumbnail(
                exercise,
                width: 218,
                height: 132,
                delta: delta,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 12, 8),
                  child: Align(
                    alignment: AlignmentDirectional.topStart,
                    child: Text(
                      name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.palette.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
  }

  Widget _buildExerciseThumbnail(
    Exercise exercise, {
    required double width,
    required double height,
    double delta = 0,
  }) {
    final resolved = VideoThumbnailResolver.resolve(
      thumbnailUrl: exercise.thumbnailUrl,
      videoUrl: exercise.videoUrl,
    );
    Widget placeholder() => ColoredBox(
          color: context.palette.surfaceVariant,
          child: Center(
            child: Icon(
              Icons.fitness_center,
              color: context.palette.textSecondary,
              size: 34,
            ),
          ),
        );

    final Widget image;
    if (resolved == null) {
      image = placeholder();
    } else if (resolved.startsWith('assets/')) {
      image = Image.asset(
        resolved,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder(),
      );
    } else {
      image = Image.network(
        resolved,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder(),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      child: SizedBox(
        width: width,
        height: height,
        child: delta == 0
            ? image
            : ParallaxFill(delta: delta, shift: 18, zoom: 1.14, child: image),
      ),
    );
  }

  void _openExerciseSession(WorkoutDay day, int startIndex) {
    if (!context.read<WorkoutProvider>().isDayStartable(day)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<LanguageProvider>().t('workout_day_locked')),
        ),
      );
      return;
    }
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
                  style: AppTextStyles.caption.copyWith(
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

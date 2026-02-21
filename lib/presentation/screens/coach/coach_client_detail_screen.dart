import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../providers/language_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/coach_provider.dart';
import '../../widgets/custom_card.dart';
import '../../../data/models/coach_client.dart';
import '../../../data/models/workout_plan.dart';
import '../../../data/models/nutrition_plan.dart';
import 'coach_message_thread_screen.dart';
import 'coach_schedule_session_sheet.dart';
import 'coach_workout_plan_viewer_screen.dart';
import 'coach_nutrition_plan_viewer_screen.dart';
import 'workout_plan_editor_screen.dart';
import 'nutrition_plan_editor_screen.dart';

class CoachClientDetailScreen extends StatefulWidget {
  final String clientId;

  const CoachClientDetailScreen({
    super.key,
    required this.clientId,
  });

  @override
  State<CoachClientDetailScreen> createState() =>
      _CoachClientDetailScreenState();
}

class _CoachClientDetailScreenState extends State<CoachClientDetailScreen> {
  WorkoutPlan? _workoutPlan;
  NutritionPlan? _nutritionPlan;
  bool _isPlansLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadClientDetails();
    });
  }

  Future<void> _loadClientDetails() async {
    final authProvider = context.read<AuthProvider>();
    final coachProvider = context.read<CoachProvider>();
    final coachId = authProvider.user?.id;

    if (coachId == null) {
      return;
    }

    await coachProvider.loadClientDetails(
      coachId: coachId,
      clientId: widget.clientId,
    );

    if (!mounted) return;
    await _loadClientPlans(coachId);
  }

  Future<void> _loadClientPlans(String coachId) async {
    setState(() {
      _isPlansLoading = true;
    });
    final coachProvider = context.read<CoachProvider>();
    final workout =
        await coachProvider.getClientWorkoutPlan(coachId, widget.clientId);
    final nutrition =
        await coachProvider.getClientNutritionPlan(coachId, widget.clientId);
    if (!mounted) return;
    setState(() {
      _workoutPlan = workout;
      _nutritionPlan = nutrition;
      _isPlansLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final authProvider = context.watch<AuthProvider>();
    final coachProvider = context.watch<CoachProvider>();
    final client = coachProvider.selectedClient;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          client?.fullName ?? languageProvider.t('coach_client_detail_title'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadClientDetails,
          ),
        ],
      ),
      body: coachProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : coachProvider.error != null || client == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        coachProvider.error ??
                            languageProvider.t('coach_client_detail_load_failed'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.error),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadClientDetails,
                        child: Text(languageProvider.t('retry')),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadClientDetails,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Client header
                        _buildClientHeader(client, languageProvider),
                        const SizedBox(height: 16),
                        _buildClientActions(client, languageProvider),

                        const SizedBox(height: 24),

                        // Fitness score section
                        _buildFitnessScoreSection(
                          client,
                          authProvider,
                          languageProvider,
                        ),

                        const SizedBox(height: 16),

                        // Plans section
                        _buildPlansSection(
                            client, languageProvider, authProvider),

                        const SizedBox(height: 16),

                        // Progress mirror
                        _buildProgressMirrorSection(client, languageProvider),

                        const SizedBox(height: 16),

                        // Activity section
                        _buildActivitySection(client, languageProvider),

                        const SizedBox(height: 16),

                        // Contact section
                        _buildContactSection(client, languageProvider),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildClientHeader(client, LanguageProvider lang) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: client.profilePhotoUrl != null
                  ? NetworkImage(client.profilePhotoUrl!)
                  : null,
              child: client.profilePhotoUrl == null
                  ? Text(
                      client.initials,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                    )
                  : null,
            ),

            const SizedBox(height: 16),

            Text(
              client.fullName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Badges
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                // Subscription tier
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getTierColor(client.subscriptionTier),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    client.subscriptionTier,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Status
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(client.statusText),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    client.statusText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            if (client.goal != null) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.flag,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    client.goal!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildClientActions(client, LanguageProvider lang) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.chat_bubble_outline),
            label: Text(lang.t('coach_message_client')),
            onPressed: () => _openMessageThread(client),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.video_call),
            label: Text(lang.t('coach_schedule_call')),
            onPressed: () => _openScheduleSheet(client),
          ),
        ),
      ],
    );
  }

  void _openMessageThread(client) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CoachMessageThreadScreen(
          clientId: client.id,
          clientName: client.fullName,
        ),
      ),
    );
  }

  Future<void> _openScheduleSheet(client) {
    return showCoachScheduleSessionSheet(
      context,
      clientId: client.id,
      clientName: client.fullName,
    );
  }

  Widget _buildFitnessScoreSection(
    client,
    AuthProvider authProvider,
    LanguageProvider lang,
  ) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  lang.t('coach_fitness_score'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () =>
                      _showAssignScoreDialog(authProvider, lang),
                  icon: const Icon(Icons.edit, size: 16),
                  label: Text(lang.t('coach_edit')),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: client.fitnessScore != null
                      ? _getScoreColor(client.fitnessScore!)
                      : AppColors.textDisabled,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        client.fitnessScore?.toString() ?? '--',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textWhite,
                        ),
                      ),
                      Text(
                        lang.t('coach_out_of_100'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textWhite,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlansSection(
      client, LanguageProvider lang, AuthProvider authProvider) {
    final coachId = authProvider.user?.id;
    final workoutProgress = _calculateWorkoutProgress(_workoutPlan);
    final nutritionProgress = _calculateNutritionProgress(_nutritionPlan);

    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang.t('coach_assigned_plans_title'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_isPlansLoading)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: const CircularProgressIndicator(),
                ),
              )
            else ...[
              _buildPlanEntry(
                lang: lang,
                icon: Icons.fitness_center,
                color: AppColors.primary,
                title: lang.t('coach_workout_plan_title'),
                assignedName: client.workoutPlanName,
                progress: workoutProgress,
                onView: _workoutPlan != null
                    ? () => _openWorkoutViewer(client.fullName)
                    : null,
                onEdit:
                    coachId != null ? () => _openWorkoutEditor(coachId) : null,
              ),
              const Divider(),
              _buildPlanEntry(
                lang: lang,
                icon: Icons.restaurant,
                color: AppColors.success,
                title: lang.t('coach_nutrition_plan_title'),
                assignedName: client.nutritionPlanName,
                progress: nutritionProgress,
                onView: _nutritionPlan != null
                    ? () => _openNutritionViewer(client.fullName)
                    : null,
                onEdit: coachId != null
                    ? () => _openNutritionEditor(coachId)
                    : null,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlanEntry({
    required LanguageProvider lang,
    required IconData icon,
    required Color color,
    required String title,
    required String? assignedName,
    required double? progress,
    VoidCallback? onView,
    VoidCallback? onEdit,
  }) {
    final planName = assignedName ?? lang.t('coach_plan_not_assigned');
    final hasProgress = progress != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    planName,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  if (hasProgress) ...[
                    LinearProgressIndicator(
                      value: progress.clamp(0, 1),
                      minHeight: 6,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(progress * 100).round()}% ${lang.t('complete')}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ] else
                    Text(
                      lang.t('coach_no_progress_yet'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.remove_red_eye_outlined),
                label: Text(lang.t('coach_view_plan')),
                onPressed: onView,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit),
                label: Text(lang.t('coach_edit_plan')),
                onPressed: onEdit,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressMirrorSection(
    CoachClient client,
    LanguageProvider lang,
  ) {
    final snapshot = _buildProgressSnapshot(client);
    if (snapshot == null) {
      return const SizedBox.shrink();
    }

    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  lang.t('coach_progress_mirror_title'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _openProgressPeekSheet(snapshot, lang),
                  icon: const Icon(Icons.timeline, size: 16),
                  label: Text(lang.t('coach_timeline')),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildProgressStatTile(
                    title: lang.t('coach_workout_adherence'),
                    value: snapshot.workoutCompletion,
                    icon: Icons.fitness_center,
                    color: AppColors.primary,
                    lang: lang,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildProgressStatTile(
                    title: lang.t('coach_nutrition_adherence'),
                    value: snapshot.nutritionCompletion,
                    icon: Icons.restaurant,
                    color: AppColors.success,
                    lang: lang,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStreakPill(snapshot.streakDays, lang),
            const SizedBox(height: 16),
            _buildTrendStrip(
              title: lang.t('coach_training_days'),
              color: AppColors.primary,
              points: snapshot.workoutTrend,
              lang: lang,
            ),
            const SizedBox(height: 12),
            _buildTrendStrip(
              title: lang.t('coach_nutrition_days'),
              color: AppColors.success,
              points: snapshot.nutritionTrend,
              lang: lang,
            ),
            const SizedBox(height: 16),
            _buildFlagWrap(snapshot.flags, lang),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStatTile({
    required String title,
    required double? value,
    required IconData icon,
    required Color color,
    required LanguageProvider lang,
  }) {
    final display = value != null ? '${(value * 100).round()}%' : '--';
    final subtitle = value != null
        ? (value >= 0.7
            ? lang.t('coach_on_track')
            : lang.t('coach_needs_focus'))
        : lang.t('coach_no_data_yet');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            display,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: value?.clamp(0, 1) ?? 0,
            minHeight: 5,
            color: color,
            backgroundColor: AppColors.surface,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendStrip({
    required String title,
    required Color color,
    required List<_TrendPoint> points,
    required LanguageProvider lang,
  }) {
    if (points.isEmpty) {
      return Text(
        lang.t('coach_no_timeline_captured'),
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: points.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final point = points[index];
              return Container(
                width: 96,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      point.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: point.value.clamp(0, 1),
                        minHeight: 5,
                        color: color,
                        backgroundColor: AppColors.surface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(point.value * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStreakPill(int streak, LanguageProvider lang) {
    final label = streak > 0
        ? lang.t('coach_day_streak', args: {'days': '$streak'})
        : lang.t('coach_no_active_streak');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department, color: AppColors.accent),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlagWrap(Set<_ProgressFlag> flags, LanguageProvider lang) {
    if (flags.isEmpty) {
      return Text(
        lang.t('coach_all_on_track'),
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: flags
          .map(
            (flag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _flagLabel(flag, lang),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  void _openProgressPeekSheet(
    _ClientProgressSnapshot snapshot,
    LanguageProvider lang,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => CoachProgressPeekSheet(
        snapshot: snapshot,
        lang: lang,
      ),
    );
  }

  _ClientProgressSnapshot? _buildProgressSnapshot(CoachClient client) {
    final workoutTrend = _workoutPlan?.days
            ?.map(
              (day) => _TrendPoint(
                label: day.dayName,
                value: day.exercises.isEmpty
                    ? 0
                    : day.exercises
                            .where((exercise) => exercise.isCompleted)
                            .length /
                        day.exercises.length,
                order: day.dayNumber,
              ),
            )
            .toList() ??
        <_TrendPoint>[];

    final nutritionTrend = _nutritionPlan?.days
            ?.map(
              (day) => _TrendPoint(
                label: day.dayName,
                value: day.meals.isEmpty
                    ? 0
                    : day.meals.where((meal) => meal.completed).length /
                        day.meals.length,
                order: day.dayNumber,
              ),
            )
            .toList() ??
        <_TrendPoint>[];

    final workoutCompletion = _calculateWorkoutProgress(_workoutPlan);
    final nutritionCompletion = _calculateNutritionProgress(_nutritionPlan);

    if (workoutCompletion == null &&
        nutritionCompletion == null &&
        workoutTrend.isEmpty &&
        nutritionTrend.isEmpty) {
      return null;
    }

    final flags = <_ProgressFlag>{};
    if (workoutCompletion != null && workoutCompletion < 0.6) {
      flags.add(_ProgressFlag.lowWorkout);
    }
    if (nutritionCompletion != null && nutritionCompletion < 0.6) {
      flags.add(_ProgressFlag.lowNutrition);
    }
    final lastActivity = client.lastActivity;
    if (lastActivity == null ||
        DateTime.now().difference(lastActivity).inDays > 5) {
      flags.add(_ProgressFlag.inactive);
    }

    final streak = _calculateAdherenceStreak(workoutTrend, nutritionTrend);

    return _ClientProgressSnapshot(
      workoutCompletion: workoutCompletion,
      nutritionCompletion: nutritionCompletion,
      workoutTrend: workoutTrend,
      nutritionTrend: nutritionTrend,
      streakDays: streak,
      flags: flags,
    );
  }

  int _calculateAdherenceStreak(
    List<_TrendPoint> workoutTrend,
    List<_TrendPoint> nutritionTrend,
  ) {
    final orderedWorkout = [...workoutTrend]
      ..sort((a, b) => a.order.compareTo(b.order));
    if (orderedWorkout.isNotEmpty) {
      return _streakFromPoints(orderedWorkout);
    }
    final orderedNutrition = [...nutritionTrend]
      ..sort((a, b) => a.order.compareTo(b.order));
    return _streakFromPoints(orderedNutrition);
  }

  int _streakFromPoints(List<_TrendPoint> points) {
    int streak = 0;
    for (final point in points.reversed) {
      if (point.value >= 0.7) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  String _flagLabel(_ProgressFlag flag, LanguageProvider lang) {
    switch (flag) {
      case _ProgressFlag.lowWorkout:
        return lang.t('coach_low_workout_adherence');
      case _ProgressFlag.lowNutrition:
        return lang.t('coach_low_nutrition_adherence');
      case _ProgressFlag.inactive:
        return lang.t('coach_needs_new_activity');
    }
  }

  Widget _buildActivitySection(client, LanguageProvider lang) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang.t('coach_activity_title'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // Assigned date
            if (client.assignedDate != null)
              _buildInfoRow(
                icon: Icons.calendar_today,
                label: lang.t('coach_assigned_date'),
                value: _formatDate(client.assignedDate!),
              ),

            const SizedBox(height: 12),

            // Last activity
            if (client.lastActivity != null)
              _buildInfoRow(
                icon: Icons.access_time,
                label: lang.t('coach_last_activity'),
                value: _formatDate(client.lastActivity!),
              ),

            const SizedBox(height: 12),

            // Message count
            _buildInfoRow(
              icon: Icons.message,
              label: lang.t('messages'),
              value: '${client.messageCount}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection(client, LanguageProvider lang) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang.t('coach_contact_information'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // Email
            if (client.email != null)
              _buildInfoRow(
                icon: Icons.email,
                label: lang.t('email'),
                value: client.email!,
              ),

            if (client.email != null && client.phoneNumber != null)
              const SizedBox(height: 12),

            // Phone
            if (client.phoneNumber != null)
              _buildInfoRow(
                icon: Icons.phone,
                label: lang.t('coach_phone_label'),
                value: client.phoneNumber!,
              ),
          ],
        ),
      ),
    );
  }

  double? _calculateWorkoutProgress(WorkoutPlan? plan) {
    if (plan?.days == null || plan!.days!.isEmpty) return null;
    final totalExercises =
        plan.days!.fold<int>(0, (sum, day) => sum + day.exercises.length);
    if (totalExercises == 0) return null;
    final completedExercises = plan.days!.fold<int>(
        0,
        (sum, day) =>
            sum +
            day.exercises.where((exercise) => exercise.isCompleted).length);
    return completedExercises / totalExercises;
  }

  double? _calculateNutritionProgress(NutritionPlan? plan) {
    final meals = plan?.meals;
    if (meals == null || meals.isEmpty) return null;
    final completed = meals.where((meal) => meal.completed).length;
    return completed / meals.length;
  }

  Future<void> _openWorkoutEditor(String coachId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkoutPlanEditorScreen(
          clientId: widget.clientId,
          coachId: coachId,
        ),
      ),
    );
    if (mounted) {
      _loadClientDetails();
    }
  }

  Future<void> _openNutritionEditor(String coachId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NutritionPlanEditorScreen(
          clientId: widget.clientId,
          coachId: coachId,
        ),
      ),
    );
    if (mounted) {
      _loadClientDetails();
    }
  }

  Future<void> _openWorkoutViewer(String clientName) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CoachWorkoutPlanViewerScreen(
          clientId: widget.clientId,
          clientName: clientName,
        ),
      ),
    );
    final coachId = context.read<AuthProvider>().user?.id;
    if (coachId != null) {
      await _loadClientPlans(coachId);
    }
  }

  Future<void> _openNutritionViewer(String clientName) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CoachNutritionPlanViewerScreen(
          clientId: widget.clientId,
          clientName: clientName,
        ),
      ),
    );
    final coachId = context.read<AuthProvider>().user?.id;
    if (coachId != null) {
      await _loadClientPlans(coachId);
    }
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAssignScoreDialog(AuthProvider authProvider, LanguageProvider lang) {
    final coachProvider = context.read<CoachProvider>();
    final client = coachProvider.selectedClient;
    if (client == null) return;

    int score = client.fitnessScore ?? 50;
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title:
              Text(lang.t('coach_assign_fitness_score')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: _getScoreColor(score),
                ),
              ),
              Slider(
                value: score.toDouble(),
                min: 0,
                max: 100,
                divisions: 100,
                label: score.toString(),
                onChanged: (value) {
                  setState(() {
                    score = value.round();
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: InputDecoration(
                  labelText: lang.t('coach_notes_optional'),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(lang.t('auth_cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);

                final success = await coachProvider.assignFitnessScore(
                  coachId: authProvider.user!.id,
                  clientId: client.id,
                  fitnessScore: score,
                  notes: notesController.text.isNotEmpty
                      ? notesController.text
                      : null,
                );

                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(lang.t('coach_assign_fitness_score_success')),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text(coachProvider.error ?? lang.t('coach_assign_fitness_score_failed')),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              child: Text(lang.t('coach_assign')),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'smart premium':
        return AppColors.accent;
      case 'premium':
        return AppColors.primary;
      case 'freemium':
      default:
        return AppColors.textSecondary;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppColors.success;
      case 'recent':
        return AppColors.warning;
      case 'inactive':
        return AppColors.error;
      case 'new':
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.warning;
    return AppColors.error;
  }
}

class _ClientProgressSnapshot {
  final double? workoutCompletion;
  final double? nutritionCompletion;
  final List<_TrendPoint> workoutTrend;
  final List<_TrendPoint> nutritionTrend;
  final int streakDays;
  final Set<_ProgressFlag> flags;

  const _ClientProgressSnapshot({
    required this.workoutCompletion,
    required this.nutritionCompletion,
    required this.workoutTrend,
    required this.nutritionTrend,
    required this.streakDays,
    required this.flags,
  });
}

class _TrendPoint {
  final String label;
  final double value;
  final int order;

  const _TrendPoint({
    required this.label,
    required this.value,
    required this.order,
  });
}

enum _ProgressFlag {
  lowWorkout,
  lowNutrition,
  inactive,
}

class CoachProgressPeekSheet extends StatelessWidget {
  final _ClientProgressSnapshot snapshot;
  final LanguageProvider lang;

  const CoachProgressPeekSheet({
    super.key,
    required this.snapshot,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              lang.t('coach_progress_timeline_title'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              lang.t('coach_progress_timeline_subtitle'),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _PeekStatTile(
                    label: lang.t('coach_workouts_label'),
                    value: snapshot.workoutCompletion,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PeekStatTile(
                    label: lang.t('coach_nutrition_label'),
                    value: snapshot.nutritionCompletion,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildPeekTimeline(
              title: lang.t('coach_workout_log'),
              points: snapshot.workoutTrend,
              color: AppColors.primary,
            ),
            const SizedBox(height: 20),
            _buildPeekTimeline(
              title: lang.t('coach_nutrition_log'),
              points: snapshot.nutritionTrend,
              color: AppColors.success,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeekTimeline({
    required String title,
    required List<_TrendPoint> points,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        if (points.isEmpty)
          Text(
            lang.t('coach_no_entries_captured'),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          )
        else
          ...points.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      point.label,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 160,
                    child: LinearProgressIndicator(
                      value: point.value.clamp(0, 1),
                      minHeight: 6,
                      color: color,
                      backgroundColor: AppColors.surface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${(point.value * 100).round()}%'),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _PeekStatTile extends StatelessWidget {
  final String label;
  final double? value;
  final Color color;

  const _PeekStatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final display = value != null ? '${(value! * 100).round()}%' : '--';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            display,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: value?.clamp(0, 1) ?? 0,
            minHeight: 5,
            color: color,
            backgroundColor: AppColors.surface,
          ),
        ],
      ),
    );
  }
}

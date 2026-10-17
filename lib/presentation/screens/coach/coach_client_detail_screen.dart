import '../../widgets/aash_backdrop.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../providers/language_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/coach_provider.dart';
import '../../widgets/custom_card.dart';
import '../../../data/models/coach_client.dart';
import '../../../data/models/coach_client_checkin.dart';
import '../../../data/models/workout_plan.dart';
import '../../../data/models/nutrition_plan.dart';
import 'coach_message_thread_screen.dart';
import 'coach_schedule_session_sheet.dart';
import 'coach_workout_plan_viewer_screen.dart';
import 'coach_nutrition_plan_viewer_screen.dart';
import 'workout_plan_editor_screen.dart';
import 'nutrition_plan_editor_screen.dart';
import '../../../core/theme/app_palette.dart';

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

class _CoachClientDetailScreenState extends State<CoachClientDetailScreen>
    with WidgetsBindingObserver {
  WorkoutPlan? _workoutPlan;
  NutritionPlan? _nutritionPlan;
  bool _isPlansLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadClientDetails();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _loadClientDetails();
    }
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
    final lang = context.watch<LanguageProvider>();
    final authProvider = context.watch<AuthProvider>();
    final coachProvider = context.watch<CoachProvider>();
    final client = coachProvider.selectedClient;
    final checkIns = coachProvider.clientCheckIns;
    final latestCheckIn = coachProvider.latestClientCheckIn;

    return AashScaffold(
      appBar: AppBar(
        title: Text(
          client?.fullName ?? lang.t('coach_client_detail_title'),
        ),
        actions: [
          IconButton(
            tooltip: lang.t('refresh'),
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
                            lang.t('coach_client_detail_load_failed'),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: context.palette.error),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadClientDetails,
                        child: Text(lang.t('retry')),
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
                        _buildClientHeader(client, lang),
                        const SizedBox(height: 16),
                        _buildClientActions(client, lang),

                        const SizedBox(height: 24),

                        // Fitness score section
                        _buildFitnessScoreSection(
                          client,
                          authProvider,
                          lang,
                        ),

                        const SizedBox(height: 16),

                        // Plans section
                        _buildPlansSection(client, lang, authProvider),

                        const SizedBox(height: 16),

                        // Check-in timeline
                        _buildCheckInTimelineSection(
                          client,
                          checkIns,
                          lang,
                        ),

                        const SizedBox(height: 16),

                        // Activity section
                        _buildActivitySection(client, lang),

                        const SizedBox(height: 16),

                        // Latest check-in section
                        _buildLatestCheckInSection(
                          client,
                          latestCheckIn,
                          lang,
                        ),

                        const SizedBox(height: 16),

                        // Contact section
                        _buildContactSection(client, lang),
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
              backgroundColor: context.palette.primary.withValues(alpha: 0.1),
              backgroundImage: client.profilePhotoUrl != null
                  ? NetworkImage(client.profilePhotoUrl!)
                  : null,
              child: client.profilePhotoUrl == null
                  ? Text(
                      client.initials,
                      style: TextStyle(
                        color: context.palette.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                    )
                  : null,
            ),

            const SizedBox(height: 16),

            Text(
              client.fullName,
              style: AppTextStyles.h1,
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
                    color: _getTierColor(client.subscriptionTier)
                        .withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(AppRadius.large),
                  ),
                  child: Text(
                    client.subscriptionTier,
                    style: TextStyle(
                      fontSize: 12,
                      color: _getTierColor(client.subscriptionTier),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Status
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(client.statusText)
                        .withValues(alpha: 0.12),
                    border: Border.all(
                      color: _getStatusColor(client.statusText)
                          .withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.large),
                  ),
                  child: Text(
                    client.statusText,
                    style: TextStyle(
                      fontSize: 12,
                      color: _getStatusColor(client.statusText),
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
                  Icon(Icons.flag,
                      size: 16, color: context.palette.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    client.goal!,
                    style: TextStyle(
                      fontSize: 14,
                      color: context.palette.textSecondary,
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
                  style: AppTextStyles.h3,
                ),
                TextButton.icon(
                  onPressed: () => _showAssignScoreDialog(authProvider, lang),
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
                          .withValues(alpha: 0.15)
                      : context.palette.surfaceVariant,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        client.fitnessScore?.toString() ?? '--',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: client.fitnessScore != null
                              ? _getScoreColor(client.fitnessScore!)
                              : context.palette.textSecondary,
                        ),
                      ),
                      Text(
                        lang.t('coach_out_of_100'),
                        style: TextStyle(
                          fontSize: 12,
                          color: context.palette.textSecondary,
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
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: 12),
            if (_isPlansLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              _buildPlanEntry(
                lang: lang,
                icon: Icons.fitness_center,
                color: context.palette.primary,
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
                borderRadius: BorderRadius.circular(AppRadius.medium),
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
                    style: TextStyle(color: context.palette.textSecondary),
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
                      style: TextStyle(
                        fontSize: 12,
                        color: context.palette.textSecondary,
                      ),
                    ),
                  ] else
                    Text(
                      lang.t('coach_no_progress_yet'),
                      style: TextStyle(
                        fontSize: 12,
                        color: context.palette.textSecondary,
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

  Widget _buildCheckInTimelineSection(
    CoachClient client,
    List<CoachClientCheckIn> checkIns,
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
                  lang.t('coach_client_detail_check_in_timeline'),
                  style: AppTextStyles.h3,
                ),
                if (checkIns.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: context.palette.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      '${checkIns.length}',
                      style: TextStyle(
                        color: context.palette.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              lang.t(
                  'coach_client_detail_every_client_check_in_including_inbody'),
              style: TextStyle(
                fontSize: 13,
                color: context.palette.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            if (checkIns.isEmpty)
              _buildCheckInEmptyState(lang)
            else
              ...checkIns.map((checkIn) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildCheckInCard(client, checkIn, lang),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckInEmptyState(LanguageProvider lang) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: context.palette.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.timeline_outlined,
            size: 40,
            color: context.palette.textDisabled,
          ),
          const SizedBox(height: 12),
          Text(
            lang.t('coach_client_detail_no_check_ins_yet'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            lang.t(
                'coach_client_detail_inbody_progress_and_intake_events_will'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: context.palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckInCard(
    CoachClient client,
    CoachClientCheckIn checkIn,
    LanguageProvider lang,
  ) {
    final metrics = _buildMetricPills(checkIn.metrics, lang);
    final changes = _buildChangeChips(checkIn.changes, lang);
    final contextRows = _buildIntakeContextRows(checkIn.context, lang);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: context.palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:
                      _checkInTypeColor(checkIn.type).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                child: Icon(
                  _checkInTypeIcon(checkIn.type),
                  color: _checkInTypeColor(checkIn.type),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      checkIn.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDateTime(checkIn.occurredAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: context.palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color:
                      _checkInTypeColor(checkIn.type).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  _checkInTypeLabel(checkIn, lang),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _checkInTypeColor(checkIn.type),
                  ),
                ),
              ),
            ],
          ),
          if (metrics.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: metrics),
          ],
          if (changes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: changes),
          ],
          if (checkIn.notes != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.palette.surface,
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              child: Text(
                checkIn.notes!,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
          if (contextRows.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...contextRows,
          ],
        ],
      ),
    );
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
              style: AppTextStyles.h3,
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

  Widget _buildLatestCheckInSection(
    CoachClient client,
    CoachClientCheckIn? latestCheckIn,
    LanguageProvider lang,
  ) {
    final snapshot = latestCheckIn;
    final rows = <Widget>[];
    final metrics = snapshot?.metrics;

    if (snapshot != null) {
      rows.add(
        _buildInfoRow(
          icon: Icons.event_available,
          label: lang.t('coach_client_detail_latest_check_in'),
          value: _formatDateTime(snapshot.occurredAt),
        ),
      );
      rows.add(const SizedBox(height: 12));
      rows.add(
        _buildInfoRow(
          icon: _checkInTypeIcon(snapshot.type),
          label: lang.t('coach_client_detail_type'),
          value: snapshot.title,
        ),
      );
    }

    if (metrics?.weight != null) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 12));
      rows.add(
        _buildInfoRow(
          icon: Icons.scale_outlined,
          label: lang.t('weight'),
          value: '${metrics!.weight!.toStringAsFixed(1)} kg',
        ),
      );
    }
    if (metrics?.bodyFatPercentage != null) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 12));
      rows.add(
        _buildInfoRow(
          icon: Icons.percent,
          label: lang.t('coach_client_detail_body_fat'),
          value: '${metrics!.bodyFatPercentage!.toStringAsFixed(1)}%',
        ),
      );
    }
    if (metrics?.skeletalMuscleMass != null) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 12));
      rows.add(
        _buildInfoRow(
          icon: Icons.fitness_center,
          label: lang.t('coach_client_detail_skeletal_muscle_mass'),
          value: '${metrics!.skeletalMuscleMass!.toStringAsFixed(1)} kg',
        ),
      );
    }
    if (metrics?.bmi != null) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 12));
      rows.add(
        _buildInfoRow(
          icon: Icons.monitor_weight_outlined,
          label: 'BMI',
          value: metrics!.bmi!.toStringAsFixed(1),
        ),
      );
    }

    if (rows.isEmpty && client.lastActivity != null) {
      rows.add(
        _buildInfoRow(
          icon: Icons.event_available,
          label: lang.t('coach_client_detail_latest_check_in'),
          value: _formatDateTime(client.lastActivity!),
        ),
      );
    }

    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang.t('coach_client_detail_latest_check_in_snapshot'),
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: 16),
            ...rows,
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
              style: AppTextStyles.h3,
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
    final coachId = context.read<AuthProvider>().user?.id;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CoachWorkoutPlanViewerScreen(
          clientId: widget.clientId,
          clientName: clientName,
        ),
      ),
    );
    if (!mounted) return;
    if (coachId != null) {
      await _loadClientPlans(coachId);
    }
  }

  Future<void> _openNutritionViewer(String clientName) async {
    final coachId = context.read<AuthProvider>().user?.id;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CoachNutritionPlanViewerScreen(
          clientId: widget.clientId,
          clientName: clientName,
        ),
      ),
    );
    if (!mounted) return;
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
        Icon(icon, size: 20, color: context.palette.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: context.palette.textSecondary,
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

  List<Widget> _buildMetricPills(
    CoachClientCheckInMetrics? metrics,
    LanguageProvider lang,
  ) {
    if (metrics == null || !metrics.hasValues) {
      return const [];
    }
    final items = <Widget>[];
    void add(String label, String value) {
      items.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: context.palette.surface,
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          child: Text(
            '$label: $value',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    if (metrics.weight != null) {
      add(lang.t('weight'), '${metrics.weight!.toStringAsFixed(1)} kg');
    }
    if (metrics.bodyFatPercentage != null) {
      add(lang.t('progress_body_fat'),
          '${metrics.bodyFatPercentage!.toStringAsFixed(1)}%');
    }
    if (metrics.skeletalMuscleMass != null) {
      add(lang.t('coach_client_detail_muscle'),
          '${metrics.skeletalMuscleMass!.toStringAsFixed(1)} kg');
    }
    if (metrics.bmi != null) {
      add('BMI', metrics.bmi!.toStringAsFixed(1));
    }
    if (metrics.waist != null) {
      add(lang.t('progress_waist'), '${metrics.waist!.toStringAsFixed(1)} cm');
    }
    if (metrics.chest != null) {
      add(lang.t('progress_chest'), '${metrics.chest!.toStringAsFixed(1)} cm');
    }
    if (metrics.hips != null) {
      add(lang.t('progress_hips'), '${metrics.hips!.toStringAsFixed(1)} cm');
    }
    return items;
  }

  List<Widget> _buildChangeChips(
    CoachClientCheckInChanges? changes,
    LanguageProvider lang,
  ) {
    if (changes == null || !changes.hasValues) {
      return const [];
    }
    final items = <Widget>[];
    void add(String label, double value, String suffix) {
      final positive = value > 0;
      final color = positive ? AppColors.success : AppColors.error;
      final sign = positive ? '+' : '';
      items.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            '$label: $sign${value.toStringAsFixed(1)}$suffix',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      );
    }

    if (changes.weight != null) {
      add(lang.t('weight'), changes.weight!, ' kg');
    }
    if (changes.bodyFatPercentage != null) {
      add(lang.t('progress_body_fat'), changes.bodyFatPercentage!, '%');
    }
    if (changes.skeletalMuscleMass != null) {
      add(lang.t('coach_client_detail_muscle'), changes.skeletalMuscleMass!,
          ' kg');
    }
    if (changes.bmi != null) {
      add('BMI', changes.bmi!, '');
    }
    if (changes.waist != null) {
      add(lang.t('progress_waist'), changes.waist!, ' cm');
    }
    if (changes.chest != null) {
      add(lang.t('progress_chest'), changes.chest!, ' cm');
    }
    if (changes.hips != null) {
      add(lang.t('progress_hips'), changes.hips!, ' cm');
    }
    return items;
  }

  List<Widget> _buildIntakeContextRows(
    Map<String, dynamic>? context,
    LanguageProvider lang,
  ) {
    if (context == null || context.isEmpty) {
      return const [];
    }
    final rows = <Widget>[];

    void addRow(String label, dynamic value) {
      if (value == null) return;
      final text = value.toString().trim();
      if (text.isEmpty) return;
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 8));
      rows.add(
        _buildInfoRow(
          icon: Icons.subdirectory_arrow_right,
          label: label,
          value: text,
        ),
      );
    }

    addRow(lang.t('coach_client_detail_primary_goal'),
        context['primaryGoal'] ?? context['primary_goal']);
    addRow(lang.t('coach_client_detail_workout_location'),
        context['workoutLocation'] ?? context['workout_location']);
    addRow(lang.t('coach_client_detail_training_days_week'),
        context['trainingDaysPerWeek'] ?? context['training_days_per_week']);
    addRow(lang.t('coach_client_detail_experience_level'),
        context['experienceLevel'] ?? context['experience_level']);
    return rows;
  }

  IconData _checkInTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'inbody':
        return Icons.monitor_weight_outlined;
      case 'progress':
        return Icons.query_stats;
      case 'intake':
        return Icons.fact_check_outlined;
      default:
        return Icons.event_note_outlined;
    }
  }

  Color _checkInTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'inbody':
        return context.palette.primary;
      case 'progress':
        return AppColors.cyan;
      case 'intake':
        return AppColors.gold;
      default:
        return context.palette.textSecondary;
    }
  }

  String _checkInTypeLabel(CoachClientCheckIn checkIn, LanguageProvider lang) {
    switch (checkIn.type.toLowerCase()) {
      case 'inbody':
        return lang.t('coach_client_detail_inbody');
      case 'progress':
        return lang.t('coach_client_detail_progress');
      case 'intake':
        if (checkIn.stage == 'full') {
          return lang.t('coach_client_detail_full_intake');
        }
        return lang.t('coach_client_detail_intake');
      default:
        return checkIn.type;
    }
  }

  String _formatDateTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.day}/${date.month}/${date.year} • $hour:$minute $period';
  }

  void _showAssignScoreDialog(
      AuthProvider authProvider, LanguageProvider lang) {
    final coachProvider = context.read<CoachProvider>();
    final client = coachProvider.selectedClient;
    if (client == null) return;

    int score = client.fitnessScore ?? 50;
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(lang.t('coach_assign_fitness_score')),
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
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(context);

                final success = await coachProvider.assignFitnessScore(
                  coachId: authProvider.user!.id,
                  clientId: client.id,
                  fitnessScore: score,
                  notes: notesController.text.isNotEmpty
                      ? notesController.text
                      : null,
                );

                if (!mounted) return;

                if (success) {
                  messenger.showSnackBar(
                    SnackBar(
                      content:
                          Text(lang.t('coach_assign_fitness_score_success')),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } else {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(coachProvider.error ??
                          lang.t('coach_assign_fitness_score_failed')),
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
        return AppColors.gold;
      case 'premium':
        return context.palette.primary;
      case 'freemium':
      default:
        return context.palette.textSecondary;
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
        return AppColors.cyan;
      default:
        return context.palette.textSecondary;
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.warning;
    return AppColors.error;
  }
}

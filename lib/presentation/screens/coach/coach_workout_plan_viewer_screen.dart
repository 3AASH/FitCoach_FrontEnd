import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../data/models/workout_plan.dart';
import '../../providers/auth_provider.dart';
import '../../providers/coach_provider.dart';
import '../../providers/language_provider.dart';
import 'workout_plan_editor_screen.dart';

class CoachWorkoutPlanViewerScreen extends StatefulWidget {
  final String clientId;
  final String clientName;

  const CoachWorkoutPlanViewerScreen({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  @override
  State<CoachWorkoutPlanViewerScreen> createState() =>
      _CoachWorkoutPlanViewerScreenState();
}

class _CoachWorkoutPlanViewerScreenState
    extends State<CoachWorkoutPlanViewerScreen> {
  WorkoutPlan? _plan;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPlan());
  }

  Future<void> _loadPlan() async {
    final coachProvider = context.read<CoachProvider>();
    final auth = context.read<AuthProvider>();
    final coachId = auth.user?.id;
    if (coachId == null) {
      setState(() {
        _error = context.read<LanguageProvider>().t('coach_missing_coach_info');
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final plan = await coachProvider.getClientWorkoutPlan(
      coachId,
      widget.clientId,
    );

    if (!mounted) return;
    setState(() {
      _plan = plan;
      _isLoading = false;
      _error = plan == null
          ? context.read<LanguageProvider>().t('coach_workout_plan_missing')
          : null;
    });
  }

  double _calculateProgress(WorkoutPlan plan) {
    final days = plan.days ?? [];
    final totalExercises = days.fold<int>(
      0,
      (acc, day) => acc + day.exercises.length,
    );
    if (totalExercises == 0) return 0;
    final completed = days.fold<int>(
      0,
      (acc, day) => acc + day.exercises.where((ex) => ex.isCompleted).length,
    );
    return completed / totalExercises;
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.t('coach_workout_plan_title')),
        actions: [
          if (_plan != null)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: lang.t('coach_edit_plan'),
              onPressed: () => _openEditor(),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _plan == null
              ? _buildEmptyState(lang)
              : RefreshIndicator(
                  onRefresh: _loadPlan,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSummaryCard(lang, _plan!),
                      const SizedBox(height: 16),
                      ..._buildDayCards(lang, _plan!),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummaryCard(LanguageProvider lang, WorkoutPlan plan) {
    final isArabic = lang.isArabic;
    final progress = _calculateProgress(plan);
    final totalDays = plan.days?.length ?? 0;
    final totalExercises = plan.days?.fold<int>(
          0,
          (acc, day) => acc + day.exercises.length,
        ) ??
        0;
    final dateFormat = DateFormat('MMM d', isArabic ? 'ar' : 'en');
    final durationLabel = (plan.startDate != null && plan.endDate != null)
        ? '${dateFormat.format(plan.startDate!)} - ${dateFormat.format(plan.endDate!)}'
        : lang.t('coach_plan_not_specified');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              plan.name ?? lang.t('coach_plan_untitled'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (plan.description != null) ...[
              const SizedBox(height: 8),
              Text(
                plan.description!,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatChip(
                  label: lang.t('coach_plan_days'),
                  value: '$totalDays',
                ),
                const SizedBox(width: 8),
                _buildStatChip(
                  label: lang.t('coach_plan_exercises'),
                  value: '$totalExercises',
                ),
                const SizedBox(width: 8),
                _buildStatChip(
                  label: lang.t('coach_plan_duration'),
                  value: durationLabel,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(lang.t('coach_progress_label')),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
            ),
            const SizedBox(height: 4),
            Text('${(progress * 100).round()}%'),
          ],
        ),
      ),
    );
  }

  Iterable<Widget> _buildDayCards(LanguageProvider lang, WorkoutPlan plan) {
    final days = plan.days ?? [];

    if (days.isEmpty) {
      return [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                lang.t('coach_no_workout_days'),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ),
        ),
      ];
    }

    return days.map(
      (day) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ExpansionTile(
          initiallyExpanded: day.dayNumber == 1,
          title: Text(day.dayName),
          subtitle: Text(
              '${day.exercises.length} ${lang.t('coach_exercises_label')}'),
          children: day.exercises.map((exercise) {
            final completed = exercise.isCompleted;
            return ListTile(
              leading: Icon(
                completed ? Icons.check_circle : Icons.radio_button_unchecked,
                color: completed ? AppColors.success : AppColors.textDisabled,
              ),
              title: Text(exercise.name),
              subtitle: Text('${exercise.sets} x ${exercise.reps}'),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatChip({required String label, required String value}) {
    return Chip(
      backgroundColor: AppColors.surface,
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style:
                const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(LanguageProvider lang) {
    final message = _error ?? lang.t('coach_no_workout_plan_client');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.fitness_center_outlined,
                size: 64, color: AppColors.textDisabled),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditor() async {
    final coachId = context.read<AuthProvider>().user?.id;
    if (coachId == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkoutPlanEditorScreen(
          clientId: widget.clientId,
          coachId: coachId,
        ),
      ),
    );
    if (mounted) {
      _loadPlan();
    }
  }
}

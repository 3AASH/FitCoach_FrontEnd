import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../data/models/nutrition_plan.dart';
import '../../providers/auth_provider.dart';
import '../../providers/coach_provider.dart';
import '../../providers/language_provider.dart';
import 'nutrition_plan_editor_screen.dart';

class CoachNutritionPlanViewerScreen extends StatefulWidget {
  final String clientId;
  final String clientName;

  const CoachNutritionPlanViewerScreen({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  @override
  State<CoachNutritionPlanViewerScreen> createState() =>
      _CoachNutritionPlanViewerScreenState();
}

class _CoachNutritionPlanViewerScreenState
    extends State<CoachNutritionPlanViewerScreen> {
  NutritionPlan? _plan;
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
        _isLoading = false;
        _error = context.read<LanguageProvider>().t('coach_missing_coach_info');
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final plan = await coachProvider.getClientNutritionPlan(
      coachId,
      widget.clientId,
    );

    if (!mounted) return;
    setState(() {
      _plan = plan;
      _isLoading = false;
      _error = plan == null
          ? context.read<LanguageProvider>().t('coach_nutrition_plan_missing')
          : null;
    });
  }

  double _calculateProgress(NutritionPlan plan) {
    final meals = plan.meals ?? [];
    if (meals.isEmpty) return 0;
    final completed = meals.where((meal) => meal.completed).length;
    return completed / meals.length;
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.t('coach_nutrition_plan_title')),
        actions: [
          if (_plan != null)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: lang.t('coach_edit_plan'),
              onPressed: _openEditor,
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
                      ..._buildDayMeals(lang, _plan!),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummaryCard(LanguageProvider lang, NutritionPlan plan) {
    final isArabic = lang.isArabic;
    final progress = _calculateProgress(plan);
    final macroTargets = plan.macroTargets ?? const {};
    final start = plan.startDate != null
        ? DateFormat('MMM d', isArabic ? 'ar' : 'en').format(plan.startDate!)
        : lang.t('coach_plan_not_specified');
    final end = plan.endDate != null
        ? DateFormat('MMM d', isArabic ? 'ar' : 'en').format(plan.endDate!)
        : lang.t('coach_plan_not_specified');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              plan.name ?? lang.t('coach_plan_untitled'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (plan.description != null) ...[
              const SizedBox(height: 8),
              Text(
                plan.description!,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 12),
            Text(lang.t('coach_plan_duration')),
            Text('$start - $end'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildMacroChip(
                  label: lang.t('calories'),
                  value:
                      '${macroTargets['calories'] ?? plan.dailyCalories ?? 0}',
                ),
                _buildMacroChip(
                  label: lang.t('protein'),
                  value: '${macroTargets['protein'] ?? 0}g',
                ),
                _buildMacroChip(
                  label: lang.t('carbs'),
                  value: '${macroTargets['carbs'] ?? 0}g',
                ),
                _buildMacroChip(
                  label: lang.t('fat'),
                  value: '${macroTargets['fat'] ?? macroTargets['fats'] ?? 0}g',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(lang.t('coach_adherence')),
            const SizedBox(height: 6),
            LinearProgressIndicator(value: progress, minHeight: 8),
            const SizedBox(height: 4),
            Text('${(progress * 100).round()}%'),
          ],
        ),
      ),
    );
  }

  Iterable<Widget> _buildDayMeals(LanguageProvider lang, NutritionPlan plan) {
    final days = plan.days ?? [];

    if (days.isEmpty) {
      return [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                lang.t('coach_no_meal_days'),
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
          subtitle: Text('${day.meals.length} ${lang.t('meals')}'),
          children: day.meals.map((meal) {
            return ListTile(
              leading: Icon(
                meal.completed ? Icons.check_circle : Icons.schedule,
                color:
                    meal.completed ? AppColors.success : AppColors.textDisabled,
              ),
              title: Text(meal.name),
              subtitle: Text('${meal.calories} kcal - ${meal.time}'),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMacroChip({required String label, required String value}) {
    return Chip(
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
    final message = _error ?? lang.t('coach_no_nutrition_plan_client');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.restaurant_outlined,
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
        builder: (_) => NutritionPlanEditorScreen(
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

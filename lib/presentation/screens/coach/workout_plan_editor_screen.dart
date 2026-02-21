import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/workout_plan.dart';
import '../../providers/coach_provider.dart';
import '../../providers/language_provider.dart';
import '../../widgets/custom_button.dart';
import '../../../core/constants/colors.dart';

/// Workout Plan Editor Screen
/// Allows coach to edit client's workout plan
class WorkoutPlanEditorScreen extends StatefulWidget {
  final String clientId;
  final String coachId;

  const WorkoutPlanEditorScreen({
    super.key,
    required this.clientId,
    required this.coachId,
  });

  @override
  State<WorkoutPlanEditorScreen> createState() =>
      _WorkoutPlanEditorScreenState();
}

class _WorkoutPlanEditorScreenState extends State<WorkoutPlanEditorScreen> {
  bool _isLoading = true;
  WorkoutPlan? _currentPlan;
  final TextEditingController _notesController = TextEditingController();

  // Plan data structure
  Map<String, dynamic> _planData = {};

  @override
  void initState() {
    super.initState();
    _loadCurrentPlan();
  }

  Future<void> _loadCurrentPlan() async {
    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<CoachProvider>(context, listen: false);
    final plan = await provider.getClientWorkoutPlan(
      widget.coachId,
      widget.clientId,
    );

    if (plan != null) {
      setState(() {
        _currentPlan = plan;
        _planData = plan.planData ?? {};
        _notesController.text = plan.notes ?? '';
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _savePlan() async {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);

    // Validate
    if (_planData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            languageProvider.t('coach_workout_editor_add_exercises_required'),
          ),
        ),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final provider = Provider.of<CoachProvider>(context, listen: false);
    final success = await provider.updateClientWorkoutPlan(
      widget.coachId,
      widget.clientId,
      _planData,
      _notesController.text,
    );

    // ignore: use_build_context_synchronously
    Navigator.of(context).pop(); // Close loading

    if (success) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            languageProvider.t('coach_workout_editor_updated_success'),
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop(true); // Go back with success
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            languageProvider.t('coach_workout_editor_update_failed'),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.t('coach_workout_editor_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _savePlan,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current plan info
                  if (_currentPlan != null)
                    Card(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.info_outline,
                                    color: AppColors.primary),
                                const SizedBox(width: 8),
                                Text(
                                  languageProvider.t('coach_workout_editor_current_plan'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (_currentPlan!.customizedByCoach == true)
                              Text(
                                languageProvider.t('coach_workout_editor_customized_by_coach'),
                                style: const TextStyle(
                                  color: AppColors.success,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Plan editor
                  Text(
                    languageProvider.t('coach_workout_editor_plan_details'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Weeks/Days structure
                  _buildWeeksList(),

                  const SizedBox(height: 24),

                  // Notes
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: languageProvider.t('coach_workout_editor_notes_label'),
                      hintText: languageProvider.t('coach_workout_editor_notes_hint'),
                      border: const OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Save button
                  CustomButton(
                    text: languageProvider.t('coach_workout_editor_save_changes'),
                    onPressed: _savePlan,
                    icon: Icons.save,
                  ),

                  const SizedBox(height: 16),

                  // Cancel button
                  CustomButton(
                    text: languageProvider.t('cancel'),
                    onPressed: () => Navigator.of(context).pop(),
                    variant: ButtonVariant.secondary,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildWeeksList() {
    final languageProvider = context.read<LanguageProvider>();

    if (_planData['weeks'] == null) {
      _planData['weeks'] = [];
    }

    List<dynamic> weeks = _planData['weeks'];

    return Column(
      children: [
        // Add week button
        OutlinedButton.icon(
          onPressed: _addWeek,
          icon: const Icon(Icons.add),
          label: Text(languageProvider.t('coach_workout_editor_add_week')),
        ),
        const SizedBox(height: 16),

        // Weeks list
        ...List.generate(weeks.length, (weekIndex) {
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ExpansionTile(
              title: Text(
                languageProvider.t('coach_workout_editor_week_label', args: {'week': '${weekIndex + 1}'}),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: AppColors.error),
                onPressed: () => _removeWeek(weekIndex),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        languageProvider.t('coach_workout_editor_days_label'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _buildDaysList(weekIndex),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDaysList(int weekIndex) {
    final languageProvider = context.read<LanguageProvider>();

    List<dynamic> weeks = _planData['weeks'];
    if (weeks[weekIndex]['days'] == null) {
      weeks[weekIndex]['days'] = [];
    }

    List<dynamic> days = weeks[weekIndex]['days'];

    return Column(
      children: [
        // Add day button
        TextButton.icon(
          onPressed: () => _addDay(weekIndex),
          icon: const Icon(Icons.add),
          label: Text(languageProvider.t('coach_workout_editor_add_day')),
        ),

        // Days list
        ...List.generate(days.length, (dayIndex) {
          return ListTile(
            title: Text(
              languageProvider.t('coach_workout_editor_day_label', args: {'day': '${dayIndex + 1}'}),
            ),
            subtitle: Text(
              languageProvider.t('coach_workout_editor_exercise_count', args: {'count': '${days[dayIndex]['exercises']?.length ?? 0}'}),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: AppColors.error),
              onPressed: () => _removeDay(weekIndex, dayIndex),
            ),
            onTap: () => _editDay(weekIndex, dayIndex),
          );
        }),
      ],
    );
  }

  void _addWeek() {
    setState(() {
      List<dynamic> weeks = _planData['weeks'] ?? [];
      weeks.add({
        'weekNumber': weeks.length + 1,
        'days': [],
      });
      _planData['weeks'] = weeks;
    });
  }

  void _removeWeek(int weekIndex) {
    setState(() {
      List<dynamic> weeks = _planData['weeks'];
      weeks.removeAt(weekIndex);
    });
  }

  void _addDay(int weekIndex) {
    setState(() {
      List<dynamic> weeks = _planData['weeks'];
      List<dynamic> days = weeks[weekIndex]['days'] ?? [];
      days.add({
        'dayNumber': days.length + 1,
        'exercises': [],
      });
      weeks[weekIndex]['days'] = days;
    });
  }

  void _removeDay(int weekIndex, int dayIndex) {
    setState(() {
      List<dynamic> weeks = _planData['weeks'];
      List<dynamic> days = weeks[weekIndex]['days'];
      days.removeAt(dayIndex);
    });
  }

  void _editDay(int weekIndex, int dayIndex) {
    final languageProvider = context.read<LanguageProvider>();

    // Show dialog to edit exercises
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          languageProvider.t('coach_workout_editor_day_exercises'),
        ),
        content: Text(
          languageProvider.t('coach_workout_editor_edit_exercises_hint'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(languageProvider.t('coach_workout_editor_ok')),
          ),
        ],
      ),
    );
  }
}

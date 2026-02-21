import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../providers/language_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/coach_provider.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';

class WorkoutPlanBuilderScreen extends StatefulWidget {
  final String clientId;
  final String clientName;

  const WorkoutPlanBuilderScreen({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  @override
  State<WorkoutPlanBuilderScreen> createState() =>
      _WorkoutPlanBuilderScreenState();
}

class _WorkoutPlanBuilderScreenState extends State<WorkoutPlanBuilderScreen> {
  final TextEditingController _planNameController = TextEditingController();
  final TextEditingController _planDescriptionController =
      TextEditingController();

  String _selectedGoal = 'fat_loss';
  int _daysPerWeek = 3;
  List<Map<String, dynamic>> _workoutDays = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeWorkoutDays();
  }

  void _initializeWorkoutDays() {
    _workoutDays = List.generate(
        _daysPerWeek,
        (index) => {
              'day': index + 1,
              'name': 'Day ${index + 1}',
              'exercises': <Map<String, dynamic>>[],
            });
  }

  void _applyTemplate(String templateKey, LanguageProvider lang) {
    setState(() {
      if (templateKey == 'beginner') {
        _selectedGoal = 'fat_loss';
        _daysPerWeek = 3;
        _planNameController.text =
            lang.t('coach_workout_template_beginner_full');
        _planDescriptionController.text =
            lang.t('coach_workout_template_beginner_desc');
      } else if (templateKey == 'intermediate') {
        _selectedGoal = 'maintenance';
        _daysPerWeek = 4;
        _planNameController.text =
            lang.t('coach_workout_template_intermediate_full');
        _planDescriptionController.text =
            lang.t('coach_workout_template_intermediate_desc');
      } else {
        _selectedGoal = 'muscle_gain';
        _daysPerWeek = 5;
        _planNameController.text =
            lang.t('coach_workout_template_advanced_full');
        _planDescriptionController.text =
            lang.t('coach_workout_template_advanced_desc');
      }

      _initializeWorkoutDays();

      // Seed each day with a few example exercises.
      final seeds = <List<Map<String, dynamic>>>[
        [
          {'name': 'Squat', 'sets': 3, 'reps': 10},
          {'name': 'Push Up', 'sets': 3, 'reps': 12},
          {'name': 'Plank', 'sets': 3, 'reps': 45},
        ],
        [
          {'name': 'Deadlift', 'sets': 3, 'reps': 8},
          {'name': 'Row', 'sets': 3, 'reps': 10},
          {'name': 'Lunge', 'sets': 3, 'reps': 12},
        ],
        [
          {'name': 'Bench Press', 'sets': 3, 'reps': 8},
          {'name': 'Lat Pulldown', 'sets': 3, 'reps': 10},
          {'name': 'Shoulder Press', 'sets': 3, 'reps': 10},
        ],
        [
          {'name': 'Leg Press', 'sets': 4, 'reps': 10},
          {'name': 'Incline DB Press', 'sets': 3, 'reps': 10},
          {'name': 'Cable Row', 'sets': 3, 'reps': 12},
        ],
        [
          {'name': 'Hip Thrust', 'sets': 4, 'reps': 10},
          {'name': 'Pull Up', 'sets': 3, 'reps': 8},
          {'name': 'Core Circuit', 'sets': 3, 'reps': 12},
        ],
      ];

      for (var i = 0; i < _workoutDays.length; i++) {
        final exercises = seeds[i % seeds.length];
        _workoutDays[i]['exercises'] =
            exercises.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    });
  }

  @override
  void dispose() {
    _planNameController.dispose();
    _planDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.t('coach_workout_builder_title')),
        actions: [
          TextButton(
            onPressed: () => _savePlan(languageProvider),
            child: Text(
              languageProvider.t('save'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Client info
            CustomCard(
              color: AppColors.primary.withValues(alpha: 0.1),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.person, color: AppColors.textWhite),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        languageProvider.t('coach_workout_builder_client_label'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        widget.clientName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Plan name
            Text(
              languageProvider.t('coach_workout_builder_plan_name_label'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _planNameController,
              decoration: InputDecoration(
                hintText: languageProvider.t('coach_workout_builder_plan_name_hint'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Description
            Text(
              languageProvider.t('coach_workout_builder_description_label'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _planDescriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: languageProvider.t('coach_workout_builder_description_hint'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Goal selection
            Text(
              languageProvider.t('coach_workout_builder_goal_label'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children:
                  ['fat_loss', 'muscle_gain', 'general_fitness'].map((goal) {
                final isSelected = _selectedGoal == goal;
                return FilterChip(
                  label: Text(_getGoalLabel(goal, languageProvider)),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedGoal = goal;
                    });
                  },
                  selectedColor: AppColors.primary.withValues(alpha: 0.2),
                  checkmarkColor: AppColors.primary,
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Days per week
            Text(
              languageProvider.t('coach_workout_builder_days_per_week_label'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(7, (index) {
                final day = index + 1;
                final isSelected = _daysPerWeek == day;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _daysPerWeek = day;
                        _initializeWorkoutDays();
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color:
                            isSelected ? AppColors.primary : AppColors.background,
                        border: Border.all(
                          color:
                              isSelected ? AppColors.primary : AppColors.border,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '$day',
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.textWhite
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 24),

            // Workout days
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  languageProvider.t('coach_workout_builder_workout_days_label'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _addFromTemplate(languageProvider),
                  icon: const Icon(Icons.file_copy, size: 18),
                  label: Text(languageProvider.t('coach_workout_builder_from_template')),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ..._workoutDays.asMap().entries.map((entry) {
              final index = entry.key;
              final day = entry.value;
              return _buildWorkoutDayCard(day, index, languageProvider);
            }).toList(),

            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: languageProvider.t('coach_workout_builder_save_plan'),
                onPressed: () => _savePlan(languageProvider),
                variant: ButtonVariant.primary,
                size: ButtonSize.large,
                fullWidth: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutDayCard(
      Map<String, dynamic> day, int index, LanguageProvider lang) {
    final exercises = day['exercises'] as List<Map<String, dynamic>>;

    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                lang.t(
                  'coach_workout_builder_day_label',
                  args: {'day': day['day'].toString()},
                ),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _editDayName(index, lang),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 20),
                    onPressed: () => _addExercise(index, lang),
                  ),
                ],
              ),
            ],
          ),
          if (exercises.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.fitness_center,
                      size: 40,
                      color: AppColors.textDisabled,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      lang.t('coach_workout_builder_no_exercises'),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...exercises.asMap().entries.map((entry) {
              final exerciseIndex = entry.key;
              final exercise = entry.value;
              return ListTile(
                leading: const Icon(Icons.fitness_center, size: 20),
                title: Text(exercise['name'] ?? lang.t('exercise')),
                subtitle: Text(
                  lang.t(
                    'coach_workout_sets_reps',
                    args: {
                      'sets': '${exercise['sets']}',
                      'reps': '${exercise['reps']}',
                    },
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete,
                      size: 20, color: AppColors.error),
                  onPressed: () {
                    setState(() {
                      exercises.removeAt(exerciseIndex);
                    });
                  },
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  String _getGoalLabel(String goal, LanguageProvider lang) {
    if (goal == 'fat_loss' ||
        goal == 'muscle_gain' ||
        goal == 'general_fitness') {
      return lang.t(goal);
    }
    return goal;
  }

  void _editDayName(int index, LanguageProvider lang) {
    final controller = TextEditingController(text: _workoutDays[index]['name']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.t('coach_workout_builder_name_day')),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: lang.t('coach_workout_builder_name_day_hint'),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.t('cancel')),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _workoutDays[index]['name'] = controller.text;
              });
              Navigator.pop(context);
            },
            child: Text(lang.t('save')),
          ),
        ],
      ),
    );
  }

  void _addExercise(int dayIndex, LanguageProvider lang) {
    showDialog(
      context: context,
      builder: (context) {
        String exerciseName = '';
        int sets = 3;
        int reps = 12;

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(lang.t('coach_workout_builder_add_exercise')),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: InputDecoration(
                      labelText: lang.t('coach_workout_builder_exercise_name'),
                      hintText: lang.t('coach_workout_builder_exercise_name_hint'),
                    ),
                    onChanged: (value) => exerciseName = value,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: lang.t('sets'),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) => sets = int.tryParse(value) ?? 3,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: lang.t('reps'),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) => reps = int.tryParse(value) ?? 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(lang.t('cancel')),
              ),
              TextButton(
                onPressed: () {
                  if (exerciseName.isNotEmpty) {
                    setState(() {
                      (_workoutDays[dayIndex]['exercises'] as List).add({
                        'name': exerciseName,
                        'sets': sets,
                        'reps': reps,
                      });
                    });
                    Navigator.pop(context);
                  }
                },
                child: Text(lang.t('add')),
              ),
            ],
          ),
        );
      },
    );
  }

  void _addFromTemplate(LanguageProvider lang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.t('coach_workout_template_choose_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(lang.t('coach_workout_template_beginner')),
              onTap: () {
                Navigator.pop(context);
                _applyTemplate('beginner', lang);
              },
            ),
            ListTile(
              title: Text(lang.t('coach_workout_template_intermediate')),
              onTap: () {
                Navigator.pop(context);
                _applyTemplate('intermediate', lang);
              },
            ),
            ListTile(
              title: Text(lang.t('coach_workout_template_advanced')),
              onTap: () {
                Navigator.pop(context);
                _applyTemplate('advanced', lang);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePlan(LanguageProvider lang) async {
    if (_planNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang.t('coach_workout_plan_name_required'),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_isSaving) return;

    final authProvider = context.read<AuthProvider>();
    final coachProvider = context.read<CoachProvider>();

    final coachId = authProvider.user?.id;
    if (coachId == null || coachId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang.t('coach_workout_coach_missing')),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final notes = _planDescriptionController.text.trim();
      final planData = <String, dynamic>{
        'name': _planNameController.text.trim(),
        'description': notes,
        'goal': _selectedGoal,
        'daysPerWeek': _daysPerWeek,
        'days': _workoutDays,
      };

      final success = await coachProvider.updateClientWorkoutPlan(
        coachId,
        widget.clientId,
        planData,
        notes,
      );

      if (!mounted) return;
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(lang.t('coach_workout_plan_saved')),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              coachProvider.error ??
                  lang.t('coach_workout_plan_save_failed'),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/colors.dart';
import '../../../data/models/workout_plan.dart';
import '../../providers/auth_provider.dart';
import '../../providers/coach_provider.dart';
import '../../providers/language_provider.dart';
import '../../widgets/custom_button.dart';

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
  bool _isSaving = false;
  bool _isEditable = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _goalController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  List<Map<String, dynamic>> _days = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _loadCurrentPlan();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _goalController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentPlan() async {
    setState(() => _isLoading = true);

    final provider = context.read<CoachProvider>();
    final plan =
        await provider.getClientWorkoutPlan(widget.coachId, widget.clientId);

    if (!mounted) return;

    if (plan == null) {
      setState(() {
        _days = <Map<String, dynamic>>[];
        _isEditable = _isEditorRole();
        _isLoading = false;
      });
      return;
    }

    final planData = _asMap(plan.planData) ?? const <String, dynamic>{};
    final parsedDays = _normalizeDays(plan, planData);

    _nameController.text = _asString(plan.name) ??
        _asString(planData['name']) ??
        _asString(planData['title']) ??
        '';
    _descriptionController.text =
        _asString(plan.description) ?? _asString(planData['description']) ?? '';
    _goalController.text = _asString(planData['goal']) ?? '';
    _notesController.text = plan.notes ?? '';

    final editable = _isEditorRole() || _hasEditFlag(planData);

    if (kDebugMode) {
      final exerciseCount = parsedDays.fold<int>(0,
          (sum, day) => sum + ((_asList(day['exercises']) ?? const []).length));
      debugPrint(
        '[WorkoutPlanEditor] parsed dayCount=${parsedDays.length} exerciseCount=$exerciseCount editable=$editable',
      );
    }

    setState(() {
      _days = parsedDays;
      _isEditable = editable;
      _isLoading = false;
    });
  }

  bool _isEditorRole() {
    final role = (context.read<AuthProvider>().user?.role ?? '').toLowerCase();
    return role == 'coach' || role == 'admin';
  }

  bool _hasEditFlag(Map<String, dynamic> map) {
    for (final key in const [
      'editable',
      'canEdit',
      'isEditable',
      'isCustomizable',
      'builderEnabled',
    ]) {
      if (_asBool(map[key]) == true) return true;
    }
    return _asBool(map['customizedByCoach']) == true;
  }

  List<Map<String, dynamic>> _normalizeDays(
      WorkoutPlan plan, Map<String, dynamic> planData) {
    final source = _asList(planData['days']) ??
        _asList(planData['workoutDays']) ??
        plan.days?.map((d) => d.toJson()).toList() ??
        const <dynamic>[];

    if (source.isEmpty) {
      return <Map<String, dynamic>>[
        {
          'dayNumber': 1,
          'name': 'Day 1',
          'exercises': <Map<String, dynamic>>[],
        }
      ];
    }

    return source.asMap().entries.map((entry) {
      final index = entry.key;
      final rawDay = _asMap(entry.value) ?? const <String, dynamic>{};
      final rawExercises = _asList(rawDay['exercises']) ?? const <dynamic>[];
      return {
        'dayNumber':
            _asInt(rawDay['dayNumber'] ?? rawDay['day_number']) ?? (index + 1),
        'name': _asString(
                rawDay['name'] ?? rawDay['dayName'] ?? rawDay['day_name']) ??
            'Day ${index + 1}',
        'exercises': rawExercises.asMap().entries.map((exEntry) {
          final exIndex = exEntry.key;
          final exMap = _asMap(exEntry.value) ?? const <String, dynamic>{};
          final exerciseId = _asString(
            exMap['exerciseId'] ?? exMap['exercise_id'] ?? exMap['ex_id'],
          );
          return <String, dynamic>{
            if (exerciseId != null && exerciseId.trim().isNotEmpty)
              'exerciseId': exerciseId,
            'name': _asString(
                  exMap['name'] ??
                      exMap['exerciseName'] ??
                      exMap['exercise_name'] ??
                      exMap['title'],
                ) ??
                'Exercise ${exIndex + 1}',
            'sets': _asInt(exMap['sets']) ?? 3,
            'reps': _asString(exMap['reps']) ?? '10',
            if (_asString(exMap['nameEn'] ?? exMap['name_en']) != null)
              'nameEn': _asString(exMap['nameEn'] ?? exMap['name_en']),
            if (_asString(exMap['nameAr'] ?? exMap['name_ar']) != null)
              'nameAr': _asString(exMap['nameAr'] ?? exMap['name_ar']),
            if (_asString(exMap['restTime'] ?? exMap['rest_seconds']) != null)
              'restTime': _asString(exMap['restTime'] ?? exMap['rest_seconds']),
            if (_asString(exMap['tempo']) != null)
              'tempo': _asString(exMap['tempo']),
            if (_asString(exMap['notes']) != null)
              'notes': _asString(exMap['notes']),
          };
        }).toList(),
      };
    }).toList();
  }

  Future<void> _savePlan() async {
    final lang = context.read<LanguageProvider>();
    if (_isSaving) return;

    if (!_isEditable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.t('coach_workout_editor_update_failed'))),
      );
      return;
    }

    if (_days.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang.t('coach_workout_editor_add_exercises_required')),
        ),
      );
      return;
    }

    final normalizedDays = _days.asMap().entries.map((entry) {
      final index = entry.key;
      final day = entry.value;
      final dayExercises =
          (_asList(day['exercises']) ?? const <dynamic>[]).map((raw) {
        final map = _asMap(raw) ?? const <String, dynamic>{};
        final exerciseId = _asString(
          map['exerciseId'] ?? map['exercise_id'] ?? map['ex_id'],
        );
        return <String, dynamic>{
          if (exerciseId != null && exerciseId.trim().isNotEmpty)
            'exerciseId': exerciseId,
          'name': _asString(map['name']) ?? 'Exercise',
          if (_asString(map['nameEn'] ?? map['name_en']) != null)
            'nameEn': _asString(map['nameEn'] ?? map['name_en']),
          if (_asString(map['nameAr'] ?? map['name_ar']) != null)
            'nameAr': _asString(map['nameAr'] ?? map['name_ar']),
          'sets': _asInt(map['sets']) ?? 3,
          'reps': _asString(map['reps']) ?? '10',
          if (_asString(map['restTime'] ?? map['rest_seconds']) != null)
            'restTime': _asString(map['restTime'] ?? map['rest_seconds']),
          if (_asString(map['tempo']) != null) 'tempo': _asString(map['tempo']),
          if (_asString(map['notes']) != null) 'notes': _asString(map['notes']),
        };
      }).toList();

      return <String, dynamic>{
        'dayNumber': _asInt(day['dayNumber']) ?? (index + 1),
        'name': _asString(day['name']) ?? 'Day ${index + 1}',
        'exercises': dayExercises,
      };
    }).toList();

    final payload = <String, dynamic>{
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'goal': _goalController.text.trim(),
      'days': normalizedDays,
    };

    setState(() => _isSaving = true);
    final provider = context.read<CoachProvider>();
    final success = await provider.updateClientWorkoutPlan(
      widget.coachId,
      widget.clientId,
      payload,
      _notesController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      await _loadCurrentPlan();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang.t('coach_workout_editor_updated_success')),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              provider.error ?? lang.t('coach_workout_editor_update_failed')),
          backgroundColor: AppColors.error,
        ),
      );
    }

    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.t('coach_workout_editor_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _savePlan,
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
                  if (!_isEditable)
                    Card(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(lang.t('coach_plan_editor_locked')),
                      ),
                    ),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Plan Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _goalController,
                    decoration: const InputDecoration(
                      labelText: 'Goal',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        lang.t('coach_workout_builder_workout_days_label'),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      TextButton.icon(
                        onPressed: _isEditable ? _addDay : null,
                        icon: const Icon(Icons.add),
                        label: Text(lang.t('coach_plan_editor_add_day')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._days.asMap().entries.map((entry) {
                    final dayIndex = entry.key;
                    final day = entry.value;
                    final exercises =
                        (_asList(day['exercises']) ?? const <dynamic>[])
                            .map((e) => _asMap(e) ?? <String, dynamic>{})
                            .toList();
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue: _asString(day['name']) ??
                                        'Day ${dayIndex + 1}',
                                    enabled: _isEditable,
                                    decoration: InputDecoration(
                                      labelText: 'Day ${dayIndex + 1} Name',
                                    ),
                                    onChanged: (value) =>
                                        _days[dayIndex]['name'] = value,
                                  ),
                                ),
                                IconButton(
                                  onPressed: _isEditable
                                      ? () => _removeDay(dayIndex)
                                      : null,
                                  icon: const Icon(Icons.delete,
                                      color: AppColors.error),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...exercises.asMap().entries.map((exEntry) {
                              final exIndex = exEntry.key;
                              final ex = exEntry.value;
                              return Card(
                                color: AppColors.surface,
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextFormField(
                                              initialValue:
                                                  _asString(ex['name']) ?? '',
                                              enabled: _isEditable,
                                              decoration: const InputDecoration(
                                                  labelText: 'Exercise name'),
                                              onChanged: (value) =>
                                                  _updateExercise(dayIndex,
                                                      exIndex, 'name', value),
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: _isEditable
                                                ? () => _removeExercise(
                                                    dayIndex, exIndex)
                                                : null,
                                            icon: const Icon(
                                                Icons.remove_circle_outline,
                                                color: AppColors.error),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextFormField(
                                              initialValue:
                                                  (_asInt(ex['sets']) ?? 3)
                                                      .toString(),
                                              enabled: _isEditable,
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: const InputDecoration(
                                                  labelText: 'Sets'),
                                              onChanged: (value) =>
                                                  _updateExercise(
                                                dayIndex,
                                                exIndex,
                                                'sets',
                                                int.tryParse(value) ?? 0,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: TextFormField(
                                              initialValue:
                                                  _asString(ex['reps']) ?? '10',
                                              enabled: _isEditable,
                                              decoration: const InputDecoration(
                                                  labelText: 'Reps'),
                                              onChanged: (value) =>
                                                  _updateExercise(dayIndex,
                                                      exIndex, 'reps', value),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: _isEditable
                                    ? () => _addExercise(dayIndex)
                                    : null,
                                icon: const Icon(Icons.add),
                                label: Text(lang.t('coach_plan_editor_add_exercise')),
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: lang.t('coach_workout_editor_notes_label'),
                      hintText: lang.t('coach_workout_editor_notes_hint'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: _isSaving
                        ? '${lang.t('save')}...'
                        : lang.t('coach_workout_editor_save_changes'),
                    onPressed: _isSaving ? null : _savePlan,
                    icon: Icons.save,
                  ),
                ],
              ),
            ),
    );
  }

  void _addDay() {
    setState(() {
      _days.add({
        'dayNumber': _days.length + 1,
        'name': 'Day ${_days.length + 1}',
        'exercises': <Map<String, dynamic>>[],
      });
    });
  }

  void _removeDay(int dayIndex) {
    setState(() {
      _days.removeAt(dayIndex);
      for (var i = 0; i < _days.length; i++) {
        _days[i]['dayNumber'] = i + 1;
      }
    });
  }

  void _addExercise(int dayIndex) {
    setState(() {
      final exercises = (_asList(_days[dayIndex]['exercises']) ?? <dynamic>[])
          .map((e) => _asMap(e) ?? <String, dynamic>{})
          .toList();
      exercises.add({'name': '', 'sets': 3, 'reps': '10'});
      _days[dayIndex]['exercises'] = exercises;
    });
  }

  void _removeExercise(int dayIndex, int exIndex) {
    setState(() {
      final exercises = (_asList(_days[dayIndex]['exercises']) ?? <dynamic>[])
          .map((e) => _asMap(e) ?? <String, dynamic>{})
          .toList();
      if (exIndex >= 0 && exIndex < exercises.length) {
        exercises.removeAt(exIndex);
      }
      _days[dayIndex]['exercises'] = exercises;
    });
  }

  void _updateExercise(int dayIndex, int exIndex, String key, dynamic value) {
    final exercises = (_asList(_days[dayIndex]['exercises']) ?? <dynamic>[])
        .map((e) => _asMap(e) ?? <String, dynamic>{})
        .toList();
    if (exIndex >= 0 && exIndex < exercises.length) {
      exercises[exIndex][key] = value;
      _days[dayIndex]['exercises'] = exercises;
    }
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  List<dynamic>? _asList(dynamic value) {
    if (value is List) return value;
    return null;
  }

  String? _asString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is num || value is bool) return value.toString();
    return value.toString();
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  bool? _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final n = value.trim().toLowerCase();
      if (n == 'true' || n == '1' || n == 'yes') return true;
      if (n == 'false' || n == '0' || n == 'no') return false;
    }
    return null;
  }
}

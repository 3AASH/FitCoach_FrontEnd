import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/colors.dart';
import '../../../data/models/nutrition_plan.dart';
import '../../providers/auth_provider.dart';
import '../../providers/coach_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/nutrition_provider.dart';
import '../../widgets/custom_button.dart';

class NutritionPlanEditorScreen extends StatefulWidget {
  final String clientId;
  final String coachId;

  const NutritionPlanEditorScreen({
    super.key,
    required this.clientId,
    required this.coachId,
  });

  @override
  State<NutritionPlanEditorScreen> createState() =>
      _NutritionPlanEditorScreenState();
}

class _NutritionPlanEditorScreenState extends State<NutritionPlanEditorScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditable = false;

  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();
  final TextEditingController _fatsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  List<Map<String, dynamic>> _days = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _loadCurrentPlan();
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentPlan() async {
    setState(() => _isLoading = true);

    final provider = context.read<CoachProvider>();
    final plan =
        await provider.getClientNutritionPlan(widget.coachId, widget.clientId);

    if (!mounted) return;

    if (plan == null) {
      setState(() {
        _days = <Map<String, dynamic>>[];
        _isEditable = _isEditorRole();
        _isLoading = false;
      });
      return;
    }

    final mealPlan = _asMap(plan.mealPlan) ?? const <String, dynamic>{};
    final parsedDays = _normalizeDays(plan, mealPlan);

    final macros = _asMap(plan.macros) ?? const <String, dynamic>{};
    _caloriesController.text =
        (plan.dailyCalories ?? _asInt(macros['calories']) ?? 0).toString();
    _proteinController.text = (_asInt(macros['protein']) ?? 0).toString();
    _carbsController.text = (_asInt(macros['carbs']) ?? 0).toString();
    _fatsController.text =
        (_asInt(macros['fat'] ?? macros['fats']) ?? 0).toString();
    _notesController.text = plan.notes ?? '';

    final editable = _isEditorRole() ||
        _hasEditFlag(mealPlan) ||
        _hasEditFlag(_asMap(plan.macros) ?? const {});

    if (kDebugMode) {
      final mealCount = parsedDays.fold<int>(
          0, (sum, day) => sum + ((_asList(day['meals']) ?? const []).length));
      debugPrint(
        '[NutritionPlanEditor] parsed dayCount=${parsedDays.length} mealCount=$mealCount editable=$editable',
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
    return false;
  }

  List<Map<String, dynamic>> _normalizeDays(
      NutritionPlan plan, Map<String, dynamic> mealPlan) {
    final source = _asList(plan.days?.map((d) => d.toJson()).toList()) ??
        _asList(mealPlan['days']) ??
        _asList(mealPlan['mealPlan']) ??
        _asList(mealPlan['meal_plan']) ??
        const <dynamic>[];

    if (source.isEmpty) {
      return <Map<String, dynamic>>[
        {
          'dayNumber': 1,
          'dayName': 'Monday',
          'meals': <Map<String, dynamic>>[],
        }
      ];
    }

    return source.asMap().entries.map((entry) {
      final dayIndex = entry.key;
      final rawDay = _asMap(entry.value) ?? const <String, dynamic>{};
      final mealsSource = _asList(rawDay['meals']) ??
          _asList(_asMap(rawDay['mealPlan'])?['meals']) ??
          const <dynamic>[];
      return {
        'dayNumber': _asInt(rawDay['dayNumber'] ?? rawDay['day_number']) ??
            (dayIndex + 1),
        'dayName': _asString(
                rawDay['dayName'] ?? rawDay['day_name'] ?? rawDay['name']) ??
            'Day ${dayIndex + 1}',
        'meals': mealsSource.asMap().entries.map((mealEntry) {
          final mealIndex = mealEntry.key;
          final meal = _asMap(mealEntry.value) ?? const <String, dynamic>{};
          return <String, dynamic>{
            'name': _asString(
                  meal['name'] ??
                      meal['mealName'] ??
                      meal['meal_name'] ??
                      meal['title'],
                ) ??
                'Meal ${mealIndex + 1}',
            'type': _asString(meal['type']) ?? 'meal',
            'time': _asString(meal['time']) ?? '',
            'calories': _asInt(meal['calories']) ?? 0,
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
        SnackBar(content: Text(lang.t('coach_nutrition_editor_update_failed'))),
      );
      return;
    }

    final calories = int.tryParse(_caloriesController.text.trim()) ?? 0;
    if (calories <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(lang.t('coach_nutrition_editor_calories_required'))),
      );
      return;
    }

    final daysPayload = _days.asMap().entries.map((entry) {
      final dayIndex = entry.key;
      final day = entry.value;
      final meals = (_asList(day['meals']) ?? const <dynamic>[]).map((rawMeal) {
        final meal = _asMap(rawMeal) ?? const <String, dynamic>{};
        return <String, dynamic>{
          'name': _asString(meal['name']) ?? 'Meal',
          'type': _asString(meal['type']) ?? 'meal',
          'time': _asString(meal['time']) ?? '',
          'calories': _asInt(meal['calories']) ?? 0,
        };
      }).toList();
      return <String, dynamic>{
        'dayNumber': _asInt(day['dayNumber']) ?? (dayIndex + 1),
        'dayName': _asString(day['dayName']) ?? 'Day ${dayIndex + 1}',
        'meals': meals,
      };
    }).toList();

    final macros = <String, dynamic>{
      'protein': int.tryParse(_proteinController.text.trim()) ?? 0,
      'carbs': int.tryParse(_carbsController.text.trim()) ?? 0,
      'fat': int.tryParse(_fatsController.text.trim()) ?? 0,
    };

    final mealPlan = <String, dynamic>{
      'days': daysPayload,
    };

    setState(() => _isSaving = true);

    final provider = context.read<CoachProvider>();
    final success = await provider.updateClientNutritionPlan(
      widget.coachId,
      widget.clientId,
      calories,
      macros,
      mealPlan,
      _notesController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      await provider.getClientNutritionPlan(widget.coachId, widget.clientId);
      if (mounted) {
        final userNutrition =
            Provider.of<NutritionProvider?>(context, listen: false);
        await userNutrition?.loadActivePlan();
      }
      await _loadCurrentPlan();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang.t('coach_nutrition_editor_update_success')),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              provider.error ?? lang.t('coach_nutrition_editor_update_failed')),
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
        title: Text(lang.t('coach_nutrition_editor_title')),
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
                  Text(
                    lang.t('coach_nutrition_editor_daily_calories'),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _caloriesController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: lang.t('plan_editor_calories'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _proteinController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: lang.t('plan_editor_protein'),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _carbsController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: lang.t('plan_editor_carbs'),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _fatsController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: lang.t('plan_editor_fat'),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        lang.t('coach_nutrition_editor_meal_plan'),
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
                    final meals = (_asList(day['meals']) ?? const <dynamic>[])
                        .map((m) => _asMap(m) ?? <String, dynamic>{})
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
                                    initialValue: _asString(day['dayName']) ??
                                        'Day ${dayIndex + 1}',
                                    enabled: _isEditable,
                                    decoration: InputDecoration(
                                      labelText: lang.t(
                                        'plan_editor_day_name',
                                        args: {'day': '${dayIndex + 1}'},
                                      ),
                                    ),
                                    onChanged: (value) =>
                                        _days[dayIndex]['dayName'] = value,
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
                            ...meals.asMap().entries.map((mealEntry) {
                              final mealIndex = mealEntry.key;
                              final meal = mealEntry.value;
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
                                                  _asString(meal['name']) ?? '',
                                              enabled: _isEditable,
                                              decoration: InputDecoration(
                                                labelText: lang
                                                    .t('plan_editor_meal_name'),
                                              ),
                                              onChanged: (value) => _updateMeal(
                                                  dayIndex,
                                                  mealIndex,
                                                  'name',
                                                  value),
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: _isEditable
                                                ? () => _removeMeal(
                                                    dayIndex, mealIndex)
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
                                                  _asString(meal['time']) ?? '',
                                              enabled: _isEditable,
                                              decoration: InputDecoration(
                                                labelText:
                                                    lang.t('plan_editor_time'),
                                              ),
                                              onChanged: (value) => _updateMeal(
                                                  dayIndex,
                                                  mealIndex,
                                                  'time',
                                                  value),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: TextFormField(
                                              initialValue:
                                                  (_asInt(meal['calories']) ??
                                                          0)
                                                      .toString(),
                                              enabled: _isEditable,
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: InputDecoration(
                                                labelText: lang.t(
                                                  'plan_editor_calories',
                                                ),
                                              ),
                                              onChanged: (value) => _updateMeal(
                                                dayIndex,
                                                mealIndex,
                                                'calories',
                                                int.tryParse(value) ?? 0,
                                              ),
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
                                    ? () => _addMeal(dayIndex)
                                    : null,
                                icon: const Icon(Icons.add),
                                label:
                                    Text(lang.t('coach_plan_editor_add_meal')),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: lang.t('coach_nutrition_editor_notes'),
                      hintText: lang.t('coach_nutrition_editor_notes_hint'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: _isSaving
                        ? '${lang.t('save')}...'
                        : lang.t('coach_nutrition_editor_save_changes'),
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
        'dayName': 'Day ${_days.length + 1}',
        'meals': <Map<String, dynamic>>[],
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

  void _addMeal(int dayIndex) {
    setState(() {
      final meals = (_asList(_days[dayIndex]['meals']) ?? <dynamic>[])
          .map((m) => _asMap(m) ?? <String, dynamic>{})
          .toList();
      meals.add({'name': '', 'type': 'meal', 'time': '', 'calories': 0});
      _days[dayIndex]['meals'] = meals;
    });
  }

  void _removeMeal(int dayIndex, int mealIndex) {
    setState(() {
      final meals = (_asList(_days[dayIndex]['meals']) ?? <dynamic>[])
          .map((m) => _asMap(m) ?? <String, dynamic>{})
          .toList();
      if (mealIndex >= 0 && mealIndex < meals.length) {
        meals.removeAt(mealIndex);
      }
      _days[dayIndex]['meals'] = meals;
    });
  }

  void _updateMeal(int dayIndex, int mealIndex, String key, dynamic value) {
    final meals = (_asList(_days[dayIndex]['meals']) ?? <dynamic>[])
        .map((m) => _asMap(m) ?? <String, dynamic>{})
        .toList();
    if (mealIndex >= 0 && mealIndex < meals.length) {
      meals[mealIndex][key] = value;
      _days[dayIndex]['meals'] = meals;
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

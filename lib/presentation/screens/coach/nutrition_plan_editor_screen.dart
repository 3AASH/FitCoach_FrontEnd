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
import '../../widgets/library_picker_field.dart';
import 'plan_library_options.dart';
import '../../../core/theme/app_palette.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CoachProvider>().loadPlanLibraries();
    });
  }

  /// Every portion of every library meal.
  ///
  /// Watched, so the screen redraws once the libraries finish loading. Only
  /// safe to call while building - an event handler has to use
  /// [_variantOptionsNow], which reads without subscribing.
  List<RecipeVariantOption> get _variantOptions =>
      RecipeVariantOption.fromRows(
          context.watch<CoachProvider>().recipeVariantLibrary);

  List<RecipeVariantOption> get _variantOptionsNow =>
      RecipeVariantOption.fromRows(
          context.read<CoachProvider>().recipeVariantLibrary);

  /// One entry per meal, for the name picker. Portions are chosen separately,
  /// so the list never repeats a dish once per size.
  List<RecipeMealOption> get _mealOptions =>
      RecipeMealOption.fromVariants(_variantOptions);

  RecipeMealOption? _mealForRecipe(String? recipeId) {
    if (recipeId == null || recipeId.isEmpty) return null;
    for (final meal in _mealOptions) {
      if (meal.recipeId == recipeId) return meal;
    }
    return null;
  }

  /// Resolves the portion a meal row is currently on: by variant id when the
  /// plan carries one, else by the portion code recorded alongside it, else the
  /// recipe's default size.
  RecipeVariantOption? _variantForMeal(Map<String, dynamic> meal) {
    final recipe = _mealForRecipe(_asString(meal['recipeId']));
    if (recipe == null) return null;

    final variantId = _asString(meal['variantId']);
    if (variantId != null && variantId.isNotEmpty) {
      for (final variant in recipe.variants) {
        if (variant.variantId == variantId) return variant;
      }
    }
    final portionCode = _asString(meal['portionCode'])?.toUpperCase();
    if (portionCode != null && portionCode.isNotEmpty) {
      for (final variant in recipe.variants) {
        if (variant.portionCode == portionCode) return variant;
      }
    }
    return recipe.defaultVariant;
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
          final macros = _asMap(meal['macros']) ?? const <String, dynamic>{};
          return <String, dynamic>{
            'name': _asString(
                  meal['name'] ??
                      meal['mealName'] ??
                      meal['meal_name'] ??
                      meal['title'],
                ) ??
                'Meal ${mealIndex + 1}',
            // Carried through the round trip so re-saving a plan does not
            // quietly downgrade an existing library reference to free text.
            // The server spells these `plannedRecipeId`/`plannedVariantId`;
            // reading only the short spelling is why the reference used to be
            // lost the moment a saved plan was reopened.
            if (_asString(meal['plannedRecipeId'] ??
                    meal['planned_recipe_id'] ??
                    meal['recipeId'] ??
                    meal['recipe_id']) !=
                null)
              'recipeId': _asString(meal['plannedRecipeId'] ??
                  meal['planned_recipe_id'] ??
                  meal['recipeId'] ??
                  meal['recipe_id']),
            if (_asString(meal['plannedVariantId'] ??
                    meal['planned_variant_id'] ??
                    meal['variantId'] ??
                    meal['variant_id']) !=
                null)
              'variantId': _asString(meal['plannedVariantId'] ??
                  meal['planned_variant_id'] ??
                  meal['variantId'] ??
                  meal['variant_id']),
            if (_asString(meal['portionCode'] ?? meal['portion_code']) != null)
              'portionCode':
                  _asString(meal['portionCode'] ?? meal['portion_code']),
            'type': _asString(meal['type']) ?? 'meal',
            'time': _asString(meal['time']) ?? '',
            'calories': _asInt(meal['calories']) ?? 0,
            'protein': _asNum(meal['protein'] ?? macros['protein']) ?? 0,
            'carbs': _asNum(meal['carbs'] ?? macros['carbs']) ?? 0,
            'fat': _asNum(meal['fat'] ?? meal['fats'] ?? macros['fats']) ?? 0,
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
        final recipeId = _asString(meal['recipeId']);
        final variantId = _asString(meal['variantId']);
        final portionCode = _asString(meal['portionCode']);
        return <String, dynamic>{
          'name': _asString(meal['name']) ?? 'Meal',
          // Only present when the coach picked the meal out of the library.
          // Without it the save would keep the name and drop the reference,
          // which is exactly the free-text plan the picker exists to avoid.
          // Sent under both spellings because the server reads the long one.
          if (recipeId != null && recipeId.isNotEmpty) ...{
            'recipeId': recipeId,
            'plannedRecipeId': recipeId,
          },
          if (variantId != null && variantId.isNotEmpty) ...{
            'variantId': variantId,
            'plannedVariantId': variantId,
          },
          if (portionCode != null && portionCode.isNotEmpty)
            'portionCode': portionCode,
          'type': _asString(meal['type']) ?? 'meal',
          'time': _asString(meal['time']) ?? '',
          'calories': _asInt(meal['calories']) ?? 0,
          // The macros of the chosen portion. Saving calories alone left the
          // client's per-meal protein/carbs/fat at zero after any coach edit.
          'protein': _asNum(meal['protein']) ?? 0,
          'carbs': _asNum(meal['carbs']) ?? 0,
          'fat': _asNum(meal['fat']) ?? 0,
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
                              return _buildMealCard(
                                lang,
                                dayIndex,
                                mealEntry.key,
                                mealEntry.value,
                              );
                            }),
                            _buildDayTotals(lang, meals),
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

  /// One meal row: which meal, which portion of it, and the macros that come
  /// with that portion.
  ///
  /// The macro fields are read-only whenever the meal came out of the library,
  /// because they are the library's numbers and typing over them would make the
  /// plan disagree with the recipe the client is told to cook. A hand-typed
  /// meal has no recipe behind it, so there they stay editable.
  Widget _buildMealCard(
    LanguageProvider lang,
    int dayIndex,
    int mealIndex,
    Map<String, dynamic> meal,
  ) {
    final recipeId = _asString(meal['recipeId']);
    final selectedMeal = _mealForRecipe(recipeId);
    final selectedVariant = _variantForMeal(meal);
    final fromLibrary = selectedMeal != null;

    return Card(
      color: context.palette.surfaceVariant,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: LibraryPickerField<RecipeMealOption>(
                    // Rebuilt only when a meal is picked, so the field takes
                    // the new name. Keying it on the recipe id instead would
                    // also rebuild it mid-word the first time a coach types
                    // over a picked meal, which loses the caret.
                    key: ValueKey(
                        'meal:$dayIndex:$mealIndex:${_pickEpoch(dayIndex, mealIndex)}'),
                    initialValue: _asString(meal['name']) ?? '',
                    enabled: _isEditable,
                    labelText: lang.t('plan_editor_meal_name'),
                    options: _mealOptions,
                    optionLabel: (option) => option.name,
                    optionDetail: (option) => option.detail,
                    matches: _mealMatches,
                    onTextChanged: (value) {
                      // Typing over a picked meal makes it free text again:
                      // the name no longer describes the recipe that is still
                      // referenced, so the reference has to go with it.
                      _updateMeal(dayIndex, mealIndex, 'name', value);
                      _clearMealSelection(dayIndex, mealIndex);
                    },
                    onSelected: (option) =>
                        _selectMeal(dayIndex, mealIndex, option),
                  ),
                ),
                IconButton(
                  onPressed:
                      _isEditable ? () => _removeMeal(dayIndex, mealIndex) : null,
                  icon: const Icon(Icons.remove_circle_outline,
                      color: AppColors.error),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Portion picker, mirroring the admin plan editor: the sizes the
            // recipe actually defines, nothing else.
            DropdownButtonFormField<String>(
              // A FormField reads `initialValue` once, so the key has to carry
              // the current portion for the dropdown to follow a change made
              // by picking a different meal.
              key: ValueKey('portion:$dayIndex:$mealIndex:'
                  '${recipeId ?? ''}:${selectedVariant?.variantId ?? ''}'),
              initialValue: selectedVariant?.variantId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: lang.t('plan_editor_portion'),
                helperText: fromLibrary
                    ? lang.t('coach_nutrition_editor_portion_hint')
                    : lang.t('plan_editor_select_meal_first'),
                helperMaxLines: 2,
              ),
              items: (selectedMeal?.variants ?? const <RecipeVariantOption>[])
                  .map((variant) => DropdownMenuItem<String>(
                        value: variant.variantId,
                        child: Text(
                          '${_portionLabel(lang, variant.portionCode)} · '
                          '${variant.calories.round()} ${lang.t('coach_nutrition_kcal')}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList(),
              onChanged: !_isEditable || !fromLibrary
                  ? null
                  : (variantId) {
                      if (variantId == null) return;
                      _selectPortion(dayIndex, mealIndex, variantId);
                    },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _asString(meal['time']) ?? '',
                    enabled: _isEditable,
                    decoration: InputDecoration(
                      labelText: lang.t('plan_editor_time'),
                    ),
                    onChanged: (value) =>
                        _updateMeal(dayIndex, mealIndex, 'time', value),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _macroField(
                    key: 'cal:$dayIndex:$mealIndex',
                    label: lang.t('plan_editor_calories'),
                    value: _asInt(meal['calories']) ?? 0,
                    derived: fromLibrary,
                    onChanged: (value) => _updateMeal(
                        dayIndex, mealIndex, 'calories', value.round()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _macroField(
                    key: 'p:$dayIndex:$mealIndex',
                    label: lang.t('plan_editor_protein'),
                    value: _asNum(meal['protein']) ?? 0,
                    derived: fromLibrary,
                    onChanged: (value) =>
                        _updateMeal(dayIndex, mealIndex, 'protein', value),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _macroField(
                    key: 'c:$dayIndex:$mealIndex',
                    label: lang.t('plan_editor_carbs'),
                    value: _asNum(meal['carbs']) ?? 0,
                    derived: fromLibrary,
                    onChanged: (value) =>
                        _updateMeal(dayIndex, mealIndex, 'carbs', value),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _macroField(
                    key: 'f:$dayIndex:$mealIndex',
                    label: lang.t('plan_editor_fat'),
                    value: _asNum(meal['fat']) ?? 0,
                    derived: fromLibrary,
                    onChanged: (value) =>
                        _updateMeal(dayIndex, mealIndex, 'fat', value),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// A macro input. [derived] ones are filled from the chosen portion and shown
  /// read-only; the key carries the value so the field redraws when a different
  /// portion is picked rather than keeping the number it was built with.
  Widget _macroField({
    required String key,
    required String label,
    required num value,
    required bool derived,
    required ValueChanged<num> onChanged,
  }) {
    final text = value == value.roundToDouble()
        ? value.round().toString()
        : value.toStringAsFixed(1);
    return TextFormField(
      key: ValueKey('$key:$text:$derived'),
      initialValue: text,
      enabled: _isEditable,
      readOnly: derived,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
      onChanged: derived ? null : (input) => onChanged(num.tryParse(input) ?? 0),
    );
  }

  /// Totals for the day, so a coach can see the meals adding up to the target
  /// at the top of the screen instead of adding them up by hand.
  Widget _buildDayTotals(
      LanguageProvider lang, List<Map<String, dynamic>> meals) {
    if (meals.isEmpty) return const SizedBox.shrink();
    num calories = 0, protein = 0, carbs = 0, fat = 0;
    for (final meal in meals) {
      calories += _asNum(meal['calories']) ?? 0;
      protein += _asNum(meal['protein']) ?? 0;
      carbs += _asNum(meal['carbs']) ?? 0;
      fat += _asNum(meal['fat']) ?? 0;
    }
    String g(num value) => value == value.roundToDouble()
        ? '${value.round()}g'
        : '${value.toStringAsFixed(1)}g';

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 4),
        child: Text(
          '${lang.t('coach_nutrition_editor_day_total')}: '
          '${calories.round()} ${lang.t('coach_nutrition_kcal')} · '
          'P ${g(protein)} · C ${g(carbs)} · F ${g(fat)}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: context.palette.textSecondary,
          ),
        ),
      ),
    );
  }

  String _portionLabel(LanguageProvider lang, String portionCode) {
    const names = {
      'S': 'plan_editor_portion_small',
      'M': 'plan_editor_portion_medium',
      'L': 'plan_editor_portion_large',
      'XL': 'plan_editor_portion_xlarge',
    };
    final key = names[portionCode];
    return key == null ? portionCode : '$portionCode · ${lang.t(key)}';
  }

  /// Matches a meal on its name in either language, its id, its slot or its
  /// cuisine, word by word, so "egyptian breakfast" narrows the list the way
  /// typing two words is expected to.
  bool _mealMatches(RecipeMealOption option, String query) {
    final terms =
        query.toLowerCase().split(' ').where((term) => term.isNotEmpty);
    if (terms.isEmpty) return true;
    final haystack = [
      option.name,
      option.nameAr ?? '',
      option.recipeId,
      option.cuisine ?? '',
      option.mealTypes.join(' '),
      option.marketTags.join(' '),
    ].join(' ').toLowerCase();
    return terms.every(haystack.contains);
  }

  /// Picking a meal selects its default portion and takes that portion's macros
  /// with it. This is the step that was missing: the editor used to record the
  /// name and leave the calories at whatever was already in the field.
  void _selectMeal(int dayIndex, int mealIndex, RecipeMealOption option) {
    final variant = option.defaultVariant;
    setState(() {
      _pickEpochs['$dayIndex:$mealIndex'] =
          (_pickEpochs['$dayIndex:$mealIndex'] ?? 0) + 1;
      _updateMeal(dayIndex, mealIndex, 'name', option.name);
      _updateMeal(dayIndex, mealIndex, 'recipeId', option.recipeId);
      if (variant != null) _applyVariant(dayIndex, mealIndex, variant);
    });
  }

  /// Bumped each time a meal is picked from the library, and used only to force
  /// that one picker to rebuild with the new name.
  final Map<String, int> _pickEpochs = <String, int>{};

  int _pickEpoch(int dayIndex, int mealIndex) =>
      _pickEpochs['$dayIndex:$mealIndex'] ?? 0;

  void _selectPortion(int dayIndex, int mealIndex, String variantId) {
    for (final variant in _variantOptionsNow) {
      if (variant.variantId == variantId) {
        setState(() => _applyVariant(dayIndex, mealIndex, variant));
        return;
      }
    }
  }

  void _applyVariant(
      int dayIndex, int mealIndex, RecipeVariantOption variant) {
    _updateMeal(dayIndex, mealIndex, 'variantId', variant.variantId);
    _updateMeal(dayIndex, mealIndex, 'portionCode', variant.portionCode);
    _updateMeal(dayIndex, mealIndex, 'calories', variant.calories.round());
    _updateMeal(dayIndex, mealIndex, 'protein', variant.protein);
    _updateMeal(dayIndex, mealIndex, 'carbs', variant.carbs);
    _updateMeal(dayIndex, mealIndex, 'fat', variant.fat);
  }

  void _clearMealSelection(int dayIndex, int mealIndex) {
    final meals = (_asList(_days[dayIndex]['meals']) ?? <dynamic>[])
        .map((m) => _asMap(m) ?? <String, dynamic>{})
        .toList();
    if (mealIndex < 0 || mealIndex >= meals.length) return;
    if (meals[mealIndex]['recipeId'] == null) return;
    meals[mealIndex].remove('recipeId');
    meals[mealIndex].remove('variantId');
    meals[mealIndex].remove('portionCode');
    _days[dayIndex]['meals'] = meals;
    // Rebuilt so the macro fields become editable again now that the meal is
    // no longer backed by a recipe.
    setState(() {});
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
      meals.add({
        'name': '',
        'type': 'meal',
        'time': '',
        'calories': 0,
        'protein': 0,
        'carbs': 0,
        'fat': 0,
      });
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

  num? _asNum(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value.trim());
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

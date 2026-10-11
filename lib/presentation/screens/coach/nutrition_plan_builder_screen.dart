import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../providers/language_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/coach_provider.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/library_picker_field.dart';
import '../../widgets/sheet_header.dart';
import 'plan_library_options.dart';
import '../../../core/theme/app_palette.dart';
import '../../widgets/unsaved_changes_guard.dart';

class NutritionPlanBuilderScreen extends StatefulWidget {
  final String clientId;
  final String clientName;

  const NutritionPlanBuilderScreen({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  @override
  State<NutritionPlanBuilderScreen> createState() =>
      _NutritionPlanBuilderScreenState();
}

class _NutritionPlanBuilderScreenState
    extends State<NutritionPlanBuilderScreen> {
  final TextEditingController _planNameController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();
  final TextEditingController _fatController = TextEditingController();

  String _selectedGoal = 'fat_loss';
  List<Map<String, dynamic>> _meals = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeMeals();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CoachProvider>().loadPlanLibraries();
    });
  }

  List<RecipeVariantOption> get _variantOptions =>
      RecipeVariantOption.fromRows(
          context.read<CoachProvider>().recipeVariantLibrary);

  List<RecipeMealOption> get _mealOptions =>
      RecipeMealOption.fromVariants(_variantOptions);

  void _initializeMeals() {
    _meals = [
      {'type': 'breakfast', 'foods': []},
      {'type': 'lunch', 'foods': []},
      {'type': 'dinner', 'foods': []},
      {'type': 'snack', 'foods': []},
    ];
  }

  void _applyTemplate(String templateKey, LanguageProvider lang) {
    setState(() {
      if (templateKey == 'fat_loss') {
        _selectedGoal = 'fat_loss';
        _planNameController.text = lang.t('coach_nutrition_template_fat_loss');
        _caloriesController.text = '1900';
        _proteinController.text = '160';
        _carbsController.text = '170';
        _fatController.text = '60';
      } else if (templateKey == 'muscle_gain') {
        _selectedGoal = 'muscle_gain';
        _planNameController.text =
            lang.t('coach_nutrition_template_muscle_gain');
        _caloriesController.text = '2600';
        _proteinController.text = '170';
        _carbsController.text = '320';
        _fatController.text = '70';
      } else {
        _selectedGoal = 'maintenance';
        _planNameController.text =
            lang.t('coach_nutrition_template_balanced');
        _caloriesController.text = '2200';
        _proteinController.text = '150';
        _carbsController.text = '240';
        _fatController.text = '70';
      }

      _initializeMeals();

      void addFood(String mealType, Map<String, dynamic> food) {
        final meal = _meals.firstWhere((m) => m['type'] == mealType);
        (meal['foods'] as List).add(food);
      }

      addFood('breakfast', {
        'name': 'Oats',
        'calories': 320,
        'protein': 10,
        'carbs': 54,
        'fat': 6
      });
      addFood('breakfast', {
        'name': 'Eggs',
        'calories': 140,
        'protein': 12,
        'carbs': 1,
        'fat': 10
      });
      addFood('lunch', {
        'name': 'Chicken Breast',
        'calories': 220,
        'protein': 40,
        'carbs': 0,
        'fat': 6
      });
      addFood('lunch', {
        'name': 'Rice',
        'calories': 210,
        'protein': 4,
        'carbs': 45,
        'fat': 1
      });
      addFood('dinner', {
        'name': 'Salmon',
        'calories': 260,
        'protein': 34,
        'carbs': 0,
        'fat': 12
      });
      addFood('dinner', {
        'name': 'Sweet Potato',
        'calories': 180,
        'protein': 4,
        'carbs': 41,
        'fat': 0
      });
      addFood('snack', {
        'name': 'Greek Yogurt',
        'calories': 120,
        'protein': 15,
        'carbs': 8,
        'fat': 3
      });
    });
  }

  @override
  void dispose() {
    _planNameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return UnsavedChangesGuard(
      hasUnsavedChanges: _hasUnsavedWork,
      child: Scaffold(
      // One save, not two -- see the workout builder for the same change.
      appBar: AppBar(
        title: Text(lang.t('coach_nutrition_builder_title')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Client info
            CustomCard(
              color: AppColors.success.withValues(alpha: 0.1),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.success,
                    child: Icon(Icons.restaurant, color: AppColors.textWhite),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang.t('coach_nutrition_builder_client_label'),
                        style: TextStyle(
                          fontSize: 12,
                          color: context.palette.textSecondary,
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
              lang.t('coach_nutrition_builder_plan_name_label'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _planNameController,
              decoration: InputDecoration(
                hintText: lang.t('coach_nutrition_builder_plan_name_hint'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Daily targets
            Text(
              lang.t('coach_nutrition_builder_daily_targets'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildMacroInput(
                    controller: _caloriesController,
                    label: lang.t('calories'),
                    hint: '2000',
                    icon: Icons.local_fire_department,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMacroInput(
                    controller: _proteinController,
                    label: lang.t('protein'),
                    hint: '150',
                    icon: Icons.egg,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildMacroInput(
                    controller: _carbsController,
                    label: lang.t('carbs'),
                    hint: '200',
                    icon: Icons.grain,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMacroInput(
                    controller: _fatController,
                    label: lang.t('fat'),
                    hint: '60',
                    icon: Icons.water_drop,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Goal
            Text(
              lang.t('coach_nutrition_builder_goal_label'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['fat_loss', 'muscle_gain', 'maintenance'].map((goal) {
                final isSelected = _selectedGoal == goal;
                return FilterChip(
                  label: Text(_getGoalLabel(goal, lang)),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedGoal = goal;
                    });
                  },
                  selectedColor: AppColors.success.withValues(alpha: 0.2),
                  checkmarkColor: AppColors.success,
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Meals
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  lang.t('coach_nutrition_builder_meals_label'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _addFromTemplate(lang),
                  icon: const Icon(Icons.file_copy, size: 18),
                  label: Text(lang.t('coach_nutrition_builder_from_template')),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ..._meals.map((meal) => _buildMealCard(meal, lang)),

            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: CustomButton(
            text: lang.t('coach_nutrition_builder_save_plan'),
            onPressed: () => _savePlan(lang),
            variant: ButtonVariant.primary,
            size: ButtonSize.large,
            fullWidth: true,
          ),
        ),
      ),
      ),
    );
  }

  /// The plan exists only in widget state until save, so back would discard it.
  /// A named plan, any typed macro target, or any added meal counts as work.
  bool get _hasUnsavedWork {
    if (_isSaving) return false;
    if (_planNameController.text.trim().isNotEmpty) return true;
    if (_meals.isNotEmpty) return true;
    return [_caloriesController, _proteinController, _carbsController,
            _fatController]
        .any((c) => c.text.trim().isNotEmpty);
  }

  Widget _buildMacroInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color color,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: color, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildMealCard(Map<String, dynamic> meal, LanguageProvider lang) {
    final foods = meal['foods'] as List;
    final mealType = meal['type'] as String;

    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    _getMealIcon(mealType),
                    color: AppColors.success,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _getMealLabel(mealType, lang),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                tooltip: 'Add food',
                icon: const Icon(Icons.add, size: 20),
                onPressed: () => _addFood(mealType, lang),
              ),
            ],
          ),
          if (foods.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  lang.t('coach_nutrition_builder_no_foods'),
                  style: TextStyle(
                    color: context.palette.textSecondary,
                  ),
                ),
              ),
            )
          else
            ...foods.asMap().entries.map((entry) {
              final index = entry.key;
              final food = entry.value;
              return ListTile(
                leading: const Icon(Icons.restaurant_menu, size: 20),
                title: Text(food['name'] ?? ''),
                subtitle: Text(
                  '${food['calories']} cal | P: ${food['protein']}g | C: ${food['carbs']}g | F: ${food['fat']}g',
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: IconButton(
                  tooltip: 'Delete food',
                  icon:
                      const Icon(Icons.delete, size: 20, color: AppColors.error),
                  onPressed: () {
                    setState(() {
                      foods.removeAt(index);
                    });
                  },
                ),
              );
            }),
        ],
      ),
    );
  }

  IconData _getMealIcon(String type) {
    switch (type) {
      case 'breakfast':
        return Icons.breakfast_dining;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      case 'snack':
        return Icons.cookie;
      default:
        return Icons.restaurant;
    }
  }

  String _getMealLabel(String type, LanguageProvider lang) {
    switch (type) {
      case 'breakfast':
        return lang.t('coach_nutrition_builder_meal_breakfast');
      case 'lunch':
        return lang.t('coach_nutrition_builder_meal_lunch');
      case 'dinner':
        return lang.t('coach_nutrition_builder_meal_dinner');
      case 'snack':
        return lang.t('coach_nutrition_builder_meal_snack');
      default:
        return type;
    }
  }

  String _getGoalLabel(String goal, LanguageProvider lang) {
    if (goal == 'maintenance') {
      return lang.t('maintenance');
    }
    return lang.t(goal);
  }

  /// Adds one item to a meal.
  ///
  /// Picking a library meal here used to record a name and an id and leave the
  /// four macro boxes empty, so the coach retyped numbers the engine already
  /// knows. Now choosing a meal selects a portion, and the portion fills the
  /// macros — the same order the admin plan editor works in.
  void _addFood(String mealType, LanguageProvider lang) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final calories = TextEditingController(text: '0');
        final protein = TextEditingController(text: '0');
        final carbs = TextEditingController(text: '0');
        final fat = TextEditingController(text: '0');
        String foodName = '';
        RecipeMealOption? selectedMeal;
        RecipeVariantOption? selectedVariant;
        var pickEpoch = 0;

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            void applyVariant(RecipeVariantOption variant) {
              selectedVariant = variant;
              calories.text = variant.calories.round().toString();
              protein.text = _macroText(variant.protein);
              carbs.text = _macroText(variant.carbs);
              fat.text = _macroText(variant.fat);
            }

            final fromLibrary = selectedMeal != null;

            return AlertDialog(
              title: Text(lang.t('coach_nutrition_builder_add_food_title')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LibraryPickerField<RecipeMealOption>(
                      key: ValueKey('food:$pickEpoch'),
                      initialValue: foodName,
                      labelText:
                          lang.t('coach_nutrition_builder_food_name_label'),
                      options: _mealOptions,
                      optionLabel: (option) => option.name,
                      optionDetail: (option) => option.detail,
                      onTextChanged: (value) {
                        foodName = value;
                        // Typed over: no recipe stands behind this name any
                        // more, so the macros go back to being the coach's.
                        if (selectedMeal != null) {
                          setDialogState(() {
                            selectedMeal = null;
                            selectedVariant = null;
                          });
                        }
                      },
                      onSelected: (option) => setDialogState(() {
                        pickEpoch++;
                        foodName = option.name;
                        selectedMeal = option;
                        final variant = option.defaultVariant;
                        if (variant != null) applyVariant(variant);
                      }),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: ValueKey(
                          'foodPortion:${selectedMeal?.recipeId ?? ''}:${selectedVariant?.variantId ?? ''}'),
                      initialValue: selectedVariant?.variantId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: lang.t('plan_editor_portion'),
                        helperText: fromLibrary
                            ? null
                            : lang.t('plan_editor_select_meal_first'),
                      ),
                      items: (selectedMeal?.variants ??
                              const <RecipeVariantOption>[])
                          .map((variant) => DropdownMenuItem<String>(
                                value: variant.variantId,
                                child: Text(
                                  '${variant.portionCode} · '
                                  '${variant.calories.round()} ${lang.t('coach_nutrition_kcal')}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: !fromLibrary
                          ? null
                          : (variantId) {
                              final variant = selectedMeal!.variants.where(
                                  (item) => item.variantId == variantId);
                              if (variant.isEmpty) return;
                              setDialogState(() => applyVariant(variant.first));
                            },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: calories,
                      readOnly: fromLibrary,
                      decoration:
                          InputDecoration(labelText: lang.t('calories')),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: protein,
                            readOnly: fromLibrary,
                            decoration:
                                InputDecoration(labelText: lang.t('protein')),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: carbs,
                            readOnly: fromLibrary,
                            decoration:
                                InputDecoration(labelText: lang.t('carbs')),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: fat,
                            readOnly: fromLibrary,
                            decoration:
                                InputDecoration(labelText: lang.t('fat')),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(lang.t('cancel')),
                ),
                TextButton(
                  onPressed: () {
                    if (foodName.isEmpty) return;
                    setState(() {
                      final meal =
                          _meals.firstWhere((m) => m['type'] == mealType);
                      (meal['foods'] as List).add({
                        'name': foodName,
                        if (selectedMeal != null)
                          'recipeId': selectedMeal!.recipeId,
                        if (selectedVariant != null) ...{
                          'variantId': selectedVariant!.variantId,
                          'portionCode': selectedVariant!.portionCode,
                        },
                        'calories': int.tryParse(calories.text.trim()) ?? 0,
                        'protein': num.tryParse(protein.text.trim()) ?? 0,
                        'carbs': num.tryParse(carbs.text.trim()) ?? 0,
                        'fat': num.tryParse(fat.text.trim()) ?? 0,
                      });
                    });
                    Navigator.pop(dialogContext);
                  },
                  child: Text(lang.t('add')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static String _macroText(num value) => value == value.roundToDouble()
      ? value.round().toString()
      : value.toStringAsFixed(1);

  void _addFromTemplate(LanguageProvider lang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.t('coach_nutrition_builder_choose_template')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(lang.t('coach_nutrition_template_fat_loss')),
              onTap: () {
                Navigator.pop(context);
                _applyTemplate('fat_loss', lang);
              },
            ),
            ListTile(
              title: Text(lang.t('coach_nutrition_template_muscle_gain')),
              onTap: () {
                Navigator.pop(context);
                _applyTemplate('muscle_gain', lang);
              },
            ),
            ListTile(
              title: Text(lang.t('coach_nutrition_template_balanced')),
              onTap: () {
                Navigator.pop(context);
                _applyTemplate('balanced', lang);
              },
            ),
          ],
        ),
        // Every row here replaces the plan being built, so there has to be a
        // row that does not.
        actions: [dialogCancelAction(context)],
      ),
    );
  }

  Future<void> _savePlan(LanguageProvider lang) async {
    if (_planNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang.t('coach_nutrition_plan_name_required'),
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
          content: Text(lang.t('coach_nutrition_coach_missing')),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final dailyCalories = int.tryParse(_caloriesController.text.trim()) ?? 0;
    final protein = int.tryParse(_proteinController.text.trim()) ?? 0;
    final carbs = int.tryParse(_carbsController.text.trim()) ?? 0;
    final fat = int.tryParse(_fatController.text.trim()) ?? 0;

    if (dailyCalories <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang.t('coach_nutrition_calories_required')),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final macros = <String, dynamic>{
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
      };
      final mealPlan = <String, dynamic>{
        'name': _planNameController.text.trim(),
        'goal': _selectedGoal,
        'meals': _meals,
      };
      final notes = _selectedGoal;

      final success = await coachProvider.updateClientNutritionPlan(
        coachId,
        widget.clientId,
        dailyCalories,
        macros,
        mealPlan,
        notes,
      );

      if (!mounted) return;
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(lang.t('coach_nutrition_plan_saved')),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(coachProvider.error ?? lang.t('coach_nutrition_plan_save_failed')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

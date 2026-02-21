import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../providers/language_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/coach_provider.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';

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
  }

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

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.t('coach_nutrition_builder_title')),
        actions: [
          TextButton(
            onPressed: () => _savePlan(lang),
            child: Text(
              lang.t('save'),
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

            ..._meals.map((meal) => _buildMealCard(meal, lang)).toList(),

            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: lang.t('coach_nutrition_builder_save_plan'),
                onPressed: () => _savePlan(lang),
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
                  style: const TextStyle(
                    color: AppColors.textSecondary,
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
                  icon:
                      const Icon(Icons.delete, size: 20, color: AppColors.error),
                  onPressed: () {
                    setState(() {
                      foods.removeAt(index);
                    });
                  },
                ),
              );
            }).toList(),
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

  void _addFood(String mealType, LanguageProvider lang) {
    showDialog(
      context: context,
      builder: (context) {
        String foodName = '';
        int calories = 0;
        int protein = 0;
        int carbs = 0;
        int fat = 0;

        return AlertDialog(
          title: Text(lang.t('coach_nutrition_builder_add_food_title')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: lang.t('coach_nutrition_builder_food_name_label'),
                  ),
                  onChanged: (value) => foodName = value,
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    labelText: lang.t('calories'),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => calories = int.tryParse(value) ?? 0,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: lang.t('protein'),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) =>
                            protein = int.tryParse(value) ?? 0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: lang.t('carbs'),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) => carbs = int.tryParse(value) ?? 0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: lang.t('fat'),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) => fat = int.tryParse(value) ?? 0,
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
                if (foodName.isNotEmpty) {
                  setState(() {
                    final meal = _meals.firstWhere((m) => m['type'] == mealType);
                    (meal['foods'] as List).add({
                      'name': foodName,
                      'calories': calories,
                      'protein': protein,
                      'carbs': carbs,
                      'fat': fat,
                    });
                  });
                  Navigator.pop(context);
                }
              },
              child: Text(lang.t('add')),
            ),
          ],
        );
      },
    );
  }

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

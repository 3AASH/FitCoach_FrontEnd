import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/nutrition_plan.dart';
import '../../providers/coach_provider.dart';
import '../../providers/language_provider.dart';
import '../../widgets/custom_button.dart';
import '../../../core/constants/colors.dart';

/// Nutrition Plan Editor Screen
/// Allows coach to edit client's nutrition plan
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
  NutritionPlan? _currentPlan;

  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();
  final TextEditingController _fatsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  Map<String, dynamic> _mealPlan = {};

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
    final plan = await provider.getClientNutritionPlan(
      widget.coachId,
      widget.clientId,
    );

    if (plan != null) {
      setState(() {
        _currentPlan = plan;
        _caloriesController.text = plan.dailyCalories?.toString() ?? '';
        _proteinController.text = plan.macros?['protein']?.toString() ?? '';
        _carbsController.text = plan.macros?['carbs']?.toString() ?? '';
        _fatsController.text = plan.macros?['fats']?.toString() ?? '';
        _notesController.text = plan.notes ?? '';
        _mealPlan = plan.mealPlan ?? {};
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _savePlan() async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    // Validate
    if (_caloriesController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang.t('coach_nutrition_editor_calories_required')),
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
    final success = await provider.updateClientNutritionPlan(
      widget.coachId,
      widget.clientId,
      int.tryParse(_caloriesController.text) ?? 0,
      {
        'protein': int.tryParse(_proteinController.text) ?? 0,
        'carbs': int.tryParse(_carbsController.text) ?? 0,
        'fats': int.tryParse(_fatsController.text) ?? 0,
      },
      _mealPlan,
      _notesController.text,
    );

    Navigator.of(context).pop(); // Close loading

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang.t('coach_nutrition_editor_update_success'),
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop(true); // Go back with success
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang.t('coach_nutrition_editor_update_failed'),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.t('coach_nutrition_editor_title')),
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
                                  lang.t('coach_nutrition_editor_current_plan'),
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
                                lang.t(
                                  'coach_nutrition_editor_customized_by_coach',
                                ),
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

                  // Calories section
                  Text(
                    lang.t('coach_nutrition_editor_daily_calories'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _caloriesController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: lang.t('calories'),
                      hintText: '2000',
                      suffixText: lang.t('coach_nutrition_kcal'),
                      border: const OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Macros section
                  Text(
                    lang.t('coach_nutrition_editor_macronutrients'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _proteinController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: lang.t('protein'),
                            hintText: '150',
                            suffixText: lang.t('coach_nutrition_grams'),
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
                            labelText: lang.t('carbs'),
                            hintText: '200',
                            suffixText: lang.t('coach_nutrition_grams'),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: _fatsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: lang.t('fat'),
                      hintText: '65',
                      suffixText: lang.t('coach_nutrition_grams'),
                      border: const OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Meal plan preview
                  Text(
                    lang.t('coach_nutrition_editor_meal_plan'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_mealPlan.isEmpty)
                            Text(
                              lang.t('coach_nutrition_editor_no_meals'),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _mealPlan.keys.map((mealType) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    '- $mealType: ${_mealPlan[mealType].length} ${lang.t('coach_nutrition_builder_meals_label')}',
                                  ),
                                );
                              }).toList(),
                            ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: () {
                              // Navigate to meal plan builder
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    lang.t('coach_nutrition_editor_use_builder'),
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.edit),
                            label: Text(
                              lang.t('coach_nutrition_editor_edit_meals'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Notes
                  Text(
                    lang.t('coach_nutrition_editor_notes'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: lang.t('coach_nutrition_editor_notes_hint'),
                      border: const OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Save button
                  CustomButton(
                    text: lang.t('coach_nutrition_editor_save_changes'),
                    onPressed: _savePlan,
                    icon: Icons.save,
                  ),

                  const SizedBox(height: 16),

                  // Cancel button
                  CustomButton(
                    text: lang.t('cancel'),
                    onPressed: () => Navigator.of(context).pop(),
                    variant: ButtonVariant.secondary,
                  ),
                ],
              ),
            ),
    );
  }
}

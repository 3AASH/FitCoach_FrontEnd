import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/colors.dart';
import '../../../data/models/nutrition_plan.dart';
import '../../providers/language_provider.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';

class MealDetailScreen extends StatelessWidget {
  final Meal meal;

  const MealDetailScreen({super.key, required this.meal});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final isArabic = lang.isArabic;

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.t('meal_detail_title')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CustomCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: _mealColor(meal.type).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        _mealIcon(meal.type),
                        color: _mealColor(meal.type),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isArabic ? meal.nameAr : meal.nameEn,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${meal.time} • ${meal.calories} ${lang.t('cal_unit')}',
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _MacroRow(
                  title: lang.t('meal_detail_macros'),
                  protein: meal.macros.protein,
                  carbs: meal.macros.carbs,
                  fats: meal.macros.fats,
                  lang: lang,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            lang.t('meal_detail_ingredients'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...meal.foods.map(
            (food) => CustomCard(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                leading: const Icon(Icons.restaurant_menu, color: AppColors.primary),
                title: Text(isArabic ? food.nameAr : food.nameEn),
                subtitle: Text(
                  '${food.quantity}${food.unit} • ${food.calories} ${lang.t('cal_unit')}',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${food.macros.protein.round()}P'),
                    Text('${food.macros.carbs.round()}C', style: const TextStyle(color: AppColors.textSecondary)),
                    Text('${food.macros.fats.round()}F', style: const TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
          ),
          if ((meal.instructions?.isNotEmpty ?? false) || (meal.instructionsAr?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 12),
            Text(
              lang.t('meal_detail_notes'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            CustomCard(
              child: Text(
                isArabic ? (meal.instructionsAr ?? meal.instructions ?? '') : (meal.instructionsEn ?? meal.instructions ?? ''),
                style: const TextStyle(height: 1.5),
              ),
            ),
          ],
          const SizedBox(height: 24),
          CustomButton(
            text: lang.t('meal_detail_swap'),
            onPressed: () => _showSwapDialog(context, lang),
            variant: ButtonVariant.secondary,
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Color _mealColor(String type) {
    switch (type.toLowerCase()) {
      case 'breakfast':
        return AppColors.warning;
      case 'lunch':
        return AppColors.secondaryForeground;
      case 'dinner':
        return AppColors.primary;
      default:
        return AppColors.accent;
    }
  }

  IconData _mealIcon(String type) {
    switch (type.toLowerCase()) {
      case 'breakfast':
        return Icons.free_breakfast;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      default:
        return Icons.cookie;
    }
  }

  void _showSwapDialog(BuildContext context, LanguageProvider lang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.t('meal_detail_swap')),
        content: Text(lang.t('coach_messages_coming_soon')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(lang.t('done')),
          ),
        ],
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  final String title;
  final double protein;
  final double carbs;
  final double fats;
  final LanguageProvider lang;

  const _MacroRow({
    required this.title,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _MacroChip(label: lang.t('protein'), value: protein),
            const SizedBox(width: 12),
            _MacroChip(label: lang.t('carbs'), value: carbs),
            const SizedBox(width: 12),
            _MacroChip(label: lang.t('fats'), value: fats),
          ],
        ),
      ],
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final double value;

  const _MacroChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${value.round()} g',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

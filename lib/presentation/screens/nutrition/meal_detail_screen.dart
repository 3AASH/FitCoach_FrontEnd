import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/colors.dart';
import '../../../data/models/nutrition_plan.dart';
import '../../providers/language_provider.dart';
import '../../providers/nutrition_provider.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';

class MealDetailScreen extends StatelessWidget {
  final Meal meal;

  const MealDetailScreen({super.key, required this.meal});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final isArabic = lang.isArabic;
    final mealName = _localizedMealName(meal, isArabic);

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
                            mealName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${meal.time} • ${meal.calories} ${lang.t('cal_unit')}',
                            style:
                                const TextStyle(color: AppColors.textSecondary),
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
          if (meal.foods.isEmpty)
            CustomCard(
              child: Text(
                isArabic
                    ? 'لا توجد مكونات/تفاصيل متاحة'
                    : 'No ingredients/details available',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ...meal.foods.map(
            (food) => CustomCard(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                leading:
                    const Icon(Icons.restaurant_menu, color: AppColors.primary),
                title: Text(_localizedFoodName(food, isArabic)),
                subtitle: Text(
                  '${_formatQuantity(food)} - ${food.calories} ${lang.t('cal_unit')}',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${food.macros.protein.round()}P'),
                    Text('${food.macros.carbs.round()}C',
                        style: const TextStyle(color: AppColors.textSecondary)),
                    Text('${food.macros.fats.round()}F',
                        style: const TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            lang.t('meal_detail_notes'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          CustomCard(
            child: Text(
              (isArabic
                              ? (meal.instructionsAr ??
                                  meal.instructions ??
                                  meal.instructionsEn)
                              : (meal.instructionsEn ??
                                  meal.instructions ??
                                  meal.instructionsAr))
                          ?.trim()
                          .isNotEmpty ==
                      true
                  ? (isArabic
                      ? (meal.instructionsAr ??
                          meal.instructions ??
                          meal.instructionsEn)
                      : (meal.instructionsEn ??
                          meal.instructions ??
                          meal.instructionsAr))!
                  : (isArabic
                      ? 'لا توجد مكونات/تفاصيل متاحة'
                      : 'No ingredients/details available'),
              style: const TextStyle(height: 1.5),
            ),
          ),
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

  String _localizedMealName(Meal meal, bool isArabic) {
    final localized = isArabic ? meal.nameAr : meal.nameEn;
    return localized.trim().isNotEmpty ? localized : meal.name;
  }

  String _localizedFoodName(FoodItem food, bool isArabic) {
    final localized = isArabic ? food.nameAr : food.nameEn;
    if (localized.trim().isNotEmpty) return localized;
    return food.name.trim().isNotEmpty ? food.name : '-';
  }

  String _formatQuantity(FoodItem food) {
    final amount = food.quantity % 1 == 0
        ? food.quantity.round().toString()
        : food.quantity.toStringAsFixed(1);
    return '$amount${food.unit}';
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

  Future<void> _showSwapDialog(BuildContext context, LanguageProvider lang) async {
    final swapped = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => MealSwapSheet(meal: meal),
    );
    if (swapped != true || !context.mounted) return;
    // The Meal held by this screen is now stale, so hand control back to the
    // plan screen, which reloads from the provider.
    Navigator.of(context).pop(true);
  }

}

/// Lists the meals this one can be exchanged for and applies the choice.
///
/// Public so the nutrition plan screen can open the same sheet straight from a
/// meal card, without routing through the detail screen first.
class MealSwapSheet extends StatefulWidget {
  final Meal meal;

  const MealSwapSheet({super.key, required this.meal});

  @override
  State<MealSwapSheet> createState() => _MealSwapSheetState();
}

class _MealSwapSheetState extends State<MealSwapSheet> {
  List<MealAlternative>? _alternatives;
  String? _applyingVariantId;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final provider = context.read<NutritionProvider>();
    final alternatives = await provider.getMealAlternatives(widget.meal.id);
    if (!mounted) return;
    setState(() => _alternatives = alternatives);
  }

  Future<void> _apply(MealAlternative alternative) async {
    if (_applyingVariantId != null) return;
    setState(() {
      _applyingVariantId = alternative.variantId;
      _error = null;
    });

    final provider = context.read<NutritionProvider>();
    final ok = await provider.swapMeal(widget.meal.id, alternative.variantId);
    if (!mounted) return;

    if (!ok) {
      setState(() {
        _applyingVariantId = null;
        // Show the reason the server gave, which distinguishes "already
        // logged" from "not an option" rather than flattening both.
        _error = provider.error ?? context.read<LanguageProvider>().t('meal_swap_failed');
      });
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final isArabic = lang.isArabic;
    final alternatives = _alternatives;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    lang.t('meal_swap_title'),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Text(
              lang.t('meal_swap_subtitle'),
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppColors.error)),
            ],
            const SizedBox(height: 12),
            if (alternatives == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (alternatives.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    lang.t('meal_swap_none'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: alternatives.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final alternative = alternatives[index];
                    final busy = _applyingVariantId == alternative.variantId;
                    final delta = alternative.calorieDelta;
                    final deltaText = delta == 0
                        ? ''
                        : ' (${delta > 0 ? '+' : ''}$delta)';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      enabled: _applyingVariantId == null,
                      title: Text(alternative.displayName(isArabic)),
                      subtitle: Text(
                        '${alternative.calories} ${lang.t('cal_unit')}$deltaText  •  '
                        '${alternative.protein.round()}P '
                        '${alternative.carbs.round()}C '
                        '${alternative.fats.round()}F',
                      ),
                      leading: alternative.suggestedByTemplate
                          ? Tooltip(
                              message: lang.t('meal_swap_suggested'),
                              child: const Icon(Icons.star,
                                  color: AppColors.primary, size: 20),
                            )
                          : const Icon(Icons.swap_horiz,
                              color: AppColors.textSecondary, size: 20),
                      trailing: busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.chevron_right),
                      onTap: () => _apply(alternative),
                    );
                  },
                ),
              ),
          ],
        ),
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

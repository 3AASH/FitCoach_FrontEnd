import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/colors.dart';
import '../../providers/admin_provider.dart';
import '../../providers/language_provider.dart';
import '../../widgets/custom_card.dart';
import '../../../core/theme/app_palette.dart';

enum _AdminNutritionAction {
  importEngineSeed,
}

typedef _JsonSaveCallback = Future<bool> Function(Map<String, dynamic> payload);

class AdminNutritionTemplatesScreen extends StatefulWidget {
  const AdminNutritionTemplatesScreen({super.key});

  @override
  State<AdminNutritionTemplatesScreen> createState() =>
      _AdminNutritionTemplatesScreenState();
}

class _AdminNutritionTemplatesScreenState
    extends State<AdminNutritionTemplatesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this)
      ..addListener(() {
        if (!_tabController.indexIsChanging && mounted) {
          setState(() {});
        }
      });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    final provider = context.read<AdminProvider>();
    await Future.wait([
      provider.loadNutritionEngineRecipes(),
      provider.loadNutritionEnginePlans(),
      provider.loadNutritionIngredients(),
      provider.loadNutritionRecipeVariants(),
      provider.loadNutritionEngineImports(),
    ]);
  }

  Future<void> _refreshCurrent() {
    final provider = context.read<AdminProvider>();
    switch (_tabController.index) {
      case 0:
        return provider.loadNutritionEngineRecipes();
      case 1:
        return provider.loadNutritionIngredients();
      case 2:
        return provider.loadNutritionEnginePlans();
      case 3:
        return provider.loadNutritionEngineImports();
      default:
        return provider.loadNutritionEngineRecipes();
    }
  }

  Future<void> _handleAction(_AdminNutritionAction action) {
    switch (action) {
      case _AdminNutritionAction.importEngineSeed:
        return _importEngineSeed();
    }
  }

  Future<void> _importEngineSeed() async {
    final provider = context.read<AdminProvider>();
    final ok = await provider.importNutritionEngineSeed();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? context.read<LanguageProvider>().t(
                  'plan_editor_engine_seed_imported',
                )
            : provider.error ??
                context
                    .read<LanguageProvider>()
                    .t('plan_editor_seed_import_failed')),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.t('admin_nutrition_templates_title')),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(
              text: lang.t('plan_editor_engine_meals'),
              icon: const Icon(Icons.ramen_dining),
            ),
            Tab(
              text: lang.t('plan_editor_ingredients'),
              icon: const Icon(Icons.inventory_2_outlined),
            ),
            Tab(
              text: lang.t('plan_editor_engine_plans'),
              icon: const Icon(Icons.calendar_month),
            ),
            Tab(
              text: lang.t('plan_editor_imports'),
              icon: const Icon(Icons.history),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<_AdminNutritionAction>(
            tooltip: lang.t('plan_editor_nutrition_actions'),
            onSelected: _handleAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _AdminNutritionAction.importEngineSeed,
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.cloud_upload),
                  title: Text(lang.t('plan_editor_import_engine_seed')),
                ),
              ),
            ],
          ),
          IconButton(
            tooltip: lang.t('refresh'),
            onPressed: _refreshCurrent,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (provider.error != null)
              _InlineError(
                message: provider.error!,
                onDismiss: provider.clearError,
              ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildEngineRecipesTab(provider),
                  _buildIngredientsTab(provider),
                  _buildEnginePlansTab(provider),
                  _buildImportsTab(provider),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildTabFab(lang),
    );
  }

  /// Each tab owns exactly one create action. "Add meal" only ever belongs to
  /// the engine meals tab; the ingredients and plans tabs create their own
  /// entity, and the read-only imports tab gets no button at all.
  Widget? _buildTabFab(LanguageProvider lang) {
    switch (_tabController.index) {
      case 0:
        return FloatingActionButton.extended(
          onPressed: _openNewRecipe,
          icon: const Icon(Icons.add),
          label: Text(lang.t('plan_editor_add_meal')),
        );
      case 1:
        return FloatingActionButton.extended(
          onPressed: _addIngredientFromTab,
          icon: const Icon(Icons.add),
          label: Text(lang.t('plan_editor_add_ingredient_button')),
        );
      case 2:
        return FloatingActionButton.extended(
          onPressed: _openNewPlan,
          icon: const Icon(Icons.add),
          label: Text(lang.t('plan_editor_add_plan')),
        );
      default:
        return null;
    }
  }

  Widget _buildEngineRecipesTab(AdminProvider provider) {
    final recipes = provider.nutritionEngineRecipes;
    if (provider.isLoading && recipes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (recipes.isEmpty) {
      return _EmptyList(
        message:
            context.watch<LanguageProvider>().t('plan_editor_no_engine_meals'),
        onRefresh: () => provider.loadNutritionEngineRecipes(),
      );
    }
    return RefreshIndicator(
      onRefresh: () => provider.loadNutritionEngineRecipes(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: recipes.length,
        itemBuilder: (context, index) {
          final recipe = recipes[index];
          return _NutritionEngineRecipeCard(
            recipe: recipe,
            onEdit: () => _openRecipeEditor(recipe),
          );
        },
      ),
    );
  }

  Widget _buildEnginePlansTab(AdminProvider provider) {
    final plans = provider.nutritionEnginePlans;
    if (provider.isLoading && plans.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (plans.isEmpty) {
      return _EmptyList(
        message:
            context.watch<LanguageProvider>().t('plan_editor_no_engine_plans'),
        onRefresh: () => provider.loadNutritionEnginePlans(),
      );
    }
    return RefreshIndicator(
      onRefresh: () => provider.loadNutritionEnginePlans(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: plans.length,
        itemBuilder: (context, index) {
          final plan = plans[index];
          return _NutritionEnginePlanCard(
            plan: plan,
            onEdit: () => _openPlanEditor(plan),
          );
        },
      ),
    );
  }

  Widget _buildIngredientsTab(AdminProvider provider) {
    final ingredients = provider.nutritionIngredients;
    final lang = context.watch<LanguageProvider>();
    if (provider.isLoading && ingredients.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (ingredients.isEmpty) {
      return _EmptyList(
        message: lang.t('plan_editor_no_ingredients'),
        onRefresh: provider.loadNutritionIngredients,
      );
    }
    return RefreshIndicator(
      onRefresh: provider.loadNutritionIngredients,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        itemCount: ingredients.length,
        itemBuilder: (context, index) {
          final ingredient = ingredients[index];
          final macros = _ingredientPer100g(ingredient);
          final name = lang.isArabic
              ? _firstText([
                  ingredient['name_ar'],
                  ingredient['name_en'],
                  ingredient['ingredient_id'],
                ])
              : _firstText([
                  ingredient['name_en'],
                  ingredient['ingredient_id'],
                ]);
          return ListTile(
            isThreeLine: true,
            title: Text(name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // Per-100 g definition, so the admin can read the macros
                  // without opening the row.
                  '${lang.t('plan_editor_calories')} ${_macroText(macros['calories'] ?? 0)} - '
                  'P ${_macroText(macros['protein_g'] ?? 0)} - '
                  'C ${_macroText(macros['carbs_g'] ?? 0)} - '
                  'F ${_macroText(macros['fat_g'] ?? 0)} / 100 g',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  _stringValue(ingredient['ingredient_id']),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.palette.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            trailing: Icon(ingredient['is_active'] == false
                ? Icons.visibility_off_outlined
                : Icons.edit_outlined),
            onTap: () => _editIngredient(ingredient),
          );
        },
      ),
    );
  }

  Future<void> _addIngredientFromTab() async {
    final payload = await _showIngredientForm(context);
    if (payload == null || !mounted) return;
    final lang = context.read<LanguageProvider>();
    final provider = context.read<AdminProvider>();
    final created = await provider.createNutritionIngredient(payload);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(created != null
          ? lang.t('admin_ingredient_saved')
          : provider.error ?? lang.t('plan_editor_save_failed')),
      backgroundColor: created != null ? AppColors.success : AppColors.error,
    ));
  }

  Future<void> _editIngredient(Map<String, dynamic> ingredient) async {
    final id = _stringValue(ingredient['ingredient_id']);
    if (id.isEmpty) return;
    final payload = await _showIngredientForm(context, existing: ingredient);
    if (payload == null || !mounted) return;
    final lang = context.read<LanguageProvider>();
    final provider = context.read<AdminProvider>();
    final success = await provider.updateNutritionIngredient(id, payload);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success
          ? lang.t('admin_ingredient_saved')
          : provider.error ?? lang.t('plan_editor_save_failed')),
      backgroundColor: success ? AppColors.success : AppColors.error,
    ));
  }

  Widget _buildImportsTab(AdminProvider provider) {
    final imports = provider.nutritionEngineImports;
    if (provider.isLoading && imports.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (imports.isEmpty) {
      return _EmptyList(
        message: context
            .watch<LanguageProvider>()
            .t('plan_editor_no_engine_imports'),
        onRefresh: () => provider.loadNutritionEngineImports(),
      );
    }
    return RefreshIndicator(
      onRefresh: () => provider.loadNutritionEngineImports(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: imports.length,
        itemBuilder: (context, index) {
          return _NutritionEngineImportCard(importRecord: imports[index]);
        },
      ),
    );
  }

  Future<void> _openRecipeEditor(Map<String, dynamic> recipeSummary) async {
    final recipeId = _stringValue(recipeSummary['recipe_id']);
    if (recipeId.isEmpty) return;

    final fullRecipe =
        await context.read<AdminProvider>().getNutritionEngineRecipe(recipeId);
    if (!mounted || fullRecipe == null) return;
    final provider = context.read<AdminProvider>();
    if (provider.nutritionIngredients.isEmpty) {
      await provider.loadNutritionIngredients();
      if (!mounted) return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _NutritionRecipeEditorSheet(
        initialRecipe: fullRecipe,
        availableIngredients: context.read<AdminProvider>().nutritionIngredients,
        onSave: context.read<AdminProvider>().saveNutritionEngineRecipe,
      ),
    );
  }

  Future<void> _openNewRecipe() async {
    final provider = context.read<AdminProvider>();
    if (provider.nutritionIngredients.isEmpty) {
      await provider.loadNutritionIngredients();
      if (!mounted) return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _NutritionRecipeEditorSheet(
        initialRecipe: const {
          'schema_version': '1.0.0',
          'name_en': '', 'name_ar': '', 'market_tags': ['SA'],
          'cuisine': 'International', 'meal_types': ['snack'], 'diet_tags': [],
          'allergens': [], 'cost_level': 'medium', 'prep_time_min': 10,
          'difficulty': 'easy', 'ingredients_base_g': {}, 'base_nutrition': {},
          'macro_profile_hint': 'balanced',
          'portion_variants': [
            {'portion_code': 'M', 'scale_factor': 1, 'ingredients_g': {}, 'nutrition': {}, 'equivalence_group': 'admin_created'}
          ],
          'preparation': {'steps_en': [], 'steps_ar': []},
          'validation': {'status': 'admin_edited'},
          'metadata': {'version': 1, 'active': true},
        },
        availableIngredients: context.read<AdminProvider>().nutritionIngredients,
        onSave: context.read<AdminProvider>().createNutritionEngineRecipe,
        isNew: true,
      ),
    );
  }

  Future<void> _openPlanEditor(Map<String, dynamic> planSummary) async {
    final planId = _stringValue(planSummary['plan_id']);
    if (planId.isEmpty) return;

    final fullPlan =
        await context.read<AdminProvider>().getNutritionEnginePlan(planId);
    if (!mounted || fullPlan == null) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _NutritionEnginePlanEditorSheet(
        initialPlan: fullPlan,
        availableVariants: context.read<AdminProvider>().nutritionRecipeVariants,
        onSave: context.read<AdminProvider>().saveNutritionEnginePlan,
      ),
    );
  }

  Future<void> _openNewPlan() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _NutritionEnginePlanEditorSheet(
        initialPlan: const {
          'schema_version': '1.0.0', 'plan_type': 'professional', 'market': 'SA',
          'calorie_band': 2000, 'macro_profile': 'balanced', 'meal_count': 3,
          'rotation': 1, 'template_target': {}, 'days': [],
          'assignment_rules': {}, 'validation': {'status': 'admin_edited'},
        },
        availableVariants: context.read<AdminProvider>().nutritionRecipeVariants,
        onSave: context.read<AdminProvider>().saveNutritionEnginePlan,
        isNew: true,
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _InlineError({
    required this.message,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      color: AppColors.error.withValues(alpha: 0.08),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ),
          IconButton(
            tooltip: context.watch<LanguageProvider>().t('dismiss'),
            onPressed: onDismiss,
            icon: const Icon(Icons.close, size: 18),
          ),
        ],
      ),
    );
  }
}

class _EmptyList extends StatelessWidget {
  final String message;
  final Future<void> Function() onRefresh;

  const _EmptyList({
    required this.message,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 160),
          Center(
            child: Text(
              message,
              style: TextStyle(color: context.palette.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _NutritionEngineRecipeCard extends StatelessWidget {
  final Map<String, dynamic> recipe;
  final VoidCallback onEdit;

  const _NutritionEngineRecipeCard({
    required this.recipe,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final recipeId = _stringValue(recipe['recipe_id']);
    final name = lang.isArabic
        ? _firstText([recipe['name_ar'], recipe['name_en'], recipeId])
        : _firstText([recipe['name_en'], recipeId]);
    final markets = _listText(recipe['market_tags']);
    final mealTypes = _listText(recipe['meal_types']);
    final status = _stringValue(recipe['validation_status']);
    final active = recipe['is_active'] == false
        ? lang.t('plan_editor_inactive')
        : lang.t('plan_editor_active');
    final prep = _stringValue(recipe['prep_time_min'], fallback: '-');
    final cost = _stringValue(recipe['cost_level'], fallback: '-');
    final editedAt = _stringValue(recipe['admin_edited_at']);

    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.ramen_dining, color: AppColors.success),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$recipeId - $mealTypes - $markets',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.palette.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _MetaText(lang.t(
                        'plan_editor_status',
                        args: {'value': status},
                      )),
                      _MetaText(active),
                      _MetaText(lang.t(
                        'plan_editor_prep',
                        args: {'value': prep},
                      )),
                      _MetaText(lang.t(
                        'plan_editor_cost',
                        args: {'value': cost},
                      )),
                      if (editedAt.isNotEmpty)
                        _MetaText(lang.t('plan_editor_admin_edited')),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: lang.t('admin_edit_json'),
              onPressed: onEdit,
              icon: const Icon(Icons.data_object),
            ),
          ],
        ),
      ),
    );
  }
}

class _NutritionEnginePlanCard extends StatelessWidget {
  final Map<String, dynamic> plan;
  final VoidCallback onEdit;

  const _NutritionEnginePlanCard({
    required this.plan,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final planId = _stringValue(plan['plan_id']);
    final planType = _stringValue(plan['plan_type']);
    final market = _stringValue(plan['market']);
    final calories = _stringValue(plan['calorie_band']);
    final macroProfile = _stringValue(plan['macro_profile']);
    final mealCount = _stringValue(plan['meal_count']);
    final rotation = _stringValue(plan['rotation']);
    final status = _stringValue(plan['validation_status']);
    final active = plan['is_active'] == false
        ? lang.t('plan_editor_inactive')
        : lang.t('plan_editor_active');
    final editedAt = _stringValue(plan['admin_edited_at']);

    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.calendar_month, color: AppColors.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    planId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$planType - $market - $calories kcal - $macroProfile',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.palette.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _MetaText(lang.t(
                        'plan_editor_meals',
                        args: {'value': mealCount},
                      )),
                      _MetaText('${lang.t('plan_editor_rotation')}: $rotation'),
                      _MetaText(lang.t(
                        'plan_editor_status',
                        args: {'value': status},
                      )),
                      _MetaText(active),
                      if (editedAt.isNotEmpty)
                        _MetaText(lang.t('plan_editor_admin_edited')),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: lang.t('admin_edit_json'),
              onPressed: onEdit,
              icon: const Icon(Icons.data_object),
            ),
          ],
        ),
      ),
    );
  }
}

class _NutritionEngineImportCard extends StatelessWidget {
  final Map<String, dynamic> importRecord;

  const _NutritionEngineImportCard({
    required this.importRecord,
  });

  @override
  Widget build(BuildContext context) {
    final packageName = _stringValue(importRecord['package_name']);
    final version = _stringValue(importRecord['package_version']);
    final checksum = _stringValue(importRecord['package_checksum']);
    final shortChecksum =
        checksum.length > 12 ? checksum.substring(0, 12) : checksum;
    final status = _stringValue(importRecord['status']);
    final count = _stringValue(importRecord['json_file_count'], fallback: '0');
    final completedAt = _stringValue(importRecord['completed_at']);
    final counts = importRecord['counts'] is Map
        ? Map<String, dynamic>.from(importRecord['counts'] as Map)
        : const <String, dynamic>{};
    final recipeCount = _stringValue(counts['base_recipes'], fallback: '-');
    final planCount = _stringValue(counts['total_plan_files'], fallback: '-');

    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.history, color: AppColors.info),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$packageName $version',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$status - $count JSON files - $completedAt',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.palette.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'checksum $shortChecksum - recipes $recipeCount - plans $planCount',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.palette.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaText extends StatelessWidget {
  final String text;

  const _MetaText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: context.palette.textSecondary,
        fontSize: 12,
      ),
    );
  }
}

class _JsonEditorSheet extends StatefulWidget {
  final String title;
  final String hint;
  final Map<String, dynamic>? initialJson;
  final Map<String, dynamic>? defaultJson;
  final _JsonSaveCallback onSave;
  final String successMessage;

  const _JsonEditorSheet({
    required this.title,
    required this.hint,
    required this.initialJson,
    required this.defaultJson,
    required this.onSave,
    required this.successMessage,
  });

  @override
  State<_JsonEditorSheet> createState() => _JsonEditorSheetState();
}

class _JsonEditorSheetState extends State<_JsonEditorSheet> {
  final TextEditingController _jsonController = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialJson ?? widget.defaultJson ?? const {};
    _jsonController.text = const JsonEncoder.withIndent('  ').convert(initial);
  }

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.96,
        builder: (context, scrollController) => Material(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(widget.title, style: AppTextStyles.h2),
                  ),
                  IconButton(
                    tooltip: context.watch<LanguageProvider>().t(
                          'plan_editor_close',
                        ),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              TextField(
                controller: _jsonController,
                maxLines: 24,
                minLines: 16,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: widget.hint,
                ),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: Text(
                  context.watch<LanguageProvider>().t('plan_editor_save_json'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _error = null);
    Map<String, dynamic> payload;
    try {
      final parsed = jsonDecode(_jsonController.text);
      if (parsed is! Map<String, dynamic>) {
        throw FormatException(
          context.read<LanguageProvider>().t('plan_editor_error_json_object'),
        );
      }
      payload = parsed;
    } catch (error) {
      setState(() => _error = error.toString());
      return;
    }

    final ok = await widget.onSave(payload);
    if (!mounted) return;
    final providerError = context.read<AdminProvider>().error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? widget.successMessage
            : providerError ??
                context.read<LanguageProvider>().t('plan_editor_save_failed')),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
    if (ok) Navigator.pop(context);
  }
}

class _NutritionRecipeEditorSheet extends StatefulWidget {
  final Map<String, dynamic> initialRecipe;
  final List<Map<String, dynamic>> availableIngredients;
  final _JsonSaveCallback onSave;
  final bool isNew;

  const _NutritionRecipeEditorSheet({
    required this.initialRecipe,
    required this.availableIngredients,
    required this.onSave,
    this.isNew = false,
  });

  @override
  State<_NutritionRecipeEditorSheet> createState() =>
      _NutritionRecipeEditorSheetState();
}

class _NutritionRecipeEditorSheetState
    extends State<_NutritionRecipeEditorSheet> {
  final TextEditingController _jsonController = TextEditingController();
  final TextEditingController _recipeIdController = TextEditingController();
  final TextEditingController _nameEnController = TextEditingController();
  final TextEditingController _nameArController = TextEditingController();
  final TextEditingController _mealTypesController = TextEditingController();
  final TextEditingController _cuisineController = TextEditingController();
  final TextEditingController _prepTimeController = TextEditingController();
  final TextEditingController _difficultyController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();
  final TextEditingController _fatController = TextEditingController();
  List<MapEntry<String, TextEditingController>> _ingredients = [];
  List<Map<String, dynamic>> _variants = [];
  // Preserve untouched recipe fields when saving from structured mode.
  late Map<String, dynamic> _rawRecipe;
  bool _jsonMode = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _rawRecipe = Map<String, dynamic>.from(widget.initialRecipe);
    _jsonController.text =
        const JsonEncoder.withIndent('  ').convert(_rawRecipe);
    _loadStructured(_rawRecipe);
  }

  @override
  void dispose() {
    _jsonController.dispose();
    _recipeIdController.dispose();
    _nameEnController.dispose();
    _nameArController.dispose();
    _mealTypesController.dispose();
    _cuisineController.dispose();
    _prepTimeController.dispose();
    _difficultyController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    for (final entry in _ingredients) {
      entry.value.dispose();
    }
    super.dispose();
  }

  void _loadStructured(Map<String, dynamic> recipe) {
    _recipeIdController.text = _stringValue(recipe['recipe_id']);
    _nameEnController.text = _stringValue(recipe['name_en']);
    _nameArController.text = _stringValue(recipe['name_ar']);
    _mealTypesController.text =
        (_asList(recipe['meal_types']) ?? const []).join(', ');
    _cuisineController.text = _stringValue(recipe['cuisine']);
    _prepTimeController.text =
        _stringValue(recipe['prep_time_min'], fallback: '10');
    _difficultyController.text =
        _stringValue(recipe['difficulty'], fallback: 'easy');
    final nutrition = _asMap(recipe['base_nutrition']) ?? const {};
    _caloriesController.text =
        _stringValue(nutrition['calories'], fallback: '0');
    _proteinController.text =
        _stringValue(nutrition['protein_g'], fallback: '0');
    _carbsController.text = _stringValue(nutrition['carbs_g'], fallback: '0');
    _fatController.text = _stringValue(nutrition['fat_g'], fallback: '0');

    for (final entry in _ingredients) {
      entry.value.dispose();
    }
    final ingredients = _asMap(recipe['ingredients_base_g']) ?? const {};
    _ingredients = ingredients.entries
        .map((entry) => MapEntry(
              entry.key,
              TextEditingController(text: _stringValue(entry.value)),
            ))
        .toList();
      _variants = (_asList(recipe['portion_variants']) ?? const [])
        .map((item) => Map<String, dynamic>.from(_asMap(item) ?? const {}))
        .toList();
  }

  Map<String, dynamic> _buildRecipe() {
    final merged = Map<String, dynamic>.from(_rawRecipe);
    if (!widget.isNew) merged['recipe_id'] = _recipeIdController.text.trim();
    merged['name_en'] = _nameEnController.text.trim();
    merged['name_ar'] = _nameArController.text.trim();
    merged['meal_types'] = _mealTypesController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    merged['cuisine'] = _cuisineController.text.trim();
    merged['prep_time_min'] = int.tryParse(_prepTimeController.text.trim());
    merged['difficulty'] = _difficultyController.text.trim();
    merged['base_nutrition'] = {
      'calories': num.tryParse(_caloriesController.text.trim()) ?? 0,
      'protein_g': num.tryParse(_proteinController.text.trim()) ?? 0,
      'carbs_g': num.tryParse(_carbsController.text.trim()) ?? 0,
      'fat_g': num.tryParse(_fatController.text.trim()) ?? 0,
    };
    merged['ingredients_base_g'] = {
      for (final entry in _ingredients)
        if (entry.key.trim().isNotEmpty)
          entry.key.trim(): num.tryParse(entry.value.text.trim()) ?? 0,
    };
    final baseIngredients = merged['ingredients_base_g'] as Map<String, dynamic>;
    merged['portion_variants'] = _variants.map((variant) {
      final scale = num.tryParse(_stringValue(variant['scale_factor'])) ?? 1;
      return {
        ...variant,
        'portion_code': _stringValue(variant['portion_code'], fallback: 'M'),
        'scale_factor': scale,
        'ingredients_g': baseIngredients.map((id, grams) => MapEntry(
            id, ((num.tryParse(_stringValue(grams)) ?? 0) * scale))),
      };
    }).toList();
    return merged;
  }

  void _addIngredient() {
    setState(() {
      _ingredients.add(MapEntry('', TextEditingController(text: '0')));
    });
  }

  Future<void> _createIngredient() async {
    final payload = await _showIngredientForm(context);
    if (payload == null || !mounted) return;
    final ingredient =
        await context.read<AdminProvider>().createNutritionIngredient(payload);
    if (!mounted || ingredient == null) return;
    setState(() => _ingredients.add(MapEntry(
        _stringValue(ingredient['ingredient_id']),
        TextEditingController(text: '0'))));
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients[index].value.dispose();
      _ingredients.removeAt(index);
    });
  }

  void _addVariant() {
    setState(() => _variants.add({
          'portion_code': 'M', 'scale_factor': 1,
          'nutrition': {}, 'equivalence_group': 'admin_created',
        }));
  }

  void _removeVariant(int index) {
    setState(() => _variants.removeAt(index));
  }

  void _renameIngredient(int index, String name) {
    final controller = _ingredients[index].value;
    setState(() {
      _ingredients[index] = MapEntry(name, controller);
    });
  }

  /// The sheet is handed a snapshot of the ingredient list, but creating an
  /// ingredient from inside the sheet replaces the provider's list. Read through
  /// to the provider so a just-created ingredient resolves its name and macros.
  List<Map<String, dynamic>> get _availableIngredients {
    final fromProvider = context.read<AdminProvider>().nutritionIngredients;
    return fromProvider.isEmpty ? widget.availableIngredients : fromProvider;
  }

  Map<String, dynamic>? _findIngredient(String ingredientId) {
    return _availableIngredients.cast<Map<String, dynamic>?>().firstWhere(
          (item) => _stringValue(item?['ingredient_id']) == ingredientId,
          orElse: () => null,
        );
  }

  void _recalculateRecipeMacros() {
    num calories = 0, protein = 0, carbs = 0, fat = 0;
    for (final entry in _ingredients) {
      // Ingredients are defined per 100 g, so scale by grams / 100 — the same
      // formula the backend uses when it recomputes the recipe on save.
      final perGram = _ingredientPerGram(_findIngredient(entry.key));
      final grams = num.tryParse(entry.value.text) ?? 0;
      calories += (perGram['calories'] ?? 0) * grams;
      protein += (perGram['protein_g'] ?? 0) * grams;
      carbs += (perGram['carbs_g'] ?? 0) * grams;
      fat += (perGram['fat_g'] ?? 0) * grams;
    }
    _caloriesController.text = calories.round().toString();
    _proteinController.text = protein.toStringAsFixed(2);
    _carbsController.text = carbs.toStringAsFixed(2);
    _fatController.text = fat.toStringAsFixed(2);
  }

  String _ingredientLabel(String ingredientId) {
    final ingredient = _findIngredient(ingredientId);
    return ingredient == null
        ? ingredientId
        : _stringValue(ingredient['name_en'], fallback: ingredientId);
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    final lang = context.watch<LanguageProvider>();
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.94,
        minChildSize: 0.5,
        maxChildSize: 0.98,
        builder: (context, scrollController) => Material(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      lang.t('plan_editor_engine_meal_json_title'),
                      style: AppTextStyles.h2,
                    ),
                  ),
                  IconButton(
                    tooltip: lang.t('plan_editor_close'),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(
                    value: false,
                    icon: const Icon(Icons.ramen_dining),
                    label: Text(lang.t('plan_editor_plan')),
                  ),
                  ButtonSegment(
                    value: true,
                    icon: const Icon(Icons.data_object),
                    label: Text(lang.t('plan_editor_json')),
                  ),
                ],
                selected: {_jsonMode},
                onSelectionChanged: (selection) {
                  setState(() {
                    if (selection.first) {
                      _jsonController.text = const JsonEncoder.withIndent('  ')
                          .convert(_buildRecipe());
                    } else {
                      try {
                        final parsed = jsonDecode(_jsonController.text);
                        if (parsed is Map<String, dynamic>) {
                          _rawRecipe = parsed;
                          _loadStructured(parsed);
                        }
                      } catch (_) {
                        // Keep current structured values if JSON parsing fails.
                      }
                    }
                    _jsonMode = selection.first;
                  });
                },
              ),
              const SizedBox(height: 16),
              if (_jsonMode)
                TextField(
                  controller: _jsonController,
                  maxLines: 24,
                  minLines: 16,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: lang.t('plan_editor_engine_meal_json_hint'),
                  ),
                  style:
                      const TextStyle(fontFamily: 'monospace', fontSize: 13),
                )
              else
                _buildRecipeEditor(lang),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: Text(lang.t('plan_editor_save_json')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeEditor(LanguageProvider lang) {
    return Column(
      children: [
        if (!widget.isNew) ...[
          TextField(
            controller: _recipeIdController,
            readOnly: true,
            decoration: InputDecoration(
              labelText: lang.t('plan_editor_recipe_id'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _nameEnController,
                decoration: InputDecoration(
                  labelText: lang.t('admin_exercise_english_name'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _nameArController,
                decoration: InputDecoration(
                  labelText: lang.t('admin_exercise_arabic_name'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _mealTypesController,
                decoration: InputDecoration(
                  labelText: lang.t('plan_editor_slot'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _cuisineController,
                decoration: InputDecoration(
                  labelText: lang.t('plan_editor_cuisine'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _prepTimeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: lang.t('plan_editor_prep_time_minutes'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _difficultyController,
                decoration: InputDecoration(
                  labelText: lang.t('admin_exercise_difficulty'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _caloriesController,
                keyboardType: TextInputType.number,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: lang.t('plan_editor_calories'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _proteinController,
                keyboardType: TextInputType.number,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: lang.t('plan_editor_protein'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _carbsController,
                keyboardType: TextInputType.number,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: lang.t('plan_editor_carbs'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _fatController,
                keyboardType: TextInputType.number,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: lang.t('plan_editor_fat'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                lang.t('plan_editor_ingredients'),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            TextButton.icon(
              onPressed: _addIngredient,
              icon: const Icon(Icons.add),
              label: Text(lang.t('plan_editor_add_ingredient')),
            ),
            IconButton(
              tooltip: lang.t('admin_new_ingredient'),
              onPressed: _createIngredient,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
        ..._ingredients.asMap().entries.map((entry) {
          final index = entry.key;
          final ingredient = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Autocomplete<Map<String, dynamic>>(
                    initialValue: TextEditingValue(
                      text: _ingredientLabel(ingredient.key),
                    ),
                    displayStringForOption: (option) =>
                        _stringValue(option['name_en'], fallback: option['ingredient_id'].toString()),
                    optionsBuilder: (value) {
                      final query = value.text.trim().toLowerCase();
                      return _availableIngredients.where((option) {
                        final id = _stringValue(option['ingredient_id']).toLowerCase();
                        final nameEn = _stringValue(option['name_en']).toLowerCase();
                        final nameAr = _stringValue(option['name_ar']);
                        return query.isEmpty || id.contains(query) || nameEn.contains(query) || nameAr.contains(value.text.trim());
                      });
                    },
                    onSelected: (selected) => _renameIngredient(
                      index,
                      _stringValue(selected['ingredient_id']),
                    ),
                    fieldViewBuilder: (context, controller, focusNode, onSubmitted) => TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: lang.t('plan_editor_ingredient_name'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: ingredient.value,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(_recalculateRecipeMacros),
                    decoration: InputDecoration(
                      labelText: lang.t('plan_editor_grams'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _removeIngredient(index),
                  icon: const Icon(Icons.remove_circle_outline,
                      color: AppColors.error),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                lang.t('plan_editor_portion_variants'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              tooltip: lang.t('add'),
              onPressed: _addVariant,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
        ..._variants.asMap().entries.map((entry) {
          final index = entry.key;
          final variant = entry.value;
          return Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: _stringValue(variant['portion_code'], fallback: 'M'),
                  decoration: InputDecoration(
                      labelText: lang.t('plan_editor_portion_code')),
                  onChanged: (value) => variant['portion_code'] = value.toUpperCase(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: _stringValue(variant['scale_factor'], fallback: '1'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                      labelText: lang.t('plan_editor_scale_factor')),
                  onChanged: (value) => variant['scale_factor'] = num.tryParse(value) ?? 1,
                ),
              ),
              IconButton(
                tooltip: lang.t('delete'),
                onPressed: _variants.length > 1 ? () => _removeVariant(index) : null,
                icon: const Icon(Icons.remove_circle_outline, color: AppColors.error),
              ),
            ],
          );
        }),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _error = null);
    Map<String, dynamic> payload;
    try {
      if (_jsonMode) {
        final parsed = jsonDecode(_jsonController.text);
        if (parsed is! Map<String, dynamic>) {
          throw FormatException(
            context.read<LanguageProvider>().t('plan_editor_error_json_object'),
          );
        }
        payload = parsed;
      } else {
        payload = _buildRecipe();
      }
    } catch (error) {
      setState(() => _error = error.toString());
      return;
    }

    final ok = await widget.onSave(payload);
    if (!mounted) return;
    final providerError = context.read<AdminProvider>().error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? context
                .read<LanguageProvider>()
                .t('plan_editor_engine_meal_saved')
            : providerError ??
                context.read<LanguageProvider>().t('plan_editor_save_failed')),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
    if (ok) Navigator.pop(context);
  }
}

class _NutritionEnginePlanEditorSheet extends StatefulWidget {
  final Map<String, dynamic> initialPlan;
  final List<Map<String, dynamic>> availableVariants;
  final bool isNew;
  final Future<bool> Function(
    Map<String, dynamic> payload, {
    required bool includeCoachEdited,
  }) onSave;

  const _NutritionEnginePlanEditorSheet({
    required this.initialPlan,
    required this.availableVariants,
    required this.onSave,
    this.isNew = false,
  });

  @override
  State<_NutritionEnginePlanEditorSheet> createState() =>
      _NutritionEnginePlanEditorSheetState();
}

class _NutritionEnginePlanEditorSheetState
    extends State<_NutritionEnginePlanEditorSheet> {
  final TextEditingController _jsonController = TextEditingController();
  final TextEditingController _planIdController = TextEditingController();
  final TextEditingController _planTypeController = TextEditingController();
  final TextEditingController _marketController = TextEditingController();
  final TextEditingController _calorieBandController = TextEditingController();
  final TextEditingController _macroProfileController = TextEditingController();
  final TextEditingController _mealCountController = TextEditingController();
  final TextEditingController _rotationController = TextEditingController();
  List<Map<String, dynamic>> _days = <Map<String, dynamic>>[];
  bool _jsonMode = false;
  bool _includeCoachEdited = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _jsonController.text =
        const JsonEncoder.withIndent('  ').convert(widget.initialPlan);
    _loadStructured(widget.initialPlan);
  }

  @override
  void dispose() {
    _jsonController.dispose();
    _planIdController.dispose();
    _planTypeController.dispose();
    _marketController.dispose();
    _calorieBandController.dispose();
    _macroProfileController.dispose();
    _mealCountController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    final lang = context.watch<LanguageProvider>();
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.94,
        minChildSize: 0.5,
        maxChildSize: 0.98,
        builder: (context, scrollController) => Material(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      lang.t('plan_editor_nutrition_plan_title'),
                      style: AppTextStyles.h2,
                    ),
                  ),
                  IconButton(
                    tooltip: lang.t('plan_editor_close'),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(
                    value: false,
                    icon: const Icon(Icons.calendar_month),
                    label: Text(lang.t('plan_editor_plan')),
                  ),
                  ButtonSegment(
                    value: true,
                    icon: const Icon(Icons.data_object),
                    label: Text(lang.t('plan_editor_json')),
                  ),
                ],
                selected: {_jsonMode},
                onSelectionChanged: (selection) {
                  setState(() {
                    if (selection.first) {
                      _jsonController.text = const JsonEncoder.withIndent('  ')
                          .convert(_buildPlan());
                    }
                    _jsonMode = selection.first;
                  });
                },
              ),
              const SizedBox(height: 16),
              if (_jsonMode)
                TextField(
                  controller: _jsonController,
                  maxLines: 24,
                  minLines: 16,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: lang.t('plan_editor_engine_plan_json_hint'),
                  ),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                )
              else
                _buildPlanEditor(),
              const SizedBox(height: 16),
              SwitchListTile(
                value: _includeCoachEdited,
                contentPadding: EdgeInsets.zero,
                title: Text(lang.t('plan_editor_include_coach_edited_users')),
                subtitle: Text(lang.t('plan_editor_protect_coach_edited_hint')),
                onChanged: (value) =>
                    setState(() => _includeCoachEdited = value),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: Text(lang.t('plan_editor_save_refresh_users')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanEditor() {
    final lang = context.watch<LanguageProvider>();
    return Column(
      children: [
        TextField(
          controller: _planIdController,
          decoration: InputDecoration(
            labelText: lang.t('plan_editor_plan_id'),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _field(
                _planTypeController,
                lang.t('plan_editor_plan_type'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _field(_marketController, lang.t('plan_editor_market')),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _field(
                    _calorieBandController, lang.t('plan_editor_calories'),
                    number: true)),
            const SizedBox(width: 12),
            Expanded(
              child: _field(
                _macroProfileController,
                lang.t('plan_editor_macro_profile'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _field(
                    _mealCountController, lang.t('plan_editor_meals_per_day'),
                    number: true)),
            const SizedBox(width: 12),
            Expanded(
                child: _field(
                    _rotationController, lang.t('plan_editor_rotation'),
                    number: true)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                lang.t('plan_editor_days_meals'),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            TextButton.icon(
              onPressed: _addDay,
              icon: const Icon(Icons.add),
              label: Text(lang.t('plan_editor_add_day')),
            ),
          ],
        ),
        ..._days.asMap().entries.map((entry) {
          final dayIndex = entry.key;
          final day = entry.value;
          final meals = _asList(day['meals']) ?? const <dynamic>[];
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
                          initialValue: _stringValue(
                            day['day_number'] ?? day['dayNumber'],
                            fallback: '${dayIndex + 1}',
                          ),
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: lang.t('plan_editor_day'),
                          ),
                          onChanged: (value) => day['day_number'] =
                              int.tryParse(value) ?? dayIndex + 1,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _removeDay(dayIndex),
                        icon: const Icon(Icons.delete, color: AppColors.error),
                      ),
                    ],
                  ),
                  ...meals.asMap().entries.map((mealEntry) {
                    final mealIndex = mealEntry.key;
                    final meal = _asMap(mealEntry.value) ?? <String, dynamic>{};
                    final nutrition = _asMap(meal['planned_nutrition']) ??
                        <String, dynamic>{};
                    return Card(
                      color: context.palette.surfaceVariant,
                      margin: const EdgeInsets.only(top: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue: _stringValue(meal['slot']),
                                    decoration: InputDecoration(
                                        labelText: lang.t('plan_editor_slot')),
                                    onChanged: (value) => meal['slot'] = value,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      _removeMeal(dayIndex, mealIndex),
                                  icon: const Icon(Icons.remove_circle_outline,
                                      color: AppColors.error),
                                ),
                              ],
                            ),
                            // Pick the meal by name only. Portion variants are
                            // chosen in the dedicated "Portion" field below, so
                            // this list never repeats a meal once per variant.
                            Autocomplete<Map<String, dynamic>>(
                              key: ValueKey(
                                'meal:$dayIndex:$mealIndex:'
                                '${_stringValue(meal['planned_recipe_id'])}',
                              ),
                              initialValue: TextEditingValue(
                                text: _mealNameForRecipe(
                                    _stringValue(meal['planned_recipe_id'])),
                              ),
                              displayStringForOption: _mealLabel,
                              optionsBuilder: (value) {
                                final query = value.text.trim().toLowerCase();
                                return _mealOptions.where((option) =>
                                    query.isEmpty ||
                                    _mealLabel(option)
                                        .toLowerCase()
                                        .contains(query) ||
                                    _stringValue(option['recipe_id'])
                                        .toLowerCase()
                                        .contains(query));
                              },
                              onSelected: (option) => _selectMeal(
                                meal,
                                _stringValue(option['recipe_id']),
                              ),
                              fieldViewBuilder: (context, controller, focusNode,
                                      onSubmitted) =>
                                  TextField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: InputDecoration(
                                  labelText: lang.t('plan_editor_meal'),
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildPortionField(lang, meal),
                            const SizedBox(height: 8),
                            // Swap options offered to the user. Kept separate
                            // from the meal's own portion so the two are not
                            // mistaken for each other.
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Autocomplete<Map<String, dynamic>>(
                                    key: ValueKey(
                                      'alt:$dayIndex:$mealIndex:'
                                      '${_stringValue(meal['planned_recipe_id'])}:'
                                      '${(_asList(meal['alternative_variant_ids']) ?? const []).length}',
                                    ),
                                    displayStringForOption: _mealLabel,
                                    optionsBuilder: (value) =>
                                        _alternativeOptions(meal, value.text),
                                    onSelected: (variant) =>
                                        _addAlternative(meal, variant),
                                    fieldViewBuilder: (context, controller,
                                            focusNode, onSubmitted) =>
                                        TextField(
                                      controller: controller,
                                      focusNode: focusNode,
                                      decoration: InputDecoration(
                                        labelText: lang
                                            .t('plan_editor_alternative_meals'),
                                        helperText: _stringValue(
                                                    meal['planned_recipe_id'])
                                                .isEmpty
                                            ? lang.t(
                                                'plan_editor_alternative_pick_meal_first')
                                            : lang.t(
                                                'plan_editor_alternative_scope'),
                                        helperMaxLines: 2,
                                        border: const OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Filling three sensible swaps by hand for
                                // every meal of every day is the reason plans
                                // shipped with none.
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: OutlinedButton.icon(
                                    onPressed:
                                        _stringValue(meal['planned_recipe_id'])
                                                .isEmpty
                                            ? null
                                            : () => _suggestAlternatives(meal),
                                    icon: const Icon(Icons.auto_awesome,
                                        size: 18),
                                    label: Text(
                                        lang.t('plan_editor_alternative_suggest')),
                                  ),
                                ),
                              ],
                            ),
                            Wrap(
                              spacing: 6,
                              children: (_asList(meal['alternative_variant_ids']) ?? const [])
                                  .map((item) => InputChip(
                                        // Show the meal name, not the raw id.
                                        label: Text(_variantLabelById(
                                            _stringValue(item))),
                                        onDeleted: () => setState(() {
                                          final alternatives = List<dynamic>.from(
                                              _asList(meal['alternative_variant_ids']) ?? const []);
                                          alternatives.remove(item);
                                          meal['alternative_variant_ids'] = alternatives;
                                        }),
                                      ))
                                  .toList(),
                            ),
                            Row(
                              children: [
                                Expanded(
                                    child: _derivedMacroField(lang.t('plan_editor_calories'), nutrition['calories']),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: _derivedMacroField(lang.t('plan_editor_protein'), nutrition['protein_g']),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: _derivedMacroField(lang.t('plan_editor_carbs'), nutrition['carbs_g']),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: _derivedMacroField(lang.t('plan_editor_fat'), nutrition['fat_g']),
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
                      onPressed: () => _addMeal(dayIndex),
                      icon: const Icon(Icons.add),
                      label: Text(lang.t('plan_editor_add_meal')),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  /// The portion of the selected meal. Constrained to that meal's own variants,
  /// which is also what the backend requires — it rejects a plan meal whose
  /// variant belongs to a different recipe.
  Widget _buildPortionField(LanguageProvider lang, Map<String, dynamic> meal) {
    final recipeId = _stringValue(meal['planned_recipe_id']);
    final variants = _variantsForRecipe(recipeId);
    final selectedId = _stringValue(meal['planned_meal_variant_id']);
    final hasSelection = variants
        .any((variant) => _stringValue(variant['variant_id']) == selectedId);
    return DropdownButtonFormField<String>(
      initialValue: hasSelection ? selectedId : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: lang.t('plan_editor_portion'),
        border: const OutlineInputBorder(),
        helperText:
            variants.isEmpty ? lang.t('plan_editor_select_meal_first') : null,
      ),
      items: variants
          .map((variant) => DropdownMenuItem<String>(
                value: _stringValue(variant['variant_id']),
                child: Text(_portionLabel(variant)),
              ))
          .toList(),
      onChanged: variants.isEmpty
          ? null
          : (variantId) {
              if (variantId != null) _selectPortion(meal, variantId);
            },
    );
  }

  /// One entry per meal, deduplicated from the flat variant list.
  List<Map<String, dynamic>> get _mealOptions {
    final byRecipe = <String, Map<String, dynamic>>{};
    for (final variant in widget.availableVariants) {
      final recipeId = _stringValue(variant['recipe_id']);
      if (recipeId.isEmpty || byRecipe.containsKey(recipeId)) continue;
      byRecipe[recipeId] = <String, dynamic>{
        'recipe_id': recipeId,
        'name_en': variant['name_en'],
        'name_ar': variant['name_ar'],
      };
    }
    final meals = byRecipe.values.toList()
      ..sort((a, b) => _mealLabel(a).toLowerCase().compareTo(
            _mealLabel(b).toLowerCase(),
          ));
    return meals;
  }

  List<Map<String, dynamic>> _variantsForRecipe(String recipeId) {
    if (recipeId.isEmpty) return const <Map<String, dynamic>>[];
    final variants = widget.availableVariants
        .where((variant) => _stringValue(variant['recipe_id']) == recipeId)
        .toList()
      ..sort((a, b) => _portionSortKey(a).compareTo(_portionSortKey(b)));
    return variants;
  }

  /// Order portions small to large, with anything unrecognised last.
  int _portionSortKey(Map<String, dynamic> variant) {
    const order = ['S', 'M', 'L', 'XL', 'XXL'];
    final index =
        order.indexOf(_stringValue(variant['portion_code']).toUpperCase());
    return index < 0 ? order.length : index;
  }

  Map<String, dynamic>? _variantById(String variantId) {
    if (variantId.isEmpty) return null;
    return widget.availableVariants.cast<Map<String, dynamic>?>().firstWhere(
          (variant) => _stringValue(variant?['variant_id']) == variantId,
          orElse: () => null,
        );
  }

  void _selectMeal(Map<String, dynamic> meal, String recipeId) {
    final variants = _variantsForRecipe(recipeId);
    // Default to the medium portion when the meal has one, else the smallest.
    final defaultVariant = variants.cast<Map<String, dynamic>?>().firstWhere(
          (variant) =>
              _stringValue(variant?['portion_code']).toUpperCase() == 'M',
          orElse: () => variants.isEmpty ? null : variants.first,
        );
    setState(() {
      meal['planned_recipe_id'] = recipeId;
      meal['planned_meal_variant_id'] =
          _stringValue(defaultVariant?['variant_id']);
      meal['planned_nutrition'] =
          _normalizeNutritionMap(defaultVariant?['nutrition']);
      // The planned portion must not also sit in the swap list.
      final alternatives =
          List<dynamic>.from(_asList(meal['alternative_variant_ids']) ?? const [])
            ..removeWhere((item) =>
                _stringValue(item) ==
                _stringValue(defaultVariant?['variant_id']));
      meal['alternative_variant_ids'] = alternatives;
    });
  }

  void _selectPortion(Map<String, dynamic> meal, String variantId) {
    final variant = _variantById(variantId);
    if (variant == null) return;
    setState(() {
      meal['planned_recipe_id'] = _stringValue(variant['recipe_id']);
      meal['planned_meal_variant_id'] = variantId;
      meal['planned_nutrition'] = _normalizeNutritionMap(variant['nutrition']);
      final alternatives =
          List<dynamic>.from(_asList(meal['alternative_variant_ids']) ?? const [])
            ..removeWhere((item) => _stringValue(item) == variantId);
      meal['alternative_variant_ids'] = alternatives;
    });
  }

  /// Meal name without a portion suffix.
  String _mealLabel(Map<String, dynamic> meal) {
    final isArabic = context.read<LanguageProvider>().isArabic;
    final fallback = _stringValue(meal['recipe_id']);
    return isArabic
        ? _firstText([meal['name_ar'], meal['name_en'], fallback])
        : _firstText([meal['name_en'], meal['name_ar'], fallback]);
  }

  String _mealNameForRecipe(String recipeId) {
    if (recipeId.isEmpty) return '';
    final variants = _variantsForRecipe(recipeId);
    if (variants.isEmpty) return recipeId;
    return _mealLabel(variants.first);
  }

  String _portionLabel(Map<String, dynamic> variant) {
    final portion = _stringValue(variant['portion_code']);
    return portion.isEmpty ? _stringValue(variant['variant_id']) : portion;
  }

  static final _slotSuffix = RegExp(r'_\d+$');

  /// `snack_1` and `snack_2` are both snack slots as far as the catalogue
  /// cares, and a blank slot should not silently filter everything out.
  String _baseMealType(Map<String, dynamic> meal) {
    final slot = _stringValue(meal['slot']).trim().toLowerCase();
    return slot.replaceAll(_slotSuffix, '');
  }

  num _variantCalories(Map<String, dynamic> variant) {
    final nutrition = _asMap(variant['nutrition']);
    final value = nutrition?['calories'] ?? variant['calories'];
    return value is num ? value : num.tryParse('$value') ?? 0;
  }

  bool _variantServesSlot(Map<String, dynamic> variant, String mealType) {
    if (mealType.isEmpty) return true;
    final types = (_asList(variant['meal_types']) ?? const [])
        .map((item) => item.toString().toLowerCase())
        .toList();
    // Tolerate a catalogue that has not been reimported with meal_types yet
    // rather than presenting an empty picker.
    if (types.isEmpty) return true;
    return types.contains(mealType);
  }

  bool _variantServesMarket(Map<String, dynamic> variant) {
    final market = _marketController.text.trim().toUpperCase();
    if (market.isEmpty) return true;
    final tags = (_asList(variant['market_tags']) ?? const [])
        .map((item) => item.toString().toUpperCase())
        .toList();
    if (tags.isEmpty) return true;
    return tags.contains(market);
  }

  /// Candidate swaps for a meal: same slot, same market, a different dish, and
  /// one portion per dish. The old picker listed every variant in the
  /// catalogue, so it offered breakfasts against dinners, meals from the other
  /// market, and four other sizes of the meal already selected.
  Iterable<Map<String, dynamic>> _alternativeOptions(
    Map<String, dynamic> meal,
    String query,
  ) {
    final plannedRecipeId = _stringValue(meal['planned_recipe_id']);
    if (plannedRecipeId.isEmpty) return const <Map<String, dynamic>>[];

    final mealType = _baseMealType(meal);
    final selectedIds = (_asList(meal['alternative_variant_ids']) ?? const [])
        .map((item) => item.toString())
        .toSet();
    final selectedRecipeIds = selectedIds
        .map((id) => _stringValue(_variantById(id)?['recipe_id']))
        .where((id) => id.isNotEmpty)
        .toSet();
    final target = _variantCalories(
      _variantById(_stringValue(meal['planned_meal_variant_id'])) ??
          const <String, dynamic>{},
    );
    final normalizedQuery = query.trim().toLowerCase();

    final bestPerRecipe = <String, Map<String, dynamic>>{};
    for (final variant in widget.availableVariants) {
      final recipeId = _stringValue(variant['recipe_id']);
      if (recipeId.isEmpty || recipeId == plannedRecipeId) continue;
      if (selectedRecipeIds.contains(recipeId)) continue;
      if (!_variantServesSlot(variant, mealType)) continue;
      if (!_variantServesMarket(variant)) continue;
      if (normalizedQuery.isNotEmpty &&
          !_mealLabel(variant).toLowerCase().contains(normalizedQuery)) {
        continue;
      }
      // Keep the portion that lands closest to the meal being replaced, so the
      // day's calories barely move when a client takes the swap.
      final current = bestPerRecipe[recipeId];
      if (current == null ||
          (_variantCalories(variant) - target).abs() <
              (_variantCalories(current) - target).abs()) {
        bestPerRecipe[recipeId] = variant;
      }
    }

    final options = bestPerRecipe.values.toList()
      ..sort((a, b) => (_variantCalories(a) - target)
          .abs()
          .compareTo((_variantCalories(b) - target).abs()));
    return options.take(25);
  }

  void _addAlternative(Map<String, dynamic> meal, Map<String, dynamic> variant) {
    setState(() {
      final alternatives = List<dynamic>.from(
          _asList(meal['alternative_variant_ids']) ?? const []);
      alternatives.add(variant['variant_id']);
      meal['alternative_variant_ids'] = alternatives;
    });
  }

  /// Fills the meal up to three alternatives with the closest available swaps.
  void _suggestAlternatives(Map<String, dynamic> meal) {
    final existing = List<dynamic>.from(
        _asList(meal['alternative_variant_ids']) ?? const []);
    final suggestions = _alternativeOptions(meal, '')
        .take(3 - existing.length.clamp(0, 3))
        .map((variant) => variant['variant_id'])
        .toList();
    if (suggestions.isEmpty) return;
    setState(() {
      meal['alternative_variant_ids'] = [...existing, ...suggestions];
    });
  }

  String _variantLabel(Map<String, dynamic> variant) {
    final name = _mealLabel(variant);
    final portion = _stringValue(variant['portion_code']);
    return '$name${portion.isEmpty ? '' : ' ($portion)'}';
  }

  String _variantLabelById(String variantId) {
    final variant = _variantById(variantId);
    return variant == null ? variantId : _variantLabel(variant);
  }

    Widget _derivedMacroField(String label, dynamic value) => TextFormField(
      key: ValueKey('$label:${_stringValue(value, fallback: '0')}'),
      initialValue: _stringValue(value, fallback: '0'),
        readOnly: true,
        decoration: InputDecoration(labelText: label),
      );

  Widget _field(TextEditingController controller, String label,
      {bool number = false}) {
    return TextField(
      controller: controller,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  void _loadStructured(Map<String, dynamic> plan) {
    _planIdController.text =
        _stringValue(plan['plan_id'], fallback: 'new_plan');
    _planTypeController.text =
        _stringValue(plan['plan_type'], fallback: 'professional');
    _marketController.text = _stringValue(plan['market'], fallback: 'SA');
    _calorieBandController.text =
        _stringValue(plan['calorie_band'], fallback: '2000');
    _macroProfileController.text =
        _stringValue(plan['macro_profile'], fallback: 'balanced');
    _mealCountController.text = _stringValue(plan['meal_count'], fallback: '3');
    _rotationController.text = _stringValue(plan['rotation'], fallback: '1');
    _days = (_asList(plan['days']) ?? const <dynamic>[])
        .map((item) => Map<String, dynamic>.from(_asMap(item) ?? const {}))
        .map((day) {
      day['meals'] = (_asList(day['meals']) ?? const <dynamic>[]).map((item) {
        final meal = Map<String, dynamic>.from(_asMap(item) ?? const {});
        meal['planned_nutrition'] =
            _normalizeNutritionMap(meal['planned_nutrition']);
        return meal;
      }).toList();
      return day;
    }).toList();
  }

  Map<String, dynamic> _buildPlan() {
    return <String, dynamic>{
      if (!widget.isNew) 'plan_id': _planIdController.text.trim(),
      'schema_version':
          _stringValue(widget.initialPlan['schema_version'], fallback: '1.0'),
      'plan_type': _planTypeController.text.trim(),
      'market': _marketController.text.trim(),
      'calorie_band': int.tryParse(_calorieBandController.text.trim()) ?? 0,
      'macro_profile': _macroProfileController.text.trim(),
      'meal_count': int.tryParse(_mealCountController.text.trim()) ?? 3,
      'rotation': int.tryParse(_rotationController.text.trim()) ?? 1,
      'template_target':
          _asMap(widget.initialPlan['template_target']) ?? <String, dynamic>{},
      'assignment_rules':
          _asMap(widget.initialPlan['assignment_rules']) ?? <String, dynamic>{},
      'validation':
          _asMap(widget.initialPlan['validation']) ?? <String, dynamic>{},
      'days': _days.asMap().entries.map((entry) {
        final index = entry.key;
        final day = entry.value;
        return <String, dynamic>{
          'day_number': int.tryParse(
                  _stringValue(day['day_number'] ?? day['dayNumber'])) ??
              index + 1,
          'meals': (_asList(day['meals']) ?? const <dynamic>[]).map((raw) {
            final meal = _asMap(raw) ?? const <String, dynamic>{};
            final nutrition = _normalizeNutritionMap(meal['planned_nutrition']);
            return <String, dynamic>{
              'slot': _stringValue(meal['slot'], fallback: 'snack'),
              'planned_recipe_id': _stringValue(meal['planned_recipe_id']),
              'planned_meal_variant_id':
                  _stringValue(meal['planned_meal_variant_id']),
              'planned_nutrition': {
                'calories':
                    num.tryParse(_stringValue(nutrition['calories'])) ?? 0,
                'protein_g':
                    num.tryParse(_stringValue(nutrition['protein_g'])) ?? 0,
                'carbs_g':
                    num.tryParse(_stringValue(nutrition['carbs_g'])) ?? 0,
                'fat_g': num.tryParse(_stringValue(nutrition['fat_g'])) ?? 0,
              },
              'alternative_variant_ids':
                  _asList(meal['alternative_variant_ids']) ?? const [],
            };
          }).toList(),
        };
      }).toList(),
    };
  }

  num _asMacroNumber(dynamic value) {
    if (value is num) return value;
    return num.tryParse(_stringValue(value)) ?? 0;
  }

  Map<String, dynamic> _normalizeNutritionMap(dynamic rawNutrition) {
    final raw = _asMap(rawNutrition) ?? const <String, dynamic>{};
    return <String, dynamic>{
      'calories': _asMacroNumber(raw['calories']),
      'protein_g': _asMacroNumber(raw['protein_g'] ?? raw['protein']),
      'carbs_g': _asMacroNumber(raw['carbs_g'] ?? raw['carbs']),
      'fat_g': _asMacroNumber(raw['fat_g'] ?? raw['fat'] ?? raw['fats']),
    };
  }

  void _addDay() {
    setState(() {
      _days.add(
          {'day_number': _days.length + 1, 'meals': <Map<String, dynamic>>[]});
    });
  }

  void _removeDay(int index) {
    setState(() => _days.removeAt(index));
  }

  void _addMeal(int dayIndex) {
    setState(() {
      final meals = (_asList(_days[dayIndex]['meals']) ?? <dynamic>[])
          .map((item) => _asMap(item) ?? <String, dynamic>{})
          .toList();
      meals.add({
        'slot': 'snack',
        'planned_recipe_id': '',
        'planned_meal_variant_id': '',
        'planned_nutrition': {
          'calories': 0,
          'protein_g': 0,
          'carbs_g': 0,
          'fat_g': 0,
        },
        'alternative_variant_ids': <String>[],
      });
      _days[dayIndex]['meals'] = meals;
    });
  }

  void _removeMeal(int dayIndex, int mealIndex) {
    setState(() {
      final meals = (_asList(_days[dayIndex]['meals']) ?? <dynamic>[])
          .map((item) => _asMap(item) ?? <String, dynamic>{})
          .toList();
      if (mealIndex >= 0 && mealIndex < meals.length) {
        meals.removeAt(mealIndex);
      }
      _days[dayIndex]['meals'] = meals;
    });
  }

  Future<void> _save() async {
    setState(() => _error = null);
    Map<String, dynamic> payload;
    try {
      if (_jsonMode) {
        final parsed = jsonDecode(_jsonController.text);
        if (parsed is! Map<String, dynamic>) {
          throw FormatException(
            context.read<LanguageProvider>().t('plan_editor_error_json_object'),
          );
        }
        payload = parsed;
      } else {
        payload = _buildPlan();
        if (!widget.isNew && _stringValue(payload['plan_id']).isEmpty) {
          throw FormatException(
            context
                .read<LanguageProvider>()
                .t('plan_editor_error_plan_id_required'),
          );
        }
        if ((_asList(payload['days']) ?? const []).isEmpty) {
          throw FormatException(
            context
                .read<LanguageProvider>()
                .t('plan_editor_error_day_required'),
          );
        }
        // The backend rejects a meal without both a recipe and one of its
        // variants; say so here rather than surfacing a generic 400.
        for (final rawDay in _asList(payload['days']) ?? const []) {
          final day = _asMap(rawDay) ?? const <String, dynamic>{};
          for (final rawMeal in _asList(day['meals']) ?? const []) {
            final meal = _asMap(rawMeal) ?? const <String, dynamic>{};
            if (_stringValue(meal['planned_recipe_id']).isEmpty ||
                _stringValue(meal['planned_meal_variant_id']).isEmpty) {
              throw FormatException(
                context
                    .read<LanguageProvider>()
                    .t('plan_editor_error_meal_selection_required'),
              );
            }
          }
        }
      }
    } catch (error) {
      setState(() => _error = error.toString());
      return;
    }

    final provider = context.read<AdminProvider>();
    final ok = widget.isNew
      ? await provider.createNutritionEnginePlan(payload)
        : await widget.onSave(payload, includeCoachEdited: _includeCoachEdited);
    if (!mounted) return;
    final providerError = provider.error;
    final lang = context.read<LanguageProvider>();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? lang.t('plan_editor_engine_plan_saved_users_refreshed')
            : providerError ?? lang.t('plan_editor_save_failed')),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
    if (ok) Navigator.pop(context);
  }
}

String _stringValue(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

num _numValue(dynamic value) {
  if (value is num) return value;
  return num.tryParse(_stringValue(value)) ?? 0;
}

/// Trim a trailing `.0` so 52.0 reads as "52" in an input field.
String _macroText(num value) {
  if (value == value.roundToDouble()) return value.round().toString();
  return value.toStringAsFixed(2);
}

/// Ingredient macros are defined and stored per 100 g (`per_100g`, matching the
/// nutrition engine schema and how nutrition labels are printed). The API also
/// returns a derived `per_gram` block, so fall back to it for older payloads.
Map<String, num> _ingredientPer100g(Map<String, dynamic>? ingredient) {
  final per100g = _asMap(ingredient?['per_100g']);
  if (per100g != null && per100g.isNotEmpty) {
    return <String, num>{
      'calories': _numValue(per100g['calories']),
      'protein_g': _numValue(per100g['protein_g'] ?? per100g['protein']),
      'carbs_g': _numValue(per100g['carbs_g'] ?? per100g['carbs']),
      'fat_g': _numValue(per100g['fat_g'] ?? per100g['fat']),
    };
  }
  final perGram = _asMap(ingredient?['per_gram']) ?? const <String, dynamic>{};
  return <String, num>{
    'calories': _numValue(perGram['calories']) * 100,
    'protein_g': _numValue(perGram['protein_g'] ?? perGram['protein']) * 100,
    'carbs_g': _numValue(perGram['carbs_g'] ?? perGram['carbs']) * 100,
    'fat_g': _numValue(perGram['fat_g'] ?? perGram['fat']) * 100,
  };
}

/// Per-gram macros used to total up a recipe from its ingredient grams.
Map<String, num> _ingredientPerGram(Map<String, dynamic>? ingredient) {
  return _ingredientPer100g(ingredient)
      .map((key, value) => MapEntry(key, value / 100));
}

/// One form for both creating and editing an ingredient, so the per-100 g
/// definition is identical wherever an admin enters it. Returns the API payload,
/// or null when cancelled.
Future<Map<String, dynamic>?> _showIngredientForm(
  BuildContext context, {
  Map<String, dynamic>? existing,
}) {
  final lang = context.read<LanguageProvider>();
  final isEdit = existing != null;
  final macros = _ingredientPer100g(existing);
  final nameEn =
      TextEditingController(text: _stringValue(existing?['name_en']));
  final nameAr =
      TextEditingController(text: _stringValue(existing?['name_ar']));
  final calories =
      TextEditingController(text: _macroText(macros['calories'] ?? 0));
  final protein =
      TextEditingController(text: _macroText(macros['protein_g'] ?? 0));
  final carbs = TextEditingController(text: _macroText(macros['carbs_g'] ?? 0));
  final fat = TextEditingController(text: _macroText(macros['fat_g'] ?? 0));
  var active = existing?['is_active'] != false;
  String? error;

  Widget macroField(TextEditingController controller, String label) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
        ),
      );

  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: Text(
          lang.t(isEdit ? 'admin_edit_ingredient' : 'admin_new_ingredient'),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    error!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              TextField(
                controller: nameEn,
                decoration: InputDecoration(
                  labelText: lang.t('admin_exercise_english_name'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameAr,
                decoration: InputDecoration(
                  labelText: lang.t('admin_exercise_arabic_name'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                lang.t('admin_per_100g_hint'),
                style: TextStyle(
                  color: context.palette.textSecondary,
                  fontSize: 12,
                ),
              ),
              macroField(calories, lang.t('admin_calories_per_100g')),
              macroField(protein, lang.t('admin_protein_per_100g')),
              macroField(carbs, lang.t('admin_carbs_per_100g')),
              macroField(fat, lang.t('admin_fat_per_100g')),
              if (isEdit)
                SwitchListTile(
                  value: active,
                  contentPadding: EdgeInsets.zero,
                  title: Text(lang.t('plan_editor_active')),
                  onChanged: (value) => setDialogState(() => active = value),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(lang.t('cancel')),
          ),
          FilledButton(
            onPressed: () {
              if (nameEn.text.trim().isEmpty) {
                setDialogState(
                  () => error = lang.t('admin_ingredient_name_required'),
                );
                return;
              }
              Navigator.pop(dialogContext, <String, dynamic>{
                'name_en': nameEn.text.trim(),
                'name_ar': nameAr.text.trim(),
                if (isEdit) 'is_active': active,
                'per_100g': <String, dynamic>{
                  'calories': num.tryParse(calories.text.trim()) ?? 0,
                  'protein_g': num.tryParse(protein.text.trim()) ?? 0,
                  'carbs_g': num.tryParse(carbs.text.trim()) ?? 0,
                  'fat_g': num.tryParse(fat.text.trim()) ?? 0,
                },
              });
            },
            child: Text(lang.t(isEdit ? 'save' : 'add')),
          ),
        ],
      ),
    ),
  );
}

String _firstText(List<dynamic> values) {
  for (final value in values) {
    final text = _stringValue(value);
    if (text.isNotEmpty) return text;
  }
  return '-';
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

String _listText(dynamic value) {
  if (value is Iterable) {
    final items = value.map((item) => item.toString()).where((item) {
      return item.trim().isNotEmpty;
    }).toList();
    return items.isEmpty ? '-' : items.join(', ');
  }
  return _stringValue(value, fallback: '-');
}

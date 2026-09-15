import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/colors.dart';
import '../../providers/admin_provider.dart';
import '../../providers/language_provider.dart';
import '../../widgets/custom_card.dart';

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
    _tabController = TabController(length: 3, vsync: this)
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
      provider.loadNutritionEngineImports(),
    ]);
  }

  Future<void> _refreshCurrent() {
    final provider = context.read<AdminProvider>();
    switch (_tabController.index) {
      case 0:
        return provider.loadNutritionEngineRecipes();
      case 1:
        return provider.loadNutritionEnginePlans();
      case 2:
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
                  _buildEnginePlansTab(provider),
                  _buildImportsTab(provider),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _NutritionRecipeEditorSheet(
        initialRecipe: fullRecipe,
        onSave: context.read<AdminProvider>().saveNutritionEngineRecipe,
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
        onSave: context.read<AdminProvider>().saveNutritionEnginePlan,
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
              style: const TextStyle(color: AppColors.textSecondary),
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
                    style: const TextStyle(
                      color: AppColors.textSecondary,
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
                    style: const TextStyle(
                      color: AppColors.textSecondary,
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
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'checksum $shortChecksum - recipes $recipeCount - plans $planCount',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
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
      style: const TextStyle(
        color: AppColors.textSecondary,
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
  final _JsonSaveCallback onSave;

  const _NutritionRecipeEditorSheet({
    required this.initialRecipe,
    required this.onSave,
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
  }

  Map<String, dynamic> _buildRecipe() {
    final merged = Map<String, dynamic>.from(_rawRecipe);
    merged['recipe_id'] = _recipeIdController.text.trim();
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
    return merged;
  }

  void _addIngredient() {
    setState(() {
      _ingredients.add(MapEntry('', TextEditingController(text: '0')));
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients[index].value.dispose();
      _ingredients.removeAt(index);
    });
  }

  void _renameIngredient(int index, String name) {
    final controller = _ingredients[index].value;
    setState(() {
      _ingredients[index] = MapEntry(name, controller);
    });
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
        TextField(
          controller: _recipeIdController,
          decoration: InputDecoration(
            labelText: lang.t('plan_editor_recipe_id'),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
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
                  child: TextFormField(
                    initialValue: ingredient.key,
                    decoration: InputDecoration(
                      labelText: lang.t('plan_editor_ingredient_name'),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) => _renameIngredient(index, value),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: ingredient.value,
                    keyboardType: TextInputType.number,
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
  final Future<bool> Function(
    Map<String, dynamic> payload, {
    required bool includeCoachEdited,
  }) onSave;

  const _NutritionEnginePlanEditorSheet({
    required this.initialPlan,
    required this.onSave,
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
                      color: AppColors.surface,
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
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue:
                                        _stringValue(meal['planned_recipe_id']),
                                    decoration: InputDecoration(
                                        labelText:
                                            lang.t('plan_editor_recipe_id')),
                                    onChanged: (value) =>
                                        meal['planned_recipe_id'] = value,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: _stringValue(
                                        meal['planned_meal_variant_id']),
                                    decoration: InputDecoration(
                                        labelText:
                                            lang.t('plan_editor_variant_id')),
                                    onChanged: (value) =>
                                        meal['planned_meal_variant_id'] = value,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue: _stringValue(
                                        nutrition['calories'],
                                        fallback: '0'),
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                        labelText:
                                            lang.t('plan_editor_calories')),
                                    onChanged: (value) =>
                                        nutrition['calories'] =
                                            num.tryParse(value) ?? 0,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: _stringValue(
                                        nutrition['protein_g'],
                                        fallback: '0'),
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                        labelText:
                                            lang.t('plan_editor_protein')),
                                    onChanged: (value) =>
                                        nutrition['protein_g'] =
                                            num.tryParse(value) ?? 0,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: _stringValue(
                                        nutrition['carbs_g'],
                                        fallback: '0'),
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                        labelText: lang.t('plan_editor_carbs')),
                                    onChanged: (value) => nutrition['carbs_g'] =
                                        num.tryParse(value) ?? 0,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: _stringValue(
                                        nutrition['fat_g'],
                                        fallback: '0'),
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                        labelText: lang.t('plan_editor_fat')),
                                    onChanged: (value) => nutrition['fat_g'] =
                                        num.tryParse(value) ?? 0,
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
        meal['planned_nutrition'] = Map<String, dynamic>.from(
            _asMap(meal['planned_nutrition']) ?? const {});
        return meal;
      }).toList();
      return day;
    }).toList();
  }

  Map<String, dynamic> _buildPlan() {
    return <String, dynamic>{
      'plan_id': _planIdController.text.trim(),
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
            final nutrition = _asMap(meal['planned_nutrition']) ?? const {};
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
        if (_stringValue(payload['plan_id']).isEmpty) {
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
      }
    } catch (error) {
      setState(() => _error = error.toString());
      return;
    }

    final ok = await widget.onSave(
      payload,
      includeCoachEdited: _includeCoachEdited,
    );
    if (!mounted) return;
    final providerError = context.read<AdminProvider>().error;
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

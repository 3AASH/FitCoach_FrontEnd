import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/colors.dart';
import '../../providers/admin_provider.dart';
import '../../providers/language_provider.dart';
import '../../widgets/custom_card.dart';

enum _AdminNutritionAction {
  importLegacyTemplates,
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
      provider.loadNutritionMealTemplates(),
      provider.loadNutritionEngineRecipes(),
      provider.loadNutritionEnginePlans(),
      provider.loadNutritionEngineImports(),
    ]);
  }

  Future<void> _refreshCurrent() {
    final provider = context.read<AdminProvider>();
    switch (_tabController.index) {
      case 1:
        return provider.loadNutritionEngineRecipes();
      case 2:
        return provider.loadNutritionEnginePlans();
      case 3:
        return provider.loadNutritionEngineImports();
      case 0:
      default:
        return provider.loadNutritionMealTemplates();
    }
  }

  Future<void> _handleAction(_AdminNutritionAction action) {
    switch (action) {
      case _AdminNutritionAction.importLegacyTemplates:
        return _importLegacyJsonFile();
      case _AdminNutritionAction.importEngineSeed:
        return _importEngineSeed();
    }
  }

  Future<void> _importLegacyJsonFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      allowMultiple: false,
    );
    final path = result?.files.single.path;
    if (path == null || !mounted) return;

    final provider = context.read<AdminProvider>();
    final ok = await provider.importNutritionMealTemplatesFromFile(path);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Nutrition templates imported'
            : provider.error ?? 'Import failed'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }

  Future<void> _importEngineSeed() async {
    final provider = context.read<AdminProvider>();
    final ok = await provider.importNutritionEngineSeed();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Nutrition engine seed imported'
            : provider.error ?? 'Seed import failed'),
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
          tabs: const [
            Tab(text: 'Legacy Meals', icon: Icon(Icons.restaurant_menu)),
            Tab(text: 'Engine Meals', icon: Icon(Icons.ramen_dining)),
            Tab(text: 'Engine Plans', icon: Icon(Icons.calendar_month)),
            Tab(text: 'Imports', icon: Icon(Icons.history)),
          ],
        ),
        actions: [
          PopupMenuButton<_AdminNutritionAction>(
            tooltip: 'Nutrition actions',
            onSelected: _handleAction,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _AdminNutritionAction.importLegacyTemplates,
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.upload_file),
                  title: Text('Import legacy JSON'),
                ),
              ),
              PopupMenuItem(
                value: _AdminNutritionAction.importEngineSeed,
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.cloud_upload),
                  title: Text('Import engine seed'),
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
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () => _openLegacyEditor(),
              icon: const Icon(Icons.add),
              label: Text(lang.t('admin_new_template')),
            )
          : null,
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
                  _buildLegacyTemplatesTab(provider),
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

  Widget _buildLegacyTemplatesTab(AdminProvider provider) {
    final templates = provider.nutritionMealTemplates;
    if (provider.isLoading && templates.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (templates.isEmpty) {
      return _EmptyList(
        message: 'No legacy nutrition templates found',
        onRefresh: () => provider.loadNutritionMealTemplates(),
      );
    }
    return RefreshIndicator(
      onRefresh: () => provider.loadNutritionMealTemplates(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: templates.length,
        itemBuilder: (context, index) {
          final template = templates[index];
          return _NutritionTemplateCard(
            template: template,
            onEdit: () => _openLegacyEditor(template: template),
          );
        },
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
        message: 'No nutrition engine meals found',
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
        message: 'No nutrition engine plans found',
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
        message: 'No nutrition engine imports found',
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

  Future<void> _openLegacyEditor({Map<String, dynamic>? template}) async {
    Map<String, dynamic>? fullTemplate = template;
    final templateId = template?['template_id']?.toString();
    if (templateId != null && templateId.isNotEmpty) {
      fullTemplate = await context
          .read<AdminProvider>()
          .getNutritionMealTemplate(templateId);
      if (!mounted || fullTemplate == null) return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _JsonEditorSheet(
        title: 'Nutrition template JSON',
        hint: 'Paste a valid nutrition meal template JSON object',
        initialJson: fullTemplate,
        defaultJson: const {
          'template_id': 'new_breakfast_template',
          'meal_type': 'breakfast',
          'name': 'High Protein Breakfast',
          'name_en': 'High Protein Breakfast',
          'name_ar': '',
          'calories': 420,
          'protein': 35,
          'carbs': 40,
          'fat': 12,
          'ingredients': ['Eggs', 'Oats', 'Greek yogurt'],
          'tags': ['high_protein']
        },
        onSave: context.read<AdminProvider>().saveNutritionMealTemplate,
        successMessage: 'Template saved',
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
      builder: (_) => _JsonEditorSheet(
        title: 'Nutrition engine meal JSON',
        hint: 'Edit the complete engine meal JSON object',
        initialJson: fullRecipe,
        defaultJson: null,
        onSave: context.read<AdminProvider>().saveNutritionEngineRecipe,
        successMessage: 'Nutrition engine meal saved',
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
      builder: (_) => _JsonEditorSheet(
        title: 'Nutrition engine plan JSON',
        hint: 'Edit the complete engine plan JSON object',
        initialJson: fullPlan,
        defaultJson: null,
        onSave: context.read<AdminProvider>().saveNutritionEnginePlan,
        successMessage: 'Nutrition engine plan saved',
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
            tooltip: 'Dismiss',
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

class _NutritionTemplateCard extends StatelessWidget {
  final Map<String, dynamic> template;
  final VoidCallback onEdit;

  const _NutritionTemplateCard({
    required this.template,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final templateId = _stringValue(template['template_id']);
    final mealType = _stringValue(template['meal_type']);
    final name = _firstText([
      template['name_en'],
      template['name'],
      templateId,
    ]);
    final calories = _stringValue(template['calories'], fallback: '-');
    final protein = _stringValue(template['protein'], fallback: '0');
    final carbs = _stringValue(template['carbs'], fallback: '0');
    final fat = _stringValue(template['fat'], fallback: '0');

    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.restaurant_menu, color: AppColors.primary),
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
                    '$templateId - $mealType - $calories kcal',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'P $protein / C $carbs / F $fat',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Edit JSON',
              onPressed: onEdit,
              icon: const Icon(Icons.data_object),
            ),
          ],
        ),
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
    final recipeId = _stringValue(recipe['recipe_id']);
    final name = _firstText([recipe['name_en'], recipeId]);
    final markets = _listText(recipe['market_tags']);
    final mealTypes = _listText(recipe['meal_types']);
    final status = _stringValue(recipe['validation_status']);
    final active = recipe['is_active'] == false ? 'Inactive' : 'Active';
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
                      _MetaText('Status: $status'),
                      _MetaText(active),
                      _MetaText('Prep: $prep min'),
                      _MetaText('Cost: $cost'),
                      if (editedAt.isNotEmpty) const _MetaText('Admin edited'),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Edit JSON',
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
    final planId = _stringValue(plan['plan_id']);
    final planType = _stringValue(plan['plan_type']);
    final market = _stringValue(plan['market']);
    final calories = _stringValue(plan['calorie_band']);
    final macroProfile = _stringValue(plan['macro_profile']);
    final mealCount = _stringValue(plan['meal_count']);
    final rotation = _stringValue(plan['rotation']);
    final status = _stringValue(plan['validation_status']);
    final active = plan['is_active'] == false ? 'Inactive' : 'Active';
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
                      _MetaText('Meals: $mealCount'),
                      _MetaText('Rotation: $rotation'),
                      _MetaText('Status: $status'),
                      _MetaText(active),
                      if (editedAt.isNotEmpty) const _MetaText('Admin edited'),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Edit JSON',
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
                    tooltip: 'Close',
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
                label: const Text('Save JSON'),
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
        throw const FormatException('JSON must be an object');
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
        content:
            Text(ok ? widget.successMessage : providerError ?? 'Save failed'),
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

String _listText(dynamic value) {
  if (value is Iterable) {
    final items = value.map((item) => item.toString()).where((item) {
      return item.trim().isNotEmpty;
    }).toList();
    return items.isEmpty ? '-' : items.join(', ');
  }
  return _stringValue(value, fallback: '-');
}

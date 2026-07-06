import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/colors.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/custom_card.dart';

class AdminNutritionTemplatesScreen extends StatefulWidget {
  const AdminNutritionTemplatesScreen({super.key});

  @override
  State<AdminNutritionTemplatesScreen> createState() =>
      _AdminNutritionTemplatesScreenState();
}

class _AdminNutritionTemplatesScreenState
    extends State<AdminNutritionTemplatesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadNutritionMealTemplates();
    });
  }

  Future<void> _refresh() {
    return context.read<AdminProvider>().loadNutritionMealTemplates();
  }

  Future<void> _importJsonFile() async {
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final templates = provider.nutritionMealTemplates;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition Templates'),
        actions: [
          IconButton(
            tooltip: 'Import JSON',
            onPressed: _importJsonFile,
            icon: const Icon(Icons.upload_file),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('New'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: provider.isLoading && templates.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : templates.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 160),
                        Center(
                          child: Text(
                            'No nutrition templates found',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      itemCount: templates.length,
                      itemBuilder: (context, index) {
                        final template = templates[index];
                        return _NutritionTemplateCard(
                          template: template,
                          onEdit: () => _openEditor(template: template),
                        );
                      },
                    ),
        ),
      ),
    );
  }

  Future<void> _openEditor({Map<String, dynamic>? template}) async {
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
      builder: (_) => _NutritionTemplateEditorSheet(
        initialTemplate: fullTemplate,
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
    final templateId = template['template_id']?.toString() ?? '';
    final mealType = template['meal_type']?.toString() ?? '';
    final name = template['name_en']?.toString().trim().isNotEmpty == true
        ? template['name_en'].toString()
        : template['name']?.toString() ?? templateId;
    final calories = template['calories']?.toString() ?? '-';
    final protein = template['protein']?.toString() ?? '0';
    final carbs = template['carbs']?.toString() ?? '0';
    final fat = template['fat']?.toString() ?? '0';

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

class _NutritionTemplateEditorSheet extends StatefulWidget {
  final Map<String, dynamic>? initialTemplate;

  const _NutritionTemplateEditorSheet({this.initialTemplate});

  @override
  State<_NutritionTemplateEditorSheet> createState() =>
      _NutritionTemplateEditorSheetState();
}

class _NutritionTemplateEditorSheetState
    extends State<_NutritionTemplateEditorSheet> {
  final TextEditingController _jsonController = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialTemplate ??
        {
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
        };
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
                  const Expanded(
                    child: Text('Nutrition Template JSON',
                        style: AppTextStyles.h2),
                  ),
                  IconButton(
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
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Paste or edit one nutrition meal template JSON',
                ),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Save Template'),
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
        throw const FormatException('Template JSON must be an object');
      }
      payload = parsed;
    } catch (error) {
      setState(() => _error = error.toString());
      return;
    }

    final provider = context.read<AdminProvider>();
    final ok = await provider.saveNutritionMealTemplate(payload);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Template saved' : provider.error ?? 'Save failed'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
    if (ok) Navigator.pop(context);
  }
}

import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../data/models/admin_workout_template.dart';
import '../../providers/admin_provider.dart';
import '../../providers/language_provider.dart';
import '../../widgets/custom_card.dart';

class AdminWorkoutTemplatesScreen extends StatefulWidget {
  const AdminWorkoutTemplatesScreen({super.key});

  @override
  State<AdminWorkoutTemplatesScreen> createState() =>
      _AdminWorkoutTemplatesScreenState();
}

class _AdminWorkoutTemplatesScreenState
    extends State<AdminWorkoutTemplatesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadWorkoutTemplates();
    });
  }

  Future<void> _refresh() {
    return context.read<AdminProvider>().loadWorkoutTemplates();
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
    final ok = await provider.importWorkoutTemplatesFromFile(path);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Workout templates imported'
            : provider.error ?? 'Import failed'),
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
        title: Text(lang.t('admin_workout_templates_title')),
        actions: [
          IconButton(
            tooltip: lang.t('admin_import_json'),
            onPressed: _importJsonFile,
            icon: const Icon(Icons.upload_file),
          ),
          IconButton(
            tooltip: lang.t('refresh'),
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: Text(lang.t('admin_new_template')),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: provider.isLoading && provider.workoutTemplates.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : provider.workoutTemplates.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 160),
                        Center(
                          child: Text(
                            'No workout templates found',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      itemCount: provider.workoutTemplates.length,
                      itemBuilder: (context, index) {
                        final template = provider.workoutTemplates[index];
                        return _TemplateCard(
                          template: template,
                          onEdit: () => _openEditor(template: template),
                          onRefreshUsers: () => _refreshUsers(template.planId),
                        );
                      },
                    ),
        ),
      ),
    );
  }

  Future<void> _openEditor({AdminWorkoutTemplate? template}) async {
    Map<String, dynamic>? fullTemplate;
    if (template != null) {
      fullTemplate = await context
          .read<AdminProvider>()
          .getWorkoutTemplate(template.planId);
      if (!mounted || fullTemplate == null) return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _TemplateEditorSheet(initialTemplate: fullTemplate),
    );
  }

  Future<void> _refreshUsers(String planId) async {
    final provider = context.read<AdminProvider>();
    final ok = await provider.refreshWorkoutTemplateUsers(planId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(ok ? 'Users refreshed' : provider.error ?? 'Refresh failed'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final AdminWorkoutTemplate template;
  final VoidCallback onEdit;
  final VoidCallback onRefreshUsers;

  const _TemplateCard({
    required this.template,
    required this.onEdit,
    required this.onRefreshUsers,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      template.type,
      if (template.goal != null) template.goal!,
      if (template.location != null) template.location!,
      if (template.trainingDays != null) '${template.trainingDays}d',
      if (template.weeks != null) '${template.weeks}w',
    ].join(' • ');

    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.calendar_view_week, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.nameEn ?? template.planId,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${template.planId} • $subtitle',
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
            IconButton(
              tooltip: 'Edit JSON',
              onPressed: onEdit,
              icon: const Icon(Icons.data_object),
            ),
            IconButton(
              tooltip: 'Refresh users',
              onPressed: onRefreshUsers,
              icon: const Icon(Icons.sync),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateEditorSheet extends StatefulWidget {
  final Map<String, dynamic>? initialTemplate;

  const _TemplateEditorSheet({this.initialTemplate});

  @override
  State<_TemplateEditorSheet> createState() => _TemplateEditorSheetState();
}

class _TemplateEditorSheetState extends State<_TemplateEditorSheet> {
  // The editor sheet builds its parts in separate methods, so read the provider here
  // rather than threading it through each one.
  String _tr(String key) =>
      Provider.of<LanguageProvider>(context, listen: false).translate(key);

  final TextEditingController _jsonController = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialTemplate ??
        {
          'plan_id': 'new_template_id',
          'type': 'starter',
          'goal': 'general_fitness',
          'location': 'gym',
          'training_days': 3,
          'weeks': 4,
          'name_en': 'New Template',
          'sessions': [
            {
              'day': 1,
              'name_en': 'Day 1',
              'work': [
                {
                  'ex_id': 'push_up',
                  'name_en': 'Push Up',
                  'sets': 3,
                  'reps': '10'
                }
              ]
            }
          ]
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
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(_tr('admin_workout_template_json'),
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
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: _tr('admin_workout_template_json_hint'),
                ),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: Text(_tr('admin_save_and_refresh_users')),
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
    final ok = await provider.saveWorkoutTemplate(payload);
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

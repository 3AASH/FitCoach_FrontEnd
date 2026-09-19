import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../data/models/admin_exercise.dart';
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
      final provider = context.read<AdminProvider>();
      provider.loadWorkoutTemplates();
      provider.loadExercises();
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
            ? context
                .read<LanguageProvider>()
                .t('plan_editor_template_imported')
            : provider.error ??
                context
                    .read<LanguageProvider>()
                    .t('plan_editor_import_failed')),
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
                      children: [
                        const SizedBox(height: 160),
                        Center(
                          child: Text(
                            lang.t('plan_editor_no_workout_templates'),
                            style:
                                const TextStyle(color: AppColors.textSecondary),
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
      builder: (_) => _TemplateEditorSheet(
        initialTemplate: fullTemplate,
        availableExercises: context.read<AdminProvider>().exercises,
      ),
    );
  }

  Future<void> _refreshUsers(String planId) async {
    final lang = context.read<LanguageProvider>();
    var includeCoachEdited = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(lang.t('plan_editor_refresh_user_plans_title')),
          content: SwitchListTile(
            value: includeCoachEdited,
            contentPadding: EdgeInsets.zero,
            title: Text(lang.t('plan_editor_include_coach_edited')),
            subtitle: Text(lang.t('plan_editor_protect_coach_edited_hint')),
            onChanged: (value) =>
                setDialogState(() => includeCoachEdited = value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(lang.t('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(lang.t('refresh')),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;

    final provider = context.read<AdminProvider>();
    final ok = await provider.refreshWorkoutTemplateUsers(
      planId,
      includeCoachEdited: includeCoachEdited,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? lang.t('plan_editor_users_refreshed')
            : provider.error ?? lang.t('plan_editor_refresh_failed')),
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
    final lang = context.watch<LanguageProvider>();
    final displayName = lang.isArabic && (template.nameAr?.isNotEmpty == true)
        ? template.nameAr!
        : (template.nameEn ?? template.planId);
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
                    displayName,
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
              tooltip: lang.t('admin_edit_json'),
              onPressed: onEdit,
              icon: const Icon(Icons.data_object),
            ),
            IconButton(
              tooltip: lang.t('admin_refresh_users'),
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
  final List<AdminExercise> availableExercises;

  const _TemplateEditorSheet({
    this.initialTemplate,
    required this.availableExercises,
  });

  @override
  State<_TemplateEditorSheet> createState() => _TemplateEditorSheetState();
}

class _TemplateEditorSheetState extends State<_TemplateEditorSheet> {
  // The editor sheet builds its parts in separate methods, so read the provider here
  // rather than threading it through each one.
  String _tr(String key) =>
      Provider.of<LanguageProvider>(context, listen: false).translate(key);

  final TextEditingController _jsonController = TextEditingController();
  final TextEditingController _planIdController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _goalController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _trainingDaysController = TextEditingController();
  final TextEditingController _weeksController = TextEditingController();
  List<Map<String, dynamic>> _sessions = <Map<String, dynamic>>[];
  // Preserve untouched template fields when saving from structured mode.
  late Map<String, dynamic> _rawTemplate;
  // Advanced templates require JSON mode because sessions are nested in `programs`.
  late bool _isAdvancedTemplate;
  final List<String> _advancedProgramPaths = [];
  String? _selectedAdvancedProgramPath;
  bool _jsonMode = false;
  bool _includeCoachEdited = false;
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
    _rawTemplate = Map<String, dynamic>.from(initial);
    _isAdvancedTemplate = _rawTemplate['programs'] is Map &&
        (_rawTemplate['programs'] as Map).isNotEmpty;
    _jsonMode = false;
    _jsonController.text = const JsonEncoder.withIndent('  ').convert(initial);
    _loadStructured(initial);
  }

  @override
  void dispose() {
    _jsonController.dispose();
    _planIdController.dispose();
    _nameController.dispose();
    _typeController.dispose();
    _goalController.dispose();
    _locationController.dispose();
    _trainingDaysController.dispose();
    _weeksController.dispose();
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
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(
                    value: false,
                    icon: const Icon(Icons.view_week),
                    label: Text(_tr('plan_editor_plan')),
                  ),
                  ButtonSegment(
                    value: true,
                    icon: const Icon(Icons.data_object),
                    label: Text(_tr('plan_editor_json')),
                  ),
                ],
                selected: {_jsonMode},
                onSelectionChanged: (selection) {
                  setState(() {
                    if (selection.first) {
                      _jsonController.text = const JsonEncoder.withIndent('  ')
                          .convert(_buildTemplate());
                    } else {
                      // Re-sync structured fields from the JSON editor when possible.
                      try {
                        final parsed = jsonDecode(_jsonController.text);
                        if (parsed is Map<String, dynamic>) {
                          _rawTemplate = parsed;
                          _loadStructured(parsed);
                        }
                      } catch (_) {
                        // Leave the structured fields untouched if the JSON is invalid.
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
                    hintText: _tr('admin_workout_template_json_hint'),
                  ),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                )
              else
                _buildPlanEditor(),
              const SizedBox(height: 16),
              SwitchListTile(
                value: _includeCoachEdited,
                contentPadding: EdgeInsets.zero,
                title: Text(_tr('plan_editor_include_coach_edited_users')),
                subtitle: Text(_tr('plan_editor_protect_coach_edited_hint')),
                onChanged: (value) =>
                    setState(() => _includeCoachEdited = value),
              ),
              const SizedBox(height: 8),
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

  Widget _buildPlanEditor() {
    return Column(
      children: [
        if (_isAdvancedTemplate && _advancedProgramPaths.isNotEmpty) ...[
          DropdownButtonFormField<String>(
            initialValue: _selectedAdvancedProgramPath,
            decoration: InputDecoration(
              labelText: _tr('plan_editor_workout_days'),
              border: const OutlineInputBorder(),
            ),
            items: _advancedProgramPaths
              .map((path) => DropdownMenuItem(value: path, child: Text(_formatAdvancedProgramPath(path))))
                .toList(),
            onChanged: (path) {
              if (path == null) return;
              setState(() {
                _selectedAdvancedProgramPath = path;
                _loadStructured(_rawTemplate);
              });
            },
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _planIdController,
          decoration: InputDecoration(
            labelText: _tr('plan_editor_plan_id'),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: _tr('plan_editor_name'),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _typeController,
                decoration: InputDecoration(
                  labelText: _tr('plan_editor_type'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _goalController,
                decoration: InputDecoration(
                  labelText: _tr('plan_editor_goal'),
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
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: _tr('plan_editor_location'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _trainingDaysController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _tr('plan_editor_training_days'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _weeksController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _tr('plan_editor_weeks'),
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
                _tr('plan_editor_workout_days'),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            TextButton.icon(
              onPressed: _addSession,
              icon: const Icon(Icons.add),
              label: Text(_tr('plan_editor_add_day')),
            ),
          ],
        ),
        ..._sessions.asMap().entries.map((entry) {
          final dayIndex = entry.key;
          final session = entry.value;
          final work = _asList(session['work']) ?? const <dynamic>[];
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
                            session['name_en'] ??
                                session['name'] ??
                                session['day_name'],
                            fallback: 'Day ${dayIndex + 1}',
                          ),
                          decoration: InputDecoration(
                            labelText: _tr(
                              'plan_editor_day_name',
                            ).replaceAll('{day}', '${dayIndex + 1}'),
                          ),
                          onChanged: (value) => session['name_en'] = value,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _removeSession(dayIndex),
                        icon: const Icon(Icons.delete, color: AppColors.error),
                      ),
                    ],
                  ),
                  ...work.asMap().entries.map((exerciseEntry) {
                    final exerciseIndex = exerciseEntry.key;
                    final exercise =
                        _asMap(exerciseEntry.value) ?? <String, dynamic>{};
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
                                  child: Autocomplete<AdminExercise>(
                                    initialValue: TextEditingValue(
                                      text: _stringValue(
                                        _resolveExerciseName(exercise),
                                      ),
                                    ),
                                    displayStringForOption: (option) =>
                                        option.nameEn,
                                    optionsBuilder: (value) {
                                      final query = value.text.trim().toLowerCase();
                                      return widget.availableExercises.where((item) {
                                        final id = (item.exId ?? item.id).toLowerCase();
                                        return query.isEmpty ||
                                            item.nameEn.toLowerCase().contains(query) ||
                                            id.contains(query) ||
                                            (item.nameAr?.contains(value.text.trim()) ?? false);
                                      });
                                    },
                                    onSelected: (selected) => setState(() {
                                      exercise['ex_id'] = selected.exId ?? selected.id;
                                      exercise['name_en'] = selected.nameEn;
                                      exercise['name_ar'] = selected.nameAr;
                                      exercise['video_url'] = selected.videoUrl;
                                      exercise['thumbnail_url'] = selected.thumbnailUrl;
                                    }),
                                    fieldViewBuilder: (context, controller, focusNode,
                                        onSubmitted) => TextField(
                                      controller: controller,
                                      focusNode: focusNode,
                                      onChanged: (value) {
                                        exercise['name_en'] = value;
                                      },
                                      decoration: InputDecoration(
                                        labelText: _tr('plan_editor_exercise_name'),
                                        border: const OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      _removeExercise(dayIndex, exerciseIndex),
                                  icon: const Icon(Icons.remove_circle_outline,
                                      color: AppColors.error),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue: _stringValue(exercise['sets'],
                                        fallback: '3'),
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                        labelText: _tr('plan_editor_sets')),
                                    onChanged: (value) => exercise['sets'] =
                                        int.tryParse(value) ?? 0,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: _stringValue(exercise['reps'],
                                        fallback: '10'),
                                    decoration: InputDecoration(
                                        labelText: _tr('plan_editor_reps')),
                                    onChanged: (value) =>
                                        exercise['reps'] = value,
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
                      onPressed: () => _addExercise(dayIndex),
                      icon: const Icon(Icons.add),
                      label: Text(_tr('plan_editor_add_exercise')),
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

  void _loadStructured(Map<String, dynamic> template) {
    _planIdController.text =
        _stringValue(template['plan_id'], fallback: 'new_template_id');
    _nameController.text =
        _stringValue(template['name_en'] ?? template['name']);
    _typeController.text = _stringValue(template['type'], fallback: 'starter');
    _goalController.text = _stringValue(template['goal']);
    _locationController.text = _stringValue(template['location']);
    _trainingDaysController.text =
        _stringValue(template['training_days'], fallback: '3');
    _weeksController.text = _stringValue(template['weeks'], fallback: '4');
    _advancedProgramPaths.clear();
    if (_isAdvancedTemplate) {
      final programs = _asMap(template['programs']) ?? const {};
      programs.forEach((location, goals) {
        (_asMap(goals) ?? const {}).forEach((goal, experiences) {
          (_asMap(experiences) ?? const {}).forEach((experience, sessions) {
            if (_asList(sessions) != null) {
              _advancedProgramPaths.add('$location|$goal|$experience');
            }
          });
        });
      });
      _selectedAdvancedProgramPath ??= _advancedProgramPaths.isEmpty
          ? null
          : _advancedProgramPaths.first;
      final parts = _selectedAdvancedProgramPath?.split('|') ?? const [];
      if (parts.length == 3) {
        template = {
          ...template,
          'sessions': _asMap(_asMap(_asMap(template['programs'])?[parts[0]])?[parts[1]])?[parts[2]],
        };
      }
    }
    _sessions = (_asList(template['sessions']) ??
            _asList(template['days']) ??
            const <dynamic>[])
        .map((item) => Map<String, dynamic>.from(_asMap(item) ?? const {}))
        .map((session) {
      session['work'] = (_asList(session['work']) ??
              _asList(session['exercises']) ??
              const <dynamic>[])
          .map((item) => _normalizeWorkoutExercise(_asMap(item) ?? const {}))
          .toList();
      return session;
    }).toList();
  }

  Map<String, dynamic> _normalizeWorkoutExercise(Map<String, dynamic> exercise) {
    final normalized = Map<String, dynamic>.from(exercise);
    final exId = _stringValue(
      normalized['ex_id'] ?? normalized['exId'] ?? normalized['id'],
    );
    if (exId.isNotEmpty) {
      normalized['ex_id'] = exId;
    }

    final fallback = _findExerciseById(exId);
    final nameEn = _stringValue(
      normalized['name_en'] ?? normalized['name'] ?? fallback?.nameEn,
    );
    final nameAr = _stringValue(normalized['name_ar'] ?? fallback?.nameAr);

    if (nameEn.isNotEmpty) {
      normalized['name_en'] = nameEn;
    }
    if (nameAr.isNotEmpty) {
      normalized['name_ar'] = nameAr;
    }

    return normalized;
  }

  AdminExercise? _findExerciseById(String exId) {
    if (exId.isEmpty) return null;
    for (final item in widget.availableExercises) {
      final candidate = _stringValue(item.exId ?? item.id);
      if (candidate == exId) return item;
    }
    return null;
  }

  String _resolveExerciseName(Map<String, dynamic> exercise) {
    final fromTemplate = _stringValue(exercise['name_en'] ?? exercise['name']);
    if (fromTemplate.isNotEmpty) return fromTemplate;
    final exId = _stringValue(exercise['ex_id'] ?? exercise['exId'] ?? exercise['id']);
    final resolved = _findExerciseById(exId);
    return _stringValue(resolved?.nameEn, fallback: exId);
  }

  Map<String, dynamic> _buildTemplate() {
    // Merge edits into the original template so hidden fields are not dropped.
    final merged = Map<String, dynamic>.from(_rawTemplate);
    merged['plan_id'] = _planIdController.text.trim();
    merged['type'] = _typeController.text.trim();
    if (_goalController.text.trim().isNotEmpty) {
      merged['goal'] = _goalController.text.trim();
    }
    if (_locationController.text.trim().isNotEmpty) {
      merged['location'] = _locationController.text.trim();
    }
    merged['training_days'] =
        int.tryParse(_trainingDaysController.text.trim()) ?? _sessions.length;
    merged['weeks'] = int.tryParse(_weeksController.text.trim()) ?? 4;
    merged['name_en'] = _nameController.text.trim();
    final sessions = _sessions.asMap().entries.map((entry) {
      final index = entry.key;
      final session = entry.value;
      return <String, dynamic>{
        'day': index + 1,
        'name_en': _stringValue(session['name_en'] ?? session['name'],
            fallback: 'Day ${index + 1}'),
        if (_stringValue(session['name_ar']).isNotEmpty)
          'name_ar': _stringValue(session['name_ar']),
        'work': (_asList(session['work']) ?? const <dynamic>[]).map((raw) {
          final exercise = _asMap(raw) ?? const <String, dynamic>{};
          return <String, dynamic>{
            'ex_id': _stringValue(exercise['ex_id']),
            'name_en': _stringValue(exercise['name_en'] ?? exercise['name']),
            if (_stringValue(exercise['name_ar']).isNotEmpty)
              'name_ar': _stringValue(exercise['name_ar']),
            'sets': int.tryParse(_stringValue(exercise['sets'])) ?? 3,
            'reps': _stringValue(exercise['reps'], fallback: '10'),
          };
        }).toList(),
      };
    }).toList();
    if (_isAdvancedTemplate) {
      final parts = _selectedAdvancedProgramPath?.split('|') ?? const [];
      final programs = _asMap(merged['programs']) ?? <String, dynamic>{};
      if (parts.length == 3) {
        final goals = Map<String, dynamic>.from(_asMap(programs[parts[0]]) ?? const {});
        final experiences = Map<String, dynamic>.from(_asMap(goals[parts[1]]) ?? const {});
        experiences[parts[2]] = sessions;
        goals[parts[1]] = experiences;
        programs[parts[0]] = goals;
        merged['programs'] = programs;
      }
    } else {
      merged['sessions'] = sessions;
    }
    return merged;
  }

  void _addSession() {
    setState(() {
      _sessions.add({
        'day': _sessions.length + 1,
        'name_en': 'Day ${_sessions.length + 1}',
        'work': <Map<String, dynamic>>[],
      });
    });
  }

  void _removeSession(int index) {
    setState(() => _sessions.removeAt(index));
  }

  void _addExercise(int dayIndex) {
    setState(() {
      final work = (_asList(_sessions[dayIndex]['work']) ?? <dynamic>[])
          .map((item) => _asMap(item) ?? <String, dynamic>{})
          .toList();
      work.add({'ex_id': '', 'name_en': '', 'sets': 3, 'reps': '10'});
      _sessions[dayIndex]['work'] = work;
    });
  }

  void _removeExercise(int dayIndex, int exerciseIndex) {
    setState(() {
      final work = (_asList(_sessions[dayIndex]['work']) ?? <dynamic>[])
          .map((item) => _asMap(item) ?? <String, dynamic>{})
          .toList();
      if (exerciseIndex >= 0 && exerciseIndex < work.length) {
        work.removeAt(exerciseIndex);
      }
      _sessions[dayIndex]['work'] = work;
    });
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

  String _stringValue(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  String _formatAdvancedProgramPath(String path) {
    final parts = path.split('|');
    if (parts.length != 3) return path;
    String humanize(String value) => value
        .split('_')
        .map((word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
    return '${humanize(parts[0])} • ${humanize(parts[1])} • ${humanize(parts[2])}';
  }

  Future<void> _save() async {
    setState(() => _error = null);
    Map<String, dynamic> payload;
    try {
      if (_jsonMode) {
        final parsed = jsonDecode(_jsonController.text);
        if (parsed is! Map<String, dynamic>) {
          throw FormatException(_tr('plan_editor_error_template_json_object'));
        }
        payload = parsed;
      } else {
        payload = _buildTemplate();
        if (_stringValue(payload['plan_id']).isEmpty) {
          throw FormatException(_tr('plan_editor_error_plan_id_required'));
        }
        // An advanced template keeps its days inside
        // programs[location][goal][experience], not in a top-level `sessions`
        // array, so checking `payload['sessions']` rejected every advanced
        // template no matter how many days were defined. Check the editor's own
        // day list, which holds the days for either shape.
        if (_sessions.isEmpty) {
          throw FormatException(_tr('plan_editor_error_workout_day_required'));
        }
        if (_isAdvancedTemplate && _selectedAdvancedProgramPath == null) {
          // Without a selected program path _buildTemplate has nowhere to write
          // the days back to, and the edit would be silently dropped.
          throw FormatException(
            _tr('plan_editor_error_program_path_required'),
          );
        }
      }
    } catch (error) {
      setState(() => _error = error.toString());
      return;
    }

    final provider = context.read<AdminProvider>();
    final ok = await provider.saveWorkoutTemplate(
      payload,
      includeCoachEdited: _includeCoachEdited,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? _tr('plan_editor_template_saved')
            : provider.error ?? _tr('plan_editor_save_failed')),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
    if (ok) Navigator.pop(context);
  }
}

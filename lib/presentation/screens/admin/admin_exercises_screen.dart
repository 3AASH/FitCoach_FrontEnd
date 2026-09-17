import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/video_thumbnail_resolver.dart';
import '../../../data/models/admin_exercise.dart';
import '../../providers/admin_provider.dart';
import '../../providers/language_provider.dart';
import '../../widgets/custom_card.dart';

String _humanizeSnakeCase(String value) {
  return value
      .split('_')
      .map((word) =>
          word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}

class AdminExercisesScreen extends StatefulWidget {
  const AdminExercisesScreen({super.key});

  @override
  State<AdminExercisesScreen> createState() => _AdminExercisesScreenState();
}

class _AdminExercisesScreenState extends State<AdminExercisesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadExercises();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() {
    return context.read<AdminProvider>().loadExercises(
          search: _searchController.text.trim().isEmpty
              ? null
              : _searchController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.t('home_exercise_library')),
        actions: [
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
        label: Text(lang.t('add')),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _refresh(),
                decoration: InputDecoration(
                  hintText: lang.t('admin_exercise_search_hint'),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _refresh();
                          },
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                  ),
                ),
              ),
            ),
            if (provider.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  provider.error!,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: provider.isLoading && provider.exercises.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : provider.exercises.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 160),
                              Center(
                                child: Text(
                                  'No exercises found',
                                  style:
                                      TextStyle(color: AppColors.textSecondary),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                            itemCount: provider.exercises.length,
                            itemBuilder: (context, index) {
                              final exercise = provider.exercises[index];
                              return _ExerciseAdminCard(
                                exercise: exercise,
                                availableExercises: provider.exercises,
                                onEdit: () => _openEditor(exercise: exercise),
                                onUploadVideo: () => _uploadVideo(exercise),
                                onDelete: () => _confirmDelete(exercise),
                              );
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditor({AdminExercise? exercise}) async {
    final availableExercises = context.read<AdminProvider>().exercises;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ExerciseEditorSheet(
        exercise: exercise,
        availableExercises: availableExercises,
      ),
    );
  }

  Future<void> _confirmDelete(AdminExercise exercise) async {
    final lang = context.read<LanguageProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.t('delete')),
        content: Text(lang.t('admin_delete_exercise_confirm',
            args: {'name': exercise.nameEn})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(lang.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(lang.t('delete')),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    final ok = await context.read<AdminProvider>().deleteExercise(exercise.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Exercise deleted'
            : context.read<AdminProvider>().error ?? 'Delete failed'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }

  Future<void> _uploadVideo(AdminExercise exercise) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );
    final path = result?.files.single.path;
    if (path == null || !mounted) return;

    final provider = context.read<AdminProvider>();
    final ok = await provider.uploadExerciseVideo(exercise.id, path);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(ok ? 'Video uploaded' : provider.error ?? 'Upload failed'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }
}

class _ExerciseAdminCard extends StatelessWidget {
  final AdminExercise exercise;
  final List<AdminExercise> availableExercises;
  final VoidCallback onEdit;
  final VoidCallback onUploadVideo;
  final VoidCallback onDelete;

  const _ExerciseAdminCard({
    required this.exercise,
    required this.availableExercises,
    required this.onEdit,
    required this.onUploadVideo,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final displayName = lang.isArabic && (exercise.nameAr?.isNotEmpty == true)
        ? exercise.nameAr!
        : exercise.nameEn;
    final subtitle = [
      if (exercise.exId != null) exercise.exId!,
      if (exercise.muscleGroups.isNotEmpty)
        exercise.muscleGroups.map(_humanizeSnakeCase).join(', '),
      if (exercise.equipment.isNotEmpty)
        exercise.equipment.map(_humanizeSnakeCase).join(', '),
    ].join(' • ');
    final alternativesCount =
        exercise.alternativesCount ?? exercise.alternatives.length;
    final alternativeLabels = _alternativeLabels();

    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _ExerciseThumb(
                url: exercise.thumbnailUrl, videoUrl: exercise.videoUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (alternativeLabels.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${lang.t('admin_exercise_swap_alternatives')}: ${alternativeLabels.take(3).join(', ')}${alternativeLabels.length > 3 ? ' +' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (exercise.difficulty != null)
                        _Badge(label: exercise.difficulty!),
                      if (exercise.videoUrl != null)
                        _Badge(label: lang.t('video')),
                      _Badge(
                        label: exercise.hasAlternatives
                            ? lang.t('admin_exercise_swaps_count',
                                args: {'count': '$alternativesCount'})
                            : lang.t('admin_exercise_no_swaps'),
                        background: exercise.hasAlternatives
                            ? AppColors.success.withValues(alpha: 0.14)
                            : AppColors.surface,
                        foreground: exercise.hasAlternatives
                            ? AppColors.success
                            : AppColors.textSecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: lang.t('edit'),
              onPressed: onEdit,
              icon: const Icon(Icons.edit),
            ),
            IconButton(
              tooltip: lang.t('admin_exercise_upload_video'),
              onPressed: onUploadVideo,
              icon: const Icon(Icons.video_call),
            ),
            IconButton(
              tooltip: lang.t('delete'),
              onPressed: onDelete,
              color: AppColors.error,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _alternativeLabels() {
    final byKey = <String, AdminExercise>{};
    for (final item in availableExercises) {
      byKey[item.id] = item;
      final exId = item.exId;
      if (exId != null && exId.trim().isNotEmpty) {
        byKey[exId] = item;
      }
    }

    return exercise.alternatives.map((id) => byKey[id]?.nameEn ?? id).toList();
  }
}

class _ExerciseEditorSheet extends StatefulWidget {
  final AdminExercise? exercise;
  final List<AdminExercise> availableExercises;

  const _ExerciseEditorSheet({
    this.exercise,
    required this.availableExercises,
  });

  @override
  State<_ExerciseEditorSheet> createState() => _ExerciseEditorSheetState();
}

class _ExerciseEditorSheetState extends State<_ExerciseEditorSheet> {
  // This sheet builds its parts in separate methods, so each one would otherwise have
  // to thread the provider through.
  String _tr(String key, {Map<String, String>? args}) =>
      Provider.of<LanguageProvider>(context, listen: false)
          .translate(key, args: args);

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _exId;
  late final TextEditingController _nameEn;
  late final TextEditingController _nameAr;
  late final TextEditingController _category;
  late final TextEditingController _difficulty;
  late final TextEditingController _muscles;
  late final TextEditingController _equipment;
  late final TextEditingController _videoUrl;
  late final TextEditingController _thumbnailUrl;
  late final TextEditingController _instructions;
  late final Set<String> _selectedAlternatives;

  @override
  void initState() {
    super.initState();
    final exercise = widget.exercise;
    _exId = TextEditingController(text: exercise?.exId ?? '');
    _nameEn = TextEditingController(text: exercise?.nameEn ?? '');
    _nameAr = TextEditingController(text: exercise?.nameAr ?? '');
    _category = TextEditingController(text: exercise?.category ?? '');
    _difficulty = TextEditingController(text: exercise?.difficulty ?? '');
    _muscles =
        TextEditingController(text: exercise?.muscleGroups.join(', ') ?? '');
    _equipment =
        TextEditingController(text: exercise?.equipment.join(', ') ?? '');
    _selectedAlternatives = {
      ...(exercise?.alternatives ?? const []).map(_canonicalAlternativeKey),
    };
    _videoUrl = TextEditingController(text: exercise?.videoUrl ?? '');
    _thumbnailUrl = TextEditingController(text: exercise?.thumbnailUrl ?? '');
    _instructions = TextEditingController(text: exercise?.instructions ?? '');
  }

  @override
  void dispose() {
    _exId.dispose();
    _nameEn.dispose();
    _nameAr.dispose();
    _category.dispose();
    _difficulty.dispose();
    _muscles.dispose();
    _equipment.dispose();
    _videoUrl.dispose();
    _thumbnailUrl.dispose();
    _instructions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final inset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: Form(
            key: _formKey,
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.exercise == null
                            ? lang.t('admin_exercise_create_title')
                            : lang.t('admin_exercise_edit_title'),
                        style: AppTextStyles.h2,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _field(_nameEn, _tr('admin_exercise_english_name'),
                    required: true),
                _field(_exId, _tr('admin_exercise_template_id')),
                _field(_nameAr, _tr('admin_exercise_arabic_name')),
                _field(_category, _tr('admin_exercise_category')),
                _field(_difficulty, _tr('admin_exercise_difficulty')),
                _field(_muscles, _tr('admin_exercise_muscles')),
                _field(_equipment, _tr('admin_exercise_equipment')),
                _buildSwapSelector(),
                _field(_videoUrl, _tr('admin_exercise_video_url')),
                _field(_thumbnailUrl, _tr('admin_exercise_thumbnail_url')),
                _field(_instructions, _tr('admin_exercise_instructions'),
                    maxLines: 4),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: Text(lang.t('save')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: required
            ? (value) =>
                value == null || value.trim().isEmpty ? 'Required' : null
            : null,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final base = widget.exercise;
    final videoUrl = _emptyToNull(_videoUrl.text);
    final thumbnailUrl = _emptyToNull(_thumbnailUrl.text) ??
        VideoThumbnailResolver.fromVideoUrl(videoUrl);
    final exercise = AdminExercise(
      id: base?.id ?? '',
      exId: _emptyToNull(_exId.text),
      nameEn: _nameEn.text.trim(),
      nameAr: _emptyToNull(_nameAr.text),
      category: _emptyToNull(_category.text),
      difficulty: _emptyToNull(_difficulty.text),
      muscleGroups: _csv(_muscles.text),
      equipment: _csv(_equipment.text),
      alternatives: _selectedAlternatives.toList()..sort(),
      alternativesCount: _selectedAlternatives.length,
      videoUrl: videoUrl,
      thumbnailUrl: thumbnailUrl,
      instructions: _emptyToNull(_instructions.text),
    );

    final provider = context.read<AdminProvider>();
    final ok = base == null
        ? await provider.createExercise(exercise)
        : await provider.updateExercise(exercise);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Exercise saved' : provider.error ?? 'Save failed'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
    if (ok) Navigator.pop(context);
  }

  String? _emptyToNull(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  List<String> _csv(String value) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  String _exerciseKey(AdminExercise exercise) => exercise.id;

  String _canonicalAlternativeKey(String id) => _exerciseByKey[id]?.id ?? id;

  Map<String, AdminExercise> get _exerciseByKey {
    final byKey = <String, AdminExercise>{};
    for (final exercise in widget.availableExercises) {
      byKey[exercise.id] = exercise;
      final exId = exercise.exId;
      if (exId != null && exId.trim().isNotEmpty) {
        byKey[exId] = exercise;
      }
    }
    return byKey;
  }

  List<AdminExercise> get _selectableExercises {
    final currentId = widget.exercise?.id;
    final currentExId = widget.exercise?.exId;
    return widget.availableExercises.where((exercise) {
      return exercise.id != currentId && exercise.exId != currentExId;
    }).toList()
      ..sort(
          (a, b) => a.nameEn.toLowerCase().compareTo(b.nameEn.toLowerCase()));
  }

  Widget _buildSwapSelector() {
    final byKey = _exerciseByKey;
    final selected = _selectedAlternatives.toList()..sort();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: _tr('admin_exercise_swap_alternatives'),
          border: const OutlineInputBorder(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (selected.isEmpty)
              Text(
                _tr('admin_no_swap_exercises_selected'),
                style: const TextStyle(color: AppColors.textSecondary),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selected.map((id) {
                  final exercise = byKey[id];
                  return InputChip(
                    label: Text(exercise?.nameEn ?? id),
                    onDeleted: () {
                      setState(() => _selectedAlternatives.remove(id));
                    },
                  );
                }).toList(),
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _openSwapPicker,
              icon: const Icon(Icons.swap_horiz),
              label: Text(_tr('admin_choose_from_exercise_library')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSwapPicker() async {
    final options = _selectableExercises;
    final draft = {..._selectedAlternatives};
    String query = '';

    final result = await showDialog<Set<String>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final normalizedQuery = query.trim().toLowerCase();
            final filtered = normalizedQuery.isEmpty
                ? options
                : options.where((exercise) {
                    final key = _exerciseKey(exercise).toLowerCase();
                    return exercise.nameEn
                            .toLowerCase()
                            .contains(normalizedQuery) ||
                        (exercise.nameAr ?? '')
                            .toLowerCase()
                            .contains(normalizedQuery) ||
                        key.contains(normalizedQuery);
                  }).toList();

            return AlertDialog(
              title: Text(_tr('admin_choose_swap_exercises')),
              content: SizedBox(
                width: double.maxFinite,
                height: 460,
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        labelText: _tr('admin_exercise_search_exercises'),
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setDialogState(() => query = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(child: Text(_tr('admin_no_exercises_found')))
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final exercise = filtered[index];
                                final key = _exerciseKey(exercise);
                                final selected = draft.contains(key);
                                return CheckboxListTile(
                                  value: selected,
                                  title: Text(
                                    exercise.nameEn,
                                    style: const TextStyle(
                                        color: AppColors.textPrimary),
                                  ),
                                  subtitle: Text(
                                    [
                                      if (exercise.muscleGroups.isNotEmpty)
                                        exercise.muscleGroups
                                            .map(_humanizeSnakeCase)
                                            .join(', '),
                                      if (exercise.equipment.isNotEmpty)
                                        exercise.equipment
                                            .map(_humanizeSnakeCase)
                                            .join(', '),
                                    ].join(' • '),
                                    style: const TextStyle(
                                        color: AppColors.textSecondary),
                                  ),
                                  onChanged: (value) {
                                    setDialogState(() {
                                      if (value == true) {
                                        draft.add(key);
                                      } else {
                                        draft.remove(key);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(_tr('cancel')),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, draft),
                  child: Text(_tr('admin_apply')),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;
    setState(() {
      _selectedAlternatives
        ..clear()
        ..addAll(result);
    });
  }
}

class _ExerciseThumb extends StatelessWidget {
  final String? url;
  final String? videoUrl;

  const _ExerciseThumb({this.url, this.videoUrl});

  @override
  Widget build(BuildContext context) {
    final imageUrl = VideoThumbnailResolver.resolve(
      thumbnailUrl: url,
      videoUrl: videoUrl,
    );
    if (imageUrl == null || imageUrl.isEmpty) {
      return _placeholder();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.fitness_center, color: AppColors.textSecondary),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color? background;
  final Color? foreground;

  const _Badge({
    required this.label,
    this.background,
    this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background ?? AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground ?? AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

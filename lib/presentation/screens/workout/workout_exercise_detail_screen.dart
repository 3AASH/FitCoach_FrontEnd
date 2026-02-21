import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/demo_config.dart';
import '../../../core/constants/colors.dart';
import '../../../data/models/workout_plan.dart';
import '../../../data/services/exercise_catalog_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/workout_provider.dart';
import '../../widgets/custom_card.dart';

class WorkoutExerciseDetailScreen extends StatefulWidget {
  final Exercise exercise;
  final VoidCallback onStartExercise;

  const WorkoutExerciseDetailScreen({
    super.key,
    required this.exercise,
    required this.onStartExercise,
  });

  @override
  State<WorkoutExerciseDetailScreen> createState() => _WorkoutExerciseDetailScreenState();
}

class _WorkoutExerciseDetailScreenState extends State<WorkoutExerciseDetailScreen> {
  bool _showTutorial = false;
  bool _tutorialLoaded = false;
  final ExerciseCatalogService _catalogService = ExerciseCatalogService.instance;

  @override
  void initState() {
    super.initState();
    _loadTutorialFlag();
  }

  Future<void> _loadTutorialFlag() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(_tutorialKey) ?? false;
    if (mounted) {
      setState(() {
        _showTutorial = DemoConfig.isDemo && !seen;
        _tutorialLoaded = true;
      });
    }
  }

  String get _tutorialKey => 'exercise_seen_${widget.exercise.id}';

  Future<void> _dismissTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialKey, true);
    if (mounted) {
      setState(() {
        _showTutorial = false;
      });
    }
  }

  Future<void> _startFromTutorial() async {
    await _dismissTutorial();
    widget.onStartExercise();
  }

  Future<void> _showAlternatives() async {
    final provider = context.read<WorkoutProvider>();
    final lang = context.read<LanguageProvider>();
    final authProvider = context.read<AuthProvider>();
    final injuries = authProvider.user?.injuries ?? [];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<List<Exercise>>(
            future: provider.getExerciseAlternatives(widget.exercise.id, injuries),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 160,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final alternatives = snapshot.data ?? [];
              if (alternatives.isEmpty) {
                return SizedBox(
                  height: 200,
                  child: Center(
                    child: Text(
                      lang.t('exercise_no_alternatives'),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                );
              }
              return SizedBox(
                height: 420,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang.t('exercise_alternative_exercises'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        itemCount: alternatives.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final alt = alternatives[index];
                          return ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: AppColors.border),
                            ),
                            title: Text(
                              alt.nameEn,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${alt.sets} ${lang.t('sets')} \u2022 ${alt.reps} ${lang.t('reps')}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                              trailing: Icon(
                                Directionality.of(context) == TextDirection.rtl
                                    ? Icons.chevron_left
                                    : Icons.chevron_right,
                              ),
                            onTap: () async {
                              Navigator.pop(context);
                              final success = await provider.substituteExercise(
                                widget.exercise.id,
                                alt.id,
                              );
                              if (success && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(lang.t('exercise_substituted_successfully')),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  List<String> _splitLines(String? text) {
    if (text == null || text.trim().isEmpty) {
      return [];
    }
    return text
        .split(RegExp(r'\\.|\\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final isArabic = lang.isArabic;
    final exercise = widget.exercise;
    final equipmentLabel = _localizeEquipment(exercise.equipment, isArabic, lang.t('equipment'));
    final muscleLabel = _localizeMuscles(exercise.muscleGroup, isArabic);
    final heroImage = exercise.thumbnailUrl ?? 'assets/placeholders/splash_onboarding/workout_onboarding.png';
    final instructions = _splitLines(
      isArabic ? exercise.instructionsAr ?? exercise.instructions : exercise.instructionsEn ?? exercise.instructions,
    );
    final tips = _splitLines(exercise.notes);

    Widget buildHeroImage() {
      if (heroImage.startsWith('assets/')) {
        return Image.asset(heroImage, fit: BoxFit.cover);
      }
      return Image.network(
        heroImage,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(
          'assets/placeholders/splash_onboarding/workout_onboarding.png',
          fit: BoxFit.cover,
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.8,
                child: buildHeroImage(),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            isArabic ? Icons.arrow_forward : Icons.arrow_back,
                            color: AppColors.textWhite,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isArabic ? exercise.nameAr : exercise.nameEn,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textWhite,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${muscleLabel.isEmpty ? '' : muscleLabel} \u2022 ${exercise.category ?? ''}',
                                style: TextStyle(
                                  color: AppColors.textWhite.withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            ),
                          ),
                        if (exercise.difficulty != null)
                          _DifficultyBadge(label: exercise.difficulty!),
                        IconButton(
                          onPressed: _showAlternatives,
                          icon: const Icon(Icons.swap_horiz, color: AppColors.textWhite),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomCard(
                            padding: EdgeInsets.zero,
                            child: Container(
                              height: 180,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.play_circle, size: 48, color: AppColors.textSecondary),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${isArabic ? exercise.nameAr : exercise.nameEn} ${lang.t('exercise_demo')}',
                                      style: const TextStyle(color: AppColors.textSecondary),
                                    ),
                                    const SizedBox(height: 8),
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              isArabic
                                                ? lang.t('exercise_video_unavailable')
                                                : lang.t('exercise_video_unavailable'),
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.play_arrow),
                                      label: Text(lang.t('exercise_watch_video_btn')),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _QuickStat(
                                value: '${exercise.sets}',
                                label: lang.t('exercise_sets'),
                              ),
                              _QuickStat(
                                value: exercise.reps,
                                label: lang.t('exercise_reps'),
                              ),
                              _QuickStat(
                                value: exercise.restTime ?? lang.t('exercise_rest_default'),
                                label: lang.t('exercise_rest'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: TabBar(
                              labelColor: AppColors.primary,
                              unselectedLabelColor: AppColors.textSecondary,
                              indicatorColor: AppColors.primary,
                              indicatorWeight: 3,
                              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                              tabs: [
                                Tab(text: lang.t('exercise_overview')),
                                Tab(text: lang.t('exercise_instructions')),
                                Tab(text: lang.t('exercise_tips')),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 320,
                            child: TabBarView(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 12),
                                    CustomCard(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            lang.t('exercise_equipment_needed'),
                                            style: const TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 8,
                                            children: [
                                              _Badge(text: equipmentLabel),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    CustomCard(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            lang.t('exercise_muscle_groups'),
                                            style: const TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                          const SizedBox(height: 8),
                                          _Badge(text: muscleLabel),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 12),
                                      CustomCard(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              lang.t('exercise_step_by_step'),
                                              style: const TextStyle(fontWeight: FontWeight.w600),
                                            ),
                                            const SizedBox(height: 12),
                                            if (instructions.isEmpty)
                                              Text(lang.t('exercise_no_instructions'))
                                            else
                                              ...instructions.asMap().entries.map((entry) {
                                                final idx = entry.key + 1;
                                                final line = entry.value;
                                                return Padding(
                                                  padding: const EdgeInsets.only(bottom: 8),
                                                  child: Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Container(
                                                        width: 24,
                                                        height: 24,
                                                        decoration: BoxDecoration(
                                                          color: AppColors.primary,
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                        child: Center(
                                                          child: Text(
                                                            '$idx',
                                                            style: const TextStyle(
                                                              color: AppColors.textWhite,
                                                              fontWeight: FontWeight.w600,
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(child: Text(line)),
                                                    ],
                                                  ),
                                                );
                                              }),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 12),
                                      CustomCard(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              lang.t('exercise_key_cues'),
                                              style: const TextStyle(fontWeight: FontWeight.w600),
                                            ),
                                            const SizedBox(height: 8),
                                            if (tips.isEmpty)
                                              Text(lang.t('exercise_no_tips'))
                                            else
                                              ...tips.map(
                                                (tip) => Padding(
                                                  padding: const EdgeInsets.only(bottom: 6),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        width: 6,
                                                        height: 6,
                                                        decoration: BoxDecoration(
                                                          color: AppColors.success,
                                                          borderRadius: BorderRadius.circular(3),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(child: Text(tip)),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _showAlternatives,
                                  icon: const Icon(Icons.swap_horiz),
                                  label: Text(lang.t('exercise_swap_exercise')),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: widget.onStartExercise,
                                  icon: const Icon(Icons.play_arrow),
                                  label: Text(lang.t('exercise_start_exercise')),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_tutorialLoaded && _showTutorial)
              _TutorialOverlay(
                onGotIt: _dismissTutorial,
                onStart: _startFromTutorial,
              ),
          ],
        ),
      ),
    );
  }

  String _localizeEquipment(String? equipment, bool isArabic, String fallback) {
    if (equipment == null || equipment.trim().isEmpty) {
      return fallback;
    }
    return _localizeList(equipment, isArabic, isEquipment: true);
  }

  String _localizeMuscles(String? muscles, bool isArabic) {
    if (muscles == null || muscles.trim().isEmpty) {
      return '';
    }
    return _localizeList(muscles, isArabic, isEquipment: false);
  }

  String _localizeList(String value, bool isArabic, {required bool isEquipment}) {
    final parts = value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
    final labels = parts.map((part) {
      return isEquipment
          ? (_catalogService.getEquipLabel(part, isArabic: isArabic) ?? part)
          : (_catalogService.getMuscleLabel(part, isArabic: isArabic) ?? part);
    }).toList();
    return labels.join(', ');
  }
}

class _QuickStat extends StatelessWidget {
  final String value;
  final String label;

  const _QuickStat({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  final String label;

  const _DifficultyBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final normalized = label.toLowerCase();
    Color background;
    Color foreground;
    switch (normalized) {
      case 'beginner':
        background = AppColors.success.withValues(alpha: 0.2);
        foreground = AppColors.success;
        break;
      case 'intermediate':
        background = AppColors.warning.withValues(alpha: 0.2);
        foreground = AppColors.warning;
        break;
      case 'advanced':
        background = AppColors.error.withValues(alpha: 0.2);
        foreground = AppColors.error;
        break;
      default:
        background = AppColors.textWhite.withValues(alpha: 0.2);
        foreground = AppColors.textWhite;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;

  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
    );
  }
}

class _TutorialOverlay extends StatelessWidget {
  final VoidCallback onGotIt;
  final VoidCallback onStart;

  const _TutorialOverlay({
    required this.onGotIt,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return Positioned.fill(
      child: Container(
        color: AppColors.textPrimary.withValues(alpha: 0.7),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Material(
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          lang.t('exercise_tutorial_title'),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _TutorialStep(
                      icon: Icons.play_arrow,
                      title: lang.t('exercise_watch_video_title'),
                      description: lang.t('exercise_watch_video_desc'),
                    ),
                    const SizedBox(height: 12),
                    _TutorialStep(
                      icon: Icons.flash_on,
                      title: lang.t('exercise_start_set_title'),
                      description: lang.t('exercise_start_set_desc'),
                    ),
                    const SizedBox(height: 12),
                    _TutorialStep(
                      icon: Icons.check_circle_outline,
                      title: lang.t('exercise_log_reps_title'),
                      description: lang.t('exercise_log_reps_desc'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onGotIt,
                            child: Text(lang.t('exercise_got_it')),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: onStart,
                            child: Text(lang.t('exercise_start_exercise')),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TutorialStep extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _TutorialStep({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

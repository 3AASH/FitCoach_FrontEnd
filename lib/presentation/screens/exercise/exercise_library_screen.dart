import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/video_thumbnail_resolver.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/exercise_catalog_service.dart';
import '../../providers/language_provider.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';
import '../../../core/theme/app_palette.dart';

class ExerciseLibraryScreen extends StatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  String _selectedCategory = 'all';
  String _selectedDifficulty = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ExerciseCatalogService _catalogService =
      ExerciseCatalogService.instance;
  final WorkoutRepository _workoutRepository = WorkoutRepository();
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _exercises = [];

  final List<String> _categories = [
    'all',
    'chest',
    'back',
    'shoulders',
    'arms',
    'legs',
    'core',
    'cardio',
  ];

  final List<String> _difficulties = [
    'all',
    'beginner',
    'intermediate',
    'advanced'
  ];

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    try {
      await _catalogService.load();
      final backendExercises = await _workoutRepository.getExerciseLibrary();
      if (!mounted) return;
      setState(() {
        _exercises = backendExercises.map(_fromBackendExercise).toList();
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      await _loadLocalCatalogFallback(e);
    }
  }

  Future<void> _loadLocalCatalogFallback(Object error) async {
    try {
      final catalog = await _catalogService.load();
      if (!mounted) return;
      setState(() {
        _exercises = catalog.exercises.map((ex) {
          return {
            'id': ex.id,
            'nameEn': ex.nameEn,
            'nameAr': ex.nameAr,
            'category': _inferCategory(ex.muscles),
            'difficulty': 'beginner',
            'equipment': ex.equip.join(', '),
            'equipmentList': ex.equip,
            'muscle': ex.muscles.join(', '),
            'muscleList': ex.muscles,
            'videoUrl': ex.videoUrl,
            'thumbnail': ex.thumbnailUrl,
            'instructions': _splitLines(ex.instructionsEn ?? ''),
            'instructionsAr': _splitLines(ex.instructionsAr ?? ''),
          };
        }).toList();
        _isLoading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = error.toString();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final isArabic = languageProvider.isArabic;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(isArabic ? 'مكتبة التمارين' : 'Exercise Library'),
        ),
        body: Center(
          child: Text(
            isArabic
                ? 'تعذر تحميل مكتبة التمارين'
                : 'Failed to load exercise library',
            style: TextStyle(color: context.palette.textSecondary),
          ),
        ),
      );
    }

    final filteredExercises = _exercises.where((ex) {
      if (_selectedCategory != 'all' && ex['category'] != _selectedCategory) {
        return false;
      }
      if (_selectedDifficulty != 'all' &&
          ex['difficulty'] != _selectedDifficulty) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final name = isArabic ? ex['nameAr'] : ex['nameEn'];
        return name.toLowerCase().contains(query);
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'مكتبة التمارين' : 'Exercise Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilters(context, isArabic),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: isArabic ? 'ابحث عن تمرين...' : 'Search exercises...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: context.palette.surfaceVariant,
              ),
            ),
          ),

          // Category chips
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_getCategoryName(category, isArabic)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.primary,
                  ),
                );
              },
            ),
          ),

          // Exercise list
          Expanded(
            child: filteredExercises.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 80,
                          color: context.palette.textDisabled,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          isArabic
                              ? 'لم يتم العثور على تمارين'
                              : 'No exercises found',
                          style: TextStyle(
                            fontSize: 18,
                            color: context.palette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredExercises.length,
                    itemBuilder: (context, index) {
                      return _buildExerciseCard(
                        filteredExercises[index],
                        isArabic,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> exercise, bool isArabic) {
    final equipmentLabel =
        _formatEquip(exercise['equipmentList'] as List<dynamic>, isArabic);
    final musclesLabel =
        _formatMuscles(exercise['muscleList'] as List<dynamic>, isArabic);
    final thumbnail = _resolveThumbnail(
        exercise['thumbnail'] as String?, exercise['videoUrl'] as String?);
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () => _showExerciseDetail(exercise, isArabic),
      child: Row(
        children: [
          // Thumbnail
          _buildThumbnail(thumbnail, 80, 80),

          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? exercise['nameAr'] : exercise['nameEn'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  musclesLabel,
                  style: TextStyle(
                    fontSize: 14,
                    color: context.palette.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildBadge(
                      _getDifficultyLabel(exercise['difficulty'], isArabic),
                      _getDifficultyColor(exercise['difficulty']),
                    ),
                    const SizedBox(width: 8),
                    _buildBadge(
                      equipmentLabel,
                      context.palette.textSecondary,
                    ),
                  ],
                ),
              ],
            ),
          ),

          Icon(
            isArabic ? Icons.chevron_left : Icons.chevron_right,
            color: context.palette.textDisabled,
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _getCategoryName(String category, bool isArabic) {
    final names = {
      'all': isArabic ? 'الكل' : 'All',
      'chest': isArabic ? 'صدر' : 'Chest',
      'back': isArabic ? 'ظهر' : 'Back',
      'shoulders': isArabic ? 'أكتاف' : 'Shoulders',
      'arms': isArabic ? 'ذراعين' : 'Arms',
      'legs': isArabic ? 'أرجل' : 'Legs',
      'core': isArabic ? 'بطن' : 'Core',
      'cardio': isArabic ? 'كارديو' : 'Cardio',
    };
    return names[category] ?? category;
  }

  String _getDifficultyLabel(String difficulty, bool isArabic) {
    final labels = {
      'beginner': isArabic ? 'مبتدئ' : 'Beginner',
      'intermediate': isArabic ? 'متوسط' : 'Intermediate',
      'advanced': isArabic ? 'متقدم' : 'Advanced',
    };
    return labels[difficulty] ?? difficulty;
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'beginner':
        return AppColors.success;
      case 'intermediate':
        return AppColors.warning;
      case 'advanced':
        return AppColors.error;
      default:
        return context.palette.textSecondary;
    }
  }

  void _showFilters(BuildContext context, bool isArabic) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isArabic ? 'المستوى' : 'Difficulty Level',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _difficulties.map((diff) {
                final isSelected = _selectedDifficulty == diff;
                return FilterChip(
                  label: Text(_getDifficultyLabel(diff, isArabic)),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedDifficulty = diff;
                    });
                    Navigator.pop(context);
                  },
                  selectedColor: AppColors.primary.withValues(alpha: 0.2),
                  checkmarkColor: AppColors.primary,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showExerciseDetail(Map<String, dynamic> exercise, bool isArabic) {
    final equipmentLabel =
        _formatEquip(exercise['equipmentList'] as List<dynamic>, isArabic);
    final musclesLabel =
        _formatMuscles(exercise['muscleList'] as List<dynamic>, isArabic);
    final instructions = isArabic
        ? (exercise['instructionsAr'] as List<dynamic>)
        : (exercise['instructions'] as List<dynamic>);
    final thumbnail = _resolveThumbnail(
        exercise['thumbnail'] as String?, exercise['videoUrl'] as String?);
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.palette.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Video thumbnail with play button
                Stack(
                  alignment: Alignment.center,
                  children: [
                    _buildThumbnail(
                      thumbnail,
                      double.infinity,
                      200,
                      borderRadius: 12,
                    ),
                    InkWell(
                      onTap: () =>
                          _openVideo(exercise['videoUrl'] as String?, isArabic),
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Title
                Text(
                  isArabic ? exercise['nameAr'] : exercise['nameEn'],
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                // Badges
                Row(
                  children: [
                    _buildBadge(
                      _getDifficultyLabel(exercise['difficulty'], isArabic),
                      _getDifficultyColor(exercise['difficulty']),
                    ),
                    const SizedBox(width: 8),
                    _buildBadge(
                      equipmentLabel,
                      context.palette.textSecondary,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Target muscles
                _buildSection(
                  isArabic ? 'العضلات المستهدفة' : 'Target Muscles',
                  musclesLabel,
                  isArabic,
                ),

                const SizedBox(height: 24),

                // Instructions
                Text(
                  isArabic ? 'التعليمات' : 'Instructions',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...List<Widget>.generate(
                  instructions.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            instructions[index] as String,
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Add to workout button
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: isArabic ? 'إضافة إلى التمرين' : 'Add to Workout',
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isArabic
                                ? 'تمت الإضافة إلى التمرين'
                                : 'Added to workout',
                          ),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                    variant: ButtonVariant.primary,
                    size: ButtonSize.large,
                    fullWidth: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, bool isArabic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            fontSize: 15,
            color: context.palette.textSecondary,
          ),
        ),
      ],
    );
  }

  List<String> _splitLines(String text) {
    if (text.trim().isEmpty) return [];
    return text
        .split(RegExp(r'\n|\r'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  Map<String, dynamic> _fromBackendExercise(Map<String, dynamic> ex) {
    final muscles = _stringList(ex['muscle_groups'] ?? ex['muscleGroups']);
    final equip = _stringList(ex['equipment']);
    return {
      'id': _string(ex['ex_id'] ?? ex['exId'] ?? ex['id']) ?? '',
      'nameEn':
          _string(ex['name_en'] ?? ex['nameEn'] ?? ex['name']) ?? 'Exercise',
      'nameAr': _string(
              ex['name_ar'] ?? ex['nameAr'] ?? ex['name_en'] ?? ex['name']) ??
          'Exercise',
      'category': _string(ex['category']) ?? _inferCategory(muscles),
      'difficulty': _string(ex['difficulty']) ?? 'beginner',
      'equipment': equip.join(', '),
      'equipmentList': equip,
      'muscle': muscles.join(', '),
      'muscleList': muscles,
      'videoUrl': _string(ex['video_url'] ?? ex['videoUrl']),
      'thumbnail': _string(ex['thumbnail_url'] ?? ex['thumbnailUrl']),
      'instructions': _splitLines(
          _string(ex['instructions_en'] ?? ex['instructions']) ?? ''),
      'instructionsAr': _splitLines(
          _string(ex['instructions_ar'] ?? ex['instructions']) ?? ''),
    };
  }

  List<String> _stringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    if (value is String && value.trim().isNotEmpty) {
      return value
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }

  String? _string(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  Widget _buildThumbnail(
    String? url,
    double width,
    double height, {
    double borderRadius = 8,
  }) {
    final placeholder = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.palette.surfaceVariant,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(Icons.fitness_center, color: context.palette.textSecondary),
    );

    if (url == null || url.isEmpty) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.network(
        url,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
  }

  String? _resolveThumbnail(String? thumbnailUrl, String? videoUrl) {
    return VideoThumbnailResolver.resolve(
      thumbnailUrl: thumbnailUrl,
      videoUrl: videoUrl,
    );
  }

  Future<void> _openVideo(String? videoUrl, bool isArabic) async {
    if (videoUrl == null || videoUrl.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(isArabic ? 'Video unavailable' : 'Video unavailable')),
      );
      return;
    }
    final resolvedUrl = VideoThumbnailResolver.assetUrl(videoUrl);
    final uri = Uri.tryParse(resolvedUrl?.trim() ?? '');
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(isArabic ? 'Video unavailable' : 'Video unavailable')),
      );
    }
  }

  String _inferCategory(List<String> muscles) {
    if (muscles.contains('chest')) {
      return 'chest';
    }
    if (muscles.contains('back') ||
        muscles.contains('lats') ||
        muscles.contains('mid_back')) {
      return 'back';
    }
    if (muscles.contains('shoulders') ||
        muscles.contains('front_delts') ||
        muscles.contains('rear_delts') ||
        muscles.contains('side_delts')) {
      return 'shoulders';
    }
    if (muscles.contains('biceps') || muscles.contains('triceps')) {
      return 'arms';
    }
    if (muscles.contains('quads') ||
        muscles.contains('glutes') ||
        muscles.contains('hamstrings') ||
        muscles.contains('calves')) {
      return 'legs';
    }
    if (muscles.contains('core')) {
      return 'core';
    }
    if (muscles.contains('cardio')) {
      return 'cardio';
    }
    return 'all';
  }

  String _formatEquip(List<dynamic> equip, bool isArabic) {
    final labels = equip
        .map((e) =>
            _catalogService.getEquipLabel(e.toString(), isArabic: isArabic) ??
            e.toString())
        .toList();
    return labels.join(', ');
  }

  String _formatMuscles(List<dynamic> muscles, bool isArabic) {
    final labels = muscles
        .map((m) =>
            _catalogService.getMuscleLabel(m.toString(), isArabic: isArabic) ??
            m.toString())
        .toList();
    return labels.join(', ');
  }
}

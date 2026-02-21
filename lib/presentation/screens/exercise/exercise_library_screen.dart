import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../data/services/exercise_catalog_service.dart';
import '../../providers/language_provider.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';

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
  final ExerciseCatalogService _catalogService = ExerciseCatalogService.instance;
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
  
  final List<String> _difficulties = ['all', 'beginner', 'intermediate', 'advanced'];
  
  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
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
            isArabic ? 'تعذر تحميل مكتبة التمارين' : 'Failed to load exercise library',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }
    
    final filteredExercises = _exercises.where((ex) {
      if (_selectedCategory != 'all' && ex['category'] != _selectedCategory) {
        return false;
      }
      if (_selectedDifficulty != 'all' && ex['difficulty'] != _selectedDifficulty) {
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
                fillColor: AppColors.surface,
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
                          color: AppColors.textDisabled,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          isArabic
                              ? 'لم يتم العثور على تمارين'
                              : 'No exercises found',
                          style: const TextStyle(
                            fontSize: 18,
                            color: AppColors.textSecondary,
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
    final equipmentLabel = _formatEquip(exercise['equipmentList'] as List<dynamic>, isArabic);
    final musclesLabel = _formatMuscles(exercise['muscleList'] as List<dynamic>, isArabic);
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () => _showExerciseDetail(exercise, isArabic),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              exercise['thumbnail'],
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          
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
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
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
                      AppColors.textSecondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Icon(
            isArabic ? Icons.chevron_left : Icons.chevron_right,
            color: AppColors.textDisabled,
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
        return AppColors.textSecondary;
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
    final equipmentLabel = _formatEquip(exercise['equipmentList'] as List<dynamic>, isArabic);
    final musclesLabel = _formatMuscles(exercise['muscleList'] as List<dynamic>, isArabic);
    final instructions = isArabic
        ? (exercise['instructionsAr'] as List<dynamic>)
        : (exercise['instructions'] as List<dynamic>);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Video thumbnail with play button
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        exercise['thumbnail'],
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Container(
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
                      AppColors.textSecondary,
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
                          decoration: BoxDecoration(
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
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
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

  String _inferCategory(List<String> muscles) {
    if (muscles.contains('chest')) return 'chest';
    if (muscles.contains('back') || muscles.contains('lats') || muscles.contains('mid_back')) return 'back';
    if (muscles.contains('shoulders') || muscles.contains('front_delts') || muscles.contains('rear_delts') || muscles.contains('side_delts')) return 'shoulders';
    if (muscles.contains('biceps') || muscles.contains('triceps')) return 'arms';
    if (muscles.contains('quads') || muscles.contains('glutes') || muscles.contains('hamstrings') || muscles.contains('calves')) return 'legs';
    if (muscles.contains('core')) return 'core';
    if (muscles.contains('cardio')) return 'cardio';
    return 'all';
  }

  String _formatEquip(List<dynamic> equip, bool isArabic) {
    final labels = equip
        .map((e) => _catalogService.getEquipLabel(e.toString(), isArabic: isArabic) ?? e.toString())
        .toList();
    return labels.join(', ');
  }

  String _formatMuscles(List<dynamic> muscles, bool isArabic) {
    final labels = muscles
        .map((m) => _catalogService.getMuscleLabel(m.toString(), isArabic: isArabic) ?? m.toString())
        .toList();
    return labels.join(', ');
  }
}

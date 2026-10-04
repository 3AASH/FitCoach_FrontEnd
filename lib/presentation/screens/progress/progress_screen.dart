import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/config/demo_config.dart';
import '../../../data/repositories/progress_repository.dart';
import '../../../data/repositories/nutrition_repository.dart';
import '../../providers/language_provider.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_stat_info_card.dart';
import '../../../core/theme/app_palette.dart';
import '../../widgets/sheet_header.dart';

class ProgressEntry {
  final String id;
  final String? userId;
  final DateTime? date;
  final double? weight;
  final double? bodyFatPercentage;
  final double? chest;
  final double? waist;
  final double? hips;
  final double? bicepsLeft;
  final double? bicepsRight;
  final double? thighLeft;
  final double? thighRight;
  final String? frontPhotoUrl;
  final String? sidePhotoUrl;
  final String? backPhotoUrl;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProgressEntry({
    required this.id,
    this.userId,
    this.date,
    this.weight,
    this.bodyFatPercentage,
    this.chest,
    this.waist,
    this.hips,
    this.bicepsLeft,
    this.bicepsRight,
    this.thighLeft,
    this.thighRight,
    this.frontPhotoUrl,
    this.sidePhotoUrl,
    this.backPhotoUrl,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory ProgressEntry.fromJson(Map<String, dynamic> json) {
    return ProgressEntry(
      id: _stringValue(json['id'] ?? json['_id']),
      userId: _nullableStringValue(json['user_id'] ?? json['userId']),
      date: _dateValue(json['date']),
      weight: _doubleValue(json['weight']),
      bodyFatPercentage: _doubleValue(
        json['body_fat_percentage'] ?? json['bodyFatPercentage'],
      ),
      chest: _doubleValue(json['chest']),
      waist: _doubleValue(json['waist']),
      hips: _doubleValue(json['hips']),
      bicepsLeft: _doubleValue(json['biceps_left'] ?? json['bicepsLeft']),
      bicepsRight: _doubleValue(json['biceps_right'] ?? json['bicepsRight']),
      thighLeft: _doubleValue(json['thigh_left'] ?? json['thighLeft']),
      thighRight: _doubleValue(json['thigh_right'] ?? json['thighRight']),
      frontPhotoUrl: _nullableStringValue(
        json['front_photo_url'] ?? json['frontPhotoUrl'],
      ),
      sidePhotoUrl: _nullableStringValue(
        json['side_photo_url'] ?? json['sidePhotoUrl'],
      ),
      backPhotoUrl: _nullableStringValue(
        json['back_photo_url'] ?? json['backPhotoUrl'],
      ),
      notes: _nullableStringValue(json['notes']),
      createdAt: _dateValue(json['created_at'] ?? json['createdAt']),
      updatedAt: _dateValue(json['updated_at'] ?? json['updatedAt']),
    );
  }

  bool get hasPhotos =>
      frontPhotoUrl != null || sidePhotoUrl != null || backPhotoUrl != null;
}

String _stringValue(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

String? _nullableStringValue(dynamic value) {
  final text = _stringValue(value);
  return text.isEmpty ? null : text;
}

DateTime? _dateValue(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

double? _doubleValue(dynamic value) {
  if (value is int) return value.toDouble();
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim());
  return null;
}

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  String _selectedPeriod = 'week';
  bool _loading = false;
  String? _error;
  List<ProgressEntry> _entries = [];
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final Map<String, List<num>> _mockData = {
    'weight': [75.0, 74.8, 74.5, 74.3, 74.0, 73.8, 73.5],
    'workouts': [1, 1, 0, 1, 1, 0, 1],
    'calories': [1800, 2000, 1900, 2100, 1950, 2050, 1850],
  };

  @override
  void initState() {
    super.initState();
    if (!DemoConfig.isDemo) {
      _loadProgress();
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repository = ProgressRepository();
      final entries = await repository.getEntries();
      try {
        _nutritionHistory = await NutritionRepository().getNutritionHistory();
      } catch (_) {
        // Other progress remains available when nutrition access is unavailable.
      }
      if (!mounted) return;
      setState(() {
        _entries = entries.map(ProgressEntry.fromJson).toList()
          ..sort((a, b) {
            final aDate =
                a.date ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bDate =
                b.date ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bDate.compareTo(aDate);
          });
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  List<double> get _weightSeries {
    if (DemoConfig.isDemo) {
      return (_mockData['weight'] ?? const <num>[])
          .map((e) => e.toDouble())
          .toList();
    }

    if (_entries.isEmpty) {
      return const <double>[];
    }

    final sorted = [..._entries]..sort((a, b) {
        final aDate =
            a.date ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate =
            b.date ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return aDate.compareTo(bDate);
      });

    final series = sorted.map((e) => e.weight).whereType<double>().toList();

    return series;
  }

  List<int> get _workoutSeries {
    if (DemoConfig.isDemo) {
      return (_mockData['workouts'] ?? const <num>[])
          .map((e) => e.toInt())
          .toList();
    }

    final now = DateTime.now();
    final last7 = List<int>.filled(7, 0);
    for (final entry in _entries) {
      final date = entry.date;
      if (date == null) continue;
      final dayDiff =
          now.difference(DateTime(date.year, date.month, date.day)).inDays;
      if (dayDiff >= 0 && dayDiff < 7) {
        final index = 6 - dayDiff;
        last7[index] = 1;
      }
    }
    return last7;
  }

  List<double> get _calorieSeries {
    if (DemoConfig.isDemo) {
      return (_mockData['calories'] ?? const <num>[])
          .map((e) => e.toDouble())
          .toList();
    }

    final today = DateTime.now();
    final byDate = {for (final day in _nutritionHistory)
      day['date'].toString().substring(0, 10): double.tryParse(day['calories'].toString()) ?? 0.0};
    return List.generate(7, (index) {
      final date = DateTime(today.year, today.month, today.day - 6 + index);
      return byDate[date.toIso8601String().substring(0, 10)] ?? 0.0;
    });
  }

  List<Map<String, dynamic>> _nutritionHistory = [];

  int get _workoutCount {
    if (DemoConfig.isDemo) {
      return (_mockData['workouts'] ?? const <num>[])
          .where((e) => e.toInt() == 1)
          .length;
    }
    return _entries.length;
  }

  int get _streakDays {
    if (DemoConfig.isDemo) return 7;

    final days = _entries
        .map((e) => e.date)
        .whereType<DateTime>()
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet();

    if (days.isEmpty) return 0;

    var streak = 0;
    var cursor = DateTime.now();
    while (days.contains(DateTime(cursor.year, cursor.month, cursor.day))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return streak;
  }

  int? get _averageCalories {
    final series = _calorieSeries;
    if (series.isEmpty) return null;
    final total = series.reduce((a, b) => a + b);
    return (total / series.length).round();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.t('coach_progress_label')),
        actions: [
          IconButton(
            onPressed: DemoConfig.isDemo ? null : _loadProgress,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Period selector
                      _buildPeriodSelector(lang),

                      const SizedBox(height: 24),

                      // Summary cards
                      _buildSummaryCards(lang),

                      const SizedBox(height: 24),

                      // Weight chart
                      _buildWeightChart(lang),

                      const SizedBox(height: 24),

                      // Workout frequency
                      _buildWorkoutFrequency(lang),

                      const SizedBox(height: 24),

                      // Calories chart
                      _buildCaloriesChart(lang),

                      const SizedBox(height: 24),

                      // Detailed progress entries
                      _buildDetailedProgressEntries(lang),

                      const SizedBox(height: 24),

                      // Achievements
                      _buildAchievements(lang),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addProgress(lang),
        icon: const Icon(Icons.add),
        label: Text(lang.t('progress_log_progress')),
      ),
    );
  }

  Widget _buildPeriodSelector(LanguageProvider lang) {
    return Row(
      children: ['week', 'month', 'year'].map((period) {
        final isSelected = _selectedPeriod == period;
        return Padding(
          padding: const EdgeInsetsDirectional.only(end: 8),
          child: FilterChip(
            label: Text(_getPeriodLabel(period, lang)),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                _selectedPeriod = period;
              });
            },
            selectedColor: AppColors.primary.withValues(alpha: 0.2),
            checkmarkColor: AppColors.primary,
          ),
        );
      }).toList(),
    );
  }

  String _getPeriodLabel(String period, LanguageProvider lang) {
    final labels = {
      'week': lang.t('admin_period_week'),
      'month': lang.t('admin_period_month'),
      'year': lang.t('coach_earnings_period_year'),
    };
    return labels[period] ?? period;
  }

  Widget _buildSummaryCards(LanguageProvider lang) {
    final weights = _weightSeries;
    double? lossValue;
    if (weights.length >= 2) {
      lossValue = weights.first - weights.last;
    }
    return Row(
      children: [
        Expanded(
          child: CustomStatCard(
            title: lang.t('progress_lost'),
            value: lossValue == null
                ? '-1.5kg'
                : '${lossValue >= 0 ? '-' : '+'}${lossValue.abs().toStringAsFixed(1)}kg',
            icon: Icons.trending_down,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: CustomStatCard(
            title: lang.t('progress_workouts'),
            value: _workoutCount.toString(),
            icon: Icons.fitness_center,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: CustomStatCard(
            title: lang.t('progress_streak'),
            value: '${_streakDays}d',
            icon: Icons.local_fire_department,
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }

  Widget _buildWeightChart(LanguageProvider lang) {
    final weights = _weightSeries;
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang.t('weight'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: CustomPaint(
              painter: _LineChartPainter(
                data: weights,
                color: AppColors.primary,
              ),
              child: Container(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                lang.t('progress_start_weight', args: {
                  'value': weights.isNotEmpty
                      ? weights.first.toStringAsFixed(1)
                      : '--'
                }),
                style: TextStyle(
                  fontSize: 12,
                  color: context.palette.textSecondary,
                ),
              ),
              Text(
                lang.t('progress_current_weight', args: {
                  'value': weights.isNotEmpty
                      ? weights.last.toStringAsFixed(1)
                      : '--'
                }),
                style: TextStyle(
                  fontSize: 12,
                  color: context.palette.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutFrequency(LanguageProvider lang) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang.t('progress_workout_frequency'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final workouts = _workoutSeries;
              final hasWorkout =
                  index < workouts.length && workouts[index] == 1;
              final days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
              return Column(
                children: [
                  Text(
                    days[index],
                    style: TextStyle(
                      fontSize: 12,
                      color: context.palette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: hasWorkout ? AppColors.success : context.palette.surfaceVariant,
                      shape: BoxShape.circle,
                    ),
                    child: hasWorkout
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          )
                        : null,
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCaloriesChart(LanguageProvider lang) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang.t('progress_calories'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: (_calorieSeries.isEmpty
                      ? <double>[0, 0, 0, 0, 0, 0, 0]
                      : _calorieSeries)
                  .map<Widget>((cal) {
                const maxCal = 2500;
                final height = (cal / maxCal) * 150;
                return Container(
                  width: 30,
                  height: height,
                  decoration: const BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            lang.t('progress_average_calories',
                args: {'value': _averageCalories?.toString() ?? '--'}),
            style: TextStyle(
              fontSize: 12,
              color: context.palette.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedProgressEntries(LanguageProvider lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lang.t('progress_detailed_progress'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (_entries.isEmpty)
          CustomCard(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  lang.t('progress_no_progress_entries_yet'),
                  style: TextStyle(
                    color: context.palette.textSecondary,
                  ),
                ),
              ),
            ),
          )
        else
          ..._entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildProgressEntryCard(entry, lang),
              )),
      ],
    );
  }

  Widget _buildProgressEntryCard(ProgressEntry entry, LanguageProvider lang) {
    final chips = <Widget>[];
    void addChip(String label, String value) {
      chips.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$label: $value',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }

    if (entry.weight != null) {
      addChip(lang.t('weight'),
          '${entry.weight!.toStringAsFixed(1)} kg');
    }
    if (entry.bodyFatPercentage != null) {
      addChip(lang.t('progress_body_fat'),
          '${entry.bodyFatPercentage!.toStringAsFixed(1)}%');
    }
    if (entry.waist != null) {
      addChip(lang.t('progress_waist'),
          '${entry.waist!.toStringAsFixed(1)} cm');
    }
    if (entry.chest != null) {
      addChip(lang.t('progress_chest'),
          '${entry.chest!.toStringAsFixed(1)} cm');
    }
    if (entry.hips != null) {
      addChip(
          lang.t('progress_hips'), '${entry.hips!.toStringAsFixed(1)} cm');
    }
    if (entry.bicepsLeft != null || entry.bicepsRight != null) {
      final left = entry.bicepsLeft != null
          ? entry.bicepsLeft!.toStringAsFixed(1)
          : '--';
      final right = entry.bicepsRight != null
          ? entry.bicepsRight!.toStringAsFixed(1)
          : '--';
      addChip(lang.t('progress_arms'), 'L $left / R $right cm');
    }
    if (entry.thighLeft != null || entry.thighRight != null) {
      final left =
          entry.thighLeft != null ? entry.thighLeft!.toStringAsFixed(1) : '--';
      final right = entry.thighRight != null
          ? entry.thighRight!.toStringAsFixed(1)
          : '--';
      addChip(lang.t('progress_thighs'), 'L $left / R $right cm');
    }

    final photoUrls = [
      entry.frontPhotoUrl,
      entry.sidePhotoUrl,
      entry.backPhotoUrl
    ].whereType<String>().where((url) => url.isNotEmpty).toList();

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatEntryDate(entry.date ?? entry.createdAt),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: chips,
            ),
          ],
          if (entry.notes != null) ...[
            const SizedBox(height: 12),
            Text(
              entry.notes!,
              style: TextStyle(
                color: context.palette.textSecondary,
              ),
            ),
          ],
          if (photoUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 88,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photoUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final url = photoUrls[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      url,
                      width: 88,
                      height: 88,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 88,
                        height: 88,
                        color: context.palette.surfaceVariant,
                        child: const Icon(Icons.image_not_supported_outlined),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatEntryDate(DateTime? date) {
    if (date == null) return '--';
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildAchievements(LanguageProvider lang) {
    final workoutCount = _workoutCount;
    final streakDays = _streakDays;
    final hasFirstWeek = streakDays >= 7 || workoutCount >= 7;
    final hasTwentyWorkouts = workoutCount >= 20;

    final achievements = [
      {
        'icon': Icons.emoji_events,
        'title': lang.t('progress_first_week'),
        'description':
            lang.t('progress_completed_your_first_week'),
        'unlocked': DemoConfig.isDemo ? true : hasFirstWeek,
      },
      {
        'icon': Icons.local_fire_department,
        'title': lang.t('progress_7_day_streak'),
        'description': lang.t('progress_7_consecutive_days'),
        'unlocked': DemoConfig.isDemo ? true : streakDays >= 7,
      },
      {
        'icon': Icons.star,
        'title': lang.t('progress_20_workouts'),
        'description': lang.t('progress_completed_20_workouts'),
        'unlocked': DemoConfig.isDemo ? false : hasTwentyWorkouts,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lang.t('public_coach_profile_tab_achievements'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...achievements.map((achievement) {
          final unlocked = achievement['unlocked'] as bool;
          return CustomCard(
            margin: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: unlocked
                        ? AppColors.accent.withValues(alpha: 0.1)
                        : context.palette.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    achievement['icon'] as IconData,
                    color: unlocked ? AppColors.accent : context.palette.textDisabled,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        achievement['title'] as String,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: unlocked
                              ? context.palette.textPrimary
                              : context.palette.textDisabled,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        achievement['description'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (unlocked)
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  void _addProgress(LanguageProvider lang) {
    _weightController.clear();
    _notesController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SheetHeader(title: lang.t('progress_log_title')),
              const SizedBox(height: 24),
              TextField(
                controller: _weightController,
                decoration: InputDecoration(
                  labelText: lang.t('progress_weight_kg'),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: lang.t('coach_workout_editor_notes_label'),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _saveProgress(lang),
                  child: Text(lang.t('save')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProgress(LanguageProvider lang) async {
    final weight = double.tryParse(_weightController.text.trim());
    final notes = _notesController.text.trim();

    if (weight == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang.t('progress_enter_a_valid_weight'),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!DemoConfig.isDemo) {
      try {
        final repository = ProgressRepository();
        await repository.createEntry({
          'date': DateTime.now().toIso8601String().split('T').first,
          'weight': weight,
          'notes': notes.isEmpty ? null : notes,
        });
        await _loadProgress();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              lang.t('progress_failed_to_save_progress'),
            ),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          lang.t('progress_progress_saved'),
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }
}

// Simple line chart painter
class _LineChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _LineChartPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final minValue = data.reduce((a, b) => a < b ? a : b);
    final range = (maxValue - minValue) == 0 ? 1.0 : (maxValue - minValue);
    final denominator = data.length <= 1 ? 1 : (data.length - 1);

    for (var i = 0; i < data.length; i++) {
      final x = (i / denominator) * size.width;
      final y = size.height - ((data[i] - minValue) / range) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Draw points
    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (var i = 0; i < data.length; i++) {
      final x = (i / denominator) * size.width;
      final y = size.height - ((data[i] - minValue) / range) * size.height;
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter oldDelegate) => false;
}

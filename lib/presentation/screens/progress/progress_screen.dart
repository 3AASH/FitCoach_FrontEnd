import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/config/demo_config.dart';
import '../../../data/repositories/progress_repository.dart';
import '../../providers/language_provider.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_stat_info_card.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  String _selectedPeriod = 'week';
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _entries = [];
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
      if (!mounted) return;
      setState(() {
        _entries = entries;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
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

    final sorted = [..._entries]
      ..sort(
        (a, b) => (a['date'] ?? '')
            .toString()
            .compareTo((b['date'] ?? '').toString()),
      );

    final series = sorted
        .map((e) => (e['weight'] as num?)?.toDouble())
        .whereType<double>()
        .toList();

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
      final dateValue = entry['date']?.toString();
      if (dateValue == null || dateValue.isEmpty) continue;
      final date = DateTime.tryParse(dateValue);
      if (date == null) continue;
      final dayDiff = now.difference(DateTime(date.year, date.month, date.day)).inDays;
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

    final values = _entries
        .map((e) => e['calories'] ?? e['caloriesIntake'] ?? e['calories_intake'])
        .map((v) => v is num ? v.toDouble() : double.tryParse(v?.toString() ?? ''))
        .whereType<double>()
        .toList();

    if (values.length <= 7) return values;
    return values.sublist(values.length - 7);
  }

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
        .map((e) => DateTime.tryParse((e['date'] ?? '').toString()))
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
    final isArabic = context.watch<LanguageProvider>().isArabic;

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'التقدم' : 'Progress'),
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
                      _buildPeriodSelector(isArabic),

                      const SizedBox(height: 24),

                      // Summary cards
                      _buildSummaryCards(isArabic),

                      const SizedBox(height: 24),

                      // Weight chart
                      _buildWeightChart(isArabic),

                      const SizedBox(height: 24),

                      // Workout frequency
                      _buildWorkoutFrequency(isArabic),

                      const SizedBox(height: 24),

                      // Calories chart
                      _buildCaloriesChart(isArabic),

                      const SizedBox(height: 24),

                      // Achievements
                      _buildAchievements(isArabic),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addProgress(isArabic),
        icon: const Icon(Icons.add),
        label: Text(isArabic ? 'سجل تقدم' : 'Log Progress'),
      ),
    );
  }

  Widget _buildPeriodSelector(bool isArabic) {
    return Row(
      children: ['week', 'month', 'year'].map((period) {
        final isSelected = _selectedPeriod == period;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FilterChip(
            label: Text(_getPeriodLabel(period, isArabic)),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                _selectedPeriod = period;
              });
            },
            selectedColor: AppColors.primary.withOpacity(0.2),
            checkmarkColor: AppColors.primary,
          ),
        );
      }).toList(),
    );
  }

  String _getPeriodLabel(String period, bool isArabic) {
    final labels = {
      'week': isArabic ? 'أسبوع' : 'Week',
      'month': isArabic ? 'شهر' : 'Month',
      'year': isArabic ? 'سنة' : 'Year',
    };
    return labels[period] ?? period;
  }

  Widget _buildSummaryCards(bool isArabic) {
    final weights = _weightSeries;
    double? lossValue;
    if (weights.length >= 2) {
      lossValue = weights.first - weights.last;
    }
    return Row(
      children: [
        Expanded(
          child: CustomStatCard(
            title: isArabic ? 'فقدت' : 'Lost',
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
            title: isArabic ? 'تمارين' : 'Workouts',
            value: _workoutCount.toString(),
            icon: Icons.fitness_center,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: CustomStatCard(
            title: isArabic ? 'متتالي' : 'Streak',
            value: '${_streakDays}d',
            icon: Icons.local_fire_department,
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }

  Widget _buildWeightChart(bool isArabic) {
    final weights = _weightSeries;
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? 'الوزن' : 'Weight',
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
                isArabic
                    ? 'البداية: ${weights.isNotEmpty ? weights.first.toStringAsFixed(1) : '--'} كجم'
                    : 'Start: ${weights.isNotEmpty ? weights.first.toStringAsFixed(1) : '--'}kg',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                isArabic
                    ? 'الحالي: ${weights.isNotEmpty ? weights.last.toStringAsFixed(1) : '--'} كجم'
                    : 'Current: ${weights.isNotEmpty ? weights.last.toStringAsFixed(1) : '--'}kg',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutFrequency(bool isArabic) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? 'تكرار التمارين' : 'Workout Frequency',
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
              final hasWorkout = index < workouts.length && workouts[index] == 1;
              final days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
              return Column(
                children: [
                  Text(
                    days[index],
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: hasWorkout ? AppColors.success : AppColors.surface,
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

  Widget _buildCaloriesChart(bool isArabic) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? 'السعرات الحرارية' : 'Calories',
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
                  .map((cal) {
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
            isArabic
                ? 'متوسط: ${_averageCalories?.toString() ?? '--'} سعرة/يوم'
                : 'Average: ${_averageCalories?.toString() ?? '--'} cal/day',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievements(bool isArabic) {
    final workoutCount = _workoutCount;
    final streakDays = _streakDays;
    final hasFirstWeek = streakDays >= 7 || workoutCount >= 7;
    final hasTwentyWorkouts = workoutCount >= 20;

    final achievements = [
      {
        'icon': Icons.emoji_events,
        'title': isArabic ? 'أول أسبوع' : 'First Week',
        'description': isArabic ? 'أكملت أسبوعك الأول' : 'Completed your first week',
        'unlocked': DemoConfig.isDemo ? true : hasFirstWeek,
      },
      {
        'icon': Icons.local_fire_department,
        'title': isArabic ? 'متتالي 7 أيام' : '7 Day Streak',
        'description': isArabic ? '7 أيام متتالية' : '7 consecutive days',
        'unlocked': DemoConfig.isDemo ? true : streakDays >= 7,
      },
      {
        'icon': Icons.star,
        'title': isArabic ? '20 تمرين' : '20 Workouts',
        'description': isArabic ? 'أكملت 20 تمرين' : 'Completed 20 workouts',
        'unlocked': DemoConfig.isDemo ? false : hasTwentyWorkouts,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isArabic ? 'الإنجازات' : 'Achievements',
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
                        ? AppColors.accent.withOpacity(0.1)
                        : AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    achievement['icon'] as IconData,
                    color: unlocked ? AppColors.accent : AppColors.textDisabled,
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
                              ? AppColors.textPrimary
                              : AppColors.textDisabled,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        achievement['description'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
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
        }).toList(),
      ],
    );
  }

  void _addProgress(bool isArabic) {
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
              Text(
                isArabic ? 'سجل تقدمك' : 'Log Your Progress',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _weightController,
                decoration: InputDecoration(
                  labelText: isArabic ? 'الوزن (كجم)' : 'Weight (kg)',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: isArabic ? 'ملاحظات' : 'Notes',
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _saveProgress(isArabic),
                  child: Text(isArabic ? 'حفظ' : 'Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProgress(bool isArabic) async {
    final weight = double.tryParse(_weightController.text.trim());
    final notes = _notesController.text.trim();

    if (weight == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic ? 'أدخل وزنًا صالحًا' : 'Enter a valid weight',
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
              isArabic ? 'فشل حفظ التقدم' : 'Failed to save progress',
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
          isArabic ? 'تم حفظ التقدم' : 'Progress saved',
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

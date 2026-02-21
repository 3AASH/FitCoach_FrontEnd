import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../data/models/workout_plan.dart';
import '../../providers/language_provider.dart';
import '../../providers/workout_provider.dart';

class WorkoutExerciseSessionScreen extends StatefulWidget {
  final List<Exercise> exercises;
  final int startIndex;
  final void Function(Exercise exercise) onShowSubstitute;

  const WorkoutExerciseSessionScreen({
    super.key,
    required this.exercises,
    required this.startIndex,
    required this.onShowSubstitute,
  });

  @override
  State<WorkoutExerciseSessionScreen> createState() => _WorkoutExerciseSessionScreenState();
}

class _WorkoutExerciseSessionScreenState extends State<WorkoutExerciseSessionScreen> {
  late int _currentIndex;
  int _currentSet = 0;
  int _timerSeconds = 0;
  bool _isResting = false;
  bool _isTimerRunning = false;
  Timer? _timer;
  final Map<String, List<_LoggedSet>> _loggedSets = {};
  final TextEditingController _repsController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.startIndex;
    _setupForExercise();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _setupForExercise() {
    final exercise = widget.exercises[_currentIndex];
    _currentSet = _loggedSets[exercise.id]?.length ?? 0;
    _timerSeconds = _parseRestSeconds(exercise.restTime);
    _isResting = false;
    _isTimerRunning = false;
    _repsController.text = _defaultReps(exercise.reps).toString();
    _weightController.text = '';
  }

  int _defaultReps(String reps) {
    final match = RegExp(r'(\\d+)').firstMatch(reps);
    if (match == null) return 10;
    return int.tryParse(match.group(0) ?? '') ?? 10;
  }

  int _parseRestSeconds(String? restTime) {
    if (restTime == null) return 60;
    final match = RegExp(r'(\\d+)').firstMatch(restTime);
    if (match == null) return 60;
    final value = int.tryParse(match.group(0) ?? '') ?? 60;
    if (restTime.contains('min')) {
      return value * 60;
    }
    return value;
  }

  void _startRestTimer() {
    _timer?.cancel();
    _isResting = true;
    _isTimerRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds <= 1) {
        timer.cancel();
        setState(() {
          _timerSeconds = _parseRestSeconds(currentExercise.restTime);
          _isTimerRunning = false;
          _isResting = false;
        });
      } else {
        setState(() {
          _timerSeconds -= 1;
        });
      }
    });
  }

  void _toggleTimer() {
    if (!_isResting) return;
    setState(() {
      _isTimerRunning = !_isTimerRunning;
    });
    if (_isTimerRunning) {
      _startRestTimer();
    } else {
      _timer?.cancel();
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _timerSeconds = _parseRestSeconds(currentExercise.restTime);
      _isTimerRunning = false;
      _isResting = true;
    });
  }

  void _logSet() {
    final provider = context.read<WorkoutProvider>();
    final exercise = currentExercise;
    final reps = int.tryParse(_repsController.text) ?? _defaultReps(exercise.reps);
    final weight = double.tryParse(_weightController.text);

    final logged = _loggedSets.putIfAbsent(exercise.id, () => []);
    if (logged.length >= exercise.sets) return;

    logged.add(_LoggedSet(reps: reps, weight: weight, time: DateTime.now()));
    setState(() {
      _currentSet = logged.length;
    });

    if (logged.length >= exercise.sets) {
      provider.completeExercise(exercise.id);
    } else {
      _timerSeconds = _parseRestSeconds(exercise.restTime);
      _startRestTimer();
    }
  }

  void _nextExercise() {
    if (_currentIndex < widget.exercises.length - 1) {
      setState(() {
        _currentIndex += 1;
        _setupForExercise();
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  Exercise get currentExercise => widget.exercises[_currentIndex];

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final isArabic = lang.isArabic;
    final provider = context.watch<WorkoutProvider>();
    final completed = provider.isExerciseCompleted(currentExercise.id);
    final logged = _loggedSets[currentExercise.id] ?? [];
    final progress = currentExercise.sets == 0
        ? 0.0
        : (logged.length / currentExercise.sets);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/placeholders/splash_onboarding/workout_onboarding.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.35)),
          ),
          SafeArea(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  color: AppColors.primary.withValues(alpha: 0.85),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(
                              isArabic ? Icons.arrow_forward : Icons.arrow_back,
                              color: Colors.white,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isArabic ? currentExercise.nameAr : currentExercise.nameEn,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  lang.t('workouts_set_of', args: {
                                    'current': '${_currentSet + 1}',
                                    'total': '${currentExercise.sets}',
                                  }),
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _SessionCard(
                          child: Row(
                            children: [
                              Expanded(
                                child: _MetricItem(
                                  value: '${currentExercise.sets}',
                                  label: lang.t('sets'),
                                ),
                              ),
                              Expanded(
                                child: _MetricItem(
                                  value: currentExercise.reps,
                                  label: lang.t('reps'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _SessionCard(
                          child: Container(
                            height: 160,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.play_circle, size: 48, color: AppColors.textSecondary),
                                  const SizedBox(height: 8),
                                  Text(
                                    lang.t('workouts_exercise_demo'),
                                    style: const TextStyle(color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (_isResting) ...[
                          const SizedBox(height: 12),
                          _SessionCard(
                            color: const Color(0xFFEAF2FF),
                            child: Column(
                              children: [
                                const Icon(Icons.timer, size: 32, color: Color(0xFF246BFD)),
                                const SizedBox(height: 8),
                                Text(
                                  _formatTime(_timerSeconds),
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF246BFD),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  lang.t('workouts_rest_time'),
                                  style: const TextStyle(color: Color(0xFF246BFD)),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: _toggleTimer,
                                      icon: Icon(_isTimerRunning ? Icons.pause : Icons.play_arrow),
                                      label: Text(_isTimerRunning ? lang.t('pause') : lang.t('resume')),
                                    ),
                                    const SizedBox(width: 12),
                                    OutlinedButton.icon(
                                      onPressed: _resetTimer,
                                      icon: const Icon(Icons.refresh),
                                      label: Text(lang.t('reset')),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => widget.onShowSubstitute(currentExercise),
                            icon: const Icon(Icons.warning_amber_rounded, color: Color(0xFFB91C1C)),
                            label: Text(lang.t('workouts_report_injury')),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFB91C1C),
                              backgroundColor: const Color(0xFFFFF1F2),
                              side: const BorderSide(color: Color(0xFFFCA5A5)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (!completed)
                          _SessionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang.t('workouts_log_set'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _NumberField(
                                        label: lang.t('reps'),
                                        controller: _repsController,
                                        minValue: 1,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _NumberField(
                                        label: '${lang.t('weight')} (${lang.t('kg')})',
                                        controller: _weightController,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _logSet,
                                    child: Text(lang.t('workouts_log_set_button')),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (logged.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _SessionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang.t('workouts_completed_sets'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...logged.asMap().entries.map((entry) {
                                  final idx = entry.key + 1;
                                  final set = entry.value;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('${lang.t('set')} $idx'),
                                        Text('${set.reps} ${lang.t('reps')}'
                                            '${set.weight == null ? '' : ' \u2022 ${set.weight} ${lang.t('kg')}'}'),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ],
                        if (completed) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _nextExercise,
                              child: Text(
                                _currentIndex < widget.exercises.length - 1
                                    ? lang.t('workouts_next_exercise')
                                    : lang.t('workouts_finish_workout'),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final Widget child;
  final Color? color;

  const _SessionCard({
    required this.child,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String value;
  final String label;

  const _MetricItem({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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

class _NumberField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final int minValue;

  const _NumberField({
    required this.label,
    required this.controller,
    this.minValue = 0,
  });

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  int _currentValue() {
    final value = int.tryParse(widget.controller.text);
    return value ?? widget.minValue;
  }

  void _applyDelta(int delta) {
    final current = _currentValue();
    var next = current + delta;
    if (next < widget.minValue) {
      next = widget.minValue;
    }
    widget.controller.text = next.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () => _applyDelta(-1),
                icon: const Icon(Icons.remove),
                visualDensity: VisualDensity.compact,
              ),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _applyDelta(1),
                icon: const Icon(Icons.add),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoggedSet {
  final int reps;
  final double? weight;
  final DateTime time;

  _LoggedSet({
    required this.reps,
    required this.weight,
    required this.time,
  });
}

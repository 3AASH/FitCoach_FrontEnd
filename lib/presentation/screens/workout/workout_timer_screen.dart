import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../providers/language_provider.dart';
import '../../widgets/custom_button.dart';
import 'dart:async';

class WorkoutTimerScreen extends StatefulWidget {
  final String exerciseName;
  final int sets;
  final int reps;
  final int restSeconds;
  
  const WorkoutTimerScreen({
    super.key,
    required this.exerciseName,
    this.sets = 3,
    this.reps = 12,
    this.restSeconds = 60,
  });

  @override
  State<WorkoutTimerScreen> createState() => _WorkoutTimerScreenState();
}

class _WorkoutTimerScreenState extends State<WorkoutTimerScreen> {
  int _currentSet = 1;
  int _remainingSeconds = 0;
  int _restSeconds = 0;
  bool _isResting = false;
  bool _isPaused = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _restSeconds = widget.restSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exerciseName),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _confirmExit(context, languageProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: _currentSet / widget.sets,
            backgroundColor: AppColors.surface,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Set counter
                  Text(
                    languageProvider.t('workouts_set_of', args: {
                      'current': _currentSet.toString(),
                      'total': widget.sets.toString(),
                    }),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Timer circle
                  Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isResting
                          ? AppColors.warning.withValues(alpha: 0.1)
                          : AppColors.success.withValues(alpha: 0.1),
                      border: Border.all(
                        color: _isResting ? AppColors.warning : AppColors.success,
                        width: 8,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isResting) ...[
                            const Icon(
                              Icons.timer,
                              size: 60,
                              color: AppColors.warning,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _formatTime(_remainingSeconds),
                              style: const TextStyle(
                                fontSize: 64,
                                fontWeight: FontWeight.bold,
                                color: AppColors.warning,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              languageProvider.t('workouts_rest_time'),
                              style: const TextStyle(
                                fontSize: 20,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ] else ...[
                            const Icon(
                              Icons.fitness_center,
                              size: 60,
                              color: AppColors.success,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '${widget.reps}',
                              style: const TextStyle(
                                fontSize: 64,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              languageProvider.t('reps'),
                              style: const TextStyle(
                                fontSize: 20,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Status message
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _isResting
                          ? AppColors.warning.withValues(alpha: 0.1)
                          : AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusMessage(languageProvider),
                      style: TextStyle(
                        fontSize: 16,
                        color: _isResting ? AppColors.warning : AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Control buttons
                  if (_isResting) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Pause/Resume
                        SizedBox(
                          width: 140,
                          child: CustomButton(
                            text: _isPaused
                                ? languageProvider.t('resume')
                                : languageProvider.t('pause'),
                            onPressed: _togglePause,
                            variant: ButtonVariant.secondary,
                            size: ButtonSize.large,
                            icon: _isPaused ? Icons.play_arrow : Icons.pause,
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // Skip rest
                        SizedBox(
                          width: 140,
                          child: CustomButton(
                            text: languageProvider.t('skip'),
                            onPressed: _skipRest,
                            variant: ButtonVariant.secondary,
                            size: ButtonSize.large,
                            icon: Icons.skip_next,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: languageProvider.t('complete_set'),
                        onPressed: _completeSet,
                        variant: ButtonVariant.primary,
                        size: ButtonSize.large,
                        icon: Icons.check,
                        fullWidth: true,
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  // Secondary actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: () => _adjustRest(context, languageProvider),
                        icon: const Icon(Icons.settings),
                        label: Text(languageProvider.t('workouts_adjust_rest')),
                      ),
                      const SizedBox(width: 24),
                      TextButton.icon(
                        onPressed: () => _skipExercise(context, languageProvider),
                        icon: const Icon(Icons.skip_next),
                        label: Text(languageProvider.t('workouts_skip_exercise')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
  
  String _getStatusMessage(LanguageProvider lang) {
    if (_isResting) {
      if (_isPaused) {
        return lang.t('workouts_rest_paused');
      }
      return lang.t('workouts_rest_motivation');
    } else {
      return lang.t('workouts_complete_reps', args: {'reps': widget.reps.toString()});
    }
  }
  
  void _completeSet() {
    if (_currentSet < widget.sets) {
      // Start rest timer
      setState(() {
        _isResting = true;
        _remainingSeconds = _restSeconds;
        _isPaused = false;
      });
      _startRestTimer();
    } else {
      // Workout complete
      _showWorkoutComplete();
    }
  }
  
  void _startRestTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            _timer?.cancel();
            _isResting = false;
            _currentSet++;
          }
        });
      }
    });
  }
  
  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }
  
  void _skipRest() {
    _timer?.cancel();
    setState(() {
      _isResting = false;
      _currentSet++;
      _isPaused = false;
    });
  }
  
  void _adjustRest(BuildContext context, LanguageProvider lang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.t('workouts_adjust_rest_time')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [30, 45, 60, 90, 120].map((seconds) {
            return ListTile(
              title: Text(lang.t('workouts_seconds_label', args: {'seconds': '$seconds'})),
              onTap: () {
                Navigator.pop(context);
                _setRestDuration(seconds);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _setRestDuration(int seconds) {
    setState(() {
      _restSeconds = seconds;
      if (_isResting) {
        _remainingSeconds = seconds;
        _isPaused = false;
      }
    });

    if (_isResting) {
      _startRestTimer();
    }
  }
  
  void _skipExercise(BuildContext context, LanguageProvider lang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.t('workouts_skip_exercise_confirm_title')),
        content: Text(lang.t('workouts_skip_exercise_confirm_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.t('cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true); // Return to workout screen
            },
            child: Text(lang.t('skip')),
          ),
        ],
      ),
    );
  }
  
  void _confirmExit(BuildContext context, LanguageProvider lang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.t('workouts_end_workout_confirm_title')),
        content: Text(lang.t('workouts_end_workout_confirm_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.t('cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(lang.t('workouts_end')),
          ),
        ],
      ),
    );
  }
  
  void _showWorkoutComplete() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final lang = context.read<LanguageProvider>();
        return AlertDialog(
          title: Column(
            children: [
              const Icon(
                Icons.celebration,
                size: 60,
                color: AppColors.success,
              ),
              const SizedBox(height: 16),
              Text(
                lang.t('workouts_great_job'),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Text(
            lang.t('workouts_completed_all_sets'),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, true);
              },
              child: Text(lang.t('done')),
            ),
          ],
        );
      },
    );
  }
}

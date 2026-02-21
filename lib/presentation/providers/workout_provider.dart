import 'package:flutter/material.dart';
import '../../core/config/demo_config.dart';
import '../../core/config/demo_mode.dart';
import '../../data/demo/repositories/demo_workout_repository.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/models/workout_plan.dart';
import '../../data/services/exercise_catalog_service.dart';

class WorkoutProvider extends ChangeNotifier {
  final WorkoutRepository _repository;
  final DemoWorkoutRepository _demoRepository;
  final DemoModeConfig _demoConfig;
  final ExerciseCatalogService _catalogService = ExerciseCatalogService.instance;

  WorkoutPlan? _activePlan;
  List<Exercise> _exerciseLibrary = [];
  bool _isLoading = false;
  String? _error;
  int? _currentDayIndex;
  final Map<String, bool> _completedExercises = {};

  WorkoutProvider(
    this._repository, {
    DemoWorkoutRepository? demoRepository,
    DemoModeConfig? demoConfig,
  })  : _demoRepository = demoRepository ?? DemoWorkoutRepository(),
        _demoConfig = demoConfig ?? const DemoModeConfig();

  WorkoutPlan? get activePlan => _activePlan;
  List<Exercise> get exerciseLibrary => _exerciseLibrary;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int? get currentDayIndex => _currentDayIndex;

  WorkoutDay? get currentDay {
    if (_activePlan == null || _currentDayIndex == null) return null;
    if (_activePlan!.days == null || _currentDayIndex! >= _activePlan!.days!.length) return null;
    return _activePlan!.days![_currentDayIndex!];
  }

  Future<void> loadActivePlan() async {
    if (_demoConfig.isDemo) {
      _activePlan = await _demoRepository.getActivePlan(
        userId: DemoConfig.demoUserId,
      );
      await _ensureCatalogLoaded();
      if (_activePlan != null) {
        _activePlan = _applyCatalogToPlan(_activePlan!);
      }
      _currentDayIndex = 0;
      _error = null;
      _isLoading = false;
      notifyListeners();
      return;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final plan = await _repository.getActivePlan();
      await _ensureCatalogLoaded();
      _activePlan = plan == null ? null : _applyCatalogToPlan(plan);
    } catch (e) {
      _error = e.toString();
      _activePlan = null;
      _currentDayIndex = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadExerciseLibrary() async {
    if (_demoConfig.isDemo) {
      _exerciseLibrary = await _demoRepository.getExerciseLibrary();
      await _ensureCatalogLoaded();
      _exerciseLibrary = _exerciseLibrary.map(_applyCatalogToExercise).toList();
      _error = null;
      _isLoading = false;
      notifyListeners();
      return;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final exercisesData = await _repository.getExerciseLibrary();
      _exerciseLibrary = exercisesData.map<Exercise>((e) => Exercise.fromJson(e)).toList();
      await _ensureCatalogLoaded();
      _exerciseLibrary = _exerciseLibrary.map(_applyCatalogToExercise).toList();
    } catch (e) {
      _error = e.toString();
      _exerciseLibrary = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  void setCurrentDay(int dayIndex) {
    _currentDayIndex = dayIndex;
    notifyListeners();
  }

  Future<bool> completeExercise(String exerciseId) async {
    if (_demoConfig.isDemo) {
      _completedExercises[exerciseId] = true;
      notifyListeners();
      return true;
    }
    try {
      await _repository.markExerciseComplete(exerciseId);
    } catch (e) {
      _error = e.toString();
    }
    _completedExercises[exerciseId] = true;
    notifyListeners();
    return true;
  }

  Future<List<Exercise>> getExerciseAlternatives(
    String exerciseId,
    List<String> userInjuries,
  ) async {
    if (_demoConfig.isDemo) {
      final alternatives = await _demoRepository.getExerciseAlternatives(exerciseId);
      await _ensureCatalogLoaded();
      return alternatives.map(_applyCatalogToExercise).toList();
    }
    _isLoading = true;
    notifyListeners();

    try {
      final alternatives = await _repository.getExerciseAlternatives(
        exerciseId,
        userInjuries,
      );
      await _ensureCatalogLoaded();
      _isLoading = false;
      notifyListeners();
      return alternatives.map(_applyCatalogToExercise).toList();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  Future<void> _ensureCatalogLoaded() async {
    try {
      await _catalogService.load();
    } catch (_) {
      // Ignore catalog load errors; app can still function.
    }
  }

  WorkoutPlan _applyCatalogToPlan(WorkoutPlan plan) {
    final days = plan.days;
    if (days == null) return plan;
    final updatedDays = days.map((day) {
      final updatedExercises = day.exercises.map(_applyCatalogToExercise).toList();
      return WorkoutDay(
        id: day.id,
        dayName: day.dayName,
        dayNameAr: day.dayNameAr,
        dayNumber: day.dayNumber,
        exercises: updatedExercises,
        notes: day.notes,
      );
    }).toList();

    return WorkoutPlan(
      id: plan.id,
      userId: plan.userId,
      coachId: plan.coachId,
      name: plan.name,
      nameAr: plan.nameAr,
      description: plan.description,
      descriptionAr: plan.descriptionAr,
      planData: plan.planData,
      notes: plan.notes,
      days: updatedDays,
      startDate: plan.startDate,
      endDate: plan.endDate,
      isActive: plan.isActive,
      customizedByCoach: plan.customizedByCoach,
      createdAt: plan.createdAt,
      updatedAt: plan.updatedAt,
    );
  }

  Exercise _applyCatalogToExercise(Exercise exercise) {
    final catalog = _catalogService.catalog;
    if (catalog == null) return exercise;

    ExerciseCatalogItem? item = catalog.byId[exercise.id];
    item ??= _findCatalogByName(catalog, exercise.nameEn, exercise.nameAr);
    if (item == null) return exercise;

    final equipment = (exercise.equipment == null || exercise.equipment!.trim().isEmpty)
        ? item.equip.join(', ')
        : exercise.equipment;
    final muscleGroup = (exercise.muscleGroup == null || exercise.muscleGroup!.trim().isEmpty)
        ? item.muscles.join(', ')
        : exercise.muscleGroup;

    return exercise.copyWith(
      name: exercise.name.isNotEmpty ? exercise.name : item.nameEn,
      nameAr: exercise.nameAr.isNotEmpty ? exercise.nameAr : item.nameAr,
      nameEn: exercise.nameEn.isNotEmpty ? exercise.nameEn : item.nameEn,
      equipment: equipment,
      muscleGroup: muscleGroup,
      videoUrl: exercise.videoUrl ?? item.videoUrl,
      thumbnailUrl: exercise.thumbnailUrl ?? item.thumbnailUrl,
      instructions: exercise.instructions?.isNotEmpty == true
          ? exercise.instructions
          : item.instructionsEn,
      instructionsEn: exercise.instructionsEn?.isNotEmpty == true
          ? exercise.instructionsEn
          : item.instructionsEn,
      instructionsAr: exercise.instructionsAr?.isNotEmpty == true
          ? exercise.instructionsAr
          : item.instructionsAr,
    );
  }

  ExerciseCatalogItem? _findCatalogByName(
    ExerciseCatalog catalog,
    String nameEn,
    String nameAr,
  ) {
    String normalize(String input) => input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\u0600-\u06FF]'), '');
    final en = normalize(nameEn);
    final ar = normalize(nameAr);
    for (final ex in catalog.exercises) {
      final exEn = normalize(ex.nameEn);
      final exAr = normalize(ex.nameAr);
      if ((en.isNotEmpty && exEn == en) || (ar.isNotEmpty && exAr == ar)) {
        return ex;
      }
    }
    return null;
  }

  Future<bool> substituteExercise(
    String originalExerciseId,
    String newExerciseId,
  ) async {
    if (_demoConfig.isDemo) {
      _error = null;
      notifyListeners();
      return true;
    }
    try {
      await _repository.substituteExercise(
        originalExerciseId,
        newExerciseId,
      );
      await loadActivePlan();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> logWorkout(Map<String, dynamic> workoutData) async {
    if (_demoConfig.isDemo) {
      return true;
    }
    try {
      await _repository.logWorkout(workoutData);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  bool isExerciseCompleted(String exerciseId) {
    return _completedExercises[exerciseId] ?? false;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

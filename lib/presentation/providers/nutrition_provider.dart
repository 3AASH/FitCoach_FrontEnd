import 'package:flutter/material.dart';
import '../../core/config/demo_config.dart';
import '../../data/demo/demo_data.dart';
import '../../data/repositories/nutrition_repository.dart';
import '../../data/models/nutrition_plan.dart';

class NutritionProvider extends ChangeNotifier {
  DateTime? _selectedDate;
  DateTime get selectedDate => _selectedDate ?? DateTime.now();
  String dateKey(DateTime date) => date.toIso8601String().substring(0, 10);
  Future<void> selectDate(DateTime date) async {
    _selectedDate = dateKey(date) == dateKey(DateTime.now()) ? null : date;
    await loadActivePlan();
  }
  final NutritionRepository _repository;

  NutritionPlan? _activePlan;
  bool _isLoading = false;
  String? _error;
  DateTime? _trialStartDate;
  int _trialDaysRemaining = 0;
  bool _hasTrialExpired = false;
  NutritionTodayProgress? _todayProgress;
  NutritionAccessStatus? _accessStatus;
  NutritionIntakeRequirements? _intakeRequirements;

  NutritionProvider(this._repository);

  NutritionPlan? get activePlan => _activePlan;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get trialStartDate => _trialStartDate;
  int get trialDaysRemaining => _trialDaysRemaining;
  bool get hasTrialExpired => _hasTrialExpired;
  NutritionTodayProgress? get todayProgress => _todayProgress;
  NutritionAccessStatus? get accessStatus => _accessStatus;
  NutritionIntakeRequirements? get intakeRequirements => _intakeRequirements;
  bool get requiresFirstWorkout => _accessStatus?.requiresFirstWorkout == true;
  bool get hasNutritionAccess => _accessStatus?.hasAccess ?? false;
  bool get requiresNutritionIntake =>
      _intakeRequirements != null && !_intakeRequirements!.isComplete;
  String? accessMessage({bool isArabic = false}) {
    if (_accessStatus == null) return null;
    return isArabic
        ? (_accessStatus!.messageAr ?? _accessStatus!.message)
        : (_accessStatus!.message ?? _accessStatus!.messageAr);
  }

  Map<String, dynamic> get macroTargets {
    final targets = _activePlan?.macroTargets;
    final progressTarget = _todayProgress?.targetCalories ?? 0;
    return {
      'calories': (progressTarget > 0
          ? progressTarget
          : (targets?['calories'] ?? 2000)),
      'protein': targets?['protein'] ?? 150,
      'carbs': targets?['carbs'] ?? 250,
      'fat': targets?['fat'] ?? 70,
    };
  }

  List<DayMealPlan> get dayPlans => _activePlan?.days ?? const <DayMealPlan>[];

  int getTodayDayNumber() {
    final days = dayPlans;
    if (days.isEmpty) return 1;

    final start = _activePlan?.startDate;
    if (start == null) {
      // Fall back to the first day.
      return days.first.dayNumber;
    }

    final diff = DateTime.utc(selectedDate.year, selectedDate.month, selectedDate.day)
        .difference(DateTime.utc(start.year, start.month, start.day))
        .inDays;
    final normalized = (diff % days.length) + 1;
    return normalized;
  }

  DayMealPlan? getDayPlanByNumber(int dayNumber) {
    try {
      return dayPlans.firstWhere((d) => d.dayNumber == dayNumber);
    } catch (_) {
      return null;
    }
  }

  List<Meal> getMealsForDayNumber(int dayNumber) {
    final plan = getDayPlanByNumber(dayNumber);
    if (plan != null) return plan.meals;
    return _activePlan?.meals ?? const <Meal>[];
  }

  List<Meal> getMealsForToday() {
    return getMealsForDayNumber(getTodayDayNumber());
  }

  List<Map<String, dynamic>> get dailyMealPlan {
    final meals = getMealsForToday();
    return meals
        .map((meal) => {
              'id': meal.id,
              'type': meal.type,
              'completed': meal.completed,
              'foods': meal.foods,
            })
        .toList();
  }

  Map<String, dynamic> getCurrentMacros() {
    if (_todayProgress != null) {
      return {
        'calories': _todayProgress!.consumedCalories,
        'protein': _todayProgress!.consumedProtein,
        'carbs': _todayProgress!.consumedCarbs,
        'fat': _todayProgress!.consumedFats,
      };
    }
    final meals = getMealsForToday().where((meal) => meal.completed);
    double calories = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;

    for (final meal in meals) {
      for (final food in meal.foods) {
        calories += food.calories;
        protein += food.macros.protein;
        carbs += food.macros.carbs;
        fat += food.macros.fats;
      }
    }

    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }

  Map<String, dynamic> getRemainingMacros() {
    final current = getCurrentMacros();
    final targets = macroTargets;
    return {
      'calories': (targets['calories'] ?? 0) - (current['calories'] ?? 0),
      'protein': (targets['protein'] ?? 0) - (current['protein'] ?? 0),
      'carbs': (targets['carbs'] ?? 0) - (current['carbs'] ?? 0),
      'fat': (targets['fat'] ?? 0) - (current['fat'] ?? 0),
    };
  }

  Future<void> loadActivePlan() async {
    if (DemoConfig.isDemo) {
      _activePlan = DemoData.nutritionPlan(userId: DemoConfig.demoUserId);
      _todayProgress = _activePlan?.todayProgress;
      _accessStatus = NutritionAccessStatus(
        hasAccess: true,
        tier: 'demo',
        daysRemaining: 4,
        isTrialActive: true,
      );
      _error = null;
      _isLoading = false;
      notifyListeners();
      return;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await refreshAccessStatus(notify: false);
      if (_accessStatus?.hasAccess == false) {
        _activePlan = null;
        _todayProgress = null;
        _intakeRequirements = null;
        _isLoading = false;
        notifyListeners();
        return;
      }

      final plan = _selectedDate == null
          ? await _repository.getActivePlan()
          : await _repository.getPlanForDate(_selectedDate!);
      _activePlan = plan;
      _todayProgress = plan?.todayProgress;
    } catch (e) {
      _error = e.toString();
      _activePlan = null;
      _todayProgress = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<NutritionAccessStatus?> refreshAccessStatus({
    bool notify = true,
  }) async {
    if (DemoConfig.isDemo) {
      _accessStatus = NutritionAccessStatus(
        hasAccess: true,
        tier: 'demo',
        daysRemaining: 4,
        isTrialActive: true,
      );
      _applyAccessTrialState();
      if (notify) notifyListeners();
      return _accessStatus;
    }

    try {
      _accessStatus = await _repository.getAccessStatus();
      _applyAccessTrialState();
      _error = null;
      if (notify) notifyListeners();
      return _accessStatus;
    } catch (e) {
      _error = e.toString();
      if (notify) notifyListeners();
      return null;
    }
  }

  /// [planType] defaults to null, which lets the server pick from the user's
  /// subscription tier. Passing 'starter' unconditionally (as every caller used
  /// to) asked premium clients the starter question set, while /nutrition/generate
  /// derives the plan type from the tier and then rejects the answers with a 422
  /// for the professional-only fields the form never showed.
  Future<NutritionIntakeRequirements?> loadIntakeRequirements({
    String? planType,
  }) async {
    if (DemoConfig.isDemo) {
      _intakeRequirements = NutritionIntakeRequirements(
        planType: planType ?? 'starter',
        missingFields: const [],
        questions: const [],
        access: _accessStatus,
      );
      notifyListeners();
      return _intakeRequirements;
    }

    try {
      _intakeRequirements =
          await _repository.getIntakeRequirements(planType: planType);
      if (_intakeRequirements?.access != null) {
        _accessStatus = _intakeRequirements!.access;
        _applyAccessTrialState();
      }
      _error = null;
      notifyListeners();
      return _intakeRequirements;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> checkTrialStatus() async {
    if (DemoConfig.isDemo) {
      _trialStartDate = DateTime.now().subtract(const Duration(days: 3));
      _trialDaysRemaining = 4;
      _hasTrialExpired = false;
      notifyListeners();
      return;
    }
    try {
      final trialData = await _repository.getTrialStatus();
      _trialStartDate = trialData['startDate'] != null
          ? DateTime.parse(trialData['startDate'] as String)
          : null;
      _trialDaysRemaining =
          _asInt(trialData['daysRemaining'] ?? trialData['days_remaining']) ??
              0;
      _hasTrialExpired =
          trialData['hasAccess'] == false && _trialDaysRemaining <= 0;

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  bool canAccessNutrition(String subscriptionTier) {
    if (DemoConfig.isDemo) return true;
    if (_accessStatus != null) return _accessStatus!.hasAccess;
    final tier = subscriptionTier.trim().toLowerCase();
    return tier == 'premium' || tier == 'smart premium';
  }

  bool checkFreemiumAccess(String tier, DateTime trialStartDate) {
    if (tier.toLowerCase().contains('premium')) return true;
    if (_accessStatus != null) return _accessStatus!.hasAccess;
    return getRemainingTrialDays(trialStartDate) > 0;
  }

  int getRemainingTrialDays(DateTime trialStartDate) {
    if (_accessStatus != null || _hasTrialExpired) {
      return _trialDaysRemaining > 0 ? _trialDaysRemaining : 0;
    }

    final trialStartDay = DateTime(
      trialStartDate.year,
      trialStartDate.month,
      trialStartDate.day,
    );
    final today = DateTime.now();
    final elapsedDays = DateTime(today.year, today.month, today.day)
        .difference(trialStartDay)
        .inDays;
    return (14 - elapsedDays).clamp(0, 14);
  }

  /// Meals the client may swap this one for. Returns an empty list rather than
  /// throwing, so a failed lookup shows "no alternatives" instead of breaking
  /// the screen the client was reading.
  Future<List<MealAlternative>> getMealAlternatives(String mealId) async {
    if (DemoConfig.isDemo) return const <MealAlternative>[];
    try {
      return await _repository.getMealAlternatives(mealId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return const <MealAlternative>[];
    }
  }

  /// Applies a swap and reloads the plan so every screen shows the new meal
  /// and the day's totals move with it.
  Future<bool> swapMeal(String mealId, String variantId) async {
    if (DemoConfig.isDemo) return true;
    try {
      await _repository.swapMeal(mealId, variantId);
      await loadActivePlan();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> logMeal(String mealId, Map<String, dynamic> data) async {
    if (DemoConfig.isDemo) {
      return true;
    }
    try {
      final meal = _activePlan?.meals?.where((item) => item.id == mealId).firstOrNull;
      final logDate = meal?.scheduledDate ?? selectedDate;
      if (meal?.canLog == false || dateKey(logDate).compareTo(dateKey(DateTime.now())) > 0) {
        return false;
      }
      final response = await _repository.logMeal(mealId, {
        ...data,
        'logDate': dateKey(logDate),
        'timezoneOffsetMinutes': DateTime.now().timeZoneOffset.inMinutes,
      });
      final progressMap =
          _asMap(response['todayProgress'] ?? response['today_progress']);
      if (progressMap != null && dateKey(logDate) == dateKey(selectedDate)) {
        _todayProgress = NutritionTodayProgress.fromJson(progressMap);
      }
      _markMealCompletedLocal(mealId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getNutritionHistory() async {
    if (DemoConfig.isDemo) {
      return [
        {
          'date': DateTime.now()
              .subtract(const Duration(days: 1))
              .toIso8601String(),
          'calories': 2150,
          'protein': 140,
          'carbs': 240,
          'fat': 65,
        },
        {
          'date': DateTime.now()
              .subtract(const Duration(days: 2))
              .toIso8601String(),
          'calories': 2300,
          'protein': 155,
          'carbs': 255,
          'fat': 70,
        },
      ];
    }
    _isLoading = true;
    notifyListeners();

    try {
      final history = await _repository.getNutritionHistory();
      _isLoading = false;
      notifyListeners();
      return history;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  Future<void> markMealComplete(String mealId) async {
    await logMeal(mealId, {'completed': true});
  }

  int getMealProgress() {
    if (_activePlan == null ||
        _activePlan!.meals == null ||
        _activePlan!.meals!.isEmpty) {
      return 0;
    }
    final total = _activePlan!.meals!.length;
    final completed =
        _activePlan!.meals!.where((m) => m.completed == true).length;
    return ((completed / total) * 100).round();
  }

  Meal? getMealByType(String mealType) {
    if (_activePlan == null || _activePlan!.meals == null) return null;
    try {
      return _activePlan!.meals!.firstWhere((m) => m.type == mealType);
    } catch (_) {
      return null;
    }
  }

  Future<void> addCustomFood(String mealType, FoodItem food) async {
    if (_activePlan == null || _activePlan!.meals == null) return;
    try {
      final meal = _activePlan!.meals!.firstWhere((m) => m.type == mealType);
      meal.foods.add(food);
      notifyListeners();
    } catch (_) {
      // Meal not found.
    }
  }

  int getCalorieProgress() {
    if (_todayProgress != null) {
      return _todayProgress!.progressPercent.clamp(0, 100).round();
    }
    if (_activePlan == null || _activePlan!.meals == null) return 0;
    final current = getCurrentMacros()['calories'] as num? ?? 0;
    final target = macroTargets['calories'] as num? ?? 0;
    if (target == 0) return 0;
    final percent = (current / target) * 100;
    return percent.clamp(0, 100).round();
  }

  bool isOverMacroLimit(String macro) {
    if (_activePlan == null || _activePlan!.meals == null) return false;
    double total = 0;
    for (final meal in _activePlan!.meals!) {
      for (final food in meal.foods) {
        if (macro == 'calories') {
          total += food.calories;
        } else if (macro == 'protein') {
          total += food.macros.protein;
        } else if (macro == 'carbs') {
          total += food.macros.carbs;
        } else if (macro == 'fat' || macro == 'fats') {
          total += food.macros.fats;
        }
      }
    }
    final target = macroTargets[macro] ?? 0;
    return total > target;
  }

  Future<void> resetDailyTracking() async {
    if (_activePlan == null || _activePlan!.meals == null) return;
    for (final meal in _activePlan!.meals!) {
      meal.completed = false;
    }
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _applyAccessTrialState() {
    if (_accessStatus == null) return;
    _trialStartDate = _accessStatus!.trialStartedAt;
    _trialDaysRemaining = _accessStatus!.daysRemaining ?? 0;
    _hasTrialExpired =
        !_accessStatus!.hasAccess && !_accessStatus!.isTrialActive;
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  void _markMealCompletedLocal(String mealId) {
    if (_activePlan == null || _activePlan!.meals == null) return;
    try {
      final meal = _activePlan!.meals!.firstWhere((m) => m.id == mealId);
      meal.completed = true;
    } catch (_) {
      // Ignore.
    }
  }
}

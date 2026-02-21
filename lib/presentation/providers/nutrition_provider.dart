import 'package:flutter/material.dart';
import '../../core/config/demo_config.dart';
import '../../data/demo/demo_data.dart';
import '../../data/repositories/nutrition_repository.dart';
import '../../data/models/nutrition_plan.dart';

class NutritionProvider extends ChangeNotifier {
  final NutritionRepository _repository;

  NutritionPlan? _activePlan;
  bool _isLoading = false;
  String? _error;
  DateTime? _trialStartDate;
  int _trialDaysRemaining = 0;
  bool _hasTrialExpired = false;

  static const int freemiumTrialDays = 14;

  NutritionProvider(this._repository);

  NutritionPlan? get activePlan => _activePlan;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get trialStartDate => _trialStartDate;
  int get trialDaysRemaining => _trialDaysRemaining;
  bool get hasTrialExpired => _hasTrialExpired;

  Map<String, dynamic> get macroTargets {
    final targets = _activePlan?.macroTargets;
    return {
      'calories': targets?['calories'] ?? 2000,
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

    final diff = DateTime.now().difference(DateTime(start.year, start.month, start.day)).inDays;
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
    final meals = _activePlan?.meals ?? [];
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
    final meals = _activePlan?.meals ?? [];
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
      _activePlan = plan;
    } catch (e) {
      _error = e.toString();
      _activePlan = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> checkTrialStatus() async {
    if (DemoConfig.isDemo) {
      _trialStartDate = DateTime.now().subtract(const Duration(days: 3));
      _trialDaysRemaining = freemiumTrialDays - 3;
      _hasTrialExpired = false;
      notifyListeners();
      return;
    }
    try {
      final trialData = await _repository.getTrialStatus();
      _trialStartDate = trialData['startDate'] != null
          ? DateTime.parse(trialData['startDate'] as String)
          : null;

      if (_trialStartDate != null) {
        final daysSinceStart = DateTime.now().difference(_trialStartDate!).inDays;
        _trialDaysRemaining = freemiumTrialDays - daysSinceStart;
        _hasTrialExpired = _trialDaysRemaining <= 0;
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  bool canAccessNutrition(String subscriptionTier) {
    return subscriptionTier == 'Premium' || subscriptionTier == 'Smart Premium';
  }

  bool checkFreemiumAccess(String tier, DateTime trialStartDate) {
    if (tier.toLowerCase().contains('premium')) return true;
    final daysSinceStart = DateTime.now().difference(trialStartDate).inDays;
    return daysSinceStart < freemiumTrialDays;
  }

  int getRemainingTrialDays(DateTime trialStartDate) {
    final daysSinceStart = DateTime.now().difference(trialStartDate).inDays;
    final remaining = freemiumTrialDays - daysSinceStart;
    return remaining > 0 ? remaining : 0;
  }

  Future<bool> logMeal(String mealId, Map<String, dynamic> data) async {
    if (DemoConfig.isDemo) {
      return true;
    }
    try {
      await _repository.logMeal(mealId, data);
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
          'date': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          'calories': 2150,
          'protein': 140,
          'carbs': 240,
          'fat': 65,
        },
        {
          'date': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
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
    if (_activePlan == null || _activePlan!.meals == null) return;
    try {
      final meal = _activePlan!.meals!.firstWhere((m) => m.id == mealId);
      meal.completed = true;
      notifyListeners();
    } catch (_) {
      // Meal not found, ignore.
    }
  }

  int getMealProgress() {
    if (_activePlan == null || _activePlan!.meals == null || _activePlan!.meals!.isEmpty) return 0;
    final total = _activePlan!.meals!.length;
    final completed = _activePlan!.meals!.where((m) => m.completed == true).length;
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
    if (_activePlan == null || _activePlan!.meals == null) return 0;
    double totalCalories = 0;
    for (final meal in _activePlan!.meals!) {
      for (final food in meal.foods) {
        totalCalories += food.calories;
      }
    }
    final target = macroTargets['calories'] ?? 0;
    if (target == 0) return 0;
    final percent = (totalCalories / target) * 100;
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
}

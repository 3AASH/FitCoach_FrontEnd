import 'dart:convert';

import 'package:flutter/foundation.dart';

class NutritionPlan {
  /// Returns a flat list of all meals across all days, or null if days is null.
  List<Meal>? get meals {
    if (days == null) return null;
    return days!.expand((day) => day.meals).toList();
  }

  final String id;
  final String userId;
  final String? coachId;
  final String? name;
  final String? description;
  final List<DayMealPlan>? days;
  final Map<String, dynamic>? macros;
  final Map<String, dynamic>? mealPlan;
  final int? dailyCalories;
  final String? notes;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final bool? customizedByCoach;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, int>? macroTargets;
  final NutritionTodayProgress? todayProgress;

  NutritionPlan({
    required this.id,
    required this.userId,
    this.coachId,
    this.name,
    this.description,
    this.days,
    this.macros,
    this.mealPlan,
    this.dailyCalories,
    this.notes,
    this.startDate,
    this.endDate,
    this.isActive = true,
    this.customizedByCoach,
    required this.createdAt,
    this.updatedAt,
    this.macroTargets,
    this.todayProgress,
  });

  factory NutritionPlan.fromJson(Map<String, dynamic> json) {
    final createdAtValue = json['created_at'] ?? json['createdAt'];
    final mealPlanMap = _asMap(json['meal_plan'] ?? json['mealPlan']);
    final mealPlanDays =
        _asList(mealPlanMap?['days']) ?? _asList(mealPlanMap?['mealPlanDays']);
    final flatMeals = _asList(mealPlanMap?['meals']) ?? _asList(json['meals']);
    final daysSource = _asList(json['days']) ??
        mealPlanDays ??
        _asList(json['meal_plan']) ??
        _asList(json['mealPlan']);
    final parsedDays = daysSource
            ?.asMap()
            .entries
            .map((entry) => DayMealPlan.fromJson(
                  _asMap(entry.value) ?? const {},
                  index: entry.key,
                ))
            .toList() ??
        (flatMeals != null
            ? <DayMealPlan>[
                DayMealPlan.fromJson(
                  {
                    'dayNumber': 1,
                    'dayName': 'Day 1',
                    'meals': flatMeals,
                  },
                  index: 0,
                ),
              ]
            : null);
    return NutritionPlan(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? json['userId'] ?? '').toString(),
      coachId: asString(json['coach_id'] ?? json['coachId']),
      name: asString(json['name']),
      description: asString(json['description']),
      days: parsedDays,
      macros: _asMap(json['macros']),
      mealPlan: mealPlanMap,
      dailyCalories: _asInt(json['daily_calories'] ?? json['dailyCalories']),
      notes: asString(json['notes']),
      startDate: _asDateTime(json['start_date'] ?? json['startDate']),
      endDate: _asDateTime(json['end_date'] ?? json['endDate']),
      isActive: asBool(json['is_active'] ?? json['isActive']) ?? true,
      customizedByCoach:
          asBool(json['customized_by_coach'] ?? json['customizedByCoach']),
      createdAt: _asDateTime(createdAtValue) ?? DateTime.now(),
      updatedAt: _asDateTime(json['updated_at'] ?? json['updatedAt']),
      macroTargets: (json['macroTargets'] ?? json['macro_targets']) != null
          ? (_asMap(json['macroTargets'] ?? json['macro_targets']) ?? const {})
              .map((k, v) => MapEntry(k, _asInt(v) ?? 0))
          : null,
      todayProgress: NutritionTodayProgress.fromJson(
        _asMap(json['todayProgress'] ?? json['today_progress']) ??
            <String, dynamic>{
              'targetCalories': json['targetCalories'],
              'consumedCalories': json['consumedCalories'],
              'remainingCalories': json['remainingCalories'],
              'progressPercent': json['progressPercent'],
              'consumedProtein': json['consumedProtein'],
              'consumedCarbs': json['consumedCarbs'],
              'consumedFats': json['consumedFats'],
            },
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'coach_id': coachId,
      'userId': userId,
      'coachId': coachId,
      'name': name,
      'description': description,
      'days': days?.map((day) => day.toJson()).toList(),
      'macros': macros,
      'meal_plan': mealPlan,
      'daily_calories': dailyCalories,
      'dailyCalories': dailyCalories,
      'notes': notes,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'is_active': isActive,
      'customized_by_coach': customizedByCoach,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'macroTargets': macroTargets,
      'macro_targets': macroTargets,
      'todayProgress': todayProgress?.toJson(),
      'today_progress': todayProgress?.toJson(),
    };
  }
}

class NutritionTodayProgress {
  final double targetCalories;
  final double consumedCalories;
  final double remainingCalories;
  final double progressPercent;
  final double consumedProtein;
  final double consumedCarbs;
  final double consumedFats;

  NutritionTodayProgress({
    required this.targetCalories,
    required this.consumedCalories,
    required this.remainingCalories,
    required this.progressPercent,
    required this.consumedProtein,
    required this.consumedCarbs,
    required this.consumedFats,
  });

  factory NutritionTodayProgress.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return NutritionTodayProgress.empty();
    return NutritionTodayProgress(
      targetCalories:
          _asDouble(json['targetCalories'] ?? json['target_calories']),
      consumedCalories:
          _asDouble(json['consumedCalories'] ?? json['consumed_calories']),
      remainingCalories:
          _asDouble(json['remainingCalories'] ?? json['remaining_calories']),
      progressPercent:
          _asDouble(json['progressPercent'] ?? json['progress_percent']),
      consumedProtein:
          _asDouble(json['consumedProtein'] ?? json['consumed_protein']),
      consumedCarbs: _asDouble(json['consumedCarbs'] ?? json['consumed_carbs']),
      consumedFats: _asDouble(json['consumedFats'] ?? json['consumed_fats']),
    );
  }

  factory NutritionTodayProgress.empty() => NutritionTodayProgress(
        targetCalories: 0,
        consumedCalories: 0,
        remainingCalories: 0,
        progressPercent: 0,
        consumedProtein: 0,
        consumedCarbs: 0,
        consumedFats: 0,
      );

  Map<String, dynamic> toJson() => {
        'targetCalories': targetCalories,
        'consumedCalories': consumedCalories,
        'remainingCalories': remainingCalories,
        'progressPercent': progressPercent,
        'consumedProtein': consumedProtein,
        'consumedCarbs': consumedCarbs,
        'consumedFats': consumedFats,
      };
}

class NutritionAccessStatus {
  final bool hasAccess;
  final bool requiresFirstWorkout;
  final String? tier;
  final String? reason;
  final String? message;
  final String? messageAr;
  final Map<String, dynamic>? action;
  final DateTime? trialStartedAt;
  final DateTime? trialExpiresAt;
  final int? daysRemaining;
  final bool isTrialActive;

  NutritionAccessStatus({
    required this.hasAccess,
    this.requiresFirstWorkout = false,
    this.tier,
    this.reason,
    this.message,
    this.messageAr,
    this.action,
    this.trialStartedAt,
    this.trialExpiresAt,
    this.daysRemaining,
    this.isTrialActive = false,
  });

  factory NutritionAccessStatus.fromJson(Map<String, dynamic> json) {
    final source = _asMap(json['access']) ?? json;
    return NutritionAccessStatus(
      hasAccess: asBool(source['hasAccess'] ?? source['has_access']) ?? false,
      requiresFirstWorkout: asBool(source['requiresFirstWorkout'] ??
              source['requires_first_workout']) ??
          false,
      tier: asString(source['tier']),
      reason: asString(source['reason']),
      message: asString(source['message']),
      messageAr: asString(source['messageAr'] ?? source['message_ar']),
      action: _asMap(source['action']),
      trialStartedAt:
          _asDateTime(source['trialStartedAt'] ?? source['trial_started_at']),
      trialExpiresAt:
          _asDateTime(source['trialExpiresAt'] ?? source['trial_expires_at']),
      daysRemaining:
          _asInt(source['daysRemaining'] ?? source['days_remaining']),
      isTrialActive:
          asBool(source['isTrialActive'] ?? source['is_trial_active']) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'hasAccess': hasAccess,
        'requiresFirstWorkout': requiresFirstWorkout,
        'tier': tier,
        'reason': reason,
        'message': message,
        'messageAr': messageAr,
        'action': action,
        'trialStartedAt': trialStartedAt?.toIso8601String(),
        'trialExpiresAt': trialExpiresAt?.toIso8601String(),
        'daysRemaining': daysRemaining,
        'isTrialActive': isTrialActive,
      };
}

class NutritionIntakeRequirements {
  final String planType;
  final List<String> missingFields;
  final List<Map<String, dynamic>> questions;
  final Map<String, dynamic>? context;
  final NutritionAccessStatus? access;

  NutritionIntakeRequirements({
    required this.planType,
    required this.missingFields,
    required this.questions,
    this.context,
    this.access,
  });

  bool get isComplete => missingFields.isEmpty;

  factory NutritionIntakeRequirements.fromJson(Map<String, dynamic> json) {
    final missing = _asList(json['missingFields'] ?? json['missing_fields']) ??
        const <dynamic>[];
    final rawQuestions = _asList(json['questions']) ?? const <dynamic>[];
    return NutritionIntakeRequirements(
      planType: asString(json['planType'] ?? json['plan_type']) ?? 'starter',
      missingFields: missing.map((item) => item.toString()).toList(),
      questions: rawQuestions
          .map((item) => _asMap(item) ?? <String, dynamic>{'field': '$item'})
          .toList(),
      context: _asMap(json['context']),
      access: json['access'] != null
          ? NutritionAccessStatus.fromJson(_asMap(json['access']) ?? const {})
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'planType': planType,
        'missingFields': missingFields,
        'questions': questions,
        'context': context,
        'access': access?.toJson(),
      };
}

class DayMealPlan {
  final String id;
  final String dayName;
  final int dayNumber;
  final List<Meal> meals;
  final String? notes;

  DayMealPlan({
    required this.id,
    required this.dayName,
    required this.dayNumber,
    required this.meals,
    this.notes,
  });

  factory DayMealPlan.fromJson(
    Map<String, dynamic> json, {
    int index = 0,
  }) {
    final dayNumber =
        _asInt(json['dayNumber'] ?? json['day_number'] ?? json['day']) ??
            (index + 1);
    return DayMealPlan(
      id: asString(json['id']) ?? '',
      dayName: resolveNutritionDayName(json, index, dayNumber: dayNumber),
      dayNumber: dayNumber,
      meals: (_asList(json['meals']) ??
              _asList(_asMap(json['mealPlan'])?['meals']) ??
              const [])
          .map((meal) => Meal.fromJson(_asMap(meal) ?? const {}))
          .toList(),
      notes: asString(json['notes']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dayName': dayName,
      'dayNumber': dayNumber,
      'meals': meals.map((meal) => meal.toJson()).toList(),
      'notes': notes,
    };
  }
}

class Meal {
  final String id;
  final String name;
  final String nameAr;
  final String nameEn;
  final String type; // breakfast, lunch, dinner, snack
  final String time;
  final List<FoodItem> foods;
  final MacroTargets macros;
  final int calories;
  final String? instructions;
  final String? instructionsAr;
  final String? instructionsEn;
  final String? imageUrl;
  final int order;
  bool completed;

  Meal({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.nameEn,
    required this.type,
    required this.time,
    required this.foods,
    required this.macros,
    required this.calories,
    this.instructions,
    this.instructionsAr,
    this.instructionsEn,
    this.imageUrl,
    this.order = 0,
    this.completed = false,
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    final fallbackName = resolveMealName(json);
    return Meal(
      id: asString(json['id']) ?? '',
      name: fallbackName,
      nameAr: asString(json['nameAr'] ?? json['name_ar']) ?? fallbackName,
      nameEn: asString(json['nameEn'] ?? json['name_en']) ?? fallbackName,
      type: asString(json['type']) ?? '',
      time: asString(json['time']) ?? '',
      foods: (_asList(json['foods']) ?? const [])
          .map((food) => FoodItem.fromJson(_asMap(food) ?? const {}))
          .toList(),
      macros: MacroTargets.fromJson(_asMap(json['macros']) ?? const {}),
      calories: _asInt(json['calories']) ?? 0,
      instructions: asString(json['instructions']),
      instructionsAr: asString(json['instructionsAr']),
      instructionsEn: asString(json['instructionsEn']),
      imageUrl: asString(json['imageUrl']),
      order: _asInt(json['order']) ?? 0,
      completed: asBool(json['completed'] ??
              json['isCompleted'] ??
              json['is_completed']) ??
          false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nameAr': nameAr,
      'nameEn': nameEn,
      'type': type,
      'time': time,
      'foods': foods.map((food) => food.toJson()).toList(),
      'macros': macros.toJson(),
      'calories': calories,
      'instructions': instructions,
      'instructionsAr': instructionsAr,
      'instructionsEn': instructionsEn,
      'imageUrl': imageUrl,
      'order': order,
      'completed': completed,
    };
  }
}

String? asString(dynamic v) {
  return readString(v);
}

String? readString(dynamic v) {
  if (v == null) return null;
  if (v is String) return v;
  if (v is List || v is Map) return jsonEncode(v);
  if (v is num || v is bool) return v.toString();
  if (kDebugMode) {
    debugPrint(
        '[NutritionPlan] Unexpected type for asString: ${v.runtimeType}');
  }
  return v.toString();
}

String resolveMealName(Map<String, dynamic> json) {
  final prioritized = [
    readString(json['name']),
    readString(json['mealName']),
    readString(json['meal_name']),
    readString(json['title']),
    readString(json['nameEn']),
    readString(json['name_en']),
    readString(json['nameAr']),
    readString(json['name_ar']),
  ];
  for (final candidate in prioritized) {
    final value = candidate?.trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
  }
  return 'Meal';
}

String resolveNutritionDayName(
  Map<String, dynamic> json,
  int index, {
  int? dayNumber,
}) {
  final prioritized = [
    readString(json['dayName']),
    readString(json['day_name']),
    readString(json['name']),
    readString(json['title']),
  ];
  for (final candidate in prioritized) {
    final value = candidate?.trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
  }
  final resolvedNumber = dayNumber ??
      _asInt(json['dayNumber'] ?? json['day_number'] ?? json['day']) ??
      (index + 1);
  return 'Day $resolvedNumber';
}

bool? asBool(dynamic v) {
  if (v == null) return null;
  if (v is bool) return v;
  if (v is int) return v == 1;
  if (v is String) {
    final normalized = v.trim().toLowerCase();
    return ['true', '1', 'yes'].contains(normalized);
  }
  if (kDebugMode) {
    debugPrint('[NutritionPlan] Unexpected type for asBool: ${v.runtimeType}');
  }
  return null;
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  if (value != null && kDebugMode) {
    debugPrint('[NutritionPlan] Unexpected map type: ${value.runtimeType}');
  }
  return null;
}

List<dynamic>? _asList(dynamic value) {
  if (value is List) return value;
  if (value != null && kDebugMode) {
    debugPrint('[NutritionPlan] Unexpected list type: ${value.runtimeType}');
  }
  return null;
}

DateTime? _asDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  if (value != null && kDebugMode) {
    debugPrint(
        '[NutritionPlan] Unexpected datetime type: ${value.runtimeType}');
  }
  return null;
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  if (value != null && kDebugMode) {
    debugPrint('[NutritionPlan] Unexpected int type: ${value.runtimeType}');
  }
  return null;
}

double _asDouble(dynamic value, {double fallback = 0}) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  if (value != null && kDebugMode) {
    debugPrint('[NutritionPlan] Unexpected double type: ${value.runtimeType}');
  }
  return fallback;
}

class FoodItem {
  final String id;
  final String name;
  final String nameAr;
  final String nameEn;
  final double quantity;
  final String unit;
  final MacroTargets macros;
  final int calories;

  FoodItem({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.nameEn,
    required this.quantity,
    required this.unit,
    required this.macros,
    required this.calories,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: asString(json['id']) ?? '',
      name: asString(json['name']) ?? '',
      nameAr: asString(json['nameAr'] ?? json['name_ar']) ??
          asString(json['name']) ??
          '',
      nameEn: asString(json['nameEn'] ?? json['name_en']) ??
          asString(json['name']) ??
          '',
      quantity: _asDouble(json['quantity']),
      unit: asString(json['unit']) ?? '',
      macros: MacroTargets.fromJson(_asMap(json['macros']) ?? const {}),
      calories: _asInt(json['calories']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nameAr': nameAr,
      'nameEn': nameEn,
      'quantity': quantity,
      'unit': unit,
      'macros': macros.toJson(),
      'calories': calories,
    };
  }
}

class MacroTargets {
  final double protein;
  final double carbs;
  final double fats;

  MacroTargets({
    required this.protein,
    required this.carbs,
    required this.fats,
  });

  factory MacroTargets.fromJson(Map<String, dynamic> json) {
    return MacroTargets(
      protein: _asDouble(json['protein']),
      carbs: _asDouble(json['carbs']),
      fats: _asDouble(json['fats']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
    };
  }
}

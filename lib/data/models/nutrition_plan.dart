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
  });
  
    factory NutritionPlan.fromJson(Map<String, dynamic> json) {
    final createdAtValue = json['created_at'] ?? json['createdAt'];
    return NutritionPlan(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? json['userId'] ?? '').toString(),
      coachId: json['coach_id'] as String? ?? json['coachId'] as String?,
      name: json['name'] as String?,
      description: json['description'] as String?,
      days: json['days'] != null
        ? (json['days'] as List)
          .map((day) => DayMealPlan.fromJson(day as Map<String, dynamic>))
          .toList()
        : null,
      macros: json['macros'] as Map<String, dynamic>?,
      mealPlan: json['meal_plan'] as Map<String, dynamic>?,
      dailyCalories: json['daily_calories'] as int? ?? json['dailyCalories'] as int?,
      notes: json['notes'] as String?,
      startDate: json['start_date'] != null || json['startDate'] != null
        ? DateTime.parse(json['start_date'] ?? json['startDate'] as String)
        : null,
      endDate: json['end_date'] != null || json['endDate'] != null
        ? DateTime.parse(json['end_date'] ?? json['endDate'] as String)
        : null,
      isActive: json['is_active'] as bool? ?? true,
      customizedByCoach: json['customized_by_coach'] as bool?,
      createdAt: createdAtValue != null
        ? DateTime.parse(createdAtValue as String)
        : DateTime.now(),
      updatedAt: json['updated_at'] != null || json['updatedAt'] != null
        ? DateTime.parse(json['updated_at'] ?? json['updatedAt'] as String)
        : null,
      macroTargets: (json['macroTargets'] ?? json['macro_targets']) != null
        ? ((json['macroTargets'] ?? json['macro_targets']) as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, v is int ? v : int.tryParse(v.toString()) ?? 0))
        : null,
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
    };
  }
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
  
  factory DayMealPlan.fromJson(Map<String, dynamic> json) {
    return DayMealPlan(
      id: json['id'] as String,
      dayName: json['dayName'] as String,
      dayNumber: json['dayNumber'] as int,
      meals: (json['meals'] as List)
          .map((meal) => Meal.fromJson(meal as Map<String, dynamic>))
          .toList(),
      notes: json['notes'] as String?,
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
    return Meal(
      id: json['id'] as String,
      name: json['name'] as String,
      nameAr: json['nameAr'] as String,
      nameEn: json['nameEn'] as String,
      type: json['type'] as String,
      time: json['time'] as String,
      foods: (json['foods'] as List)
          .map((food) => FoodItem.fromJson(food as Map<String, dynamic>))
          .toList(),
      macros: MacroTargets.fromJson(json['macros'] as Map<String, dynamic>),
      calories: json['calories'] as int,
      instructions: json['instructions'] as String?,
      instructionsAr: json['instructionsAr'] as String?,
      instructionsEn: json['instructionsEn'] as String?,
      imageUrl: json['imageUrl'] as String?,
      order: json['order'] as int? ?? 0,
      completed: json['completed'] as bool? ?? false,
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
      id: json['id'] as String,
      name: json['name'] as String,
      nameAr: json['nameAr'] as String,
      nameEn: json['nameEn'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String,
      macros: MacroTargets.fromJson(json['macros'] as Map<String, dynamic>),
      calories: json['calories'] as int,
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
      protein: (json['protein'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      fats: (json['fats'] as num).toDouble(),
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

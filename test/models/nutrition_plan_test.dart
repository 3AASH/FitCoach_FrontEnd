import 'package:flutter_test/flutter_test.dart';
import 'package:fitapp/data/models/nutrition_plan.dart';
// Ensure that the file 'nutrition_plan.dart' exists and defines the NutritionPlan class.
// File macro_targets.dart not found, import commented out
// import '../../lib/data/models/macro_targets.dart';
// Make sure macro_targets.dart defines and exports MacroTargets class.
// File food_item.dart not found, import commented out
// import '../../lib/data/models/food_item.dart';
// File meal.dart not found, import commented out
// import '../../lib/data/models/meal.dart';
// File day_meal_plan.dart not found, import commented out
// import '../../lib/data/models/day_meal_plan.dart';

void main() {
  group('NutritionPlan Model Tests', () {
    test('should create NutritionPlan from JSON', () {
      final json = {
        'id': 'plan_123',
        'userId': 'user_456',
        'coachId': 'coach_789',
        'name': 'Weight Loss Plan',
        'description': 'High protein, low carb',
        'days': [
          {
            'id': 'day_1',
            'dayName': 'Monday',
            'dayNumber': 1,
            'meals': [
              {
                'id': 'meal_1',
                'name': 'Breakfast',
                'nameAr': 'فطور',
                'nameEn': 'Breakfast',
                'type': 'breakfast',
                'time': '07:00',
                'foods': [
                  {
                    'id': 'food_1',
                    'name': 'Eggs',
                    'nameAr': 'بيض',
                    'nameEn': 'Eggs',
                    'quantity': 3.0,
                    'unit': 'pieces',
                    'macros': {
                      'protein': 18.0,
                      'carbs': 1.5,
                      'fats': 15.0,
                    },
                    'calories': 210,
                  }
                ],
                'macros': {
                  'protein': 18.0,
                  'carbs': 1.5,
                  'fats': 15.0,
                },
                'calories': 210,
                'order': 1,
              }
            ],
          }
        ],
        'macros': {
          'protein': 150.0,
          'carbs': 100.0,
          'fats': 50.0,
        },
        'dailyCalories': 1800,
        'startDate': '2024-01-01T00:00:00.000Z',
        'endDate': '2024-03-31T00:00:00.000Z',
        'isActive': true,
        'createdAt': '2024-01-01T00:00:00.000Z',
        'updatedAt': '2024-01-01T00:00:00.000Z',
      };

      final plan = NutritionPlan.fromJson(json);

      expect(plan.id, 'plan_123');
      expect(plan.userId, 'user_456');
      expect(plan.coachId, 'coach_789');
      expect(plan.name, 'Weight Loss Plan');
      expect(plan.description, 'High protein, low carb');
      expect(plan.days?.length, 1);
      expect(plan.dailyCalories, 1800);
      expect(plan.macros?['protein'], 150.0);
      expect(plan.macros?['carbs'], 100.0);
      expect(plan.macros?['fats'], 50.0);
      expect(plan.isActive, true);
    });

    test('should convert NutritionPlan to JSON', () {
      final macros = MacroTargets(protein: 120.0, carbs: 150.0, fats: 60.0);
      
      final foodMacros = MacroTargets(protein: 30.0, carbs: 40.0, fats: 15.0);
      final food = FoodItem(
        id: 'food_1',
        name: 'Chicken',
        nameAr: 'دجاج',
        nameEn: 'Chicken',
        quantity: 200.0,
        unit: 'g',
        macros: foodMacros,
        calories: 330,
      );

      final meal = Meal(
        id: 'meal_1',
        name: 'Lunch',
        nameAr: 'غداء',
        nameEn: 'Lunch',
        type: 'lunch',
        time: '13:00',
        foods: [food],
        macros: foodMacros,
        calories: 330,
      );

      final day = DayMealPlan(
        id: 'day_1',
        dayName: 'Monday',
        dayNumber: 1,
        meals: [meal],
      );

      final plan = NutritionPlan(
        id: 'plan_1',
        userId: 'user_1',
        coachId: 'coach_1',
        name: 'Test Plan',
        days: [day],
        macros: macros.toJson(),
        dailyCalories: 2000,
        startDate: DateTime(2024, 1, 1),
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final json = plan.toJson();

      expect(json['id'], 'plan_1');
      expect(json['name'], 'Test Plan');
      expect(json['dailyCalories'], 2000);
      expect(json['macros']['protein'], 120.0);
      expect(json['days'], isA<List>());
    });

    test('should handle null optional fields', () {
      final json = {
        'id': 'plan_1',
        'userId': 'user_1',
        'coachId': 'coach_1',
        'name': 'Simple Plan',
        'days': [],
        'macros': {
          'protein': 100.0,
          'carbs': 100.0,
          'fats': 50.0,
        },
        'dailyCalories': 1500,
        'startDate': '2024-01-01T00:00:00.000Z',
        'createdAt': '2024-01-01T00:00:00.000Z',
        'updatedAt': '2024-01-01T00:00:00.000Z',
      };

      final plan = NutritionPlan.fromJson(json);

      expect(plan.description, isNull);
      expect(plan.endDate, isNull);
      expect(plan.isActive, true); // default value
    });
  });

  group('DayMealPlan Model Tests', () {
    test('should create DayMealPlan from JSON', () {
      final json = {
        'id': 'day_1',
        'dayName': 'Tuesday',
        'dayNumber': 2,
        'meals': [],
        'notes': 'High carb day',
      };

      final day = DayMealPlan.fromJson(json);

      expect(day.id, 'day_1');
      expect(day.dayName, 'Tuesday');
      expect(day.dayNumber, 2);
      expect(day.meals, isEmpty);
      expect(day.notes, 'High carb day');
    });

    test('should convert DayMealPlan to JSON', () {
      final day = DayMealPlan(
        id: 'day_1',
        dayName: 'Wednesday',
        dayNumber: 3,
        meals: [],
        notes: 'Refeed day',
      );

      final json = day.toJson();

      expect(json['dayName'], 'Wednesday');
      expect(json['dayNumber'], 3);
      expect(json['notes'], 'Refeed day');
    });
  });

  group('Meal Model Tests', () {
    test('should create Meal from JSON', () {
      final json = {
        'id': 'meal_1',
        'name': 'Dinner',
        'nameAr': 'عشاء',
        'nameEn': 'Dinner',
        'type': 'dinner',
        'time': '19:00',
        'foods': [],
        'macros': {
          'protein': 40.0,
          'carbs': 50.0,
          'fats': 20.0,
        },
        'calories': 520,
        'instructions': 'Grill chicken and serve with rice',
        'instructionsAr': 'اشوي الدجاج وقدمه مع الأرز',
        'instructionsEn': 'Grill chicken and serve with rice',
        'imageUrl': 'https://example.com/dinner.jpg',
        'order': 3,
      };

      final meal = Meal.fromJson(json);

      expect(meal.id, 'meal_1');
      expect(meal.name, 'Dinner');
      expect(meal.nameAr, 'عشاء');
      expect(meal.type, 'dinner');
      expect(meal.time, '19:00');
      expect(meal.calories, 520);
      expect(meal.macros.protein, 40.0);
      expect(meal.instructions, 'Grill chicken and serve with rice');
      expect(meal.order, 3);
    });

    test('should convert Meal to JSON', () {
      final macros = MacroTargets(protein: 25.0, carbs: 30.0, fats: 10.0);
      
      final meal = Meal(
        id: 'meal_1',
        name: 'Snack',
        nameAr: 'وجبة خفيفة',
        nameEn: 'Snack',
        type: 'snack',
        time: '15:00',
        foods: [],
        macros: macros,
        calories: 300,
      );

      final json = meal.toJson();

      expect(json['name'], 'Snack');
      expect(json['type'], 'snack');
      expect(json['calories'], 300);
      expect(json['macros']['protein'], 25.0);
    });

    test('should handle null optional fields', () {
      final json = {
        'id': 'meal_1',
        'name': 'Simple Meal',
        'nameAr': 'وجبة',
        'nameEn': 'Simple Meal',
        'type': 'breakfast',
        'time': '08:00',
        'foods': [],
        'macros': {
          'protein': 20.0,
          'carbs': 25.0,
          'fats': 10.0,
        },
        'calories': 260,
      };

      final meal = Meal.fromJson(json);

      expect(meal.instructions, isNull);
      expect(meal.instructionsAr, isNull);
      expect(meal.instructionsEn, isNull);
      expect(meal.imageUrl, isNull);
      expect(meal.order, 0); // default value
    });
  });

  group('FoodItem Model Tests', () {
    test('should create FoodItem from JSON', () {
      final json = {
        'id': 'food_1',
        'name': 'Brown Rice',
        'nameAr': 'أرز بني',
        'nameEn': 'Brown Rice',
        'quantity': 150.0,
        'unit': 'g',
        'macros': {
          'protein': 4.5,
          'carbs': 35.0,
          'fats': 1.5,
        },
        'calories': 165,
      };

      final food = FoodItem.fromJson(json);

      expect(food.id, 'food_1');
      expect(food.name, 'Brown Rice');
      expect(food.nameAr, 'أرز بني');
      expect(food.quantity, 150.0);
      expect(food.unit, 'g');
      expect(food.macros.protein, 4.5);
      expect(food.macros.carbs, 35.0);
      expect(food.macros.fats, 1.5);
      expect(food.calories, 165);
    });

    test('should convert FoodItem to JSON', () {
      final macros = MacroTargets(protein: 26.0, carbs: 0.0, fats: 12.0);
      
      final food = FoodItem(
        id: 'food_1',
        name: 'Salmon',
        nameAr: 'سلمون',
        nameEn: 'Salmon',
        quantity: 150.0,
        unit: 'g',
        macros: macros,
        calories: 208,
      );

      final json = food.toJson();

      expect(json['name'], 'Salmon');
      expect(json['quantity'], 150.0);
      expect(json['calories'], 208);
      expect(json['macros']['protein'], 26.0);
    });

    test('should handle integer quantity as double', () {
      final json = {
        'id': 'food_1',
        'name': 'Banana',
        'nameAr': 'موز',
        'nameEn': 'Banana',
        'quantity': 2, // integer
        'unit': 'pieces',
        'macros': {
          'protein': 2.0,
          'carbs': 50.0,
          'fats': 0.5,
        },
        'calories': 210,
      };

      final food = FoodItem.fromJson(json);

      expect(food.quantity, 2.0); // converted to double
    });
  });

  group('MacroTargets Model Tests', () {
    test('should create MacroTargets from JSON', () {
      final json = {
        'protein': 150.0,
        'carbs': 200.0,
        'fats': 60.0,
      };

      final macros = MacroTargets.fromJson(json);

      expect(macros.protein, 150.0);
      expect(macros.carbs, 200.0);
      expect(macros.fats, 60.0);
    });

    test('should convert MacroTargets to JSON', () {
      final macros = MacroTargets(
        protein: 120.0,
        carbs: 180.0,
        fats: 50.0,
      );

      final json = macros.toJson();

      expect(json['protein'], 120.0);
      expect(json['carbs'], 180.0);
      expect(json['fats'], 50.0);
    });

    test('should handle integer values as double', () {
      final json = {
        'protein': 100, // integer
        'carbs': 150, // integer
        'fats': 50, // integer
      };

      final macros = MacroTargets.fromJson(json);

      expect(macros.protein, 100.0);
      expect(macros.carbs, 150.0);
      expect(macros.fats, 50.0);
    });
  });
}

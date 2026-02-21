import 'package:flutter_test/flutter_test.dart';
import 'package:fitapp/data/repositories/nutrition_repository.dart';

void main() {
  group('NutritionRepository Tests', () {
    late NutritionRepository nutritionRepository;

    setUp(() {
      nutritionRepository = NutritionRepository();
    });

    test('should create NutritionRepository instance', () {
      expect(nutritionRepository, isNotNull);
      expect(nutritionRepository, isA<NutritionRepository>());
    });

    test('should have proper initialization', () {
      final repo = NutritionRepository();
      expect(repo, isNotNull);
    });
  });
}
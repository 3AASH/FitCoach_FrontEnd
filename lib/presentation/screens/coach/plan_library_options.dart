/// Typed views over the raw exercise and recipe rows the coach plan builders
/// search.
///
/// The endpoints hand back loosely shaped maps whose key names differ between
/// the engine tables and the legacy columns (`ex_id` vs `id`, `name_en` vs
/// `name`). Normalising once here keeps that spelling out of the four screens
/// and out of [LibraryPickerField], which only needs a label, a detail line and
/// an id.
library;

String? _string(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

String? _firstString(List<dynamic> candidates) {
  for (final candidate in candidates) {
    final value = _string(candidate);
    if (value != null) return value;
  }
  return null;
}

String _joinList(dynamic value) {
  if (value is List) {
    return value.map(_string).whereType<String>().join(', ');
  }
  return _string(value) ?? '';
}

class ExerciseLibraryOption {
  final String id;
  final String name;
  final String detail;

  const ExerciseLibraryOption({
    required this.id,
    required this.name,
    required this.detail,
  });

  static ExerciseLibraryOption? fromRow(Map<String, dynamic> row) {
    final name = _firstString([
      row['name_en'],
      row['nameEn'],
      row['name'],
      row['exercise_name'],
    ]);
    final id = _firstString([
      row['ex_id'],
      row['exId'],
      row['id'],
      row['exercise_id'],
    ]);
    // An entry with no name cannot be shown and one with no id cannot be
    // referenced, so it would only be a row the coach can pick and not save.
    if (name == null || id == null) return null;

    final muscle = _joinList(row['muscle_group'] ?? row['muscleGroup'] ?? row['primary_muscles']);
    final equipment = _joinList(row['equipment']);
    final detail = [muscle, equipment, id]
        .where((part) => part.isNotEmpty)
        .join(' · ');

    return ExerciseLibraryOption(id: id, name: name, detail: detail);
  }

  static List<ExerciseLibraryOption> fromRows(List<Map<String, dynamic>> rows) =>
      rows.map(fromRow).whereType<ExerciseLibraryOption>().toList();
}

num? _num(dynamic value) {
  if (value is num) return value;
  if (value == null) return null;
  return num.tryParse(value.toString().trim());
}

/// One portion of one recipe — the row the coach editors actually plan against.
///
/// A meal on its own has no calories: "Koshari" is a dish, "Koshari (M)" is
/// 620 kcal. The coach screens used to plan against the dish, so the calories
/// beside a picked meal were whatever had been typed there before. This carries
/// the portion and the macros that come with it, so choosing a size can fill
/// them in the way the admin plan editor already does.
class RecipeVariantOption {
  final String variantId;
  final String recipeId;
  final String portionCode;
  final String name;
  final String? nameAr;
  final List<String> mealTypes;
  final List<String> marketTags;
  final String? cuisine;
  final num calories;
  final num protein;
  final num carbs;
  final num fat;

  const RecipeVariantOption({
    required this.variantId,
    required this.recipeId,
    required this.portionCode,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.nameAr,
    this.mealTypes = const [],
    this.marketTags = const [],
    this.cuisine,
  });

  /// Name plus size, e.g. "Koshari (M)". Used wherever one row has to be
  /// distinguishable from the other portions of the same dish.
  String get label =>
      portionCode.isEmpty ? name : '$name ($portionCode)';

  String get detail {
    final parts = <String>[
      '${calories.round()} kcal',
      'P ${_macro(protein)} · C ${_macro(carbs)} · F ${_macro(fat)}',
      if (mealTypes.isNotEmpty) mealTypes.join(', '),
      recipeId,
    ];
    return parts.join(' · ');
  }

  static String _macro(num value) =>
      value == value.roundToDouble() ? '${value.round()}g' : '${value.toStringAsFixed(1)}g';

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value.map(_string).whereType<String>().toList();
    }
    final single = _string(value);
    return single == null ? const [] : [single];
  }

  static RecipeVariantOption? fromRow(Map<String, dynamic> row) {
    final variantId = _firstString([row['variant_id'], row['variantId']]);
    final recipeId = _firstString([row['recipe_id'], row['recipeId']]);
    if (variantId == null || recipeId == null) return null;

    // `nutrition` is the engine's own block; the flat columns are the derived
    // copy the listing also returns. Either one is enough.
    final nutrition = row['nutrition'] is Map
        ? Map<String, dynamic>.from(row['nutrition'] as Map)
        : const <String, dynamic>{};

    return RecipeVariantOption(
      variantId: variantId,
      recipeId: recipeId,
      portionCode:
          (_firstString([row['portion_code'], row['portionCode']]) ?? '')
              .toUpperCase(),
      name: _firstString([row['name_en'], row['nameEn'], row['name']]) ?? recipeId,
      nameAr: _firstString([row['name_ar'], row['nameAr']]),
      mealTypes: _stringList(row['meal_types'] ?? row['mealTypes']),
      marketTags: _stringList(row['market_tags'] ?? row['marketTags']),
      cuisine: _string(row['cuisine']),
      calories: _num(nutrition['calories']) ?? _num(row['calories']) ?? 0,
      protein: _num(nutrition['protein_g']) ?? _num(row['protein_g']) ?? 0,
      carbs: _num(nutrition['carbs_g']) ?? _num(row['carbs_g']) ?? 0,
      fat: _num(nutrition['fat_g']) ?? _num(row['fat_g']) ?? 0,
    );
  }

  static List<RecipeVariantOption> fromRows(List<Map<String, dynamic>> rows) =>
      rows.map(fromRow).whereType<RecipeVariantOption>().toList();
}

/// A meal, independent of portion: one entry per recipe, with every portion of
/// it hanging off it. This is what the meal picker lists, so a dish appears
/// once rather than once per size.
class RecipeMealOption {
  final String recipeId;
  final String name;
  final String? nameAr;
  final List<String> mealTypes;
  final List<String> marketTags;
  final String? cuisine;
  final List<RecipeVariantOption> variants;

  const RecipeMealOption({
    required this.recipeId,
    required this.name,
    required this.variants,
    this.nameAr,
    this.mealTypes = const [],
    this.marketTags = const [],
    this.cuisine,
  });

  String get detail {
    final portions = variants.map((v) => v.portionCode).where((c) => c.isNotEmpty);
    return [
      if (mealTypes.isNotEmpty) mealTypes.join(', '),
      if (cuisine != null && cuisine!.isNotEmpty) cuisine!,
      if (portions.isNotEmpty) portions.join('/'),
      recipeId,
    ].join(' · ');
  }

  /// The portion to preselect: medium when the recipe has one, otherwise the
  /// smallest it does have. Matches how the admin plan editor picks a default.
  RecipeVariantOption? get defaultVariant {
    if (variants.isEmpty) return null;
    for (final variant in variants) {
      if (variant.portionCode == 'M') return variant;
    }
    return variants.first;
  }

  static const _portionOrder = ['S', 'M', 'L', 'XL', 'XXL'];

  static int _portionSortKey(RecipeVariantOption variant) {
    final index = _portionOrder.indexOf(variant.portionCode);
    return index < 0 ? _portionOrder.length : index;
  }

  /// Groups a flat variant list into one entry per recipe, portions ordered
  /// small to large and meals ordered by name.
  static List<RecipeMealOption> fromVariants(
      List<RecipeVariantOption> variants) {
    final byRecipe = <String, List<RecipeVariantOption>>{};
    for (final variant in variants) {
      byRecipe.putIfAbsent(variant.recipeId, () => []).add(variant);
    }

    final meals = byRecipe.entries.map((entry) {
      final sorted = [...entry.value]
        ..sort((a, b) => _portionSortKey(a).compareTo(_portionSortKey(b)));
      final first = sorted.first;
      return RecipeMealOption(
        recipeId: entry.key,
        name: first.name,
        nameAr: first.nameAr,
        mealTypes: first.mealTypes,
        marketTags: first.marketTags,
        cuisine: first.cuisine,
        variants: sorted,
      );
    }).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return meals;
  }
}

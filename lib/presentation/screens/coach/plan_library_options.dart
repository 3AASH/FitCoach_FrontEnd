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

class RecipeLibraryOption {
  final String id;
  final String name;
  final String detail;

  const RecipeLibraryOption({
    required this.id,
    required this.name,
    required this.detail,
  });

  static RecipeLibraryOption? fromRow(Map<String, dynamic> row) {
    final id = _firstString([row['recipe_id'], row['recipeId'], row['id']]);
    final name = _firstString([row['name_en'], row['nameEn'], row['name'], id]);
    if (name == null || id == null) return null;

    final mealTypes = _joinList(row['meal_types'] ?? row['mealTypes']);
    final cuisine = _string(row['cuisine']) ?? '';
    final detail = [mealTypes, cuisine, id]
        .where((part) => part.isNotEmpty)
        .join(' · ');

    return RecipeLibraryOption(id: id, name: name, detail: detail);
  }

  static List<RecipeLibraryOption> fromRows(List<Map<String, dynamic>> rows) =>
      rows.map(fromRow).whereType<RecipeLibraryOption>().toList();
}

/// Translated labels for the nutrition engine's controlled vocabularies.
///
/// `plan_type`, `market`, `macro_profile`, `cost_level` and friends are plain
/// `VARCHAR` columns, not enums, and the admin screens printed whatever the
/// seed happened to write. An Arabic-speaking admin saw
/// `professional - SA - 2000 kcal - balanced`: the surrounding screen
/// translated, the data not.
///
/// Because the columns are free text, a value the backend starts sending
/// tomorrow must not vanish. [catalogLabel] looks the value up and falls back
/// to the value itself when the catalogue has nothing for it.
library;

import '../../presentation/providers/language_provider.dart';

/// The translated label for [value] within [domain], or [value] unchanged.
///
/// [domain] names the column — `plan_type`, `market`, `macro_profile`,
/// `cost_level`, `difficulty`, `meal_type`, `validation_status` — and the key
/// looked up is `catalog_<domain>_<value>`, lower-cased.
String catalogLabel(LanguageProvider lang, String domain, Object? value) {
  final raw = value?.toString().trim() ?? '';
  if (raw.isEmpty) return '';
  final key = 'catalog_${domain}_${raw.toLowerCase()}';
  return lang.hasKey(key) ? lang.t(key) : raw;
}

/// [values] as a comma-separated list of translated labels.
///
/// Used for the array columns (`market_tags`, `meal_types`), which arrive as a
/// list and were previously joined raw.
String catalogLabels(
        LanguageProvider lang, String domain, Iterable<Object?> values) =>
    values
        .map((value) => catalogLabel(lang, domain, value))
        .where((label) => label.isNotEmpty)
        // Arabic has its own comma; using the Latin one leaves a stray glyph
        // leaning the wrong way in the middle of an Arabic list.
        .join(lang.isArabic ? '، ' : ', ');

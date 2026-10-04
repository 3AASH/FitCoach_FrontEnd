/// The translation catalogue is the single place English and Arabic live.
///
/// Screens used to carry their own pairs (`isArabic ? 'نعم' : 'Yes'`), which
/// meant the same sentence was written several different ways in several files
/// and the translators never saw any of them. Everything user-facing now goes
/// through [LanguageProvider.t], and these tests hold that line:
///
///  * every key exists in both languages, so switching language can never fall
///    back to the other one;
///  * no value smuggles Dart interpolation (`$name`) into the map, which reads
///    a variable that does not exist where the map is declared;
///  * no key is declared twice in one map, where the second silently wins;
///  * every `t('literal')` a screen asks for is actually in the catalogue,
///    since a miss only shows up at runtime as a humanised key;
///  * no screen has gone back to inlining its own two translations.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _providerPath = 'lib/presentation/providers/language_provider.dart';

/// A `'key': 'value',` entry. Dart lets either quote style be the outer one and
/// the app uses both (`"Today's Sessions"` avoids escaping the apostrophe), so
/// match them separately rather than assuming single quotes.
final _entry = RegExp(
  r"""^\s*'([a-zA-Z0-9_]+)'\s*:\s*\n?\s*(?:'((?:[^'\\]|\\.)*)'|"((?:[^"\\]|\\.)*)")\s*,""",
  multiLine: true,
);

/// A `t('some_key')` lookup with a literal key. Calls that build the key at
/// runtime are skipped: there is nothing to check statically.
final _lookup = RegExp(r"""\bt\(\s*'([a-zA-Z0-9_]+)'""");

/// `isArabic ? 'نعم' : 'Yes'` in any of the receiver spellings the app grew.
final _inlinePair = RegExp(
  r"""(?:[\w.]+\.)?(?:isArabic|isRtl|isRTL)\s*\?\s*'((?:[^'\\]|\\.)*)'\s*:\s*'((?:[^'\\]|\\.)*)'""",
);

/// Some `isArabic ? x : y` pairs are not copy and belong where they are
/// written: a locale code handed to `DateFormat`, or a piece of punctuation
/// like the Arabic comma. Neither is anything a translator would ever edit,
/// and pulling them into the catalogue would put machine input at the mercy
/// of a translation pass.
final _notCopy = RegExp(r'^(?:ar|en|ar_SA|en_US|[\s\p{P}]*)$', unicode: true);

bool _isNotCopy(String a, String b) =>
    _notCopy.hasMatch(a) && _notCopy.hasMatch(b);

String _providerSource() => File(_providerPath).readAsStringSync();

/// The body of one translation map, found by balancing braces from its `= {`.
String _mapBody(String source, String name) {
  final start = source.indexOf('{', RegExp('$name\\s*=\\s*\\{').firstMatch(source)!.start);
  var depth = 0;
  for (var i = start; i < source.length; i++) {
    if (source[i] == '{') depth++;
    if (source[i] == '}') {
      depth--;
      if (depth == 0) return source.substring(start, i + 1);
    }
  }
  throw StateError('unbalanced map literal for $name');
}

/// Keys in declaration order, so a key declared twice appears twice.
List<MapEntry<String, String>> _entries(String source, String name) =>
    _entry
        .allMatches(_mapBody(source, name))
        .map((m) => MapEntry(m.group(1)!, m.group(2) ?? m.group(3)!))
        .toList();

List<File> _dartSources() => Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where((file) => file.path.endsWith('.dart'))
    .toList();

int _lineOf(String source, int offset) =>
    '\n'.allMatches(source.substring(0, offset)).length + 1;

void main() {
  final source = _providerSource();
  final english = _entries(source, '_englishTranslations');
  final arabic = _entries(source, '_arabicTranslations');
  final englishKeys = english.map((e) => e.key).toSet();
  final arabicKeys = arabic.map((e) => e.key).toSet();

  test('the catalogue was parsed, so the checks below mean something', () {
    // A guard that silently matches nothing passes forever. Anchor it.
    expect(english.length, greaterThan(1500));
    expect(arabic.length, greaterThan(1500));
  });

  test('every key is translated into both languages', () {
    expect(
      englishKeys.difference(arabicKeys).toList()..sort(),
      isEmpty,
      reason: 'These keys have no Arabic value, so the Arabic build falls '
          'back to English for them.',
    );
    expect(
      arabicKeys.difference(englishKeys).toList()..sort(),
      isEmpty,
      reason: 'These keys have no English value, so the English build falls '
          'back to the humanised key for them.',
    );
  });

  test('no key is declared twice in the same map', () {
    for (final map in {'English': english, 'Arabic': arabic}.entries) {
      final seen = <String>{};
      final dupes = <String>[];
      for (final entry in map.value) {
        if (!seen.add(entry.key)) dupes.add(entry.key);
      }
      expect(
        dupes,
        isEmpty,
        reason: 'Declared twice in the $map.key map; the later value wins '
            'and the earlier one is dead: ${dupes.join(', ')}',
      );
    }
  });

  test('no translation value interpolates a Dart variable', () {
    // `'Last activity $daysAgo'` inside the map reads an identifier that is
    // not in scope where the map is declared. Runtime substitution is spelled
    // `{days}` and filled in by `t(key, args: ...)`.
    final offenders = <String>[];
    for (final map in {'English': english, 'Arabic': arabic}.entries) {
      for (final entry in map.value) {
        if (RegExp(r'(?<!\\)\$').hasMatch(entry.value)) {
          offenders.add('${map.key}/${entry.key}: ${entry.value}');
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: 'Use a {placeholder} and pass it through t(key, args: {...}) '
          'instead of Dart interpolation:\n${offenders.join('\n')}',
    );
  });

  test('no catalogue entry is really a locale code', () {
    // `DateFormat('MMM d', isArabic ? 'ar' : 'en')` looks like a translated
    // pair but is machine input, not copy. Lifting it into the catalogue puts
    // date formatting at the mercy of anyone editing translations.
    const codes = {'ar', 'en', 'ar_SA', 'en_US', 'rtl', 'ltr'};
    final offenders = <String>[];
    for (final entry in english) {
      if (codes.contains(entry.value) ||
          codes.contains(arabic
              .firstWhere((e) => e.key == entry.key,
                  orElse: () => const MapEntry('', ''))
              .value)) {
        offenders.add(entry.key);
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: 'Read the locale from LanguageProvider (lang.locale.languageCode) '
          'rather than storing it as a translation:\n${offenders.join('\n')}',
    );
  });

  test('every literal key a screen looks up is in the catalogue', () {
    final missing = <String>[];
    for (final file in _dartSources()) {
      if (file.path.endsWith('language_provider.dart')) continue;
      final text = file.readAsStringSync();
      for (final match in _lookup.allMatches(text)) {
        final key = match.group(1)!;
        if (!englishKeys.contains(key)) {
          missing.add('${file.path}:${_lineOf(text, match.start)}  $key');
        }
      }
    }
    expect(
      missing,
      isEmpty,
      reason: 'These lookups miss and render a humanised key to the user:\n'
          '${missing.join('\n')}',
    );
  });

  test('no screen inlines its own English/Arabic pair', () {
    final offenders = <String>[];
    for (final file in _dartSources()) {
      final text = file.readAsStringSync();
      for (final match in _inlinePair.allMatches(text)) {
        final arabicSide = match.group(1)!;
        final englishSide = match.group(2)!;
        if (_isNotCopy(arabicSide, englishSide)) continue;
        offenders.add(
          '${file.path}:${_lineOf(text, match.start)}  $englishSide',
        );
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: 'Translations belong in the catalogue, not in the screen. Add a '
          'key to both maps and call t() instead:\n${offenders.join('\n')}',
    );
  });
}

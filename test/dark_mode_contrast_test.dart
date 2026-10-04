/// Text you can actually read, in both themes.
///
/// The app has a palette that flips with the theme, and the input decoration
/// theme draws every field label in `textSecondary`. In dark mode that is
/// `#D1D5DB`, a near-white grey. Several editor sheets, though, were built on
/// `Material(color: Colors.white)` — a surface pinned to white whatever the
/// theme said.
///
/// Near-white on white is about 1.5:1. The labels on the exercise, workout
/// and nutrition editors were not faint in dark mode, they were gone.
///
/// A surface must therefore come from the palette, so that whatever is drawn
/// on it stays legible when the theme changes.
library;

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitapp/core/theme/app_palette.dart';

/// WCAG relative luminance.
double _luminance(Color color) {
  double channel(double component) {
    final c = component;
    return c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4) as double;
  }

  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

/// WCAG contrast ratio, 1.0 (identical) to 21.0 (black on white).
double contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final lighter = math.max(la, lb);
  final darker = math.min(la, lb);
  return (lighter + 0.05) / (darker + 0.05);
}

/// A surface fixed to a literal colour, which the theme cannot flip.
///
/// `Colors.white.withValues(alpha: …)` is excluded: a translucent wash over a
/// gradient hero is a deliberate effect, and the text on those is given an
/// explicit colour to match. The problem case is a *solid* pinned fill, which
/// is what the editor sheets had.
final _pinnedSurface = RegExp(
  r'(?:color|backgroundColor|fillColor):\s*(?:const\s+)?'
  r'Colors\.(white|black)\b(?!\d)(?!\s*\.)',
);

/// Only the containers that actually are a surface. White on a coloured
/// banner, or a black scrim over video, is deliberate and legible.
const _surfaceWidgets = {'Material', 'BoxDecoration', 'Card', 'CustomCard'};

/// A stroke is not a surface: nothing is drawn on top of it.
const _notASurface = {'Border', 'BorderSide', 'BoxShadow'};

/// The name of the constructor whose argument list encloses [offset].
///
/// Found by walking back to the unmatched `(` rather than by looking at the
/// nearby characters. A fixed lookback window is defeated by anything that
/// takes up room between the widget and its `color:` — another argument, or
/// a comment explaining the colour — and a guard that quietly stops checking
/// is worse than no guard.
String? _enclosingCall(String source, int offset) {
  var depth = 0;
  for (var i = offset - 1; i >= 0; i--) {
    final char = source[i];
    if (char == ')') depth++;
    if (char == '(') {
      if (depth == 0) {
        var end = i;
        var start = i;
        while (start > 0 &&
            RegExp(r'[A-Za-z0-9_.]').hasMatch(source[start - 1])) {
          start--;
        }
        final name = source.substring(start, end);
        // `Border.all` and the like: the leading type is what matters.
        return name.contains('.') ? name.split('.').first : name;
      }
      depth--;
    }
  }
  return null;
}

/// The source with `//` comments blanked out, keeping every offset intact.
///
/// The scan below decides what a colour belongs to by looking at the text
/// just before it. A comment sitting between the widget and its `color:` —
/// such as one explaining why the colour was changed — pushed the widget out
/// of that window and silently switched the check off. Blanking comments
/// first means prose can never hide a regression.
String _withoutComments(String source) {
  final out = source.split('');
  var inLineComment = false;
  var inString = false;
  String? quote;
  for (var i = 0; i < out.length; i++) {
    final char = out[i];
    if (inLineComment) {
      if (char == '\n') {
        inLineComment = false;
      } else {
        out[i] = ' ';
      }
      continue;
    }
    if (inString) {
      if (char == r'\') {
        i++;
      } else if (char == quote) {
        inString = false;
      }
      continue;
    }
    if (char == "'" || char == '"') {
      inString = true;
      quote = char;
      continue;
    }
    if (char == '/' && i + 1 < out.length && out[i + 1] == '/') {
      inLineComment = true;
      out[i] = ' ';
    }
  }
  return out.join();
}

List<File> _dartSources() => Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where((file) => file.path.endsWith('.dart'))
    .toList();

void main() {
  group('the palette keeps body text legible', () {
    test('secondary text has usable contrast on its own surface', () {
      for (final entry in {
        'light': AppPalette.light,
        'dark': AppPalette.dark,
      }.entries) {
        final palette = entry.value;
        // 4.5:1 is the WCAG AA floor for body text.
        expect(
          contrast(palette.textSecondary, palette.surface),
          greaterThanOrEqualTo(4.5),
          reason: 'secondary text on the ${entry.key} surface',
        );
        expect(
          contrast(palette.textPrimary, palette.surface),
          greaterThanOrEqualTo(4.5),
          reason: 'primary text on the ${entry.key} surface',
        );
      }
    });

    test('dark secondary text on a white surface is the bug, and is unusable',
        () {
      // Pins the reason the rule below exists: this is what the editor sheets
      // were doing, and it is nowhere near readable.
      final ratio = contrast(AppPalette.dark.textSecondary, Colors.white);
      expect(ratio, lessThan(2.0));
    });
  });

  test('no sheet or card pins its surface to a literal colour', () {
    final offenders = <String>[];
    for (final file in _dartSources()) {
      final source = _withoutComments(file.readAsStringSync());
      for (final match in _pinnedSurface.allMatches(source)) {
        final owner = _enclosingCall(source, match.start);
        if (owner == null) continue;
        if (_notASurface.contains(owner)) continue;
        if (!_surfaceWidgets.contains(owner)) continue;
        final line =
            '\n'.allMatches(source.substring(0, match.start)).length + 1;
        offenders.add('${file.path}:$line  Colors.${match.group(1)}');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'A surface fixed to one colour cannot follow the theme, so the '
          'theme-coloured text on it disappears. Use context.palette.surface:\n'
          '${offenders.join('\n')}',
    );
  });
}

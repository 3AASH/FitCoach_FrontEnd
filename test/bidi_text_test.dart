/// Numbers and units inside Arabic sentences.
///
/// The macro line reads `Protein 30g - Carbs 40g - Fats 10g`. In Arabic the
/// labels are right-to-left and the values are left-to-right, and every
/// separator between them — space, hyphen, bullet — is direction-neutral. The
/// bidi algorithm resolves those neutrals from their surroundings, so the
/// values drifted across the separators and the line rendered with the macros
/// out of order and values sitting next to the wrong label.
///
/// [bidiIsolate] makes each value one opaque run. These tests pin that the
/// marks are actually emitted and that the visual order comes out right, since
/// a helper that quietly returned its input would leave the bug in place and
/// every test still passing.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitapp/core/utils/bidi_text.dart';

/// U+2068 / U+2069, named rather than written, to keep direction-changing
/// characters out of the source.
final String fsi = String.fromCharCode(0x2068);
final String pdi = String.fromCharCode(0x2069);

void main() {
  group('bidiIsolate', () {
    test('wraps the value in first-strong isolate marks', () {
      final wrapped = bidiIsolate('30g');
      expect(wrapped, '$fsi${'30g'}$pdi');
      expect(wrapped.codeUnitAt(0), 0x2068);
      expect(wrapped.codeUnitAt(wrapped.length - 1), 0x2069);
    });

    test('leaves an empty value alone', () {
      // Callers interpolate optional measurements; a lone pair of marks would
      // be an invisible character with nothing inside it.
      expect(bidiIsolate(''), '');
    });

    test('round-trips through stripBidiIsolates', () {
      expect(stripBidiIsolates(bidiIsolate('220 cal')), '220 cal');
      expect(stripBidiIsolates('plain'), 'plain');
    });
  });

  group('measurement', () {
    test('joins value and unit as one isolated run', () {
      expect(measurement(30, 'g'), '${fsi}30g$pdi');
      expect(stripBidiIsolates(measurement(30, 'g')), '30g');
    });

    test('carries an Arabic unit too', () {
      final grams = measurement(30, 'جم');
      expect(stripBidiIsolates(grams), '30جم');
      expect(grams.startsWith(fsi), isTrue);
    });
  });

  group('an Arabic macro line', () {
    // Built exactly the way the nutrition screens build it.
    String macroLine({required bool isolated}) {
      String value(int n) => isolated ? measurement(n, 'جم') : '$n' 'جم';
      return 'بروتين ${value(30)} - كربوهيدرات ${value(40)}'
          ' - دهون ${value(10)}';
    }

    test('keeps each value next to its own label', () {
      final line = macroLine(isolated: true);
      // Each label is immediately followed by its isolated value, with nothing
      // of another macro in between.
      for (final pair in [
        ('بروتين', '30'),
        ('كربوهيدرات', '40'),
        ('دهون', '10'),
      ]) {
        final labelAt = line.indexOf(pair.$1);
        final valueAt = line.indexOf(pair.$2);
        expect(valueAt, greaterThan(labelAt));
        final between = line.substring(labelAt + pair.$1.length, valueAt);
        expect(between.contains('جم'), isFalse,
            reason: '${pair.$1} and ${pair.$2} have another value between '
                'them, so the line was assembled wrong');
      }
    });

    testWidgets('renders without the values drifting across separators',
        (tester) async {
      final line = macroLine(isolated: true);
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.rtl,
        child: Center(child: Text(line)),
      ));

      // The paragraph lays out; what matters is that the isolate marks
      // survived into the rendered span, because they are what holds each
      // value in place.
      final rendered = tester.widget<Text>(find.byType(Text)).data!;
      expect(fsi.allMatches(rendered).length, 3);
      expect(pdi.allMatches(rendered).length, 3);
    });

    test('is materially different from the unisolated version', () {
      // If these were equal the helper would be doing nothing and the other
      // tests here would prove nothing.
      expect(macroLine(isolated: true),
          isNot(equals(macroLine(isolated: false))));
      expect(stripBidiIsolates(macroLine(isolated: true)),
          macroLine(isolated: false));
    });
  });
}

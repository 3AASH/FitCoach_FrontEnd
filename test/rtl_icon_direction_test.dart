/// Arrows and chevrons in the Arabic build.
///
/// Material's directional icons — `arrow_back`, `arrow_forward`,
/// `chevron_left`, `chevron_right`, `send` and friends — are declared with
/// `matchTextDirection: true`, so Flutter already mirrors them whenever the
/// ambient [Directionality] is RTL. The app is RTL in Arabic (`locale: ar` plus
/// `GlobalWidgetsLocalizations`), so it gets that mirroring for free.
///
/// Screens used to *also* pick the opposite glyph by hand
/// (`isArabic ? Icons.arrow_forward : Icons.arrow_back`). Flutter then mirrored
/// that choice too, and two flips is no flip: every one of those arrows pointed
/// the wrong way in Arabic. The rule is to write the LTR icon and let Flutter
/// turn it around.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Picking an icon based on the reading direction, in any of the spellings the
/// app had grown: `isArabic`, `isRtl`, `isRTL`, or a direct `Directionality`
/// comparison.
final _manualFlip = RegExp(
  r'(?:(?:lang\.)?(?:isArabic|isRtl|isRTL)\b'
  r'|Directionality\.of\(\s*\w+\s*\)\s*==\s*TextDirection\.rtl)'
  r'\s*\?\s*(Icons\.\w+)\s*:\s*(Icons\.\w+)',
  dotAll: true,
);

List<File> _dartSources() {
  final lib = Directory('lib');
  return lib
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList();
}

/// The transform Flutter wraps an icon glyph in, or null when it leaves it
/// alone. A horizontal mirror is `scale(-1, 1)`.
Matrix4? _glyphTransform(WidgetTester tester) {
  final transforms = tester
      .widgetList<Transform>(find.descendant(
        of: find.byType(Icon),
        matching: find.byType(Transform),
      ))
      .toList();
  return transforms.isEmpty ? null : transforms.first.transform;
}

void main() {
  group('the directional icons the app relies on', () {
    test('are all auto-mirroring, so picking one by hand double-flips it', () {
      for (final icon in <IconData>[
        Icons.arrow_back,
        Icons.arrow_forward,
        Icons.arrow_back_ios,
        Icons.arrow_back_ios_new,
        Icons.arrow_forward_ios,
        Icons.chevron_left,
        Icons.chevron_right,
        Icons.send,
      ]) {
        expect(
          icon.matchTextDirection,
          isTrue,
          reason: 'Flutter is expected to mirror $icon under RTL',
        );
      }
    });

    testWidgets('are mirrored under RTL and left alone under LTR',
        (tester) async {
      await tester.pumpWidget(const Directionality(
        textDirection: TextDirection.ltr,
        child: Icon(Icons.arrow_back),
      ));
      expect(_glyphTransform(tester), isNull,
          reason: 'LTR should render the glyph as authored');

      await tester.pumpWidget(const Directionality(
        textDirection: TextDirection.rtl,
        child: Icon(Icons.arrow_back),
      ));
      final rtl = _glyphTransform(tester);
      expect(rtl, isNotNull, reason: 'RTL should mirror the glyph');
      // A horizontal flip: x is negated, y is untouched.
      expect(rtl!.entry(0, 0), -1.0);
      expect(rtl.entry(1, 1), 1.0);
    });
  });

  test('no screen reorders a Row by reading direction', () {
    // Same double-flip, one level up. `Row` consults the ambient
    // [Directionality] and already lays its children out right-to-left in
    // Arabic, so a screen that also swaps the children round by hand cancels
    // that out: the icon that should lead the row ends up trailing it.
    final handReversed = RegExp(
      r'children:\s*(?:[\w.]+\.)?(?:isArabic|isRtl|isRTL)\s*\?'
      r'|children:\s*[\w.]+\.reversed',
    );

    final offenders = <String>[];
    for (final file in _dartSources()) {
      final source = file.readAsStringSync();
      for (final match in handReversed.allMatches(source)) {
        final line =
            '\n'.allMatches(source.substring(0, match.start)).length + 1;
        offenders.add('${file.path}:$line');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'Write the children in left-to-right order once and let Flutter '
          'mirror the Row:\n${offenders.join('\n')}',
    );
  });

  test('no screen picks an arrow or chevron by reading direction', () {
    final offenders = <String>[];
    for (final file in _dartSources()) {
      final source = file.readAsStringSync();
      for (final match in _manualFlip.allMatches(source)) {
        final line = '\n'.allMatches(source.substring(0, match.start)).length + 1;
        offenders.add(
          '${file.path}:$line  ${match.group(1)} / ${match.group(2)}',
        );
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'These choose an icon by text direction, which Flutter then '
          'mirrors again - the arrow ends up pointing the wrong way in '
          'Arabic. Write the left-to-right icon on its own:\n'
          '${offenders.join('\n')}',
    );
  });
}

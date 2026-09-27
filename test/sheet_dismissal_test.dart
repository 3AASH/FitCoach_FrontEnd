/// Every modal bottom sheet needs a visible way out.
///
/// A sheet opened with `isScrollControlled: true` covers most of the screen, so
/// the scrim shrinks to a sliver at the very top and dragging a sheet that
/// scrolls internally does not work. Several editors had no exit at all short
/// of submitting the form, which is a bad place to strand someone who opened
/// one by mistake.
///
/// The exit can be a [SheetHeader]'s close button, a [SheetCloseButton], a
/// cancel action, or any control that pops. This walks every
/// `showModalBottomSheet` call and, when the call only names a widget, follows
/// it into that widget's class.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:fitapp/presentation/providers/language_provider.dart';
import 'package:fitapp/presentation/widgets/sheet_header.dart';

final _openSheet = RegExp(r'showModalBottomSheet(?:<[^>]*>)?\s*\(');

/// The widget a plumbing-only call hands the sheet off to, e.g.
/// `builder: (_) => _ExerciseEditorSheet(`. Deliberately narrow: only a class
/// whose name says it *is* the sheet counts. Following every constructor in
/// the call would let an unrelated widget that happens to contain a
/// `Navigator.pop` vouch for a sheet that has no exit of its own.
///
/// Covers both builder styles: an arrow returning the sheet, and a block body
/// that does some setup and then `return TheSheet(...)`.
final _delegate = RegExp(r'(?:=>|return)\s*(?:const\s+)?(_?[A-Z]\w*'
    r'(?:Sheet|Modal|Dialog|Picker))\s*\(');

/// Anything that lets the user leave without completing the form.
const _exits = [
  'SheetHeader',
  'SheetCloseButton',
  'Icons.close',
  'Navigator.of(context).pop',
  'Navigator.pop',
  "t('cancel')",
  'maybePop',
];

bool _hasExit(String source) => _exits.any(source.contains);

List<File> _dartSources() => Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where((file) => file.path.endsWith('.dart'))
    .toList();

/// The source of the call whose opening `(` is at or after [from].
String _callText(String source, int from) {
  final open = source.indexOf('(', from);
  var depth = 0;
  for (var i = open; i < source.length; i++) {
    if (source[i] == '(') depth++;
    if (source[i] == ')') {
      depth--;
      if (depth == 0) return source.substring(open, i + 1);
    }
  }
  return source.substring(open);
}

/// The body of `class [name]` and of its `State` companion, wherever in the app
/// they are declared. A sheet is usually a `StatefulWidget` whose build — and
/// so whose close button — lives in the state class.
String _classBodies(String name, Map<String, String> allSources) {
  final buffer = StringBuffer();
  final declaration = RegExp('class (${RegExp.escape(name)}|'
      '${RegExp.escape(name)}State|_${RegExp.escape(name)}State)\\b');
  for (final source in allSources.values) {
    for (final match in declaration.allMatches(source)) {
      final open = source.indexOf('{', match.start);
      if (open < 0) continue;
      var depth = 0;
      for (var i = open; i < source.length; i++) {
        if (source[i] == '{') depth++;
        if (source[i] == '}') {
          depth--;
          if (depth == 0) {
            buffer.write(source.substring(open, i + 1));
            break;
          }
        }
      }
    }
  }
  return buffer.toString();
}

void main() {
  testWidgets('SheetHeader offers a close button that pops the sheet',
      (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => LanguageProvider(),
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  builder: (_) => const SheetHeader(title: 'Edit plan'),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Edit plan'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('Edit plan'), findsNothing,
        reason: 'the close button should dismiss the sheet');
  });

  testWidgets('SheetCloseButton pops the sheet', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => LanguageProvider(),
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  builder: (_) => const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [SheetCloseButton(), Text('product')],
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('product'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('product'), findsNothing);
  });

  test('every modal bottom sheet in the app can be dismissed', () {
    final sources = {
      for (final file in _dartSources()) file.path: file.readAsStringSync(),
    };

    final stranded = <String>[];
    sources.forEach((path, source) {
      for (final match in _openSheet.allMatches(source)) {
        final call = _callText(source, match.start);
        if (_hasExit(call)) continue;

        // The call is only plumbing: follow the sheet widget it hands off to.
        final reachable = _delegate
            .allMatches(call)
            .map((m) => m.group(1)!)
            .where((name) => name != 'DraggableScrollableSheet')
            .any((name) => _hasExit(_classBodies(name, sources)));
        if (reachable) continue;

        final line = '\n'.allMatches(source.substring(0, match.start)).length + 1;
        stranded.add('$path:$line');
      }
    });

    expect(
      stranded,
      isEmpty,
      reason: 'These sheets give the user no way out. Add a SheetHeader (or a '
          'SheetCloseButton when the content leads with an image):\n'
          '${stranded.join('\n')}',
    );
  });
}

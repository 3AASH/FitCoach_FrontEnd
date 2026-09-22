import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitapp/core/config/theme_config.dart';
import 'package:fitapp/core/theme/app_palette.dart';

/// WCAG relative contrast ratio between two opaque colours.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  final light = AppThemeConfig.getLightTheme();
  final dark = AppThemeConfig.getDarkTheme();

  group('palette registration', () {
    test('both themes carry an AppPalette extension', () {
      expect(light.extension<AppPalette>(), isNotNull);
      expect(dark.extension<AppPalette>(), isNotNull);
    });

    testWidgets("context.palette resolves the active theme's palette",
        (tester) async {
      // Guards the accessor, not just the extension: a widget deep in the
      // tree has to get the dark palette when the app is in dark mode.
      for (final entry in {light: AppPalette.light, dark: AppPalette.dark}.entries) {
        late AppPalette seen;
        await tester.pumpWidget(MaterialApp(
          theme: entry.key,
          home: Builder(builder: (context) {
            seen = context.palette;
            return const SizedBox();
          }),
        ));
        // MaterialApp wraps the theme in an AnimatedTheme, so a single frame
        // after a theme swap still reports the lerped-from value.
        await tester.pumpAndSettle();
        expect(seen.textPrimary, entry.value.textPrimary);
        expect(seen.surface, entry.value.surface);
      }
    });
  });

  group('text is legible on the surfaces it is painted on', () {
    // The bug this guards: text colours were fixed constants while surfaces
    // changed with the theme, so body text ended up near-black on a dark
    // scaffold (and white on white inside overlays).
    for (final entry in {'light': AppPalette.light, 'dark': AppPalette.dark}.entries) {
      final name = entry.key;
      final p = entry.value;

      test('$name: primary text clears 4.5:1 on every surface', () {
        for (final surface in {
          'background': p.background,
          'surface': p.surface,
          'surfaceVariant': p.surfaceVariant,
        }.entries) {
          expect(
            _contrast(p.textPrimary, surface.value),
            greaterThanOrEqualTo(4.5),
            reason: '$name textPrimary on ${surface.key}',
          );
        }
      });

      test('$name: secondary text clears 3:1 on every surface', () {
        for (final surface in {
          'background': p.background,
          'surface': p.surface,
          'surfaceVariant': p.surfaceVariant,
        }.entries) {
          expect(
            _contrast(p.textSecondary, surface.value),
            greaterThanOrEqualTo(3.0),
            reason: '$name textSecondary on ${surface.key}',
          );
        }
      });

      test('$name: text on a brand fill is legible', () {
        expect(_contrast(p.textOnBrand, p.primary), greaterThanOrEqualTo(3.0));
      });
    }
  });

  group('the two themes are genuinely independent', () {
    // getDarkTheme() used to be getLightTheme().copyWith(...), which silently
    // kept every sub-theme the call did not re-list. These assertions fail if
    // that shortcut comes back.
    test('scaffold, card and divider colours all differ', () {
      expect(dark.scaffoldBackgroundColor,
          isNot(light.scaffoldBackgroundColor));
      expect(dark.cardTheme.color, isNot(light.cardTheme.color));
      expect(dark.dividerColor, isNot(light.dividerColor));
    });

    test('overlay surfaces track the theme instead of staying light', () {
      expect(dark.bottomSheetTheme.backgroundColor,
          isNot(light.bottomSheetTheme.backgroundColor));
      expect(dark.popupMenuTheme.color, isNot(light.popupMenuTheme.color));
      expect(dark.listTileTheme.titleTextStyle?.color,
          isNot(light.listTileTheme.titleTextStyle?.color));
      expect(dark.expansionTileTheme.textColor,
          isNot(light.expansionTileTheme.textColor));
      expect(dark.chipTheme.labelStyle?.color,
          isNot(light.chipTheme.labelStyle?.color));
    });

    test('dark mode really is dark', () {
      expect(dark.brightness, Brightness.dark);
      expect(dark.colorScheme.brightness, Brightness.dark);
      expect(dark.colorScheme.surface.computeLuminance(), lessThan(0.2));
      expect(dark.colorScheme.onSurface.computeLuminance(), greaterThan(0.5));
      expect(dark.scaffoldBackgroundColor.computeLuminance(), lessThan(0.2));
    });
  });

  group('typography carries explicit colours', () {
    // A TextStyle with a null colour inherits from the nearest
    // DefaultTextStyle, which inside an overlay is not the page's text colour.
    // That inheritance is what produced unreadable rows in menus and sheets.
    for (final entry in {'light': light, 'dark': dark}.entries) {
      test('${entry.key}: every textTheme style sets a colour', () {
        final t = entry.value.textTheme;
        final styles = <String, TextStyle?>{
          'displayLarge': t.displayLarge,
          'displayMedium': t.displayMedium,
          'displaySmall': t.displaySmall,
          'headlineMedium': t.headlineMedium,
          'headlineSmall': t.headlineSmall,
          'titleLarge': t.titleLarge,
          'titleMedium': t.titleMedium,
          'titleSmall': t.titleSmall,
          'bodyLarge': t.bodyLarge,
          'bodyMedium': t.bodyMedium,
          'bodySmall': t.bodySmall,
          'labelLarge': t.labelLarge,
          'labelMedium': t.labelMedium,
          'labelSmall': t.labelSmall,
        };
        styles.forEach((name, style) {
          expect(style?.color, isNotNull, reason: '$name has no colour');
        });
      });

      test('${entry.key}: input decoration styles set a colour', () {
        final d = entry.value.inputDecorationTheme;
        expect(d.labelStyle?.color, isNotNull);
        expect(d.floatingLabelStyle?.color, isNotNull);
        expect(d.hintStyle?.color, isNotNull);
        expect(d.errorStyle?.color, isNotNull);
      });
    }
  });

  group('AppPalette', () {
    test('lerp moves between the two palettes', () {
      final mid = AppPalette.light.lerp(AppPalette.dark, 1.0);
      expect(mid.textPrimary, AppPalette.dark.textPrimary);
      final none = AppPalette.light.lerp(AppPalette.dark, 0.0);
      expect(none.textPrimary, AppPalette.light.textPrimary);
    });

    test('copyWith replaces only the field it is given', () {
      final p = AppPalette.light.copyWith(textPrimary: const Color(0xFF00FF00));
      expect(p.textPrimary, const Color(0xFF00FF00));
      expect(p.textSecondary, AppPalette.light.textSecondary);
    });
  });
}

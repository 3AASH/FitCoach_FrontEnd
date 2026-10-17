// The shared cards must not overflow with long copy at a phone width and with
// the user's larger text setting. Text sizes in these cards were raised to 12sp,
// so this is the check that the enlarged text still fits.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitapp/core/config/theme_config.dart';
import 'package:fitapp/presentation/widgets/custom_card.dart';
import 'package:fitapp/presentation/widgets/custom_stat_info_card.dart';

const _long = 'A very long label that wraps across more than one line on a phone';

void main() {
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('stat and info cards fit with long text ($mode)', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppThemeConfig.getLightTheme(),
        darkTheme: AppThemeConfig.getDarkTheme(),
        themeMode: mode,
        builder: (context, page) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.3)),
          child: page!,
        ),
        home: const Scaffold(
          body: SizedBox(
            width: 320,
            child: Column(children: [
              CustomStatCard(
                title: _long,
                value: '12345 kcal',
                icon: Icons.bolt,
                color: Colors.teal,
              ),
              CustomInfoCard(
                title: _long,
                subtitle: _long,
                icon: Icons.person,
              ),
            ]),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('card wrapper fits long text ($mode)', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppThemeConfig.getLightTheme(),
        darkTheme: AppThemeConfig.getDarkTheme(),
        themeMode: mode,
        home: const Scaffold(
          body: SizedBox(
            width: 320,
            child: CustomCard(child: Text(_long, style: TextStyle(fontSize: 12))),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}

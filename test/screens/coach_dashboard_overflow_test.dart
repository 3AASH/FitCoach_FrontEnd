// Renders the coach dashboard, bottom bar included, at phone width and fails on
// any layout overflow. Run in demo mode so every loader returns demo data
// without a backend:
//   flutter test --dart-define=DEMO_MODE=true test/screens/coach_dashboard_overflow_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/real_fonts.dart';
import 'package:fitapp/core/config/demo_mode.dart';
import 'package:fitapp/core/config/theme_config.dart';
import 'package:fitapp/data/demo/demo_data.dart';
import 'package:fitapp/data/models/user_profile.dart';
import 'package:fitapp/data/repositories/auth_repository.dart';
import 'package:fitapp/data/repositories/coach_repository.dart';
import 'package:fitapp/data/repositories/messaging_repository.dart';
import 'package:fitapp/presentation/providers/auth_provider.dart';
import 'package:fitapp/presentation/providers/coach_provider.dart';
import 'package:fitapp/presentation/providers/language_provider.dart';
import 'package:fitapp/presentation/providers/messaging_provider.dart';
import 'package:fitapp/presentation/screens/coach/coach_dashboard_screen.dart';

/// Auth is never called in demo mode; only the signed-in user matters here.
class _UnusedAuthRepo implements AuthRepositoryBase {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _CoachAuth extends AuthProvider {
  _CoachAuth() : super(_UnusedAuthRepo());

  @override
  UserProfile? get user => DemoData.userProfile(role: 'coach');
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await loadRealFonts();
  });

  for (final locale in ['en', 'ar']) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('coach dashboard and bottom bar fit at 390px ($locale, $mode)',
          (tester) async {
        // 390x844 logical pixels at 3x, a common phone size.
        tester.view.physicalSize = const Size(390 * 3, 844 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final language = LanguageProvider();
        await language.setLanguage(locale);

        await tester.pumpWidget(MultiProvider(
          providers: [
            ChangeNotifierProvider<LanguageProvider>.value(value: language),
            ChangeNotifierProvider<AuthProvider>(create: (_) => _CoachAuth()),
            ChangeNotifierProvider<CoachProvider>(
              create: (_) => CoachProvider(CoachRepository()),
            ),
            ChangeNotifierProvider<MessagingProvider>(
              create: (_) => MessagingProvider(MessagingRepository()),
            ),
          ],
          child: MaterialApp(
            theme: AppThemeConfig.getLightTheme(),
            darkTheme: AppThemeConfig.getDarkTheme(),
            themeMode: mode,
            home: const CoachDashboardScreen(),
          ),
        ));

        // Pump in steps rather than pumpAndSettle: the screens run looping
        // animations, which would never settle.
        final errors = <Object>[];
        Future<void> pumpFrames({int frames = 20}) async {
          for (var i = 0; i < frames; i++) {
            await tester.pump(const Duration(milliseconds: 100));
            final error = tester.takeException();
            if (error != null) errors.add(error);
          }
        }

        await pumpFrames();

        // Lower dashboard content is built lazily, so scroll to it.
        for (var i = 0; i < 8; i++) {
          await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
          await pumpFrames(frames: 5);
        }

        // Each bottom-nav tab. Checking the IndexedStack index confirms the
        // tap landed on that tab before its content is checked.
        final tabs = {
          'coach_tab_clients': 1,
          'coach_tab_calendar': 2,
          'coach_tab_messages': 3,
          'coach_tab_dashboard': 0,
        };
        for (final tab in tabs.entries) {
          final label = language.t(tab.key);
          // Unselected items show only their icon; the label is the tooltip.
          await tester.tap(find.byTooltip(label).last);
          await pumpFrames();
          expect(
            tester.widget<IndexedStack>(find.byType(IndexedStack).first).index,
            tab.value,
            reason: 'tab tap did not switch to $label',
          );
          // Scroll each tab to its end as well.
          for (var i = 0; i < 6; i++) {
            final scrollables = find.byType(Scrollable);
            if (scrollables.evaluate().isEmpty) break;
            await tester.drag(scrollables.first, const Offset(0, -600));
            await pumpFrames(frames: 5);
          }
        }

        expect(errors, isEmpty, reason: 'layout errors on the coach screens');
      }, skip: !kDemoMode);
    }
  }
}

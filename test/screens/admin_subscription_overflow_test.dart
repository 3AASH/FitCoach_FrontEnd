// Renders the admin and subscription screens at phone width and fails on any
// layout overflow. Run in demo mode so providers return demo data without a
// backend:
//   flutter test --dart-define=DEMO_MODE=true test/screens/admin_subscription_overflow_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/real_fonts.dart';
import 'package:fitapp/core/config/demo_mode.dart';
import 'package:fitapp/core/config/theme_config.dart';
import 'package:fitapp/data/demo/demo_data.dart';
import 'package:fitapp/data/models/user_profile.dart';
import 'package:fitapp/data/repositories/admin_repository.dart';
import 'package:fitapp/data/repositories/auth_repository.dart';
import 'package:fitapp/data/repositories/subscription_plan_repository.dart';
import 'package:fitapp/data/repositories/user_repository.dart';
import 'package:fitapp/presentation/providers/admin_provider.dart';
import 'package:fitapp/presentation/providers/auth_provider.dart';
import 'package:fitapp/presentation/providers/language_provider.dart';
import 'package:fitapp/presentation/providers/subscription_plan_provider.dart';
import 'package:fitapp/presentation/providers/user_provider.dart';
import 'package:fitapp/presentation/screens/admin/admin_coaches_screen.dart';
import 'package:fitapp/presentation/screens/admin/admin_dashboard_screen.dart';
import 'package:fitapp/presentation/screens/admin/admin_revenue_screen.dart';
import 'package:fitapp/presentation/screens/admin/admin_users_screen.dart';
import 'package:fitapp/presentation/screens/admin/subscription_management_screen.dart';
import 'package:fitapp/presentation/screens/subscription/subscription_manager_screen.dart';
import 'package:fitapp/presentation/screens/subscription/subscription_upgrade_screen.dart';

/// Auth is never called in demo mode; only the signed-in user matters here.
class _UnusedAuthRepo implements AuthRepositoryBase {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _DemoAuth extends AuthProvider {
  _DemoAuth(this._role) : super(_UnusedAuthRepo());

  final String _role;

  @override
  UserProfile? get user => DemoData.userProfile(role: _role);
}

typedef _ScreenBuilder = Widget Function();

final Map<String, _ScreenBuilder> _screens = {
  'admin dashboard': () => const AdminDashboardScreen(),
  'admin customers': () => const AdminUsersScreen(initialRole: 'customers'),
  'admin coaches': () => const AdminCoachesScreen(),
  'admin revenue': () => const AdminRevenueScreen(),
  'subscription management': () => const SubscriptionManagementScreen(),
  'subscription upgrade': () => const SubscriptionUpgradeScreen(),
  'subscription manager': () => const SubscriptionManagerScreen(),
};

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await loadRealFonts();
  });

  for (final screen in _screens.entries) {
    for (final locale in ['en', 'ar']) {
      for (final mode in [ThemeMode.light, ThemeMode.dark]) {
        testWidgets('${screen.key} fits at 390px ($locale, $mode)',
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
              ChangeNotifierProvider<AuthProvider>(
                create: (_) => _DemoAuth('admin'),
              ),
              ChangeNotifierProvider<AdminProvider>(
                create: (_) => AdminProvider(AdminRepository()),
              ),
              ChangeNotifierProvider<SubscriptionPlanProvider>(
                create: (_) =>
                    SubscriptionPlanProvider(SubscriptionPlanRepository()),
              ),
              ChangeNotifierProvider<UserProvider>(
                create: (_) => UserProvider(UserRepository()),
              ),
            ],
            child: MaterialApp(
              theme: AppThemeConfig.getLightTheme(),
              darkTheme: AppThemeConfig.getDarkTheme(),
              themeMode: mode,
              home: screen.value(),
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

          // Scroll the whole screen so lower content is built and measured.
          for (var i = 0; i < 8; i++) {
            final scrollables = find.byType(Scrollable);
            if (scrollables.evaluate().isEmpty) break;
            await tester.drag(scrollables.first, const Offset(0, -600));
            await pumpFrames(frames: 5);
          }

          expect(errors, isEmpty, reason: 'layout errors on ${screen.key}');
        }, skip: !kDemoMode);
      }
    }
  }
}

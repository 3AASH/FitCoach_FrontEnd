import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/language_provider.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/language_selection_screen.dart';
import 'presentation/screens/onboarding_screen.dart';
import 'presentation/screens/auth/auth_screen.dart';
import 'presentation/screens/intake/first_intake_screen.dart';
import 'presentation/screens/intake/second_intake_screen.dart';
import 'presentation/screens/home/home_dashboard_screen.dart';
import 'presentation/screens/workout/workout_screen.dart';
import 'presentation/screens/nutrition/nutrition_screen.dart';
import 'presentation/screens/messaging/coach_messaging_screen.dart';
import 'presentation/screens/store/store_screen.dart';
import 'presentation/screens/account/account_screen.dart';
import 'presentation/screens/coach/coach_dashboard_screen.dart';
import 'presentation/screens/admin/admin_dashboard_screen.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  static const String _onboardingSeenKey = 'app_onboarding_seen';

  bool _showSplash = true;
  String _currentScreen = 'splash';

  @override
  void initState() {
    super.initState();
  }

  void _completeSplash() {
    _completeSplashAsync();
  }

  bool _startingUp = false;

  Future<void> _completeSplashAsync() async {
    if (_startingUp) return;
    _startingUp = true;
    final languageProvider = context.read<LanguageProvider>();
    final authProvider = context.read<AuthProvider>();
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool(_onboardingSeenKey) ?? false;

    // Wait for the stored session to be checked before choosing a screen.
    // Capped so a dead network cannot hold the app on the splash forever.
    var restoreTimedOut = false;
    await authProvider.sessionRestored.timeout(
      const Duration(seconds: 12),
      onTimeout: () => restoreTimedOut = true,
    );
    if (!mounted) return;

    setState(() {
      _showSplash = false;

      // Determine initial screen
      if (!languageProvider.hasSelectedLanguage) {
        _currentScreen = 'language';
      } else if (!authProvider.isAuthenticated) {
        _currentScreen = hasSeenOnboarding ? 'auth' : 'onboarding';
      } else {
        _currentScreen = _resolvePostAuthScreen(authProvider);
      }
    });

    if (restoreTimedOut) {
      // The check finished after we gave up waiting: if it found a valid
      // session, move on from the login/onboarding screen.
      unawaited(authProvider.sessionRestored.then((_) {
        if (!mounted || !authProvider.isAuthenticated) return;
        if (_currentScreen == 'auth' || _currentScreen == 'onboarding') {
          _navigateToScreen(_resolvePostAuthScreen(authProvider));
        }
      }));
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingSeenKey, true);
    if (!mounted) return;
    _navigateToScreen('auth');
  }

  String _resolvePostAuthScreen(AuthProvider authProvider) {
    final role = authProvider.user?.role.toLowerCase();
    if (role == 'coach') {
      return 'coachDashboard';
    }
    if (role == 'admin') {
      return 'adminDashboard';
    }
    if (authProvider.user != null &&
        !authProvider.user!.hasCompletedFirstIntake) {
      return 'firstIntake';
    }
    return 'home';
  }

  void _handlePostAuthNavigation() {
    final authProvider = context.read<AuthProvider>();
    _navigateToScreen(_resolvePostAuthScreen(authProvider));
  }

  void _navigateToScreen(String screen) {
    setState(() {
      _currentScreen = screen;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(onStart: _completeSplash);
    }

    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Auto-navigate based on auth state
        if (!authProvider.isAuthenticated &&
            _currentScreen != 'language' &&
            _currentScreen != 'onboarding' &&
            _currentScreen != 'auth') {
          Future.microtask(() => _navigateToScreen('auth'));
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          reverseDuration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          layoutBuilder: (currentChild, previousChildren) {
            return Stack(
              alignment: Alignment.center,
              children: <Widget>[
                ...previousChildren,
                if (currentChild != null) currentChild,
              ],
            );
          },
          transitionBuilder: (child, animation) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            final offset = Tween<Offset>(
              begin: const Offset(0, 0.025),
              end: Offset.zero,
            ).animate(curved);
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(position: offset, child: child),
            );
          },
          child: KeyedSubtree(
            key: ValueKey<String>(_currentScreen),
            child: _buildCurrentScreen(),
          ),
        );
      },
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentScreen) {
      case 'language':
        return LanguageSelectionScreen(
          onLanguageSelected: () => _navigateToScreen('onboarding'),
        );

      case 'onboarding':
        return OnboardingScreen(
          onComplete: _completeOnboarding,
        );

      case 'auth':
        return AuthScreen(
          onAuthenticated: _handlePostAuthNavigation,
        );

      case 'firstIntake':
        return FirstIntakeScreen(
          onComplete: () => _navigateToScreen('home'),
          onSkip: () => _navigateToScreen('home'),
        );

      case 'secondIntake':
        return SecondIntakeScreen(
          onComplete: () => _navigateToScreen('home'),
        );

      case 'home':
        return const HomeDashboardScreen();

      case 'workout':
        return const WorkoutScreen();

      case 'nutrition':
        return NutritionScreen(
          onBack: () => _navigateToScreen('home'),
          onOpenWorkout: () => _navigateToScreen('workout'),
        );

      case 'coach':
        return const CoachMessagingScreen();

      case 'store':
        return StoreScreen(
          onBack: () => _navigateToScreen('home'),
        );

      case 'account':
        return AccountScreen(
          onBack: () => _navigateToScreen('home'),
        );

      case 'coachDashboard':
        return const CoachDashboardScreen(
            // If CoachDashboardScreen has a parameter like 'onClose', use it instead:
            // onClose: () => _navigateToScreen('home'),
            // Otherwise, remove the parameter if not needed:
            );

      case 'adminDashboard':
        return const AdminDashboardScreen();

      default:
        return const HomeDashboardScreen();
    }
  }
}

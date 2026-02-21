import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
import 'presentation/widgets/animated_reveal.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  bool _showSplash = true;
  String _currentScreen = 'splash';
  int _transitionSeed = 0;

  @override
  void initState() {
    super.initState();
  }

  void _completeSplash() {
    final languageProvider = context.read<LanguageProvider>();
    final authProvider = context.read<AuthProvider>();

    setState(() {
      _showSplash = false;

      // Determine initial screen
      if (!languageProvider.hasSelectedLanguage) {
        _currentScreen = 'language';
      } else if (!authProvider.isAuthenticated) {
        _currentScreen = 'onboarding';
      } else {
        _currentScreen = _resolvePostAuthScreen(authProvider);
      }
      _transitionSeed++;
    });
  }

  String _resolvePostAuthScreen(AuthProvider authProvider) {
    final role = authProvider.user?.role.toLowerCase();
    if (role == 'coach') {
      return 'coachDashboard';
    }
    if (role == 'admin') {
      return 'adminDashboard';
    }
    if (authProvider.user != null && !authProvider.user!.hasCompletedFirstIntake) {
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
      _transitionSeed++;
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
          duration: const Duration(milliseconds: 700),
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
            final fade = Tween<double>(begin: 0, end: 1).animate(animation);
            return FadeTransition(opacity: fade, child: child);
          },
          child: KeyedSubtree(
            key: ValueKey<String>(_currentScreen),
            child: AnimatedReveal(
              key: ValueKey('reveal_${_currentScreen}_$_transitionSeed'),
              duration: const Duration(milliseconds: 700),
              offset: _offsetForScreen(_currentScreen),
              curve: Curves.easeOutCubic,
              child: _buildCurrentScreen(),
            ),
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
          onComplete: () => _navigateToScreen('auth'),
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

  Offset _offsetForScreen(String screen) {
    switch (screen) {
      case 'language':
      case 'account':
        return const Offset(0, 0.12);
      case 'onboarding':
      case 'store':
        return const Offset(0.15, 0);
      case 'auth':
      case 'coachDashboard':
        return const Offset(-0.15, 0);
      case 'firstIntake':
      case 'secondIntake':
        return const Offset(0, -0.15);
      case 'home':
      case 'workout':
        return const Offset(0.12, 0);
      case 'nutrition':
      case 'coach':
        return const Offset(-0.12, 0);
      case 'adminDashboard':
        return const Offset(0, -0.18);
      default:
        return const Offset(0, 0.1);
    }
  }
}

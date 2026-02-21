import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// ...existing code...
import 'app.dart';
import 'core/config/demo_mode.dart';
import 'core/config/theme_config.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/demo_mode_provider.dart';
import 'presentation/providers/user_provider.dart';
import 'presentation/providers/language_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/workout_provider.dart';
import 'presentation/providers/nutrition_provider.dart';
import 'presentation/providers/messaging_provider.dart';
import 'presentation/providers/quota_provider.dart';
import 'presentation/providers/coach_provider.dart';
import 'presentation/providers/admin_provider.dart';
import 'presentation/providers/video_call_provider.dart';
import 'presentation/providers/appointment_provider.dart';
import 'presentation/providers/store_provider.dart';
import 'presentation/providers/subscription_plan_provider.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/user_repository.dart';
import 'data/repositories/workout_repository.dart';
import 'data/repositories/nutrition_repository.dart';
import 'data/repositories/messaging_repository.dart';
import 'data/repositories/coach_repository.dart';
import 'data/repositories/admin_repository.dart';
import 'data/repositories/appointment_repository.dart';
import 'data/repositories/store_repository.dart';
import 'data/repositories/subscription_plan_repository.dart';
import 'data/demo/repositories/demo_workout_repository.dart';
import 'data/demo/repositories/demo_messaging_repository.dart';
import 'data/demo/repositories/demo_subscription_plan_repository.dart';
import 'data/demo/repositories/demo_metrics_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(const FitCoachApp());
}

class FitCoachApp extends StatelessWidget {
  const FitCoachApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<DemoModeConfig>(
          create: (_) => const DemoModeConfig(),
        ),
        ChangeNotifierProvider<DemoModeProvider>(
          create: (context) => DemoModeProvider(
            context.read<DemoModeConfig>(),
          ),
        ),

        // Demo repositories
        Provider<DemoWorkoutRepository>(
          create: (_) => DemoWorkoutRepository(),
        ),
        Provider<DemoMessagingRepository>(
          create: (_) => DemoMessagingRepository(),
        ),
        Provider<DemoSubscriptionPlanRepository>(
          create: (_) => DemoSubscriptionPlanRepository(),
        ),
        Provider<DemoMetricsRepository>(
          create: (_) => DemoMetricsRepository(),
        ),

        // Repositories
        Provider<AuthRepository>(
          create: (_) => AuthRepository(),
        ),
        Provider<UserRepository>(
          create: (_) => UserRepository(),
        ),
        Provider<WorkoutRepository>(
          create: (_) => WorkoutRepository(),
        ),
        Provider<NutritionRepository>(
          create: (_) => NutritionRepository(),
        ),
        Provider<MessagingRepository>(
          create: (_) => MessagingRepository(),
        ),
        Provider<CoachRepository>(
          create: (_) => CoachRepository(),
        ),
        Provider<AdminRepository>(
          create: (_) => AdminRepository(),
        ),
        Provider<AppointmentRepository>(
          create: (_) => AppointmentRepository(),
        ),
        Provider<StoreRepository>(
          create: (_) => StoreRepository(),
        ),
        Provider<SubscriptionPlanRepository>(
          create: (_) => SubscriptionPlanRepository(),
        ),
        
        // Providers
        ChangeNotifierProvider<LanguageProvider>(
          create: (_) => LanguageProvider(),
        ),
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),
        ChangeNotifierProxyProvider<AuthRepository, AuthProvider>(
          create: (context) => AuthProvider(
            context.read<AuthRepository>(),
          ),
          update: (context, authRepo, previous) =>
              previous ?? AuthProvider(authRepo),
        ),
        ChangeNotifierProxyProvider<AuthProvider, VideoCallProvider>(
          create: (_) => VideoCallProvider(),
          update: (_, authProvider, videoCallProvider) {
            final provider = videoCallProvider ?? VideoCallProvider();
            provider.setAuthToken(authProvider.token);
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<UserRepository, UserProvider>(
          create: (context) => UserProvider(
            context.read<UserRepository>(),
          ),
          update: (context, userRepo, previous) =>
              previous ?? UserProvider(userRepo),
        ),
        ChangeNotifierProxyProvider<WorkoutRepository, WorkoutProvider>(
          create: (context) => WorkoutProvider(
            context.read<WorkoutRepository>(),
            demoRepository: context.read<DemoWorkoutRepository>(),
            demoConfig: context.read<DemoModeConfig>(),
          ),
          update: (context, workoutRepo, previous) =>
              previous ??
              WorkoutProvider(
                workoutRepo,
                demoRepository: context.read<DemoWorkoutRepository>(),
                demoConfig: context.read<DemoModeConfig>(),
              ),
        ),
        ChangeNotifierProxyProvider<NutritionRepository, NutritionProvider>(
          create: (context) => NutritionProvider(
            context.read<NutritionRepository>(),
          ),
          update: (context, nutritionRepo, previous) =>
              previous ?? NutritionProvider(nutritionRepo),
        ),
        ChangeNotifierProxyProvider<MessagingRepository, MessagingProvider>(
          create: (context) => MessagingProvider(
            context.read<MessagingRepository>(),
            demoRepository: context.read<DemoMessagingRepository>(),
            demoConfig: context.read<DemoModeConfig>(),
          ),
          update: (context, messagingRepo, previous) =>
              previous ??
              MessagingProvider(
                messagingRepo,
                demoRepository: context.read<DemoMessagingRepository>(),
                demoConfig: context.read<DemoModeConfig>(),
              ),
        ),
        ChangeNotifierProxyProvider<UserRepository, QuotaProvider>(
          create: (context) => QuotaProvider(
            context.read<UserRepository>(),
          ),
          update: (context, userRepo, previous) =>
              previous ?? QuotaProvider(userRepo),
        ),
        ChangeNotifierProxyProvider<CoachRepository, CoachProvider>(
          create: (context) => CoachProvider(
            context.read<CoachRepository>(),
          ),
          update: (context, coachRepo, previous) =>
              previous ?? CoachProvider(coachRepo),
        ),
        ChangeNotifierProxyProvider<AdminRepository, AdminProvider>(
          create: (context) => AdminProvider(
            context.read<AdminRepository>(),
          ),
          update: (context, adminRepo, previous) =>
              previous ?? AdminProvider(adminRepo),
        ),
        ChangeNotifierProxyProvider<AppointmentRepository, AppointmentProvider>(
          create: (context) => AppointmentProvider(
            context.read<AppointmentRepository>(),
          ),
          update: (context, repo, previous) =>
              previous ?? AppointmentProvider(repo),
        ),
        ChangeNotifierProxyProvider<StoreRepository, StoreProvider>(
          create: (context) => StoreProvider(
            context.read<StoreRepository>(),
          ),
          update: (context, repo, previous) => previous ?? StoreProvider(repo),
        ),
        ChangeNotifierProxyProvider<SubscriptionPlanRepository, SubscriptionPlanProvider>(
          create: (context) => SubscriptionPlanProvider(
            context.read<SubscriptionPlanRepository>(),
            demoRepository: context.read<DemoSubscriptionPlanRepository>(),
            demoConfig: context.read<DemoModeConfig>(),
          ),
          update: (context, repo, previous) => previous ??
              SubscriptionPlanProvider(
                repo,
                demoRepository: context.read<DemoSubscriptionPlanRepository>(),
                demoConfig: context.read<DemoModeConfig>(),
              ),
        ),
      ],
      child: Consumer2<LanguageProvider, ThemeProvider>(
        builder: (context, languageProvider, themeProvider, _) {
          return MaterialApp(
            title: 'FitCoach+',
            debugShowCheckedModeBanner: false,
            
            // Localization
            locale: languageProvider.locale,
            supportedLocales: const [
              Locale('en', ''),
              Locale('ar', ''),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            
            // Theme
            theme: AppThemeConfig.getLightTheme(),
            darkTheme: AppThemeConfig.getDarkTheme(),
            themeMode: themeProvider.themeMode,
            
            // App
            home: const App(),
          );
        },
      ),
    );
  }
}

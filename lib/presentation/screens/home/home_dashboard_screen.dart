import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/config/demo_config.dart';
import '../../../core/constants/colors.dart';
import '../../providers/language_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/workout_provider.dart';
import '../../providers/nutrition_provider.dart';
import '../../providers/messaging_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/quota_provider.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/video_call_provider.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/aash_brand_mark.dart';
import '../../widgets/animated_reveal.dart';
import '../../widgets/custom_stat_info_card.dart';
import '../../widgets/quota_indicator.dart';
import '../../widgets/custom_button.dart';
import '../workout/workout_screen.dart';
import '../nutrition/nutrition_screen.dart';
import '../messaging/coach_messaging_screen.dart';
import '../store/store_screen.dart';
import '../account/account_screen.dart';
import '../coach/coach_dashboard_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../booking/video_booking_screen.dart';
import '../booking/appointment_detail_screen.dart';
import '../video_call/video_call_screen.dart';
import '../exercise/exercise_library_screen.dart';
import '../progress/progress_screen.dart';
import '../inbody/inbody_input_screen.dart';
import '../subscription/subscription_manager_screen.dart';
import '../settings/notification_settings_screen.dart';
import '../../../data/models/appointment.dart';
import '../../../core/theme/app_palette.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  int _selectedIndex = 0;
  String? _joiningAppointmentId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  Future<void> _loadData() async {
    final userProvider = context.read<UserProvider>();
    final workoutProvider = context.read<WorkoutProvider>();
    final nutritionProvider = context.read<NutritionProvider>();
    final quotaProvider = context.read<QuotaProvider>();
    final appointmentProvider = context.read<AppointmentProvider>();
    final authProvider = context.read<AuthProvider>();

    final futures = <Future<void>>[
      userProvider.loadProfile(),
      workoutProvider.loadActivePlan(),
      nutritionProvider.loadActivePlan(),
      nutritionProvider.checkTrialStatus(),
    ];
    final userId = authProvider.user?.id ?? userProvider.user?.id;
    if (userId != null && userId.isNotEmpty) {
      futures.add(quotaProvider.loadQuota(userId));
      futures.add(appointmentProvider.loadUserAppointments(
          userId: userId, refresh: true));
    }
    await Future.wait(futures);
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final isArabic = languageProvider.isArabic;
    final isFreemium =
        (context.watch<AuthProvider>().user?.subscriptionTier ?? 'Freemium') ==
            'Freemium';

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          TickerMode(
            enabled: _selectedIndex == 0,
            child: _buildHomeTab(languageProvider, isArabic),
          ),
          TickerMode(
            enabled: _selectedIndex == 1,
            child: _buildWorkoutTab(),
          ),
          TickerMode(
            enabled: _selectedIndex == 2,
            child: _buildNutritionTab(),
          ),
          TickerMode(
            enabled: _selectedIndex == 3,
            child: _buildCoachTab(),
          ),
          TickerMode(
            enabled: _selectedIndex == 4,
            child: _buildStoreTab(),
          ),
          TickerMode(
            enabled: _selectedIndex == 5,
            child: _buildAccountTab(),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(18, 0, 18, 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              decoration: BoxDecoration(
                color: context.palette.surface.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: context.palette.border),
                boxShadow: Theme.of(context).brightness == Brightness.dark
                    ? const []
                    : [
                        BoxShadow(
                          color:
                              context.palette.primary.withValues(alpha: 0.10),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  _buildFloatingNavItem(
                    context,
                    index: 0,
                    currentIndex: _selectedIndex,
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: languageProvider.t('home'),
                  ),
                  _buildFloatingNavItem(
                    context,
                    index: 1,
                    currentIndex: _selectedIndex,
                    icon: Icons.fitness_center_outlined,
                    activeIcon: Icons.fitness_center,
                    label: languageProvider.t('workout'),
                  ),
                  _buildFloatingNavItem(
                    context,
                    index: 2,
                    currentIndex: _selectedIndex,
                    icon: isFreemium
                        ? Icons.lock_outline
                        : Icons.restaurant_outlined,
                    activeIcon: isFreemium ? Icons.lock : Icons.restaurant,
                    label: languageProvider.t('nutrition'),
                  ),
                  _buildFloatingNavItem(
                    context,
                    index: 4,
                    currentIndex: _selectedIndex,
                    icon: Icons.shopping_bag_outlined,
                    activeIcon: Icons.shopping_bag,
                    label: languageProvider.t('store'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeTab(LanguageProvider lang, bool isArabic) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final tier = user?.subscriptionTier ?? 'Freemium';
    final tierLabel = _tierLabel(lang, tier);
    final firstName = (user?.name ?? lang.t('welcome')).split(' ').first;
    final fitnessScore = user?.fitnessScore ?? (DemoConfig.isDemo ? 72 : 0);
    final fitnessUpdatedBy = user?.fitnessScoreUpdatedBy;
    final appointmentProvider = context.watch<AppointmentProvider>();
    final nextSession = appointmentProvider.nextVideoCall;
    final isAppointmentsLoading =
        appointmentProvider.isLoading && !appointmentProvider.hasLoaded;

    final stats = DemoConfig.isDemo
        ? {
            'caloriesBurned': 2850,
            'caloriesConsumed': 1950,
            'planAdherence': 85,
            'weeklyProgress': 78,
            'workoutsCompleted': 12,
            'totalWorkouts': 14,
            'workoutMinutes': 240,
          }
        : {
            'caloriesBurned': 0,
            'caloriesConsumed': 0,
            'planAdherence': 0,
            'weeklyProgress': 0,
            'workoutsCompleted': 0,
            'totalWorkouts': 0,
            'workoutMinutes': 0,
          };

    return Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(color: context.palette.background),
        ),
        SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedReveal(
                    offset: Offset(isArabic ? 0.14 : -0.14, 0),
                    initialScale: 0.95,
                    child: _buildHomeHeader(
                      lang,
                      isArabic,
                      firstName,
                      tierLabel,
                      fitnessScore,
                      fitnessUpdatedBy,
                      stats,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedReveal(
                          delay: const Duration(milliseconds: 120),
                          offset: const Offset(0, 0.14),
                          initialScale: 0.96,
                          child: _buildHomeFeatureCarousel(lang, tier),
                        ),
                        const SizedBox(height: 16),
                        AnimatedReveal(
                          delay: const Duration(milliseconds: 160),
                          offset: const Offset(0, 0.14),
                          initialScale: 0.96,
                          child: _buildHomeShortcutGrid(lang, tier),
                        ),
                        const SizedBox(height: 16),
                        if (isAppointmentsLoading) ...[
                          AnimatedReveal(
                            delay: const Duration(milliseconds: 120),
                            offset: const Offset(0, 0.16),
                            initialScale: 0.94,
                            child: _buildNextSessionLoadingCard(lang),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (nextSession != null) ...[
                          AnimatedReveal(
                            delay: const Duration(milliseconds: 180),
                            offset: Offset(isArabic ? 0.18 : -0.18, 0),
                            initialScale: 0.94,
                            child: _buildNextSessionCardHome(
                              lang,
                              isArabic,
                              nextSession,
                              appointmentProvider,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (tier != 'Smart Premium') ...[
                          AnimatedReveal(
                            delay: const Duration(milliseconds: 240),
                            offset: const Offset(0, 0.14),
                            initialScale: 0.95,
                            child: _buildQuotaSection(lang, isArabic),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (DemoConfig.isDemo) const SizedBox(height: 16),
                        if (DemoConfig.isDemo)
                          AnimatedReveal(
                            delay: const Duration(milliseconds: 300),
                            offset: const Offset(0, 0.18),
                            initialScale: 0.95,
                            child: _buildRecentActivityCard(lang, isArabic),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHomeFeatureCarousel(LanguageProvider lang, String tier) {
    final isFreemium = tier == 'Freemium';
    final unreadMessages = context.watch<MessagingProvider>().totalUnread;
    final items = [
      _HomeFeature(
        label: lang.t('home_workouts'),
        imageAsset: 'assets/images/home/workout.jpg',
        icon: Icons.fitness_center_rounded,
        index: 1,
      ),
      _HomeFeature(
        label: lang.t('home_nutrition'),
        imageAsset: 'assets/images/home/nutrition.jpg',
        icon: Icons.restaurant_rounded,
        index: 2,
        locked: isFreemium,
      ),
      _HomeFeature(
        label: lang.t('home_coach'),
        imageAsset: 'assets/images/home/coach.jpg',
        icon: Icons.chat_bubble_outline_rounded,
        index: 3,
        badgeCount: unreadMessages,
      ),
      _HomeFeature(
        label: lang.t('home_store'),
        imageAsset: 'assets/images/home/store.jpg',
        icon: Icons.shopping_bag_outlined,
        index: 4,
      ),
    ];
    final cardWidth =
        (MediaQuery.of(context).size.width - 48).clamp(220.0, 300.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lang.t('home_explore_aash'),
          style: AppTextStyles.h4.copyWith(color: context.palette.textPrimary),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          key: const ValueKey('home-feature-carousel'),
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              for (final item in items)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 12),
                  child: SizedBox(
                    width: cardWidth.toDouble(),
                    height: 158,
                    child: _buildHomeFeatureCard(item, lang),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHomeShortcutGrid(LanguageProvider lang, String tier) {
    final shortcuts = [
      _HomeShortcut(
        label: lang.t('home_book_video_session'),
        imageAsset: 'assets/images/home/shortcuts/book-session.jpg',
        icon: Icons.videocam_rounded,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const VideoBookingScreen()),
        ),
      ),
      _HomeShortcut(
        label: lang.t('home_manage_subscription'),
        imageAsset: 'assets/images/home/shortcuts/subscription.jpg',
        icon: Icons.workspace_premium_rounded,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const SubscriptionManagerScreen(),
          ),
        ),
      ),
      _HomeShortcut(
        label: lang.t('home_view_progress'),
        imageAsset: 'assets/images/home/shortcuts/progress.jpg',
        icon: Icons.trending_up_rounded,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProgressScreen()),
        ),
      ),
      _HomeShortcut(
        label: lang.t('home_exercise_library'),
        imageAsset: 'assets/images/home/shortcuts/exercise-library.jpg',
        icon: Icons.fitness_center_rounded,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ExerciseLibraryScreen()),
        ),
      ),
      _HomeShortcut(
        label: lang.t('inbody_title'),
        imageAsset: 'assets/images/home/shortcuts/inbody.jpg',
        icon: Icons.monitor_heart_rounded,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => tier == 'Freemium'
                ? const SubscriptionManagerScreen()
                : const InBodyInputScreen(),
          ),
        ),
      ),
      _HomeShortcut(
        label: lang.t('home_supplements'),
        imageAsset: 'assets/images/home/shortcuts/supplements.jpg',
        icon: Icons.shopping_bag_rounded,
        onTap: () => setState(() => _selectedIndex = 4),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lang.t('home_quick_access'),
          style: AppTextStyles.h4.copyWith(color: context.palette.textPrimary),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          key: const ValueKey('home-shortcut-grid'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: shortcuts.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.45,
          ),
          itemBuilder: (context, index) =>
              _buildHomeShortcutCard(shortcuts[index]),
        ),
      ],
    );
  }

  Widget _buildHomeShortcutCard(_HomeShortcut shortcut) {
    const cardRadius = BorderRadius.all(Radius.circular(24));

    return Semantics(
      button: true,
      label: shortcut.label,
      child: Material(
        color: context.palette.surface,
        borderRadius: cardRadius,
        child: InkWell(
          onTap: shortcut.onTap,
          borderRadius: cardRadius,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: cardRadius,
              border: Border.all(color: context.palette.border),
              image: DecorationImage(
                image: AssetImage(shortcut.imageAsset),
                fit: BoxFit.cover,
              ),
            ),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                borderRadius: cardRadius,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x160A1424), Color(0xD90A1424)],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        shortcut.icon,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      shortcut.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeFeatureCard(_HomeFeature item, LanguageProvider lang) {
    const cardRadius = BorderRadius.all(Radius.circular(28));

    return Semantics(
      button: true,
      label: item.label,
      child: Material(
        color: context.palette.surface,
        borderRadius: cardRadius,
        child: InkWell(
          onTap: () => setState(() => _selectedIndex = item.index),
          borderRadius: cardRadius,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: cardRadius,
              border: Border.all(color: context.palette.border),
              image: DecorationImage(
                image: AssetImage(item.imageAsset),
                fit: BoxFit.cover,
              ),
            ),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                borderRadius: cardRadius,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x180A1424),
                    Color(0xA60A1424),
                    Color(0xE60A1424),
                  ],
                  stops: [0, 0.42, 1],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(item.icon, color: Colors.white, size: 20),
                        ),
                        const Spacer(),
                        if (item.locked)
                          _buildFeatureBadge(
                            icon: Icons.lock_outline,
                            label: lang.t('home_locked'),
                          )
                        else if (item.badgeCount > 0)
                          _buildFeatureBadge(
                            icon: Icons.mark_chat_unread_outlined,
                            label: '${item.badgeCount}',
                          ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.h3.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          lang.isArabic
                              ? Icons.arrow_back_rounded
                              : Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureBadge({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.36)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.captionMedium.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeHeader(
    LanguageProvider lang,
    bool isArabic,
    String firstName,
    String tierLabel,
    int fitnessScore,
    String? fitnessUpdatedBy,
    Map<String, int> stats,
  ) {
    final theme = Theme.of(context);
    final workoutMinutes = stats['workoutMinutes'] ?? 0;
    const streak = DemoConfig.isDemo ? 7 : 0;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(18, 8, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Semantics(
                button: true,
                label: lang.t('account'),
                child: InkWell(
                  onTap: () => setState(() => _selectedIndex = 5),
                  customBorder: const CircleBorder(),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: context.palette.surfaceVariant,
                    child: Text(
                      firstName.isEmpty
                          ? 'A'
                          : firstName.characters.first.toUpperCase(),
                      style: AppTextStyles.h4
                          .copyWith(color: context.palette.primary),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              const AashBrandMark(size: 48),
              const Spacer(),
              IconButton(
                tooltip: lang.t('account_tab_notifications'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NotificationSettingsScreen(),
                  ),
                ),
                icon: Icon(Icons.notifications_none_rounded,
                    color: context.palette.textPrimary),
              ),
              IconButton(
                tooltip: lang.t('account_tab_settings'),
                onPressed: () => context.read<ThemeProvider>().toggleTheme(),
                icon: Icon(
                  theme.brightness == Brightness.dark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  color: context.palette.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '${lang.t('home_hello')}, $firstName!',
                style: AppTextStyles.h2
                    .copyWith(color: context.palette.textPrimary),
              ),
              Container(
                padding: const EdgeInsetsDirectional.fromSTEB(10, 6, 10, 6),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border:
                      Border.all(color: AppColors.gold.withValues(alpha: 0.42)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_fire_department_rounded,
                        size: 16,
                        color: foregroundFor(Color.alphaBlend(
                          AppColors.gold.withValues(alpha: 0.14),
                          context.palette.surface,
                        ))),
                    const SizedBox(width: 5),
                    Text('$streak ${lang.t('progress_streak')}',
                        style: AppTextStyles.captionMedium.copyWith(
                          color: foregroundFor(Color.alphaBlend(
                            AppColors.gold.withValues(alpha: 0.14),
                            context.palette.surface,
                          )),
                        )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(lang.t('home_ready'),
              style: AppTextStyles.small
                  .copyWith(color: context.palette.textSecondary)),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.palette.surface,
              borderRadius: BorderRadius.circular(AppRadius.xlarge),
              border: Border.all(color: context.palette.border),
              boxShadow: theme.brightness == Brightness.dark
                  ? const []
                  : [
                      BoxShadow(
                        color: context.palette.primary.withValues(alpha: 0.055),
                        blurRadius: 20,
                        offset: const Offset(0, 7),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(lang.t('home_weekly_progress'),
                          style: AppTextStyles.h4
                              .copyWith(color: context.palette.textPrimary)),
                    ),
                    Container(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(10, 5, 10, 5),
                      decoration: BoxDecoration(
                        color: context.palette.surfaceVariant
                            .withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(tierLabel,
                          style: AppTextStyles.captionMedium
                              .copyWith(color: context.palette.textSecondary)),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _buildDashboardRing(
                        color: AppColors.cyan,
                        progress: ((stats['caloriesBurned'] ?? 0) / 2500)
                            .clamp(0, 1)
                            .toDouble(),
                        value: '${stats['caloriesBurned'] ?? 0}',
                        label: lang.t('home_calories_burned'),
                        unit: 'kcal',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDashboardRing(
                        color: AppColors.gold,
                        progress: (workoutMinutes / 300).clamp(0, 1).toDouble(),
                        value: '$workoutMinutes',
                        label: lang.t('home_this_week'),
                        unit: lang.t('home_duration_minutes',
                            args: {'minutes': ''}).trim(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(lang.t('home_fitness_score'),
                              style: AppTextStyles.caption.copyWith(
                                  color: context.palette.textSecondary)),
                          const SizedBox(height: 3),
                          Text('$fitnessScore / 100',
                              style: AppTextStyles.h4.copyWith(
                                  color: context.palette.textPrimary)),
                          Text(
                            fitnessUpdatedBy == 'coach'
                                ? lang.t('home_updated_by_coach')
                                : lang.t('home_auto_updated'),
                            style: AppTextStyles.caption
                                .copyWith(color: context.palette.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: lang.t('home_view_progress'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const ProgressScreen()),
                      ),
                      icon: Icon(
                        Icons.arrow_forward,
                        color: context.palette.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: (fitnessScore / 100).clamp(0, 1).toDouble(),
                    minHeight: 7,
                    backgroundColor: context.palette.surfaceVariant,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.cyan),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildCoachingQuickCheck(
                  icon: Icons.forum_outlined,
                  title: lang.t('home_coach'),
                  subtitle: lang.t('home_ready'),
                  badgeCount: context.watch<MessagingProvider>().totalUnread,
                  onTap: () => setState(() => _selectedIndex = 3),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildCoachingQuickCheck(
                  icon: Icons.event_available_outlined,
                  title: lang.t('home_todays_workout'),
                  subtitle:
                      '${stats['workoutsCompleted'] ?? 0}/${stats['totalWorkouts'] ?? 0} ${lang.t('home_this_week')}',
                  onTap: () => setState(() => _selectedIndex = 1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardRing({
    required Color color,
    required double progress,
    required String value,
    required String label,
    required String unit,
  }) {
    return Column(
      children: [
        SizedBox(
          width: 96,
          height: 96,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(value,
                        style: AppTextStyles.h3
                            .copyWith(color: context.palette.textPrimary)),
                  ),
                  Text(unit,
                      style: AppTextStyles.caption
                          .copyWith(color: context.palette.textSecondary)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.captionMedium
                .copyWith(color: context.palette.textSecondary)),
      ],
    );
  }

  Widget _buildCoachingQuickCheck({
    required IconData icon,
    required String title,
    required String subtitle,
    int badgeCount = 0,
    required VoidCallback onTap,
  }) {
    return Material(
      color: context.palette.surface,
      borderRadius: BorderRadius.circular(AppRadius.large),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.large),
        child: Container(
          constraints: const BoxConstraints(minHeight: 86),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.large),
            border: Border.all(color: context.palette.border),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                child: Badge.count(
                  count: badgeCount,
                  isLabelVisible: badgeCount > 0,
                  child: Icon(icon, color: AppColors.cyan, size: 19),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.captionMedium
                            .copyWith(color: context.palette.textPrimary)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption
                            .copyWith(color: context.palette.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingNavItem(
    BuildContext context, {
    required int index,
    required int currentIndex,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = currentIndex == index;
    final color =
        isSelected ? context.palette.primary : context.palette.textSecondary;
    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: () async {
            final tappedCurrentTab = index == _selectedIndex;
            setState(() => _selectedIndex = index);
            if (index == 1 && tappedCurrentTab) {
              final workoutProvider = context.read<WorkoutProvider>();
              await workoutProvider.loadActivePlan();
              await workoutProvider.loadWorkoutCalendar(silent: true);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 3),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(isSelected ? activeIcon : icon, color: color, size: 21),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label,
                      maxLines: 1,
                      style:
                          AppTextStyles.captionMedium.copyWith(color: color)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNextSessionLoadingCard(LanguageProvider lang) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // Light surface so text/icons stay clearly visible
        color: context.palette.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.palette.border),
      ),
      child: Row(
        children: [
          const CircularProgressIndicator(strokeWidth: 2),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              lang.t('home_loading_sessions'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextSessionCardHome(
    LanguageProvider lang,
    bool isArabic,
    Appointment appointment,
    AppointmentProvider provider,
  ) {
    final dateLabel = _formatHomeSessionDate(appointment, isArabic);
    final countdown = _formatHomeCountdown(appointment, lang);
    final canJoin = provider.canJoin(appointment);
    final isVideo = _homeIsVideoSession(appointment);
    final isJoining = _joiningAppointmentId == appointment.id;
    final joinHint = lang.t('home_join_available_hint');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // Keep strong gradient but soften a bit for readability
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang.t('home_next_session'),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textWhite.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            appointment.coachName ?? lang.t('coach'),
            style: AppTextStyles.h2.copyWith(color: AppColors.textWhite),
          ),
          const SizedBox(height: 8),
          Text(
            dateLabel,
            style: AppTextStyles.smallMedium.copyWith(
              color: AppColors.textWhite,
            ),
          ),
          if (countdown != null) ...[
            const SizedBox(height: 4),
            Text(
              countdown,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textWhite.withValues(alpha: 0.7),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: lang.t('join_video_call'),
                  onPressed: (isVideo && canJoin && !isJoining)
                      ? () => _joinAppointmentFromHome(appointment)
                      : null,
                  isLoading: isJoining,
                  size: ButtonSize.medium,
                  fullWidth: true,
                  variant: ButtonVariant.secondary,
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                style:
                    TextButton.styleFrom(foregroundColor: AppColors.textWhite),
                onPressed: () => _openAppointmentDetailsFromHome(appointment),
                child: Text(lang.t('details')),
              ),
            ],
          ),
          if (!canJoin && isVideo)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                joinHint,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textWhite.withValues(alpha: 0.7),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatHomeSessionDate(Appointment appointment, bool isArabic) {
    final locale = isArabic ? 'ar' : 'en';
    try {
      final date = DateTime.parse(appointment.scheduledAt);
      return DateFormat('EEE, MMM d \u2022 h:mm a', locale).format(date);
    } catch (_) {
      return appointment.scheduledAt;
    }
  }

  String? _formatHomeCountdown(Appointment appointment, LanguageProvider lang) {
    try {
      final date = DateTime.parse(appointment.scheduledAt);
      final diff = date.difference(DateTime.now());
      if (diff.isNegative) return null;
      final hours = diff.inHours;
      final minutes = diff.inMinutes.remainder(60);
      if (hours <= 0 && minutes <= 0) {
        return lang.t('home_starting_now');
      }
      if (hours <= 0) {
        return lang.t('home_starts_in_minutes', args: {
          'minutes': '$minutes',
        });
      }
      if (minutes > 0) {
        return lang.t('home_starts_in_hours_minutes', args: {
          'hours': '$hours',
          'minutes': '$minutes',
        });
      }
      return lang.t('home_starts_in_hours', args: {
        'hours': '$hours',
      });
    } catch (_) {
      return null;
    }
  }

  bool _homeIsVideoSession(Appointment appointment) {
    final type = (appointment.type ?? 'video').toLowerCase();
    return type == 'video';
  }

  // ignore: unused_element
  Widget _buildTodayWorkoutCard(
    LanguageProvider lang,
    bool isArabic,
    Map<String, dynamic> workout,
  ) {
    final durationMinutes = workout['durationMinutes'] as int? ?? 0;
    final durationLabel = lang.t('home_duration_minutes', args: {
      'minutes': '$durationMinutes',
    });
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                lang.t('home_todays_workout'),
                style: AppTextStyles.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.palette.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 12, color: context.palette.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      lang.t('home_today'),
                      style: AppTextStyles.small
                          .copyWith(color: context.palette.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            workout['name'] as String,
            style: AppTextStyles.bodyMedium
                .copyWith(color: context.palette.textPrimary),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                durationLabel,
                style: AppTextStyles.small
                    .copyWith(color: context.palette.textSecondary),
              ),
              const SizedBox(width: 8),
              Text(
                '\u2022',
                style: AppTextStyles.small
                    .copyWith(color: context.palette.textSecondary),
              ),
              const SizedBox(width: 8),
              Text(
                '${workout['exercises']} ${lang.t('home_exercises')}',
                style: AppTextStyles.small
                    .copyWith(color: context.palette.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.secondaryForeground,
                    AppColors.primaryDark
                  ],
                  begin: AlignmentDirectional.centerStart,
                  end: AlignmentDirectional.centerEnd,
                ),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _selectedIndex = 1),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.fitness_center,
                          size: 16, color: AppColors.textWhite),
                      const SizedBox(width: 6),
                      Text(
                        lang.t('home_start_workout'),
                        style: const TextStyle(
                          color: AppColors.textWhite,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildNavigationGridCompact(
      LanguageProvider lang, bool isArabic, String tier) {
    final isFreemium = tier == 'Freemium';
    final items = [
      _HomeNavItem(
        label: lang.t('home_workouts'),
        description: lang.t('home_workouts_desc'),
        icon: Icons.fitness_center,
        color: context.palette.primary,
        index: 1,
        background: context.palette.primary.withValues(alpha: 0.12),
      ),
      _HomeNavItem(
        label: lang.t('home_nutrition'),
        description: lang.t('home_nutrition_desc'),
        icon: Icons.restaurant,
        color: AppColors.chart4,
        index: 2,
        locked: isFreemium,
        lockedLabel: lang.t('home_tap_to_upgrade'),
        background: AppColors.chart4.withValues(alpha: 0.12),
      ),
      _HomeNavItem(
        label: lang.t('home_coach'),
        description: lang.t('home_coach_desc'),
        icon: Icons.chat_bubble_outline,
        color: AppColors.accent,
        index: 3,
        // Was a hardcoded demo '1'. The real count now comes from the same
        // source as the nav badge, so the two cannot disagree.
        badge: context.watch<MessagingProvider>().totalUnread > 0
            ? '${context.watch<MessagingProvider>().totalUnread}'
            : null,
        background: AppColors.accent.withValues(alpha: 0.12),
      ),
      _HomeNavItem(
        label: lang.t('home_store'),
        description: lang.t('home_store_desc'),
        icon: Icons.shopping_bag_outlined,
        color: AppColors.primaryLight,
        index: 4,
        background: AppColors.primaryLight.withValues(alpha: 0.12),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: items.map(_buildNavigationCardCompact).toList(),
    );
  }

  Widget _buildNavigationCardCompact(_HomeNavItem item) {
    return InkWell(
      // A locked feature used to answer in two different ways: this card
      // jumped straight to the plan picker, while the same feature's nav tab
      // opened its in-screen locked state. Both now land on the locked state,
      // which sells the feature before asking for money and keeps one answer.
      onTap: () => setState(() => _selectedIndex = item.index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: item.locked
              ? AppColors.accent.withValues(alpha: 0.12)
              : item.background ?? context.palette.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: item.locked
                ? AppColors.accent.withValues(alpha: 0.35)
                : context.palette.border,
            width: item.locked ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: item.color,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    item.icon,
                    color: foregroundFor(item.color),
                    size: 22,
                  ),
                ),
                if (item.locked)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.workspace_premium,
                        color: foregroundFor(AppColors.accent),
                        size: 22,
                      ),
                    ),
                  ),
                if (item.badge != null)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      constraints:
                          const BoxConstraints(minWidth: 20, minHeight: 20),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        item.badge!,
                        style: AppTextStyles.overline.copyWith(
                          color: foregroundFor(AppColors.error),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.label,
              style: AppTextStyles.smallMedium.copyWith(
                color: context.palette.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              item.description,
              style: AppTextStyles.caption.copyWith(
                color: context.palette.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (item.locked) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.lockedLabel,
                  style: AppTextStyles.overline.copyWith(
                    color: context.palette.textPrimary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityCard(LanguageProvider lang, bool isArabic) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up,
                  size: 18, color: context.palette.textPrimary),
              const SizedBox(width: 8),
              Text(
                lang.t('home_recent_activity'),
                style: AppTextStyles.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildActivityRow(
            title: lang.t('home_completed_push_day'),
            subtitle: lang.t('home_hours_ago'),
            badge: lang.t('home_calories_badge', args: {'calories': '250'}),
            color: AppColors.chart4,
          ),
          const SizedBox(height: 8),
          _buildActivityRow(
            title: lang.t('home_message_from_coach'),
            subtitle: lang.t('home_day_ago'),
            badge: lang.t('home_new'),
            color: context.palette.primary,
          ),
          const SizedBox(height: 8),
          _buildActivityRow(
            title: lang.t('home_weekly_progress_updated'),
            subtitle: lang.t('home_days_ago'),
            color: AppColors.secondaryForeground,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityRow({
    required String title,
    required String subtitle,
    String? badge,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.smallMedium),
              Text(subtitle,
                  style: AppTextStyles.small
                      .copyWith(color: context.palette.textSecondary)),
            ],
          ),
        ),
        if (badge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: context.palette.surfaceVariant,
            ),
            child: Text(badge,
                style: AppTextStyles.small
                    .copyWith(color: context.palette.textSecondary)),
          ),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildUpgradeCard(LanguageProvider lang, bool isArabic) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [context.palette.surface, context.palette.surfaceVariant],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.palette.border),
      ),
      child: Column(
        children: [
          Icon(Icons.workspace_premium,
              color: context.palette.primary, size: 26),
          const SizedBox(height: 8),
          Text(
            lang.t('home_unlock_premium'),
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: context.palette.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            lang.t('home_premium_desc'),
            style: AppTextStyles.small
                .copyWith(color: context.palette.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const SubscriptionManagerScreen()),
              ),
              icon: const Icon(Icons.star, size: 14),
              label: Text(lang.t('home_upgrade_now')),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.palette.primary,
                foregroundColor: context.palette.textOnBrand,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildHeroHeader(LanguageProvider lang, bool isArabic) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    final name = user?.name ?? lang.t('welcome');
    final firstName = name.split(' ').first;
    final tier = user?.subscriptionTier ?? 'Freemium';
    final tierLabel = _tierLabel(lang, tier);
    final fitnessScore = user?.fitnessScore ?? (DemoConfig.isDemo ? 72 : 0);
    final fitnessUpdatedBy = user?.fitnessScoreUpdatedBy;
    const caloriesBurned = DemoConfig.isDemo ? 2850 : 0;
    const caloriesConsumed = DemoConfig.isDemo ? 1950 : 0;
    const workoutsCompleted = DemoConfig.isDemo ? 12 : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.headerGradientStart, AppColors.headerGradientEnd],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${lang.t('home_hello')}, $firstName!',
                      style:
                          AppTextStyles.h3.copyWith(color: AppColors.textWhite),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lang.t('home_ready'),
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.textWhite.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.textWhite.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tierLabel,
                  style: AppTextStyles.smallMedium
                      .copyWith(color: AppColors.textWhite),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: lang.t('account'),
                icon: const Icon(Icons.person_outline,
                    color: AppColors.textWhite),
                onPressed: () => setState(() => _selectedIndex = 5),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.textWhite.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang.t('home_fitness_score'),
                            style: AppTextStyles.small.copyWith(
                              color: AppColors.textWhite.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            fitnessUpdatedBy == 'coach'
                                ? lang.t('home_updated_by_coach')
                                : lang.t('home_auto_updated'),
                            style: AppTextStyles.small.copyWith(
                              color:
                                  AppColors.textWhite.withValues(alpha: 0.54),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          '$fitnessScore',
                          style: AppTextStyles.h2
                              .copyWith(color: AppColors.textWhite),
                        ),
                        Text(
                          '/100',
                          style: AppTextStyles.small.copyWith(
                            color: AppColors.textWhite.withValues(alpha: 0.54),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: fitnessScore / 100,
                    minHeight: 6,
                    backgroundColor: AppColors.textWhite.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.textWhite),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildHeroStat(
                  icon: Icons.local_fire_department,
                  value: '$caloriesBurned',
                  label: lang.t('home_calories_burned'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildHeroStat(
                  icon: Icons.fitness_center,
                  value: '$workoutsCompleted',
                  label: lang.t('home_workouts_completed'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildHeroStat(
                  icon: Icons.local_dining,
                  value: '$caloriesConsumed',
                  label: lang.t('home_calories_consumed'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.textWhite.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textWhite, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style:
                AppTextStyles.bodyMedium.copyWith(color: AppColors.textWhite),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.small.copyWith(
              color: AppColors.textWhite.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildNavigationGrid(LanguageProvider lang, bool isArabic) {
    final authProvider = context.watch<AuthProvider>();
    final tier = authProvider.user?.subscriptionTier ?? 'Freemium';
    final isFreemium = tier == 'Freemium';

    final items = [
      _HomeNavItem(
        label: lang.t('home_workouts'),
        description: lang.t('home_workouts_desc'),
        icon: Icons.fitness_center,
        color: context.palette.primary,
        index: 1,
      ),
      _HomeNavItem(
        label: lang.t('home_nutrition'),
        description: lang.t('home_nutrition_desc'),
        icon: Icons.restaurant,
        color: AppColors.accent,
        index: 2,
        locked: isFreemium,
        lockedLabel: lang.t('home_locked'),
      ),
      _HomeNavItem(
        label: lang.t('home_coach'),
        description: lang.t('home_coach_desc'),
        icon: Icons.chat_bubble_outline,
        color: AppColors.secondaryForeground,
        index: 3,
      ),
      _HomeNavItem(
        label: lang.t('home_store'),
        description: lang.t('home_store_desc'),
        icon: Icons.shopping_bag_outlined,
        color: AppColors.accent,
        index: 4,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lang.t('home_quick_access'),
          style: AppTextStyles.h4.copyWith(color: context.palette.textPrimary),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: items.map(_buildNavigationCard).toList(),
        ),
      ],
    );
  }

  Widget _buildNavigationCard(_HomeNavItem item) {
    return InkWell(
      onTap: item.locked
          ? null
          : () => setState(() => _selectedIndex = item.index),
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.palette.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(color: context.palette.border),
          boxShadow: [
            BoxShadow(
              color: context.palette.textPrimary.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, color: item.color, size: 18),
                ),
                const SizedBox(height: 12),
                Text(
                  item.label,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: context.palette.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: AppTextStyles.small
                      .copyWith(color: context.palette.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            if (item.locked)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.lockedLabel,
                    style: AppTextStyles.small.copyWith(color: AppColors.error),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _tierLabel(LanguageProvider lang, String tier) {
    switch (tier) {
      case 'Smart Premium':
        return lang.t('tier_smart_premium');
      case 'Premium':
        return lang.t('tier_premium');
      case 'Freemium':
        return lang.t('tier_freemium');
      default:
        return tier;
    }
  }

  // ignore: unused_element
  Widget _buildSubscriptionBadge(LanguageProvider lang, bool isArabic) {
    final authProvider = context.watch<AuthProvider>();
    final tier = authProvider.user?.subscriptionTier ?? 'Freemium';
    final tierLabel = _tierLabel(lang, tier);

    Color getColor() {
      switch (tier) {
        case 'Premium':
          return AppColors.surfaceDarkRaised;
        case 'Smart Premium':
          return AppColors.accent;
        default:
          return context.palette.textDisabled;
      }
    }

    IconData getIcon() {
      switch (tier) {
        case 'Smart Premium':
          return Icons.auto_awesome;
        case 'Premium':
          return Icons.star;
        default:
          return Icons.person;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [getColor(), getColor().withValues(alpha: 0.7)],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            getIcon(),
            color: foregroundFor(getColor()),
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tierLabel,
                  style: AppTextStyles.h2.copyWith(
                    color: foregroundFor(getColor()),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lang.t('current_plan'),
                  style: AppTextStyles.small.copyWith(
                    color: foregroundFor(getColor()).withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          if (tier != 'Smart Premium')
            OutlinedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SubscriptionManagerScreen(),
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: foregroundFor(getColor()),
                side: BorderSide(color: foregroundFor(getColor())),
              ),
              child: Text(lang.t('upgrade')),
            ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildQuickStats(LanguageProvider lang, bool isArabic) {
    return Row(
      children: [
        Expanded(
          child: CustomStatCard(
            title: lang.t('day_streak'),
            value: '7',
            icon: Icons.local_fire_department,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: CustomStatCard(
            title: lang.t('workouts'),
            value: '24',
            icon: Icons.fitness_center,
            color: context.palette.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: CustomStatCard(
            title: lang.t('calories'),
            value: '1.8k',
            icon: Icons.local_fire_department_outlined,
            color: context.palette.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildQuotaSection(LanguageProvider lang, bool isArabic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lang.t('monthly_quota'),
          style: AppTextStyles.h3.copyWith(color: context.palette.textPrimary),
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            Expanded(
              child: QuotaIndicator(
                type: 'message',
                showDetails: true,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: QuotaIndicator(
                type: 'videoCall',
                showDetails: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildTodayWorkout(LanguageProvider lang, bool isArabic) {
    final workoutProvider = context.watch<WorkoutProvider>();
    final currentDay = workoutProvider.currentDay;
    final dayLabel = isArabic
        ? currentDay?.dayNameAr ?? currentDay?.dayName ?? lang.t('chest_day')
        : currentDay?.dayName ?? lang.t('chest_day');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lang.t('todays_workout'),
          style: AppTextStyles.h3.copyWith(color: context.palette.textPrimary),
        ),
        const SizedBox(height: 12),
        CustomCard(
          onTap: () {
            setState(() => _selectedIndex = 1);
          },
          child: workoutProvider.activePlan != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color:
                                context.palette.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.fitness_center,
                            color: context.palette.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dayLabel,
                                style: AppTextStyles.h4,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${workoutProvider.currentDay?.exercises.length ?? 8} ${lang.t('exercises')}',
                                style: AppTextStyles.small.copyWith(
                                  color: context.palette.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: context.palette.textDisabled,
                        ),
                      ],
                    ),
                  ],
                )
              : Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.fitness_center_outlined,
                        size: 48,
                        color: context.palette.textDisabled,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        lang.t('no_active_workout_plan'),
                        style: TextStyle(
                          color: context.palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildTodayNutrition(LanguageProvider lang, bool isArabic) {
    final nutritionProvider = context.watch<NutritionProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lang.t('todays_nutrition'),
          style: AppTextStyles.h3.copyWith(color: context.palette.textPrimary),
        ),
        const SizedBox(height: 12),
        CustomCard(
          onTap: () {
            setState(() => _selectedIndex = 2);
          },
          child: nutritionProvider.activePlan != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color:
                                context.palette.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.restaurant,
                            color: context.palette.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${nutritionProvider.activePlan?.dailyCalories ?? 2000} ${lang.t('calories')}',
                                style: AppTextStyles.h4,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '4 ${lang.t('meals')}',
                                style: AppTextStyles.small.copyWith(
                                  color: context.palette.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: context.palette.textDisabled,
                        ),
                      ],
                    ),
                  ],
                )
              : Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.restaurant_outlined,
                        size: 48,
                        color: context.palette.textDisabled,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        lang.t('no_active_nutrition_plan'),
                        style: TextStyle(
                          color: context.palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildQuickActions(LanguageProvider lang, bool isArabic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lang.t('quick_actions'),
          style: AppTextStyles.h3.copyWith(color: context.palette.textPrimary),
        ),
        const SizedBox(height: 12),
        CustomInfoCard(
          title: lang.t('message_coach'),
          subtitle: lang.t('connect_with_coach'),
          icon: Icons.chat_bubble_outline,
          iconColor: context.palette.primary,
          onTap: () {
            setState(() => _selectedIndex = 3);
          },
        ),
        const SizedBox(height: 12),
        CustomInfoCard(
          title: lang.t('your_progress'),
          subtitle: lang.t('view_achievements'),
          icon: Icons.trending_up,
          iconColor: context.palette.primary,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProgressScreen()),
          ),
        ),
        const SizedBox(height: 12),
        CustomInfoCard(
          title: lang.t('store'),
          subtitle: lang.t('shop_products'),
          icon: Icons.shopping_bag_outlined,
          iconColor: AppColors.accent,
          onTap: () {
            setState(() => _selectedIndex = 4);
          },
        ),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildDemoModeSection(LanguageProvider lang) {
    final authProvider = context.watch<AuthProvider>();
    final role = authProvider.user?.role ?? 'user';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lang.t('home_demo_mode'),
          style: AppTextStyles.h3.copyWith(color: context.palette.textPrimary),
        ),
        const SizedBox(height: 12),
        CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lang.t('home_demo_mode_desc'),
                style: AppTextStyles.small.copyWith(
                  color: context.palette.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: Text(lang.t('home_role_user')),
                    selected: role == 'user',
                    onSelected: (_) => authProvider.setDemoRole('user'),
                  ),
                  ChoiceChip(
                    label: Text(lang.t('home_role_coach')),
                    selected: role == 'coach',
                    onSelected: (_) => authProvider.setDemoRole('coach'),
                  ),
                  ChoiceChip(
                    label: Text(lang.t('home_role_admin')),
                    selected: role == 'admin',
                    onSelected: (_) => authProvider.setDemoRole('admin'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CoachDashboardScreen(),
                          ),
                        );
                      },
                      child: Text(lang.t('home_coach_dashboard')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AdminDashboardScreen(),
                          ),
                        );
                      },
                      child: Text(lang.t('home_admin_dashboard')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openAppointmentDetailsFromHome(Appointment appointment) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AppointmentDetailScreen(appointment: appointment),
      ),
    );
  }

  Future<void> _joinAppointmentFromHome(Appointment appointment) async {
    final videoCallProvider = context.read<VideoCallProvider>();
    final languageProvider = context.read<LanguageProvider>();

    setState(() => _joiningAppointmentId = appointment.id);

    try {
      final result = await videoCallProvider.canJoinCall(appointment.id);
      if (result == null || result['canJoin'] != true) {
        final message =
            result?['reason'] ?? languageProvider.t('cannot_join_call');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
        return;
      }

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VideoCallScreen(
            appointmentId: appointment.id,
            coachId: appointment.coachId,
            coachName: appointment.coachName ?? languageProvider.t('coach'),
            isCoach: false,
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(languageProvider.t('error'))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _joiningAppointmentId = null);
      }
    }
  }

  Widget _buildWorkoutTab() {
    return WorkoutScreen(
      isActive: _selectedIndex == 1,
      onBack: () => setState(() => _selectedIndex = 0),
    );
  }

  Widget _buildNutritionTab() {
    return NutritionScreen(
      onBack: () => setState(() => _selectedIndex = 0),
      onOpenWorkout: () => setState(() => _selectedIndex = 1),
    );
  }

  Widget _buildCoachTab() {
    return const CoachMessagingScreen();
  }

  Widget _buildStoreTab() {
    return StoreScreen(
      onBack: () => setState(() => _selectedIndex = 0),
    );
  }

  Widget _buildAccountTab() {
    return AccountScreen(
      onBack: () => setState(() => _selectedIndex = 0),
    );
  }
}

class _HomeFeature {
  final String label;
  final String imageAsset;
  final IconData icon;
  final int index;
  final bool locked;
  final int badgeCount;

  const _HomeFeature({
    required this.label,
    required this.imageAsset,
    required this.icon,
    required this.index,
    this.locked = false,
    this.badgeCount = 0,
  });
}

class _HomeShortcut {
  final String label;
  final String imageAsset;
  final IconData icon;
  final VoidCallback onTap;

  const _HomeShortcut({
    required this.label,
    required this.imageAsset,
    required this.icon,
    required this.onTap,
  });
}

class _HomeNavItem {
  final String label;
  final String description;
  final IconData icon;
  final Color color;
  final Color? background;
  final int index;
  final bool locked;
  final String lockedLabel;
  final String? badge;

  const _HomeNavItem({
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
    this.background,
    required this.index,
    this.locked = false,
    this.lockedLabel = '',
    this.badge,
  });
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'dart:convert';
import '../../../core/config/demo_config.dart';
import '../../../core/constants/colors.dart';
import '../../../data/models/nutrition_plan.dart';
import '../../providers/language_provider.dart';
import '../../providers/nutrition_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_card.dart';
import 'nutrition_intro_screen.dart';
import 'nutrition_preferences_intake_screen.dart';
import '../../../data/repositories/nutrition_repository.dart';
import '../subscription/subscription_manager_screen.dart';

class NutritionScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const NutritionScreen({super.key, this.onBack});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  bool _showIntro = false;
  bool _introLoaded = false;
  bool _showPreferencesIntake = false;
  bool _preferencesLoaded = false;

  Future<void> _handleBack() async {
    final didPop = await Navigator.of(context).maybePop();
    if (!didPop) {
      widget.onBack?.call();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadIntroFlag();
    _loadPreferencesFlag();
    Future.microtask(() {
      final provider = context.read<NutritionProvider>();
      provider.loadActivePlan();
      provider.checkTrialStatus();
    });
  }

  Future<void> _loadIntroFlag() async {
    final prefs = await SharedPreferences.getInstance();
    final seenIntro = prefs.getBool('nutrition_intro_seen') ?? false;
    if (mounted) {
      setState(() {
        _showIntro = !seenIntro;
        _introLoaded = true;
      });
    }
  }

  Future<void> _completeIntro() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('nutrition_intro_seen', true);
    if (mounted) {
      setState(() {
        _showIntro = false;
      });
    }
  }

  Future<void> _loadPreferencesFlag() async {
    final prefs = await SharedPreferences.getInstance();
    final authUserId = context.read<AuthProvider>().user?.id;
    final userId = authUserId ?? (DemoConfig.isDemo ? DemoConfig.demoUserId : null);
    if (userId == null) {
      if (mounted) {
        setState(() {
          _showPreferencesIntake = false;
          _preferencesLoaded = true;
        });
      }
      return;
    }
    final pendingKey = 'pending_nutrition_intake_$userId';
    final completedKey = 'nutrition_preferences_completed_$userId';
    final pending = prefs.getBool(pendingKey) ?? false;
    final completed = prefs.getBool(completedKey) ?? false;

    if (mounted) {
      setState(() {
        _showPreferencesIntake = pending || !completed;
        _preferencesLoaded = true;
      });
    }
  }

  Future<void> _completePreferences(Map<String, dynamic> preferences) async {
    final prefs = await SharedPreferences.getInstance();
    final authUserId = context.read<AuthProvider>().user?.id;
    final userId = authUserId ?? (DemoConfig.isDemo ? DemoConfig.demoUserId : null);
    if (userId == null) return;
    final pendingKey = 'pending_nutrition_intake_$userId';
    final completedKey = 'nutrition_preferences_completed_$userId';
    final prefsKey = 'nutrition_preferences_$userId';
    await prefs.setString(prefsKey, jsonEncode(preferences));
    await prefs.setBool(completedKey, true);
    await prefs.setBool(pendingKey, false);
    if (!DemoConfig.isDemo) {
      final repository = NutritionRepository();
      await repository.generatePlan(preferences);
      if (mounted) {
        final provider = context.read<NutritionProvider>();
        await provider.loadActivePlan();
      }
    }
    if (mounted) {
      setState(() {
        _showPreferencesIntake = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final nutritionProvider = context.watch<NutritionProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isArabic = languageProvider.isArabic;
    final subscriptionTier = authProvider.user?.subscriptionTier ?? 'Freemium';

    if (!_introLoaded || !_preferencesLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_showIntro) {
      return NutritionIntroScreen(onGetStarted: _completeIntro);
    }
    
    // Check access
    final canAccess = nutritionProvider.canAccessNutrition(subscriptionTier);

    if (nutritionProvider.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // Locked for non-premium tiers
    if (!canAccess) {
      return _buildLockedAccess(languageProvider, isArabic);
    }

    if (_showPreferencesIntake) {
      return NutritionPreferencesIntakeScreen(
        onComplete: _completePreferences,
        onBack: () => setState(() => _showPreferencesIntake = false),
      );
    }
    
    if (nutritionProvider.activePlan == null) {
      return _buildNoPlan(languageProvider, isArabic);
    }
    
    final macroTargets = nutritionProvider.macroTargets;
    final currentMacros = nutritionProvider.getCurrentMacros();
    final calorieProgress = (currentMacros['calories'] as num) /
        ((macroTargets['calories'] as num) == 0 ? 1 : (macroTargets['calories'] as num));

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.8,
                child: Image.asset(
                  'assets/placeholders/splash_onboarding/nuitration_onboarding.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF059669), Color(0xFF0F766E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => _handleBack(),
                              icon: Icon(
                                isArabic ? Icons.arrow_forward : Icons.arrow_back,
                                color: Colors.white,
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    languageProvider.t('nutrition_title'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    languageProvider.t('nutrition_tracking'),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.settings, color: Colors.white),
                              onPressed: () => setState(() => _showPreferencesIntake = true),
                              tooltip: languageProvider.t('nutrition_edit_preferences'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    languageProvider.t('nutrition_todays_progress'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${(calorieProgress * 100).clamp(0, 100).round()}%',
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '${currentMacros['calories']?.toInt() ?? 0} / ${macroTargets['calories']}',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: calorieProgress.clamp(0, 1).toDouble(),
                                  minHeight: 6,
                                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TabBar(
                        labelColor: AppColors.textPrimary,
                        unselectedLabelColor: AppColors.textSecondary,
                        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        indicator: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        tabs: [
                          Tab(text: languageProvider.t('nutrition_tab_today')),
                          Tab(text: languageProvider.t('nutrition_tab_meals')),
                          Tab(text: languageProvider.t('nutrition_tab_tracking')),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildTodayTab(languageProvider, nutritionProvider, isArabic),
                        _buildMealsTab(languageProvider, nutritionProvider, isArabic),
                        _buildTrackingTab(languageProvider, nutritionProvider, isArabic),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildTodayTab(
    LanguageProvider lang,
    NutritionProvider provider,
    bool isArabic,
  ) {
    final meals = provider.dayPlans.isNotEmpty
        ? provider.getMealsForToday()
        : (provider.activePlan?.meals ?? <Meal>[]);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMacroBreakdownGrid(lang, provider),
          const SizedBox(height: 20),
          Text(
            lang.t('todays_meals'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...(meals.map(
            (meal) => _buildMealCard(
              meal,
              lang,
              isArabic,
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildMealsTab(
    LanguageProvider lang,
    NutritionProvider provider,
    bool isArabic,
  ) {
    final plan = provider.activePlan;
    final dayPlans = provider.dayPlans;
    final todayDayNumber = provider.getTodayDayNumber();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dayPlans.isNotEmpty ? lang.t('nutrition_week_plan') : lang.t('todays_meals'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (plan == null)
            const SizedBox.shrink()
          else if (dayPlans.isEmpty)
            ...((plan.meals ?? const <Meal>[]).map(
              (meal) => _buildMealCard(
                meal,
                lang,
                isArabic,
              ),
            ))
          else
            ...dayPlans.map(
              (dayPlan) => CustomCard(
                margin: const EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.zero,
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    initiallyExpanded: dayPlan.dayNumber == todayDayNumber,
                    title: Text(
                      lang.t(
                        'nutrition_day_number',
                        args: {'number': dayPlan.dayNumber.toString()},
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    children: [
                      for (final meal in dayPlan.meals)
                        _buildMealCard(
                          meal,
                          lang,
                          isArabic,
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTrackingTab(
    LanguageProvider lang,
    NutritionProvider provider,
    bool isArabic,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMacroProgress(provider.activePlan!, lang, isArabic),
          const SizedBox(height: 20),
          _buildCalorieCounter(provider.activePlan!, lang, isArabic),
        ],
      ),
    );
  }

  Widget _buildMacroBreakdownGrid(LanguageProvider lang, NutritionProvider provider) {
    final targets = provider.macroTargets;
    final current = provider.getCurrentMacros();

    Widget buildCard(IconData icon, Color color, String label, int value, int target) {
      final progress = target == 0 ? 0.0 : (value / target).clamp(0, 1).toDouble();
      return CustomCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text('$value', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: AppColors.surface,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ],
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        buildCard(
          Icons.egg_alt,
          const Color(0xFFEF4444),
          lang.t('protein'),
          (current['protein'] as num).toInt(),
          (targets['protein'] as num).toInt(),
        ),
        buildCard(
          Icons.grass,
          const Color(0xFFF59E0B),
          lang.t('carbs'),
          (current['carbs'] as num).toInt(),
          (targets['carbs'] as num).toInt(),
        ),
        buildCard(
          Icons.opacity,
          const Color(0xFF3B82F6),
          lang.t('fats'),
          (current['fat'] as num).toInt(),
          (targets['fat'] as num).toInt(),
        ),
        buildCard(
          Icons.water_drop,
          const Color(0xFF06B6D4),
          lang.t('nutrition_water'),
          (current['water'] as num?)?.toInt() ?? 0,
          (targets['water'] as num?)?.toInt() ?? 3000,
        ),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildTrialBanner(
    NutritionProvider provider,
    LanguageProvider lang,
    bool isArabic,
  ) {
    final daysRemaining = provider.trialDaysRemaining;
    final isExpiringSoon = daysRemaining <= 3;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isExpiringSoon
              ? [AppColors.warning, AppColors.warning.withValues(alpha: 0.7)]
              : [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isExpiringSoon ? Icons.warning_amber : Icons.info_outline,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  lang.t('trial_period'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            lang.t(
              'trial_expiring',
              args: {'days': daysRemaining.toString()},
            ),
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Navigate to upgrade
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: isExpiringSoon ? AppColors.warning : AppColors.primary,
              ),
              child: Text(lang.t('upgrade_to_premium')),
            ),
          ),
        ],
      ),
    );
  }
  
  // ignore: unused_element
  Widget _buildTrialExpired(LanguageProvider lang, bool isArabic) {
    return Scaffold(
      appBar: AppBar(
        title: Text(lang.t('nutrition')),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 80,
                color: AppColors.warning,
              ),
              const SizedBox(height: 24),
              Text(
                lang.t('trial_expired'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                lang.t('upgrade_prompt'),
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to upgrade
                  },
                  child: Text(lang.t('upgrade_to_premium')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildNoPlan(LanguageProvider lang, bool isArabic) {
    return Scaffold(
      appBar: AppBar(
        title: Text(lang.t('nutrition')),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_outlined,
              size: 80,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: 24),
            Text(
              lang.t('no_active_nutrition_plan'),
              style: const TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              lang.t('nutrition_plan_coming_soon'),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textDisabled,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedAccess(LanguageProvider lang, bool isArabic) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            color: AppColors.primary,
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(
                      isArabic ? Icons.arrow_forward : Icons.arrow_back,
                      color: Colors.white,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang.t('nutrition_title'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          lang.t('nutrition_tracking'),
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: CustomCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDE68A),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: const Icon(Icons.lock, size: 36, color: Color(0xFFB45309)),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        lang.t('nutrition_locked_title'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        lang.t('nutrition_locked_desc'),
                        style: const TextStyle(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Column(
                        children: [
                          _buildLockedFeatureRow(Icons.track_changes, lang.t('nutrition_feature1'), isArabic),
                          const SizedBox(height: 8),
                          _buildLockedFeatureRow(Icons.restaurant_menu, lang.t('nutrition_feature2'), isArabic),
                          const SizedBox(height: 8),
                          _buildLockedFeatureRow(Icons.trending_up, lang.t('nutrition_feature3'), isArabic),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SubscriptionManagerScreen()),
                          ),
                          icon: const Icon(Icons.workspace_premium),
                          label: Text(lang.t('nutrition_unlock_button')),
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

  Widget _buildLockedFeatureRow(IconData icon, String label, bool isArabic) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF16A34A)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            textAlign: isArabic ? TextAlign.right : TextAlign.left,
          ),
        ),
      ],
    );
  }
  
  Widget _buildMacroProgress(
    NutritionPlan plan,
    LanguageProvider lang,
    bool isArabic,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildMacroRing(
            label: lang.t('protein'),
            value: 120,
            target: plan.macros?['protein'] ?? 0,
            color: AppColors.primary,
          ),
        ),
        Expanded(
          child: _buildMacroRing(
            label: lang.t('carbs'),
            value: 200,
            target: plan.macros?['carbs'] ?? 0,
            color: AppColors.secondary,
          ),
        ),
        Expanded(
          child: _buildMacroRing(
            label: lang.t('fats'),
            value: 50,
            target: plan.macros?['fats'] ?? 0,
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }
  
  Widget _buildMacroRing({
    required String label,
    required double value,
    required double target,
    required Color color,
  }) {
    final percentage = (value / target).clamp(0.0, 1.0);
    
    return Column(
      children: [
        SizedBox(
          width: 100,
          height: 100,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(100, 100),
                painter: _MacroRingPainter(
                  percentage: percentage,
                  color: color,
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${value.toInt()}g',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    '/ ${target.toInt()}g',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
  
  Widget _buildCalorieCounter(
    NutritionPlan plan,
    LanguageProvider lang,
    bool isArabic,
  ) {
    final consumed = 1200; // Mock data
    final target = plan.dailyCalories ?? 0;
    final remaining = target - consumed;
    final percentage = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;
    
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang.t('calories'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$consumed',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    lang.t('consumed'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$remaining',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                  Text(
                    lang.t('remaining'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: AppColors.surface,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  // ignore: unused_element
  Widget _buildMealsList(
    NutritionPlan plan,
    LanguageProvider lang,
    bool isArabic,
  ) {
    // Get today's meals (simplified - use day index in real app)
    final todayMeals = (plan.days != null && plan.days!.isNotEmpty) ? plan.days![0].meals : <Meal>[];
    
    return Column(
      children: todayMeals
          .map<Widget>((meal) => _buildMealCard(meal, lang, isArabic))
          .toList(),
    );
  }
  
  Widget _buildMealCard(Meal meal, LanguageProvider lang, bool isArabic) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meal header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getMealColor(meal.type).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getMealIcon(meal.type),
                  color: _getMealColor(meal.type),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? meal.nameAr : meal.nameEn,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${meal.time} • ${meal.calories} ${lang.t('cal_unit')}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(isArabic ? Icons.chevron_left : Icons.chevron_right),
                onPressed: () {
                  _showMealDetail(meal, lang, isArabic);
                },
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Food items
          ...meal.foods.take(3).map((food) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.circle,
                    size: 6,
                    color: AppColors.textDisabled,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${isArabic ? food.nameAr : food.nameEn} (${food.quantity}${food.unit})',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          
          if (meal.foods.length > 3) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Text(
                lang.t(
                  'more_items',
                  args: {'count': (meal.foods.length - 3).toString()},
                ),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textDisabled,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Color _getMealColor(String type) {
    switch (type.toLowerCase()) {
      case 'breakfast':
        return AppColors.warning;
      case 'lunch':
        return AppColors.secondary;
      case 'dinner':
        return AppColors.primary;
      case 'snack':
        return AppColors.accent;
      default:
        return AppColors.textDisabled;
    }
  }
  
  IconData _getMealIcon(String type) {
    switch (type.toLowerCase()) {
      case 'breakfast':
        return Icons.free_breakfast;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      case 'snack':
        return Icons.cookie;
      default:
        return Icons.restaurant;
    }
  }
  
  void _showMealDetail(Meal meal, LanguageProvider lang, bool isArabic) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Meal name
                Text(
                  isArabic ? meal.nameAr : meal.nameEn,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // All food items
                ...meal.foods.map((food) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isArabic ? food.nameAr : food.nameEn,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${food.quantity}${food.unit} • ${food.calories} ${lang.t('cal_unit')}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                
                const SizedBox(height: 24),
                
                // Instructions if available
                if (meal.instructions != null) ...[
                  Text(
                    lang.t('instructions'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isArabic 
                        ? (meal.instructionsAr ?? meal.instructions!)
                        : (meal.instructionsEn ?? meal.instructions!),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Custom painter for macro rings
class _MacroRingPainter extends CustomPainter {
  final double percentage;
  final Color color;
  
  _MacroRingPainter({
    required this.percentage,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = 8.0;
    
    // Background circle
    final bgPaint = Paint()
      ..color = AppColors.surface
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    
    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);
    
    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -math.pi / 2,
      2 * math.pi * percentage,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_MacroRingPainter oldDelegate) {
    return oldDelegate.percentage != percentage;
  }
}

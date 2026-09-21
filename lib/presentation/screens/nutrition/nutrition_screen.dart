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
import 'meal_detail_screen.dart' show MealSwapSheet;
import 'nutrition_intro_screen.dart';
import 'nutrition_preferences_intake_screen.dart';
import '../../../data/repositories/nutrition_repository.dart';
import '../subscription/subscription_manager_screen.dart';
import '../intake/first_intake_screen.dart';
import '../intake/second_intake_screen.dart';

class NutritionScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onOpenWorkout;

  const NutritionScreen({
    super.key,
    this.onBack,
    this.onOpenWorkout,
  });

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  bool _showIntro = false;
  bool _introLoaded = false;
  bool _showPreferencesIntake = false;
  bool _editingPreferences = false;
  List<Map<String, dynamic>> _nutritionHistory = [];
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadNutritionState();
    });
  }

  Future<void> _loadNutritionState() async {
    final provider = context.read<NutritionProvider>();
    await provider.loadActivePlan();
    await provider.checkTrialStatus();
    if (!mounted) return;

    if (provider.accessStatus?.hasAccess == false) {
      setState(() {
        _showPreferencesIntake = false;
        _preferencesLoaded = true;
      });
      return;
    }

    // Always ask the server what is still missing, even when a plan exists. A
    // plan can predate the preference questions (or have been generated from
    // defaults), so "has a plan" is not evidence the client ever answered them.
    await provider.loadIntakeRequirements();
    if (!mounted) return;

    await _loadPreferencesFlag(hasPlan: provider.activePlan != null);
    final history = await NutritionRepository().getNutritionHistory();
    if (mounted) setState(() => _nutritionHistory = history);
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

  Future<void> _loadPreferencesFlag({bool hasPlan = false}) async {
    final authUserId = context.read<AuthProvider>().user?.id;
    final nutritionProvider = context.read<NutritionProvider>();
    final userId =
        authUserId ?? (DemoConfig.isDemo ? DemoConfig.demoUserId : null);
    final prefs = await SharedPreferences.getInstance();
    if (userId == null) {
      if (mounted) {
        setState(() {
          _showPreferencesIntake = false;
          _preferencesLoaded = true;
        });
      }
      return;
    }

    if (nutritionProvider.accessStatus?.hasAccess == false) {
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

    // The server's missing-field list wins over any local flag. This used to
    // short-circuit on `hasPlan` and write completed=true, which meant a plan
    // created from defaults permanently convinced the client that the
    // preference questions had been answered when they never were.
    final requirements = nutritionProvider.intakeRequirements;
    if (requirements != null) {
      final complete = requirements.isComplete;
      await prefs.setBool(completedKey, complete);
      await prefs.setBool(pendingKey, !complete);
      if (mounted) {
        setState(() {
          _showPreferencesIntake = !complete;
          _preferencesLoaded = true;
        });
      }
      return;
    }

    // Requirements unavailable (offline, or the call failed). An existing plan
    // is then the best evidence the questions were answered at some point.
    if (hasPlan) {
      if (mounted) {
        setState(() {
          _showPreferencesIntake = false;
          _preferencesLoaded = true;
        });
      }
      return;
    }

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
    final authUserId = context.read<AuthProvider>().user?.id;
    final nutritionProvider = context.read<NutritionProvider>();
    final userId =
        authUserId ?? (DemoConfig.isDemo ? DemoConfig.demoUserId : null);
    if (userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final pendingKey = 'pending_nutrition_intake_$userId';
    final completedKey = 'nutrition_preferences_completed_$userId';
    final prefsKey = 'nutrition_preferences_$userId';
    await prefs.setString(prefsKey, jsonEncode(preferences));
    if (!DemoConfig.isDemo) {
      try {
        final repository = NutritionRepository();
        final response = await repository.generatePlan(preferences);
        final status = response['status']?.toString();
        final success = response['success'] == true;

        if (status == 'missing_fields' || success == false) {
          await prefs.setBool(completedKey, false);
          await prefs.setBool(pendingKey, true);
          await nutritionProvider.loadIntakeRequirements(planType: 'starter');
          if (mounted) {
            setState(() => _showPreferencesIntake = true);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  response['message']?.toString() ??
                      'Additional nutrition information is required',
                ),
              ),
            );
          }
          return;
        }

        await prefs.setBool(completedKey, true);
        await prefs.setBool(pendingKey, false);

        if (mounted) {
          await nutritionProvider.selectDate(DateTime.now());
        }

        if (status == 'professional_review_required' && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response['message']?.toString() ??
                    'Nutrition plan requires professional review before activation.',
              ),
            ),
          );
        }
      } catch (error) {
        await prefs.setBool(completedKey, false);
        await prefs.setBool(pendingKey, true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.toString()),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
    } else {
      await prefs.setBool(completedKey, true);
      await prefs.setBool(pendingKey, false);
    }
    if (mounted) {
      setState(() {
        _showPreferencesIntake = false;
      });
    }
  }

  // The single "finish your workout intake" screen. Both reasons the nutrition
  // tab can be blocked on an intake render through here so the user only ever
  // sees one such screen, and it always lands on the intake that is actually
  // outstanding instead of restarting from the first one.
  Widget _buildIntakeGate({
    required LanguageProvider languageProvider,
    required bool isArabic,
    required bool needsFirstIntake,
    required String message,
  }) {
    void completed() {
      Navigator.of(context).pop();
      _loadNutritionState();
    }

    return Scaffold(
      appBar: AppBar(title: Text(languageProvider.t('nutrition_title'))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => needsFirstIntake
                      ? FirstIntakeScreen(
                          onComplete: completed,
                          onSkip: () => Navigator.of(context).pop(),
                        )
                      : SecondIntakeScreen(onComplete: completed),
                )),
                child: Text(isArabic ? 'إكمال الاستبيان' : 'Complete intake'),
              ),
            ],
          ),
        ),
      ),
    );
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

    if (nutritionProvider.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Check access
    final canAccess = nutritionProvider.canAccessNutrition(subscriptionTier);

    // The workout intakes come first, ahead of both the onboarding screen and
    // the preference questions. They used to be spread over two branches on
    // either side of the intro, so a user missing a first-intake field was sent
    // to an intake screen, shown the intro, then sent to an intake screen
    // again -- the "multiple intakes" this is meant to stop. There is now one
    // gate, and it is the first thing this screen can render.
    final requiresIntakes =
        !canAccess && nutritionProvider.accessStatus?.requiresIntakes == true;
    // A field the first intake owns is still missing, so send the client there
    // rather than asking the same question again on the nutrition form.
    final requiresFirstIntakeField = _showPreferencesIntake &&
        nutritionProvider.intakeRequirements?.requiresFirstIntake == true;

    if (requiresIntakes || requiresFirstIntakeField) {
      final firstIntakeDone =
          authProvider.user?.hasCompletedFirstIntake == true &&
              !requiresFirstIntakeField;
      return _buildIntakeGate(
        languageProvider: languageProvider,
        isArabic: isArabic,
        needsFirstIntake: !firstIntakeDone,
        message: requiresIntakes
            ? (nutritionProvider.accessMessage(isArabic: isArabic) ??
                (isArabic
                    ? 'أكمل الاستبيان الأول والثاني قبل بدء التغذية.'
                    : 'Complete your first and second intake before starting nutrition.'))
            : (isArabic
                ? 'نحتاج إكمال بيانات ملفك الأساسي أولا حتى نحسب احتياجك من السعرات.'
                : 'We need your basic profile details first so we can calculate your calorie needs.'),
      );
    }

    if (!canAccess) {
      return _buildLockedAccess(languageProvider, isArabic);
    }

    // Onboarding sits between the intakes and the questions: by here the user
    // has everything the plan needs from the workout side, so the intro is an
    // introduction to nutrition rather than an interruption before a gate.
    if (_showIntro) {
      return NutritionIntroScreen(onGetStarted: _completeIntro);
    }

    if (_showPreferencesIntake) {
      return NutritionPreferencesIntakeScreen(
        editMode: _editingPreferences,
        missingFields: nutritionProvider.intakeRequirements?.missingFields,
        questions: nutritionProvider.intakeRequirements?.questions,
        context: nutritionProvider.intakeRequirements?.context,
        planType: nutritionProvider.intakeRequirements?.planType ?? 'starter',
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
        ((macroTargets['calories'] as num) == 0
            ? 1
            : (macroTargets['calories'] as num));

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
                                isArabic
                                    ? Icons.arrow_forward
                                    : Icons.arrow_back,
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
                              icon: const Icon(Icons.settings,
                                  color: Colors.white),
                              onPressed: () async {
                                await nutritionProvider.loadIntakeRequirements(
                                  planType: subscriptionTier.toLowerCase() == 'freemium' ? 'starter' : 'professional');
                                if (mounted) {
                                  setState(() {
                                    _editingPreferences = true;
                                    _showPreferencesIntake = true;
                                  });
                                }
                              },
                              tooltip: languageProvider
                                  .t('nutrition_edit_preferences'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    languageProvider
                                        .t('nutrition_todays_progress'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${(calorieProgress * 100).clamp(0, 100).round()}%',
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '${currentMacros['calories']?.toInt() ?? 0} / ${macroTargets['calories']}',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12),
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: calorieProgress.clamp(0, 1).toDouble(),
                                  minHeight: 6,
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.2),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          Colors.white),
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
                        labelStyle: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                        unselectedLabelStyle: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500),
                        indicator: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        tabs: [
                          Tab(text: languageProvider.t('nutrition_tab_today')),
                          Tab(text: languageProvider.t('nutrition_tab_meals')),
                          Tab(
                              text:
                                  languageProvider.t('nutrition_tab_tracking')),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildTodayTab(
                            languageProvider, nutritionProvider, isArabic),
                        _buildMealsTab(
                            languageProvider, nutritionProvider, isArabic),
                        _buildTrackingTab(
                            languageProvider, nutritionProvider, isArabic),
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
          Row(children: [
            Expanded(child: Text(MaterialLocalizations.of(context).formatFullDate(provider.selectedDate))),
            IconButton(icon: const Icon(Icons.calendar_month),
              tooltip: isArabic ? 'اختيار اليوم' : 'Select date',
              onPressed: () async {
                final date = await showDatePicker(context: context,
                  initialDate: provider.selectedDate,
                  firstDate: DateTime(2020), lastDate: DateTime.now());
                if (date != null) await provider.selectDate(date);
              }),
          ]),
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
            dayPlans.isNotEmpty
                ? lang.t('nutrition_week_plan')
                : lang.t('todays_meals'),
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
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
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
          _buildCalorieCounter(
            provider.activePlan!,
            provider.todayProgress,
            lang,
            isArabic,
          ),
          const SizedBox(height: 20),
          Text(isArabic ? 'السجل اليومي' : 'Daily history',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ..._nutritionHistory.map((day) => ListTile(
            title: Text(day['date'].toString().substring(0, 10)),
            subtitle: Text('${day['protein']} ${lang.t('protein')} | ${day['carbs']} ${lang.t('carbs')} | ${day['fat']} ${lang.t('fats')}'),
            trailing: Text('${day['calories']} ${lang.t('cal_unit')}'),
            onTap: () => provider.selectDate(DateTime.parse(day['date'].toString())),
          )),
        ],
      ),
    );
  }

  Widget _buildMacroBreakdownGrid(
      LanguageProvider lang, NutritionProvider provider) {
    final targets = provider.macroTargets;
    final current = provider.getCurrentMacros();

    Widget buildCard(
        IconData icon, Color color, String label, int value, int target) {
      final progress =
          target == 0 ? 0.0 : (value / target).clamp(0, 1).toDouble();
      return CustomCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text('$value',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
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
                foregroundColor:
                    isExpiringSoon ? AppColors.warning : AppColors.primary,
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
              const Icon(
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

  Future<void> _startNutritionGeneration() async {
    final provider = context.read<NutritionProvider>();
    final requirements =
        await provider.loadIntakeRequirements(planType: 'starter');
    if (!mounted) return;

    if (requirements == null || !requirements.isComplete) {
      setState(() => _showPreferencesIntake = true);
      return;
    }

    await _completePreferences({'plan_type': requirements.planType});
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
            const Icon(
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
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () =>
                  context.read<NutritionProvider>().loadActivePlan(),
              icon: const Icon(Icons.refresh),
              label: Text(lang.t('retry')),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _startNutritionGeneration,
              icon: const Icon(Icons.auto_awesome),
              label: Text(lang.t('nutrition_generate_plan')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedAccess(LanguageProvider lang, bool isArabic) {
    final nutritionProvider = context.read<NutritionProvider>();
    final requiresFirstWorkout = nutritionProvider.requiresFirstWorkout;
    final lockedTitle = requiresFirstWorkout
        ? (isArabic ? 'أكمل التمرين الأول' : 'Complete First Workout')
        : lang.t('nutrition_locked_title');
    final lockedMessage = requiresFirstWorkout
        ? (nutritionProvider.accessMessage(isArabic: isArabic) ??
            (isArabic
                ? 'أكمل تمرينك الأول قبل بدء خطتك الغذائية.'
                : 'Complete your first workout before starting your nutrition plan.'))
        : lang.t('nutrition_locked_desc');
    final actionLabel = requiresFirstWorkout
        ? (isArabic ? 'فتح التمرين' : 'Open Workout')
        : lang.t('nutrition_unlock_button');

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
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
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
                        child: const Icon(Icons.lock,
                            size: 36, color: Color(0xFFB45309)),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        lockedTitle,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        lockedMessage,
                        style: const TextStyle(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Column(
                        children: [
                          _buildLockedFeatureRow(Icons.track_changes,
                              lang.t('nutrition_feature1'), isArabic),
                          const SizedBox(height: 8),
                          _buildLockedFeatureRow(Icons.restaurant_menu,
                              lang.t('nutrition_feature2'), isArabic),
                          const SizedBox(height: 8),
                          _buildLockedFeatureRow(Icons.trending_up,
                              lang.t('nutrition_feature3'), isArabic),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: requiresFirstWorkout
                              ? () {
                                  if (widget.onOpenWorkout != null) {
                                    widget.onOpenWorkout!.call();
                                  } else {
                                    Navigator.of(context).maybePop();
                                  }
                                }
                              : () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const SubscriptionManagerScreen(),
                                    ),
                                  ),
                          icon: Icon(
                            requiresFirstWorkout
                                ? Icons.fitness_center
                                : Icons.workspace_premium,
                          ),
                          label: Text(actionLabel),
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
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
    NutritionTodayProgress? todayProgress,
    LanguageProvider lang,
    bool isArabic,
  ) {
    final progress = todayProgress ?? plan.todayProgress;
    final consumed = (progress?.consumedCalories ?? 0).round();
    final target =
        (progress?.targetCalories ?? plan.dailyCalories ?? 0).round();
    final remaining =
        (progress?.remainingCalories ?? (target - consumed)).round();
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
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
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
    final todayMeals = (plan.days != null && plan.days!.isNotEmpty)
        ? plan.days![0].meals
        : <Meal>[];

    return Column(
      children: todayMeals
          .map<Widget>((meal) => _buildMealCard(meal, lang, isArabic))
          .toList(),
    );
  }

  String _localizedMealName(Meal meal, bool isArabic) {
    final localized = isArabic ? meal.nameAr : meal.nameEn;
    return localized.trim().isNotEmpty ? localized : meal.name;
  }

  String _localizedFoodName(FoodItem food, bool isArabic) {
    final localized = isArabic ? food.nameAr : food.nameEn;
    if (localized.trim().isNotEmpty) return localized;
    return food.name.trim().isNotEmpty ? food.name : '-';
  }

  String _formatQuantity(FoodItem food) {
    final amount = food.quantity % 1 == 0
        ? food.quantity.round().toString()
        : food.quantity.toStringAsFixed(1);
    return '$amount${food.unit}';
  }

  String _macroLine(Meal meal, LanguageProvider lang) {
    return '${lang.t('protein')} ${meal.macros.protein.round()}g - '
        '${lang.t('carbs')} ${meal.macros.carbs.round()}g - '
        '${lang.t('fats')} ${meal.macros.fats.round()}g';
  }

  String _foodMacroLine(FoodItem food, LanguageProvider lang) {
    return '${lang.t('protein')} ${food.macros.protein.round()}g - '
        '${lang.t('carbs')} ${food.macros.carbs.round()}g - '
        '${lang.t('fats')} ${food.macros.fats.round()}g';
  }

  String _mealInstructions(Meal meal, bool isArabic) {
    final text = isArabic
        ? (meal.instructionsAr ?? meal.instructions ?? meal.instructionsEn)
        : (meal.instructionsEn ?? meal.instructions ?? meal.instructionsAr);
    if (text != null && text.trim().isNotEmpty) return text;
    return isArabic
        ? 'لا توجد مكونات/تفاصيل متاحة'
        : 'No ingredients/details available';
  }

  Widget _buildMealCard(Meal meal, LanguageProvider lang, bool isArabic) {
    final mealName = _localizedMealName(meal, isArabic);
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
                      mealName,
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
                    const SizedBox(height: 4),
                    Text(
                      _macroLine(meal, lang),
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
              Checkbox(
                value: meal.completed,
                onChanged: meal.completed || !meal.canLog
                    ? null
                    : (value) async {
                        if (value != true) return;
                        final provider = context.read<NutritionProvider>();
                        // logMeal already updates local state + notifies;
                        // no full reload needed (avoids full-screen spinner).
                        final success = await provider.logMeal(meal.id, {'completed': true});
                        if (!mounted) return;
                        if (!success) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(provider.error ?? (isArabic ? 'تعذر تسجيل الوجبة' : 'Could not log meal'))));
                        } else {
                          final history = await NutritionRepository().getNutritionHistory();
                          if (mounted) setState(() => _nutritionHistory = history);
                        }
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
                      '${_localizedFoodName(food, isArabic)} (${_formatQuantity(food)})',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

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
    final mealName = _localizedMealName(meal, isArabic);
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
                  mealName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),
                Text(
                  '${meal.calories} ${lang.t('cal_unit')} - ${_macroLine(meal, lang)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 24),

                // All food items
                if (meal.foods.isEmpty)
                  Text(
                    isArabic
                        ? 'لا توجد مكونات/تفاصيل متاحة'
                        : 'No ingredients/details available',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
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
                                _localizedFoodName(food, isArabic),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_formatQuantity(food)} - ${food.calories} ${lang.t('cal_unit')} - ${_foodMacroLine(food, lang)}',
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
                }),

                const SizedBox(height: 24),

                Text(
                  lang.t('instructions'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _mealInstructions(meal, isArabic),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  // Swapping a logged meal is refused by the server with a 409,
                  // so the action is dimmed once it has been logged and the
                  // reason is spelled out underneath.
                  child: OutlinedButton.icon(
                    onPressed: meal.completed
                        ? null
                        : () async {
                            // Close the detail sheet first so the swap list is
                            // not stacked on top of a sheet showing the old meal.
                            Navigator.of(context).pop();
                            await _openMealSwap(meal);
                          },
                    icon: const Icon(Icons.swap_horiz),
                    label: Text(lang.t('meal_detail_swap')),
                  ),
                ),
                if (meal.completed) ...[
                  const SizedBox(height: 8),
                  Text(
                    lang.t('meal_swap_already_logged'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
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

  /// Opens the swap list for a meal and reports the outcome. The provider
  /// reloads the plan on success, so nothing here has to patch local state.
  Future<void> _openMealSwap(Meal meal) async {
    final lang = context.read<LanguageProvider>();
    final swapped = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => MealSwapSheet(meal: meal),
    );
    if (swapped != true || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(lang.t('meal_swap_done'))),
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
    const strokeWidth = 8.0;

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

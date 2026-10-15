import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'dart:convert';
import '../../../core/config/demo_config.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/bidi_text.dart';
import '../../../data/models/nutrition_plan.dart';
import '../../providers/language_provider.dart';
import '../../providers/nutrition_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_card.dart';
import 'nutrition_intro_screen.dart';
import 'nutrition_preferences_intake_screen.dart';
import '../../../data/repositories/nutrition_repository.dart';
import '../subscription/subscription_manager_screen.dart';
import '../intake/first_intake_screen.dart';
import '../intake/second_intake_screen.dart';
import '../../../core/theme/app_palette.dart';

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
      // `isComplete` covers every field the target calculation needs,
      // including `sex`, which this form cannot ask. Whether to *show* the
      // form depends only on what it can collect — otherwise a missing `sex`
      // reopened the whole questionnaire on every visit.
      final needsForm = requirements.needsPreferenceAnswers;
      await prefs.setBool(completedKey, !needsForm);
      await prefs.setBool(pendingKey, needsForm);
      if (mounted) {
        setState(() {
          _showPreferencesIntake = needsForm;
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
    required LanguageProvider lang,
    required bool needsFirstIntake,
    required String message,
  }) {
    void completed() {
      Navigator.of(context).pop();
      _loadNutritionState();
    }

    return Scaffold(
      appBar: AppBar(title: Text(lang.t('nutrition_title'))),
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
                child: Text(lang.t('intake_first_complete')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final nutritionProvider = context.watch<NutritionProvider>();
    final authProvider = context.watch<AuthProvider>();
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
        lang: lang,
        needsFirstIntake: !firstIntakeDone,
        message: requiresIntakes
            ? (nutritionProvider.accessMessage(isArabic: lang.isArabic) ??
                (lang.t('nutrition_complete_your_first_and_second_intake')))
            : (lang.t('nutrition_we_need_your_basic_profile_details')),
      );
    }

    if (!canAccess) {
      return _buildLockedAccess(lang);
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
      return _buildNoPlan(lang);
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
              child: Container(color: context.palette.background),
            ),
            SafeArea(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    decoration: BoxDecoration(
                      color: context.palette.surface,
                      border: Border(
                          bottom: BorderSide(color: context.palette.border)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => _handleBack(),
                              icon: Icon(
                                Icons.arrow_back,
                                color: context.palette.textPrimary,
                              ),
                              tooltip: lang.t('back'),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lang.t('nutrition_title'),
                                    style: AppTextStyles.h2.copyWith(
                                      color: context.palette.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    lang.t('nutrition_tracking'),
                                    style: AppTextStyles.caption.copyWith(
                                      color: context.palette.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.settings,
                                  color: context.palette.textOnBrand),
                              onPressed: () async {
                                await nutritionProvider.loadIntakeRequirements(
                                    planType: subscriptionTier.toLowerCase() ==
                                            'freemium'
                                        ? 'starter'
                                        : 'professional');
                                if (mounted) {
                                  setState(() {
                                    _editingPreferences = true;
                                    _showPreferencesIntake = true;
                                  });
                                }
                              },
                              tooltip: lang.t('nutrition_edit_preferences'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: context.palette.surfaceVariant,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: context.palette.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    lang.t('nutrition_todays_progress'),
                                    style: TextStyle(
                                      color: context.palette.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: context.palette.border,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${(calorieProgress * 100).clamp(0, 100).round()}%',
                                      style: TextStyle(
                                          color: context.palette.textOnBrand),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '${currentMacros['calories']?.toInt() ?? 0} / ${macroTargets['calories']}',
                                style: AppTextStyles.caption.copyWith(
                                    color: context.palette.textSecondary),
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: calorieProgress.clamp(0, 1).toDouble(),
                                  minHeight: 6,
                                  backgroundColor: context.palette.border,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      context.palette.textOnBrand),
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
                        color: context.palette.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.palette.border),
                      ),
                      child: TabBar(
                        labelColor: context.palette.textPrimary,
                        unselectedLabelColor: context.palette.textSecondary,
                        labelStyle: AppTextStyles.caption
                            .copyWith(fontWeight: FontWeight.w600),
                        unselectedLabelStyle: AppTextStyles.caption
                            .copyWith(fontWeight: FontWeight.w500),
                        indicator: BoxDecoration(
                          color: context.palette.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        tabs: [
                          Tab(text: lang.t('nutrition_tab_today')),
                          Tab(text: lang.t('nutrition_tab_meals')),
                          Tab(text: lang.t('nutrition_tab_tracking')),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildTodayTab(lang, nutritionProvider),
                        _buildMealsTab(lang, nutritionProvider),
                        _buildTrackingTab(lang, nutritionProvider),
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
            Expanded(
                child: Text(MaterialLocalizations.of(context)
                    .formatFullDate(provider.selectedDate))),
            IconButton(
                icon: const Icon(Icons.calendar_month),
                tooltip: lang.t('nutrition_select_date'),
                onPressed: () async {
                  final date = await showDatePicker(
                      context: context,
                      initialDate: provider.selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now());
                  if (date != null) await provider.selectDate(date);
                }),
          ]),
          const SizedBox(height: 12),
          if (meals.isNotEmpty)
            SingleChildScrollView(
              key: const ValueKey('nutrition-meal-carousel'),
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                for (final meal in meals)
                  SizedBox(
                    width: (MediaQuery.of(context).size.width - 48)
                        .clamp(220.0, 300.0)
                        .toDouble(),
                    child: _buildMealCard(meal, lang),
                  ),
              ]),
            ),
        ],
      ),
    );
  }

  Widget _buildMealsTab(
    LanguageProvider lang,
    NutritionProvider provider,
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
            style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (plan == null)
            const SizedBox.shrink()
          else if (dayPlans.isEmpty)
            ...((plan.meals ?? const <Meal>[])
                .map((meal) => _buildMealCard(meal, lang)))
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
                        _buildMealCard(meal, lang),
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
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMacroProgress(provider.activePlan!, lang),
          const SizedBox(height: 20),
          _buildCalorieCounter(
            provider.activePlan!,
            provider.todayProgress,
            lang,
          ),
          const SizedBox(height: 20),
          Text(lang.t('nutrition_daily_history'),
              style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w600)),
          ..._nutritionHistory.map((day) => ListTile(
                title: Text(day['date'].toString().substring(0, 10)),
                subtitle: Text(
                    '${day['protein']} ${lang.t('protein')} | ${day['carbs']} ${lang.t('carbs')} | ${day['fat']} ${lang.t('fats')}'),
                trailing: Text('${day['calories']} ${lang.t('cal_unit')}'),
                onTap: () =>
                    provider.selectDate(DateTime.parse(day['date'].toString())),
              )),
        ],
      ),
    );
  }

  Widget _buildMacroBreakdownGrid(
      LanguageProvider lang, NutritionProvider provider) {
    final targets = provider.macroTargets;
    final current = provider.getCurrentMacros();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final proteinColor = isDark ? AppColors.proteinDark : AppColors.primary;

    Widget buildCard(String label, int value, int target, Color color) {
      final progress =
          target == 0 ? 0.0 : (value / target).clamp(0, 1).toDouble();
      return CustomCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Expanded(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.overline
                          .copyWith(color: context.palette.textSecondary))),
            ]),
            const SizedBox(height: 8),
            FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text('$value / $target g',
                    style: AppTextStyles.h4
                        .copyWith(color: context.palette.textPrimary))),
            const SizedBox(height: 8),
            ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: context.palette.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(color))),
          ],
        ),
      );
    }

    return Column(
      children: [
        Row(children: [
          Expanded(
              child: buildCard(
                  lang.t('protein'),
                  (current['protein'] as num).toInt(),
                  (targets['protein'] as num).toInt(),
                  proteinColor)),
          const SizedBox(width: 8),
          Expanded(
              child: buildCard(
                  lang.t('carbs'),
                  (current['carbs'] as num).toInt(),
                  (targets['carbs'] as num).toInt(),
                  AppColors.cyan)),
          const SizedBox(width: 8),
          Expanded(
              child: buildCard(lang.t('fats'), (current['fat'] as num).toInt(),
                  (targets['fat'] as num).toInt(), AppColors.gold)),
        ]),
        const SizedBox(height: 8),
        _buildWaterProgress(lang, current, targets),
      ],
    );
  }

  Widget _buildWaterProgress(LanguageProvider lang,
      Map<String, dynamic> current, Map<String, dynamic> targets) {
    final value = (current['water'] as num?)?.toInt() ?? 0;
    final target = (targets['water'] as num?)?.toInt() ?? 3000;
    final progress =
        target == 0 ? 0.0 : (value / target).clamp(0, 1).toDouble();
    return CustomCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(children: [
        Icon(Icons.water_drop, color: AppColors.cyan),
        const SizedBox(width: 10),
        Expanded(
            child: Text(lang.t('nutrition_water'),
                style: AppTextStyles.smallMedium
                    .copyWith(color: context.palette.textPrimary))),
        Text('$value / $target ml',
            style: AppTextStyles.caption
                .copyWith(color: context.palette.textSecondary)),
        const SizedBox(width: 12),
        SizedBox(
            width: 68,
            child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: context.palette.surfaceVariant,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.cyan)))),
      ]),
    );
  }

  // ignore: unused_element
  Widget _buildTrialBanner(
    NutritionProvider provider,
    LanguageProvider lang,
  ) {
    final daysRemaining = provider.trialDaysRemaining;
    final isExpiringSoon = daysRemaining <= 3;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isExpiringSoon
              ? [AppColors.warning, AppColors.warning.withValues(alpha: 0.7)]
              : [
                  context.palette.primary,
                  context.palette.primary.withValues(alpha: 0.7)
                ],
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
                color: context.palette.textPrimary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  lang.t('trial_period'),
                  style: AppTextStyles.h3.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.palette.textPrimary,
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
            style: AppTextStyles.small.copyWith(
              color: context.palette.textOnBrand.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SubscriptionManagerScreen(),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.palette.surface,
                foregroundColor:
                    isExpiringSoon ? AppColors.gold : context.palette.primary,
              ),
              child: Text(lang.t('upgrade_to_premium')),
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildTrialExpired(LanguageProvider lang) {
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
                style: AppTextStyles.h1.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                lang.t('upgrade_prompt'),
                style: AppTextStyles.h4.copyWith(
                  color: context.palette.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SubscriptionManagerScreen(),
                    ),
                  ),
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

    if (requirements == null || requirements.needsPreferenceAnswers) {
      setState(() => _showPreferencesIntake = true);
      return;
    }

    await _completePreferences({'plan_type': requirements.planType});
  }

  Widget _buildNoPlan(LanguageProvider lang) {
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
              color: context.palette.textDisabled,
            ),
            const SizedBox(height: 24),
            Text(
              lang.t('no_active_nutrition_plan'),
              style: AppTextStyles.h3.copyWith(
                color: context.palette.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              lang.t('nutrition_plan_coming_soon'),
              style: AppTextStyles.small.copyWith(
                color: context.palette.textDisabled,
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

  Widget _buildLockedAccess(LanguageProvider lang) {
    final nutritionProvider = context.read<NutritionProvider>();
    final requiresFirstWorkout = nutritionProvider.requiresFirstWorkout;
    final lockedTitle = requiresFirstWorkout
        ? (lang.t('nutrition_complete_first_workout'))
        : lang.t('nutrition_locked_title');
    final lockedMessage = requiresFirstWorkout
        ? (nutritionProvider.accessMessage(isArabic: lang.isArabic) ??
            (lang.t('nutrition_complete_your_first_workout_before_starting')))
        : lang.t('nutrition_locked_desc');
    final actionLabel = requiresFirstWorkout
        ? (lang.t('nutrition_open_workout'))
        : lang.t('nutrition_unlock_button');

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            color: context.palette.primary,
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(
                      Icons.arrow_back,
                      color: context.palette.textPrimary,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang.t('nutrition_title'),
                          style: AppTextStyles.h3.copyWith(
                            color: context.palette.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          lang.t('nutrition_tracking'),
                          style: AppTextStyles.caption
                              .copyWith(color: context.palette.textSecondary),
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
                          color: AppColors.gold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: const Icon(Icons.lock,
                            size: 36, color: AppColors.gold),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        lockedTitle,
                        style: AppTextStyles.h3
                            .copyWith(fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        lockedMessage,
                        style: TextStyle(color: context.palette.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Column(
                        children: [
                          _buildLockedFeatureRow(Icons.track_changes,
                              lang.t('nutrition_feature1'), lang),
                          const SizedBox(height: 8),
                          _buildLockedFeatureRow(Icons.restaurant_menu,
                              lang.t('nutrition_feature2'), lang),
                          const SizedBox(height: 8),
                          _buildLockedFeatureRow(Icons.trending_up,
                              lang.t('nutrition_feature3'), lang),
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

  Widget _buildLockedFeatureRow(
      IconData icon, String label, LanguageProvider lang) {
    return Row(
      children: [
        Icon(icon, size: 18, color: context.palette.success),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.caption
                .copyWith(color: context.palette.textSecondary),
            textAlign: TextAlign.start,
          ),
        ),
      ],
    );
  }

  Widget _buildMacroProgress(
    NutritionPlan plan,
    LanguageProvider lang,
  ) {
    final proteinColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.proteinDark
        : AppColors.primary;
    return Row(
      children: [
        Expanded(
          child: _buildMacroRing(
            label: lang.t('protein'),
            unit: lang.t('gram_unit'),
            value: 120,
            target: plan.macros?['protein'] ?? 0,
            color: proteinColor,
          ),
        ),
        Expanded(
          child: _buildMacroRing(
            label: lang.t('carbs'),
            unit: lang.t('gram_unit'),
            value: 200,
            target: plan.macros?['carbs'] ?? 0,
            color: AppColors.cyan,
          ),
        ),
        Expanded(
          child: _buildMacroRing(
            label: lang.t('fats'),
            unit: lang.t('gram_unit'),
            value: 50,
            target: plan.macros?['fats'] ?? 0,
            color: AppColors.gold,
          ),
        ),
      ],
    );
  }

  Widget _buildMacroRing({
    required String label,
    required String unit,
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
                  trackColor: context.palette.surfaceVariant,
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    measurement(value.toInt(), unit),
                    style: AppTextStyles.h3.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    '/ ${measurement(target.toInt(), unit)}',
                    style: AppTextStyles.caption.copyWith(
                      color: context.palette.textSecondary,
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
          style: AppTextStyles.small.copyWith(
            fontWeight: FontWeight.w600,
            color: context.palette.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildCalorieCounter(
    NutritionPlan plan,
    NutritionTodayProgress? todayProgress,
    LanguageProvider lang,
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
            style: AppTextStyles.h4.copyWith(
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
                    style: AppTextStyles.h1.copyWith(
                      color: AppColors.cyan,
                    ),
                  ),
                  Text(
                    lang.t('consumed'),
                    style: AppTextStyles.caption.copyWith(
                      color: context.palette.textSecondary,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$remaining',
                    style: AppTextStyles.h1.copyWith(
                      color: context.palette.textSecondary,
                    ),
                  ),
                  Text(
                    lang.t('remaining'),
                    style: AppTextStyles.caption.copyWith(
                      color: context.palette.textSecondary,
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
              backgroundColor: context.palette.surfaceVariant,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.cyan),
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
  ) {
    // Get today's meals (simplified - use day index in real app)
    final todayMeals = (plan.days != null && plan.days!.isNotEmpty)
        ? plan.days![0].meals
        : <Meal>[];

    return Column(
      children:
          todayMeals.map<Widget>((meal) => _buildMealCard(meal, lang)).toList(),
    );
  }

  String _localizedMealName(Meal meal, LanguageProvider lang) {
    final localized = lang.isArabic ? meal.nameAr : meal.nameEn;
    return localized.trim().isNotEmpty ? localized : meal.name;
  }

  String _localizedFoodName(FoodItem food, LanguageProvider lang) {
    final localized = lang.isArabic ? food.nameAr : food.nameEn;
    if (localized.trim().isNotEmpty) return localized;
    return food.name.trim().isNotEmpty ? food.name : '-';
  }

  String _formatQuantity(FoodItem food) {
    final amount = food.quantity % 1 == 0
        ? food.quantity.round().toString()
        : food.quantity.toStringAsFixed(1);
    return measurement(amount, food.unit);
  }

  /// `Protein 30g - Carbs 40g - Fats 10g`, with each weight isolated so the
  /// three pairs keep their order and their labels in Arabic. See
  /// [bidiIsolate].
  String _macrosFor(MacroTargets macros, LanguageProvider lang) {
    final g = lang.t('gram_unit');
    return '${lang.t('protein')} ${measurement(macros.protein.round(), g)} - '
        '${lang.t('carbs')} ${measurement(macros.carbs.round(), g)} - '
        '${lang.t('fats')} ${measurement(macros.fats.round(), g)}';
  }

  String _macroLine(Meal meal, LanguageProvider lang) =>
      _macrosFor(meal.macros, lang);

  String _foodMacroLine(FoodItem food, LanguageProvider lang) =>
      _macrosFor(food.macros, lang);

  String _mealCardImageAsset(String type) {
    switch (type.trim().toLowerCase()) {
      case 'breakfast':
        return 'assets/images/meals/breakfast.jpg';
      case 'lunch':
        return 'assets/images/meals/lunch.jpg';
      case 'dinner':
        return 'assets/images/meals/dinner.jpg';
      case 'snack':
      case 'snacks':
        return 'assets/images/meals/snack.jpg';
      default:
        return 'assets/images/meals/lunch.jpg';
    }
  }

  String _mealInstructions(Meal meal, LanguageProvider lang) {
    final text = lang.isArabic
        ? (meal.instructionsAr ?? meal.instructions ?? meal.instructionsEn)
        : (meal.instructionsEn ?? meal.instructions ?? meal.instructionsAr);
    if (text != null && text.trim().isNotEmpty) return text;
    return lang.t('nutrition_no_ingredients_details_available');
  }

  Widget _buildMealCard(Meal meal, LanguageProvider lang) {
    final mealName = _localizedMealName(meal, lang);
    const cardRadius = BorderRadius.all(Radius.circular(24));

    return Padding(
      key: ValueKey('nutrition-meal-card-${meal.id}'),
      padding: const EdgeInsets.only(bottom: 16),
      child: AspectRatio(
        aspectRatio: 1.22,
        child: ClipRRect(
          borderRadius: cardRadius,
          child: Material(
            color: context.palette.surface,
            child: Stack(
              fit: StackFit.expand,
              children: [
                InkWell(
                  onTap: () => _showMealDetail(meal, lang),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        _mealCardImageAsset(meal.type),
                        fit: BoxFit.cover,
                        semanticLabel: mealName,
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0x080A1424),
                              Color(0x300A1424),
                              Color(0xE80A1424),
                            ],
                            stops: [0, 0.42, 1],
                          ),
                        ),
                      ),
                      PositionedDirectional(
                        start: 16,
                        end: 64,
                        bottom: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getMealIcon(meal.type),
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    '${meal.time}  ·  ${meal.calories} ${lang.t('cal_unit')}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.captionMedium.copyWith(
                                      color:
                                          Colors.white.withValues(alpha: 0.9),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 7),
                            Text(
                              mealName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.h3.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PositionedDirectional(
                        end: 16,
                        bottom: 18,
                        child: Icon(
                          lang.isArabic
                              ? Icons.arrow_back_rounded
                              : Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                PositionedDirectional(
                  end: 8,
                  top: 8,
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(14),
                    child: Checkbox(
                      value: meal.completed,
                      checkColor: Colors.white,
                      activeColor: AppColors.cyan,
                      side: const BorderSide(color: AppColors.primaryDark),
                      onChanged: meal.completed || !meal.canLog
                          ? null
                          : (value) => _logMeal(meal, lang, value),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _logMeal(
    Meal meal,
    LanguageProvider lang,
    bool? value,
  ) async {
    if (value != true) return;
    final provider = context.read<NutritionProvider>();
    final success = await provider.logMeal(meal.id, {'completed': true});
    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.error ?? lang.t('nutrition_could_not_log_meal'),
          ),
        ),
      );
      return;
    }

    final history = await NutritionRepository().getNutritionHistory();
    if (mounted) setState(() => _nutritionHistory = history);
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

  void _showMealDetail(Meal meal, LanguageProvider lang) {
    final mealName = _localizedMealName(meal, lang);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: context.palette.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                      color: context.palette.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Meal name
                Text(
                  mealName,
                  style: AppTextStyles.h1.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),
                Text(
                  '${bidiIsolate('${meal.calories}')} ${lang.t('cal_unit')}'
                  ' - ${_macroLine(meal, lang)}',
                  style: AppTextStyles.small.copyWith(
                    color: context.palette.textSecondary,
                  ),
                ),

                const SizedBox(height: 24),

                // All food items
                if (meal.foods.isEmpty)
                  Text(
                    lang.t('nutrition_no_ingredients_details_available'),
                    style: AppTextStyles.small.copyWith(
                      color: context.palette.textSecondary,
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
                                _localizedFoodName(food, lang),
                                style: AppTextStyles.h4.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_formatQuantity(food)}'
                                ' - ${bidiIsolate('${food.calories}')}'
                                ' ${lang.t('cal_unit')}'
                                ' - ${_foodMacroLine(food, lang)}',
                                style: AppTextStyles.small.copyWith(
                                  color: context.palette.textSecondary,
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
                  style: AppTextStyles.h3.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _mealInstructions(meal, lang),
                  style: AppTextStyles.small.copyWith(
                    color: context.palette.textSecondary,
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
                    style: AppTextStyles.caption.copyWith(
                      color: context.palette.textSecondary,
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
  /// TODO: Meal swap feature removed with deleted meal_detail_screen.
  /// Implement meal swap UI or remove this method if not needed.
  Future<void> _openMealSwap(Meal meal) async {
    final lang = context.read<LanguageProvider>();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(lang.t('meal_swap_not_available'))),
    );
  }
}

// Custom painter for macro rings
class _MacroRingPainter extends CustomPainter {
  final double percentage;
  final Color color;

  /// A painter has no BuildContext, so the theme-dependent track colour is
  /// resolved by the caller and passed in rather than read from a global.
  final Color trackColor;

  _MacroRingPainter({
    required this.percentage,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 8.0;

    // Background circle
    final bgPaint = Paint()
      ..color = trackColor
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
    return oldDelegate.percentage != percentage ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor;
  }
}

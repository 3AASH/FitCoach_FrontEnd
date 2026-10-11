import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../../core/theme/app_palette.dart';
import '../../providers/language_provider.dart';

class NutritionPreferencesIntakeScreen extends StatefulWidget {
  final FutureOr<void> Function(Map<String, dynamic> preferences) onComplete;
  final bool editMode;
  final VoidCallback onBack;
  final List<String>? missingFields;
  final List<Map<String, dynamic>>? questions;
  final Map<String, dynamic>? context;
  final String planType;

  const NutritionPreferencesIntakeScreen({
    super.key,
    required this.onComplete,
    required this.onBack,
    this.missingFields,
    this.questions,
    this.context,
    this.planType = 'starter',
    this.editMode = false,
  });

  @override
  State<NutritionPreferencesIntakeScreen> createState() =>
      _NutritionPreferencesIntakeScreenState();
}

class _NutritionPreferencesIntakeScreenState
    extends State<NutritionPreferencesIntakeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _trainingDaysController = TextEditingController();

  String _goal = 'general_fitness';
  String _dailyMovement = 'mostly_sitting';
  int _mealsPerDay = 3;
  final Set<String> _dietaryExclusions = {'none'};
  final Set<String> _medicalFlags = {'none'};
  final Set<String> _dislikedFoods = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final saved = widget.context ?? <String, dynamic>{};
    _goal = saved['goal']?.toString() ?? _goal;
    _dailyMovement = saved['daily_movement']?.toString() ?? _dailyMovement;
    _mealsPerDay = (saved['meals_per_day'] as num?)?.toInt() ?? 3;
    _ageController.text = saved['age']?.toString() ?? '';
    _heightController.text = saved['height_cm']?.toString() ?? '';
    _weightController.text = saved['weight_kg']?.toString() ?? '';
    _trainingDaysController.text = saved['training_days_per_week']?.toString() ?? '';
    if (saved['dietary_exclusions'] is List && (saved['dietary_exclusions'] as List).isNotEmpty) {
      _dietaryExclusions..clear()..addAll((saved['dietary_exclusions'] as List).map((e) => e.toString()));
    }
    if (saved['disliked_foods'] is List) {
      _dislikedFoods.addAll((saved['disliked_foods'] as List).map((e) => e.toString()));
    }
    if (saved['medical_nutrition_safety_screen'] is Map) {
      final flags = (saved['medical_nutrition_safety_screen'] as Map).entries
          .where((e) => e.value == true && e.key != 'screen_completed').map((e) => e.key.toString());
      if (flags.isNotEmpty) _medicalFlags..clear()..addAll(flags);
    }
  }

  /// Every question this form can ask, prefilled from the saved context. Used
  /// as-is when reviewing preferences, and as the fallback when the server did
  /// not tell us what is missing.
  ///
  /// `sex` is absent on purpose: the first workout intake owns that question,
  /// and the caller redirects there instead of asking it here.
  List<String> get _allFields => [
        'age',
        'height_cm',
        'weight_kg',
        'goal',
        'training_days_per_week',
        'daily_movement',
        'dietary_exclusions',
        'disliked_foods',
        if (widget.planType != 'starter') 'meals_per_day',
        if (widget.planType != 'starter') 'medical_nutrition_safety_screen',
      ];

  /// What this run actually asks.
  ///
  /// On a first pass we ask only what the server reported missing, so the
  /// questions the workout intakes already own (age, height, weight, goal,
  /// training days) are not put to the client a second time -- the server
  /// fills those from `user_intake` and omits them from `missingFields`.
  ///
  /// Edit mode is the exception: the client came here to change an answer, so
  /// the whole form is shown as a review even though nothing is missing.
  List<String> get _fields {
    final missing = widget.missingFields;
    if (widget.editMode || missing == null || missing.isEmpty) {
      return _allFields;
    }

    // 'sex' is owned by the first workout intake and is handled by the
    // redirect there, so it is never a question on this form.
    //
    // If that leaves nothing, ask nothing. Falling back to the whole form
    // here — which is what this used to do — meant a client missing only
    // `sex` was put through the entire questionnaire again, re-entering the
    // age, height, weight and goal they had already given the workout
    // intakes, to fix a field this form cannot even collect.
    return missing.where((field) => field != 'sex').toList();
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _trainingDaysController.dispose();
    super.dispose();
  }

  bool _needs(String field) => _fields.contains(field);

  bool _needsAny(List<String> fields) => fields.any(_needs);

  Future<void> _submit() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    final payload = <String, dynamic>{
      'plan_type': widget.planType,
      'disliked_foods': _dislikedFoods.where((food) => food != 'none').toList(),
    };

    if (_needs('age')) {
      payload['age'] = int.parse(_ageController.text.trim());
    }
    if (_needs('height_cm')) {
      payload['height_cm'] = double.parse(_heightController.text.trim());
    }
    if (_needs('weight_kg')) {
      payload['weight_kg'] = double.parse(_weightController.text.trim());
    }
    if (_needs('goal')) {
      payload['goal'] = _goal;
    }
    if (_needs('training_days_per_week')) {
      payload['training_days_per_week'] =
          int.parse(_trainingDaysController.text.trim());
    }
    if (_needs('daily_movement')) {
      payload['daily_movement'] = _dailyMovement;
    }
    if (_needs('dietary_exclusions')) {
      payload['dietary_exclusions'] = _dietaryExclusions.toList();
    }
    if (_needs('meals_per_day')) {
      payload['meals_per_day'] = _mealsPerDay;
    }
    if (_needs('medical_nutrition_safety_screen')) {
      payload['medical_nutrition_safety_screen'] =
          _medicalFlags.where((flag) => flag != 'none').isEmpty
              ? <String, dynamic>{'screen_completed': true}
              : {
                  for (final flag
                      in _medicalFlags.where((flag) => flag != 'none'))
                    flag: true,
                };
    }

    setState(() => _saving = true);
    try {
      await widget.onComplete(payload);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: lang.t('back'),
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        title: Text(lang.t('nutrition_intake_title')),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              _copy('subtitle', lang),
              style: TextStyle(color: context.palette.textSecondary),
            ),
            const SizedBox(height: 12),
            const SizedBox(height: 20),
            if (_needsAny(const [
              'age',
              'height_cm',
              'weight_kg',
              'goal',
              'training_days_per_week'
            ]))
              _buildBodyAndTrainingSection(lang),
            if (_needs('daily_movement')) _buildDailyMovementSection(lang),
            if (_needs('dietary_exclusions'))
              _buildDietaryExclusionsSection(lang),
            if (_needs('disliked_foods'))
              _Section(
                title: _copy('dislikedTitle', lang),
                children: [
                  Text(
                    _copy('dislikedDesc', lang),
                    style: TextStyle(color: context.palette.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  // Every code here is mapped to real ingredient ids by the
                  // engine, so each chip removes meals from the plan.
                  _buildMultiSelect(options: [
                    _Option('chicken', lang.t('nutrition_option_chicken')),
                    _Option('beef', lang.t('nutrition_option_beef')),
                    _Option('lamb', lang.t('nutrition_preferences_intake_lamb')),
                    _Option('fish', lang.t('nutrition_option_fish')),
                    _Option('shrimp', lang.t('nutrition_preferences_intake_shrimp')),
                    _Option('liver', lang.t('nutrition_preferences_intake_liver')),
                    _Option('egg', lang.t('nutrition_option_eggs')),
                    _Option('oats', lang.t('nutrition_preferences_intake_oats')),
                    _Option('lentils', lang.t('nutrition_preferences_intake_lentils')),
                    _Option('foul', lang.t('nutrition_preferences_intake_foul')),
                  ], selection: _dislikedFoods),
                ],
              ),
            if (_needs('meals_per_day')) _buildMealsPerDaySection(lang),
            if (_needs('medical_nutrition_safety_screen'))
              _buildMedicalSafetySection(lang),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : widget.onBack,
                    child: Text(lang.t('nutrition_intake_back')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    child: _saving
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(context.palette.textOnBrand),
                            ),
                          )
                        : Text(lang.t('nutrition_intake_complete')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyAndTrainingSection(LanguageProvider lang) {
    return _Section(
      title: _copy('bodyTrainingTitle', lang),
      children: [
        if (_needs('age'))
          _buildNumberField(
            controller: _ageController,
            label: _copy('age', lang),
            min: 13,
            max: 90,
          ),
        if (_needs('height_cm'))
          _buildNumberField(
            controller: _heightController,
            label: _copy('height', lang),
            min: 120,
            max: 230,
          ),
        if (_needs('weight_kg'))
          _buildNumberField(
            controller: _weightController,
            label: _copy('weight', lang),
            min: 35,
            max: 250,
          ),
        if (_needs('goal'))
          _buildSingleChoice(
            title: _copy('goal', lang),
            options: [
              _Option('fat_loss', _copy('fatLoss', lang)),
              _Option('general_fitness', _copy('generalFitness', lang)),
              _Option('muscle_gain', _copy('muscleGain', lang)),
              _Option('maintenance', _copy('maintenance', lang)),
            ],
            value: _goal,
            onChanged: (value) => setState(() => _goal = value),
          ),
        if (_needs('training_days_per_week'))
          _buildNumberField(
            controller: _trainingDaysController,
            label: _copy('trainingDays', lang),
            min: 1,
            max: 7,
          ),
      ],
    );
  }

  Widget _buildDailyMovementSection(LanguageProvider lang) {
    return _Section(
      title: _copy('dailyMovement', lang),
      children: [
        _buildSingleChoice(
          title: _copy('dailyMovementPrompt', lang),
          options: [
            _Option('mostly_sitting', _copy('mostlySitting', lang)),
            _Option('some_walking', _copy('someWalking', lang)),
            _Option('on_feet_most_day', _copy('onFeet', lang)),
            _Option('very_physical_job', _copy('physicalJob', lang)),
          ],
          value: _dailyMovement,
          onChanged: (value) => setState(() => _dailyMovement = value),
        ),
      ],
    );
  }

  Widget _buildDietaryExclusionsSection(LanguageProvider lang) {
    return _Section(
      title: _copy('restrictions', lang),
      children: [
        // Only codes the engine maps onto the recipe allergen vocabulary are
        // offered. "Soy" was removed because no recipe or ingredient in the
        // catalogue contains soy, and the halal option because every meal in
        // the catalogue is already halal - both looked like filters and were
        // silently ignored.
        _buildMultiSelect(
          options: [
            _Option('none', _copy('none', lang)),
            _Option('nuts', lang.t('nutrition_option_nuts')),
            _Option('sesame', lang.t('nutrition_preferences_intake_sesame')),
            _Option('eggs', lang.t('nutrition_option_eggs')),
            _Option('fish', lang.t('nutrition_option_fish')),
            _Option('shellfish', lang.t('nutrition_preferences_intake_shellfish')),
            _Option('dairy_lactose', _copy('dairy', lang)),
            _Option('gluten', _copy('gluten', lang)),
            _Option('vegetarian', _copy('vegetarian', lang)),
            _Option('vegan', _copy('vegan', lang)),
          ],
          selection: _dietaryExclusions,
        ),
        const SizedBox(height: 10),
        Text(
          _copy('halalNote', lang),
          style: TextStyle(color: context.palette.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildMealsPerDaySection(LanguageProvider lang) {
    return _Section(
      title: _copy('mealsPerDay', lang),
      children: [
        _buildSingleChoice(
          title: _copy('mealsPerDayPrompt', lang),
          options: const [
            _Option('3', '3'),
            _Option('4', '4'),
            _Option('5', '5'),
          ],
          value: _mealsPerDay.toString(),
          onChanged: (value) => setState(() => _mealsPerDay = int.parse(value)),
        ),
      ],
    );
  }

  Widget _buildMedicalSafetySection(LanguageProvider lang) {
    return _Section(
      title: _copy('medicalTitle', lang),
      children: [
        Text(
          _copy('medicalDesc', lang),
          style: TextStyle(color: context.palette.textSecondary),
        ),
        const SizedBox(height: 12),
        _buildMultiSelect(
          options: [
            _Option('none', _copy('none', lang)),
            _Option('pregnancy', _copy('pregnancy', lang)),
            _Option('eating_disorder', _copy('eatingDisorder', lang)),
            _Option('kidney_liver_disease', _copy('kidneyLiver', lang)),
            _Option('type_1_diabetes', _copy('type1Diabetes', lang)),
            _Option('complex_diabetes_medication',
                _copy('diabetesMedication', lang)),
            _Option('bariatric_surgery', _copy('bariatric', lang)),
            _Option('therapeutic_diet', _copy('therapeuticDiet', lang)),
          ],
          selection: _medicalFlags,
        ),
      ],
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required num min,
    required num max,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (value) {
          final parsed = num.tryParse((value ?? '').trim());
          if (parsed == null) return 'Required';
          if (parsed < min || parsed > max) return 'Check this value';
          return null;
        },
      ),
    );
  }

  Widget _buildSingleChoice({
    required String title,
    required List<_Option> options,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options
                .map(
                  (option) => ChoiceChip(
                    label: Text(option.label),
                    selected: option.value == value,
                    onSelected: (_) => onChanged(option.value),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiSelect({
    required List<_Option> options,
    required Set<String> selection,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options
          .map(
            (option) => FilterChip(
              label: Text(option.label),
              selected: selection.contains(option.value),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    if (option.value == 'none') {
                      selection
                        ..clear()
                        ..add('none');
                    } else {
                      selection
                        ..remove('none')
                        ..add(option.value);
                    }
                  } else {
                    selection.remove(option.value);
                    if (selection.isEmpty && options.any((option) => option.value == 'none')) selection.add('none');
                  }
                });
              },
            ),
          )
          .toList(),
    );
  }

  String _copy(String key, LanguageProvider lang) {
    final en = {
      'subtitle':
          'Check these details before we build your plan. Anything you have already answered is filled in.',
      'bodyTrainingTitle': 'Body and Training Details',
      'age': 'Age',
      'height': 'Height in cm',
      'weight': 'Weight in kg',
      'goal': 'Goal',
      'fatLoss': 'Fat loss',
      'generalFitness': 'General fitness',
      'muscleGain': 'Muscle gain',
      'maintenance': 'Maintenance',
      'trainingDays': 'Training days per week',
      'dailyMovement': 'Daily Movement',
      'dailyMovementPrompt': 'Outside workouts, your normal day is mostly:',
      'mostlySitting': 'Mostly sitting',
      'someWalking': 'Some walking',
      'onFeet': 'On feet most of the day',
      'physicalJob': 'Very physical job',
      'restrictions': 'Food Restrictions',
      'none': 'None',
      'dairy': 'Dairy / lactose',
      'gluten': 'Gluten',
      'vegetarian': 'Vegetarian',
      'vegan': 'Vegan',
      'halalNote': 'Every meal in the plan is halal.',
      'dislikedTitle': 'Foods to avoid',
      'dislikedDesc': 'Meals containing these are left out of your plan.',
      'mealsPerDay': 'Meals Per Day',
      'mealsPerDayPrompt': 'How many meals do you prefer?',
      'medicalTitle': 'Medical Safety Review',
      'medicalDesc':
          'Select any condition that applies. These require coach/admin review before activation.',
      'pregnancy': 'Pregnancy',
      'eatingDisorder': 'Eating disorder history',
      'kidneyLiver': 'Kidney or liver disease',
      'type1Diabetes': 'Type 1 diabetes',
      'diabetesMedication': 'Complex diabetes medication',
      'bariatric': 'Bariatric surgery',
      'therapeuticDiet': 'Therapeutic diet',
    };
    final ar = {
      'subtitle': 'راجع هذه البيانات قبل إنشاء خطتك. ما سبق أن أجبت عنه تم ملؤه تلقائيا.',
      'bodyTrainingTitle': 'بيانات الجسم والتمرين',
      'age': 'العمر',
      'height': 'الطول بالسنتيمتر',
      'weight': 'الوزن بالكيلوجرام',
      'goal': 'الهدف',
      'fatLoss': 'خسارة الدهون',
      'generalFitness': 'لياقة عامة',
      'muscleGain': 'زيادة العضلات',
      'maintenance': 'ثبات الوزن',
      'trainingDays': 'أيام التمرين أسبوعيا',
      'dailyMovement': 'الحركة اليومية',
      'dailyMovementPrompt': 'بعيدا عن التمرين، يومك غالبا:',
      'mostlySitting': 'جلوس أغلب الوقت',
      'someWalking': 'بعض المشي',
      'onFeet': 'وقوف أغلب اليوم',
      'physicalJob': 'عمل بدني شديد',
      'restrictions': 'قيود الطعام',
      'none': 'لا يوجد',
      'dairy': 'ألبان / لاكتوز',
      'gluten': 'جلوتين',
      'vegetarian': 'نباتي',
      'vegan': 'نباتي بالكامل',
      'halalNote': 'كل الوجبات في الخطة حلال.',
      'dislikedTitle': 'أطعمة لا تفضلها',
      'dislikedDesc': 'الوجبات التي تحتوي على هذه الأصناف لن تظهر في خطتك.',
      'mealsPerDay': 'عدد الوجبات',
      'mealsPerDayPrompt': 'كم وجبة تفضل؟',
      'medicalTitle': 'مراجعة السلامة الطبية',
      'medicalDesc':
          'اختر أي حالة تنطبق عليك. هذه الحالات تحتاج مراجعة مدرب أو أدمن قبل التفعيل.',
      'pregnancy': 'حمل',
      'eatingDisorder': 'تاريخ اضطراب أكل',
      'kidneyLiver': 'مرض كلى أو كبد',
      'type1Diabetes': 'سكري نوع أول',
      'diabetesMedication': 'أدوية سكري معقدة',
      'bariatric': 'جراحة سمنة',
      'therapeuticDiet': 'نظام علاجي',
    };
    return (lang.isArabic ? ar : en)[key] ?? key;
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _Option {
  final String value;
  final String label;

  const _Option(this.value, this.label);
}

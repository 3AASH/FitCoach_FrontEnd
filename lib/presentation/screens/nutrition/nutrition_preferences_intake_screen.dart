import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
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

  /// The questions this form asks, which deliberately do not depend on what is
  /// already answered. The screen used to render only the fields the server
  /// reported missing, plus two extras in edit mode, so a client who came back
  /// to change a preference was shown a different questionnaire than the one
  /// they first filled in. Everything is shown every time and prefilled from
  /// the saved context, which makes this a review screen rather than a quiz.
  ///
  /// `sex` is absent on purpose: the first workout intake owns that question.
  List<String> get _fields => [
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
    final isArabic = lang.isArabic;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(isArabic ? Icons.arrow_forward : Icons.arrow_back),
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
              _copy('subtitle', isArabic),
              style: const TextStyle(color: Colors.black54),
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
              _buildBodyAndTrainingSection(isArabic),
            if (_needs('daily_movement')) _buildDailyMovementSection(isArabic),
            if (_needs('dietary_exclusions'))
              _buildDietaryExclusionsSection(isArabic),
            if (_needs('disliked_foods'))
              _Section(
                title: _copy('dislikedTitle', isArabic),
                children: [
                  Text(
                    _copy('dislikedDesc', isArabic),
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                  // Every code here is mapped to real ingredient ids by the
                  // engine, so each chip removes meals from the plan.
                  _buildMultiSelect(options: [
                    _Option('chicken', isArabic ? 'دجاج' : 'Chicken'),
                    _Option('beef', isArabic ? 'لحم بقري' : 'Beef'),
                    _Option('lamb', isArabic ? 'لحم ضأن' : 'Lamb'),
                    _Option('fish', isArabic ? 'سمك' : 'Fish'),
                    _Option('shrimp', isArabic ? 'جمبري' : 'Shrimp'),
                    _Option('liver', isArabic ? 'كبدة' : 'Liver'),
                    _Option('egg', isArabic ? 'بيض' : 'Eggs'),
                    _Option('oats', isArabic ? 'شوفان' : 'Oats'),
                    _Option('lentils', isArabic ? 'عدس' : 'Lentils'),
                    _Option('foul', isArabic ? 'فول' : 'Foul'),
                  ], selection: _dislikedFoods),
                ],
              ),
            if (_needs('meals_per_day')) _buildMealsPerDaySection(isArabic),
            if (_needs('medical_nutrition_safety_screen'))
              _buildMedicalSafetySection(isArabic),
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
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
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

  Widget _buildBodyAndTrainingSection(bool isArabic) {
    return _Section(
      title: _copy('bodyTrainingTitle', isArabic),
      children: [
        if (_needs('age'))
          _buildNumberField(
            controller: _ageController,
            label: _copy('age', isArabic),
            min: 13,
            max: 90,
          ),
        if (_needs('height_cm'))
          _buildNumberField(
            controller: _heightController,
            label: _copy('height', isArabic),
            min: 120,
            max: 230,
          ),
        if (_needs('weight_kg'))
          _buildNumberField(
            controller: _weightController,
            label: _copy('weight', isArabic),
            min: 35,
            max: 250,
          ),
        if (_needs('goal'))
          _buildSingleChoice(
            title: _copy('goal', isArabic),
            options: [
              _Option('fat_loss', _copy('fatLoss', isArabic)),
              _Option('general_fitness', _copy('generalFitness', isArabic)),
              _Option('muscle_gain', _copy('muscleGain', isArabic)),
              _Option('maintenance', _copy('maintenance', isArabic)),
            ],
            value: _goal,
            onChanged: (value) => setState(() => _goal = value),
          ),
        if (_needs('training_days_per_week'))
          _buildNumberField(
            controller: _trainingDaysController,
            label: _copy('trainingDays', isArabic),
            min: 1,
            max: 7,
          ),
      ],
    );
  }

  Widget _buildDailyMovementSection(bool isArabic) {
    return _Section(
      title: _copy('dailyMovement', isArabic),
      children: [
        _buildSingleChoice(
          title: _copy('dailyMovementPrompt', isArabic),
          options: [
            _Option('mostly_sitting', _copy('mostlySitting', isArabic)),
            _Option('some_walking', _copy('someWalking', isArabic)),
            _Option('on_feet_most_day', _copy('onFeet', isArabic)),
            _Option('very_physical_job', _copy('physicalJob', isArabic)),
          ],
          value: _dailyMovement,
          onChanged: (value) => setState(() => _dailyMovement = value),
        ),
      ],
    );
  }

  Widget _buildDietaryExclusionsSection(bool isArabic) {
    return _Section(
      title: _copy('restrictions', isArabic),
      children: [
        // Only codes the engine maps onto the recipe allergen vocabulary are
        // offered. "Soy" was removed because no recipe or ingredient in the
        // catalogue contains soy, and the halal option because every meal in
        // the catalogue is already halal - both looked like filters and were
        // silently ignored.
        _buildMultiSelect(
          options: [
            _Option('none', _copy('none', isArabic)),
            _Option('nuts', isArabic ? 'مكسرات' : 'Nuts'),
            _Option('sesame', isArabic ? 'سمسم' : 'Sesame'),
            _Option('eggs', isArabic ? 'بيض' : 'Eggs'),
            _Option('fish', isArabic ? 'سمك' : 'Fish'),
            _Option('shellfish', isArabic ? 'محار وقشريات' : 'Shellfish'),
            _Option('dairy_lactose', _copy('dairy', isArabic)),
            _Option('gluten', _copy('gluten', isArabic)),
            _Option('vegetarian', _copy('vegetarian', isArabic)),
            _Option('vegan', _copy('vegan', isArabic)),
          ],
          selection: _dietaryExclusions,
        ),
        const SizedBox(height: 10),
        Text(
          _copy('halalNote', isArabic),
          style: const TextStyle(color: Colors.black54, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildMealsPerDaySection(bool isArabic) {
    return _Section(
      title: _copy('mealsPerDay', isArabic),
      children: [
        _buildSingleChoice(
          title: _copy('mealsPerDayPrompt', isArabic),
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

  Widget _buildMedicalSafetySection(bool isArabic) {
    return _Section(
      title: _copy('medicalTitle', isArabic),
      children: [
        Text(
          _copy('medicalDesc', isArabic),
          style: const TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 12),
        _buildMultiSelect(
          options: [
            _Option('none', _copy('none', isArabic)),
            _Option('pregnancy', _copy('pregnancy', isArabic)),
            _Option('eating_disorder', _copy('eatingDisorder', isArabic)),
            _Option('kidney_liver_disease', _copy('kidneyLiver', isArabic)),
            _Option('type_1_diabetes', _copy('type1Diabetes', isArabic)),
            _Option('complex_diabetes_medication',
                _copy('diabetesMedication', isArabic)),
            _Option('bariatric_surgery', _copy('bariatric', isArabic)),
            _Option('therapeutic_diet', _copy('therapeuticDiet', isArabic)),
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

  String _copy(String key, bool isArabic) {
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
    return (isArabic ? ar : en)[key] ?? key;
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

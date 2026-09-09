import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';

class NutritionPreferencesIntakeScreen extends StatefulWidget {
  final void Function(Map<String, dynamic> preferences) onComplete;
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

  String _sex = 'male';
  String _goal = 'general_fitness';
  String _dailyMovement = 'mostly_sitting';
  int _mealsPerDay = 3;
  final Set<String> _dietaryExclusions = {'none'};
  final Set<String> _medicalFlags = {'none'};

  List<String> get _fields {
    final fields = widget.missingFields ?? const <String>[];
    if (fields.isNotEmpty) return fields;
    return const ['dietary_exclusions'];
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final payload = <String, dynamic>{
      'plan_type': widget.planType,
    };

    if (_needsAny(const ['sex', 'gender'])) {
      payload['sex'] = _sex;
    }
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
              ? <String, dynamic>{}
              : {
                  for (final flag
                      in _medicalFlags.where((flag) => flag != 'none'))
                    flag: true,
                };
    }

    widget.onComplete(payload);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final isArabic = lang.isArabic;
    final progress = _fields.isEmpty ? 1.0 : 0.5;

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
            LinearProgressIndicator(value: progress, minHeight: 6),
            const SizedBox(height: 20),
            if (_needsAny(const [
              'sex',
              'gender',
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
            if (_needs('meals_per_day')) _buildMealsPerDaySection(isArabic),
            if (_needs('medical_nutrition_safety_screen'))
              _buildMedicalSafetySection(isArabic),
            if (_fields.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  _copy('nothingMissing', isArabic),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onBack,
                    child: Text(lang.t('nutrition_intake_back')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submit,
                    child: Text(lang.t('nutrition_intake_complete')),
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
        if (_needsAny(const ['sex', 'gender']))
          _buildSingleChoice(
            title: _copy('sex', isArabic),
            options: [
              _Option('male', _copy('male', isArabic)),
              _Option('female', _copy('female', isArabic)),
            ],
            value: _sex,
            onChanged: (value) => setState(() => _sex = value),
          ),
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
        _buildMultiSelect(
          options: [
            _Option('none', _copy('none', isArabic)),
            _Option('food_allergy', _copy('foodAllergy', isArabic)),
            _Option('dairy_lactose', _copy('dairy', isArabic)),
            _Option('gluten', _copy('gluten', isArabic)),
            _Option('vegetarian', _copy('vegetarian', isArabic)),
            _Option('vegan', _copy('vegan', isArabic)),
            _Option('other_intolerance', _copy('intolerance', isArabic)),
            _Option('personal_religious', _copy('religious', isArabic)),
          ],
          selection: _dietaryExclusions,
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
                    if (selection.isEmpty) selection.add('none');
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
      'subtitle': 'Only the missing nutrition details are needed.',
      'nothingMissing': 'All required nutrition details are already available.',
      'bodyTrainingTitle': 'Body and Training Details',
      'sex': 'Sex',
      'male': 'Male',
      'female': 'Female',
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
      'foodAllergy': 'Food allergy',
      'dairy': 'Dairy / lactose',
      'gluten': 'Gluten',
      'vegetarian': 'Vegetarian',
      'vegan': 'Vegan',
      'intolerance': 'Other intolerance',
      'religious': 'Personal / religious',
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
      'subtitle': 'نحتاج فقط تفاصيل التغذية الناقصة.',
      'nothingMissing': 'كل تفاصيل التغذية المطلوبة متوفرة بالفعل.',
      'bodyTrainingTitle': 'بيانات الجسم والتمرين',
      'sex': 'النوع',
      'male': 'ذكر',
      'female': 'أنثى',
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
      'foodAllergy': 'حساسية طعام',
      'dairy': 'ألبان / لاكتوز',
      'gluten': 'جلوتين',
      'vegetarian': 'نباتي',
      'vegan': 'نباتي بالكامل',
      'intolerance': 'عدم تحمل آخر',
      'religious': 'شخصي / ديني',
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

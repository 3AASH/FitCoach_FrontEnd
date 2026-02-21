import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';

class NutritionPreferencesIntakeScreen extends StatefulWidget {
  final void Function(Map<String, dynamic> preferences) onComplete;
  final VoidCallback onBack;

  const NutritionPreferencesIntakeScreen({
    super.key,
    required this.onComplete,
    required this.onBack,
  });

  @override
  State<NutritionPreferencesIntakeScreen> createState() => _NutritionPreferencesIntakeScreenState();
}

class _NutritionPreferencesIntakeScreenState extends State<NutritionPreferencesIntakeScreen> {
  int _step = 0;
  final Set<String> _proteinSources = {};
  final Set<String> _proteinAllergies = {};
  String _portionSize = 'moderate';
  String _prepSpeed = 'normal';
  String _carbLevel = 'includes_carbs';
  String _temperature = 'both';
  final Set<String> _cuisines = {};
  final Set<String> _avoid = {};
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_step < 2) {
      setState(() => _step += 1);
    } else {
      widget.onComplete(_buildPreferences());
    }
  }

  void _prevStep() {
    if (_step == 0) {
      widget.onBack();
    } else {
      setState(() => _step -= 1);
    }
  }

  Map<String, dynamic> _buildPreferences() {
    return {
      'proteinSources': _proteinSources.toList(),
      'proteinAllergies': _proteinAllergies.toList(),
      'dinnerPreferences': {
        'portionSize': _portionSize,
        'prepSpeed': _prepSpeed,
        'carbLevel': _carbLevel,
        'temperature': _temperature,
        'cuisines': _cuisines.toList(),
        'avoid': _avoid.toList(),
      },
      'additionalNotes': _notesController.text.trim(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final isArabic = lang.isArabic;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(isArabic ? Icons.arrow_forward : Icons.arrow_back),
          onPressed: _prevStep,
        ),
        title: Text(lang.t('nutrition_intake_title')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang.t('nutrition_intake_subtitle'),
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: (_step + 1) / 3,
              minHeight: 6,
            ),
            const SizedBox(height: 20),
            Expanded(child: _buildStepContent(lang, isArabic)),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _prevStep,
                    child: Text(lang.t('nutrition_intake_back')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _nextStep,
                    child: Text(
                      _step == 2 ? lang.t('nutrition_intake_complete') : lang.t('nutrition_intake_next'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(LanguageProvider lang, bool isArabic) {
    switch (_step) {
      case 0:
        return _buildProteinStep(lang, isArabic);
      case 1:
        return _buildDinnerStep(lang, isArabic);
      default:
        return _buildNotesStep(lang);
    }
  }

  Widget _buildProteinStep(LanguageProvider lang, bool isArabic) {
    final sources = [
      _Option('chicken', lang.t('nutrition_option_chicken')),
      _Option('eggs', lang.t('nutrition_option_eggs')),
      _Option('fish', lang.t('nutrition_option_fish')),
      _Option('beef', lang.t('nutrition_option_beef')),
      _Option('plant', lang.t('nutrition_option_plant')),
    ];
    final allergies = [
      _Option('dairy', lang.t('nutrition_option_dairy')),
      _Option('gluten', lang.t('nutrition_option_gluten')),
      _Option('nuts', lang.t('nutrition_option_nuts')),
      _Option('soy', lang.t('nutrition_option_soy')),
    ];

    return ListView(
      children: [
        Text(
          lang.t('nutrition_intake_step1_title'),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(lang.t('nutrition_intake_step1_desc'), style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 16),
        Text(lang.t('nutrition_intake_protein_sources'), style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        _buildMultiSelectChips(sources, _proteinSources),
        const SizedBox(height: 16),
        Text(lang.t('nutrition_intake_allergies'), style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        _buildMultiSelectChips(allergies, _proteinAllergies),
      ],
    );
  }

  Widget _buildDinnerStep(LanguageProvider lang, bool isArabic) {
    return ListView(
      children: [
        Text(
          lang.t('nutrition_intake_step2_title'),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(lang.t('nutrition_intake_step2_desc'), style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 16),
        _buildSingleChoice(
          title: lang.t('nutrition_intake_portion'),
          options: [
            _Option('light', lang.t('nutrition_option_light')),
            _Option('moderate', lang.t('nutrition_option_moderate')),
            _Option('filling', lang.t('nutrition_option_filling')),
          ],
          value: _portionSize,
          onChanged: (value) => setState(() => _portionSize = value),
        ),
        const SizedBox(height: 12),
        _buildSingleChoice(
          title: lang.t('nutrition_intake_prep_speed'),
          options: [
            _Option('quick', lang.t('nutrition_option_quick')),
            _Option('normal', lang.t('nutrition_option_normal')),
            _Option('prep_ahead', lang.t('nutrition_option_prep_ahead')),
          ],
          value: _prepSpeed,
          onChanged: (value) => setState(() => _prepSpeed = value),
        ),
        const SizedBox(height: 12),
        _buildSingleChoice(
          title: lang.t('nutrition_intake_carb_level'),
          options: [
            _Option('no_carb', lang.t('nutrition_option_no_carb')),
            _Option('low_carb', lang.t('nutrition_option_low_carb')),
            _Option('includes_carbs', lang.t('nutrition_option_includes_carbs')),
          ],
          value: _carbLevel,
          onChanged: (value) => setState(() => _carbLevel = value),
        ),
        const SizedBox(height: 12),
        _buildSingleChoice(
          title: lang.t('nutrition_intake_temperature'),
          options: [
            _Option('hot', lang.t('nutrition_option_hot')),
            _Option('cold', lang.t('nutrition_option_cold')),
            _Option('both', lang.t('nutrition_option_both')),
          ],
          value: _temperature,
          onChanged: (value) => setState(() => _temperature = value),
        ),
        const SizedBox(height: 16),
        Text(lang.t('nutrition_intake_cuisines'), style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        _buildMultiSelectChips(
          [
            _Option('mediterranean', lang.t('nutrition_option_mediterranean')),
            _Option('arabic', lang.t('nutrition_option_arabic')),
            _Option('asian', lang.t('nutrition_option_asian')),
            _Option('italian', lang.t('nutrition_option_italian')),
          ],
          _cuisines,
        ),
        const SizedBox(height: 16),
        Text(lang.t('nutrition_intake_avoid'), style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        _buildMultiSelectChips(
          [
            _Option('spicy', lang.t('nutrition_option_spicy')),
            _Option('fried', lang.t('nutrition_option_fried')),
            _Option('sugary', lang.t('nutrition_option_sugary')),
            _Option('none', lang.t('nutrition_option_none')),
          ],
          _avoid,
        ),
      ],
    );
  }

  Widget _buildNotesStep(LanguageProvider lang) {
    return ListView(
      children: [
        Text(
          lang.t('nutrition_intake_step3_title'),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(lang.t('nutrition_intake_step3_desc'), style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 16),
        TextField(
          controller: _notesController,
          maxLines: 6,
          decoration: InputDecoration(
            hintText: lang.t('nutrition_intake_notes_placeholder'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildMultiSelectChips(List<_Option> options, Set<String> selection) {
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
                    selection.add(option.value);
                  } else {
                    selection.remove(option.value);
                  }
                });
              },
            ),
          )
          .toList(),
    );
  }

  Widget _buildSingleChoice({
    required String title,
    required List<_Option> options,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
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
    );
  }
}

class _Option {
  final String value;
  final String label;

  const _Option(this.value, this.label);
}

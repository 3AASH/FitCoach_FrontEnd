import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../providers/language_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';

class SecondIntakeScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback? onBack;

  const SecondIntakeScreen({
    super.key,
    required this.onComplete,
    this.onBack,
  });

  @override
  State<SecondIntakeScreen> createState() => _SecondIntakeScreenState();
}

class _SecondIntakeScreenState extends State<SecondIntakeScreen> {
  int _currentStep = 0;

  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  String? _selectedExperience;
  int? _selectedFrequency;

  final List<String> _selectedInjuries = [];
  final List<int> _frequencies = [2, 3, 4, 5, 6];

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _submitIntake() async {
    if (_ageController.text.isEmpty ||
        _weightController.text.isEmpty ||
        _heightController.text.isEmpty ||
        _selectedExperience == null ||
        _selectedFrequency == null) {
      _showError(context.read<LanguageProvider>().t('intake_incomplete'));
      return;
    }

    final userProvider = context.read<UserProvider>();
    final authProvider = context.read<AuthProvider>();

    final success = await userProvider.submitSecondIntake({
      'age': int.parse(_ageController.text),
      'weight': double.parse(_weightController.text),
      'height': int.parse(_heightController.text),
      'experienceLevel': _selectedExperience,
      'workoutFrequency': _selectedFrequency,
      'injuries': _selectedInjuries,
    });

    if (success && mounted) {
      if (userProvider.profile != null) {
        authProvider.updateUser(userProvider.profile!);
      }
      await _showGeneratingPlan(context.read<LanguageProvider>());
      if (mounted) {
        widget.onComplete();
      }
    } else if (userProvider.error != null && mounted) {
      _showError(userProvider.error!);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  Future<void> _showGeneratingPlan(LanguageProvider lang) async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => _GeneratingPlanScreen(lang: lang),
      ),
    );
  }

  bool _canProceedToNext() {
    switch (_currentStep) {
      case 0:
        return _ageController.text.isNotEmpty;
      case 1:
        return _weightController.text.isNotEmpty && _heightController.text.isNotEmpty;
      case 2:
        return _selectedExperience != null;
      case 3:
        return _selectedFrequency != null;
      default:
        return true;
    }
  }

  void _toggleInjury(String value) {
    setState(() {
      if (_selectedInjuries.contains(value)) {
        _selectedInjuries.remove(value);
      } else {
        _selectedInjuries.add(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final userProvider = context.watch<UserProvider>();
    final isArabic = languageProvider.isArabic;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1680761827444-9214a9c3129f?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=1080',
              fit: BoxFit.cover,
              color: Colors.black.withValues(alpha: 0.2),
              colorBlendMode: BlendMode.darken,
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.auto_awesome, color: AppColors.secondaryForeground, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    languageProvider.t('intake_second_title'),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${_currentStep + 1}/5',
                              style: const TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          languageProvider.t('intake_second_subtitle'),
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: (_currentStep + 1) / 5,
                          backgroundColor: AppColors.surface,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondaryForeground),
                        ),
                        const SizedBox(height: 24),
                        _buildCurrentStep(languageProvider),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  if (_currentStep > 0) {
                                    setState(() => _currentStep--);
                                  } else {
                                    if (widget.onBack != null) {
                                      widget.onBack!();
                                    } else {
                                      Navigator.of(context).pop();
                                    }
                                  }
                                },
                                child: Text(languageProvider.t('back')),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.secondaryForeground,
                                ),
                                onPressed: userProvider.isLoading
                                    ? null
                                    : () {
                                        if (!_canProceedToNext()) {
                                          _showError(languageProvider.t('intake_incomplete'));
                                          return;
                                        }
                                        if (_currentStep < 4) {
                                          setState(() => _currentStep++);
                                        } else {
                                          _submitIntake();
                                        }
                                      },
                                child: userProvider.isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            _currentStep == 4
                                                ? languageProvider.t('intake_second_complete')
                                                : languageProvider.t('continue'),
                                          ),
                                          const SizedBox(width: 6),
                                          Icon(
                                            isArabic ? Icons.arrow_back : Icons.arrow_forward,
                                            size: 18,
                                          ),
                                        ],
                                      ),
                              ),
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
        ],
      ),
    );
  }

  Widget _buildCurrentStep(LanguageProvider lang) {
    switch (_currentStep) {
      case 0:
        return _StepSection(
          icon: Icons.calendar_month,
          title: lang.t('intake_second_age_title'),
          description: lang.t('intake_second_age_desc'),
          children: [
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              decoration: InputDecoration(
                labelText: lang.t('age'),
                hintText: '28',
                suffixText: lang.t('years'),
                prefixIcon: const Icon(Icons.cake),
              ),
            ),
          ],
        );
      case 1:
        return _StepSection(
          icon: Icons.monitor_weight,
          title: lang.t('intake_second_body_metrics_title'),
          description: lang.t('intake_second_body_metrics_desc'),
          children: [
            TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
              ],
              decoration: InputDecoration(
                labelText: lang.t('weight'),
                hintText: '78',
                suffixText: lang.t('kg'),
                prefixIcon: const Icon(Icons.monitor_weight_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _heightController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              decoration: InputDecoration(
                labelText: lang.t('height'),
                hintText: '178',
                suffixText: lang.t('cm'),
                prefixIcon: const Icon(Icons.height),
              ),
            ),
          ],
        );
      case 2:
        return _StepSection(
          icon: Icons.fitness_center,
          title: lang.t('experience_level_title'),
          description: lang.t('experience_level_desc'),
          children: [
            _buildRadioOption(
              title: lang.t('experience_beginner'),
              subtitle: lang.t('experience_beginner_desc'),
              isSelected: _selectedExperience == 'beginner',
              onTap: () => setState(() => _selectedExperience = 'beginner'),
            ),
            const SizedBox(height: 12),
            _buildRadioOption(
              title: lang.t('experience_intermediate'),
              subtitle: lang.t('experience_intermediate_desc'),
              isSelected: _selectedExperience == 'intermediate',
              onTap: () => setState(() => _selectedExperience = 'intermediate'),
            ),
            const SizedBox(height: 12),
            _buildRadioOption(
              title: lang.t('experience_advanced'),
              subtitle: lang.t('experience_advanced_desc'),
              isSelected: _selectedExperience == 'advanced',
              onTap: () => setState(() => _selectedExperience = 'advanced'),
            ),
          ],
        );
      case 3:
        return _StepSection(
          icon: Icons.calendar_today,
          title: lang.t('intake_second_frequency_title'),
          description: lang.t('intake_second_frequency_desc'),
          children: [
            DropdownButtonFormField<int>(
              value: _selectedFrequency,
              decoration: InputDecoration(
                labelText: lang.t('workout_frequency'),
              ),
              items: _frequencies
                  .map(
                    (value) => DropdownMenuItem<int>(
                      value: value,
                      child: Text('$value'),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedFrequency = value),
            ),
          ],
        );
      case 4:
        return _StepSection(
          icon: Icons.warning_amber_rounded,
          title: lang.t('intake_second_injuries_title'),
          description: lang.t('intake_second_injuries_desc'),
          children: [
            _buildInjuryOption(lang.t('injury_shoulder'), 'shoulder'),
            _buildInjuryOption(lang.t('injury_knee'), 'knee'),
            _buildInjuryOption(lang.t('injury_lower_back'), 'lower_back'),
            _buildInjuryOption(lang.t('injury_neck'), 'neck'),
            _buildInjuryOption(lang.t('injury_ankle'), 'ankle'),
            if (_selectedInjuries.isEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        lang.t('intake_second_injuries_none'),
                        style: const TextStyle(color: AppColors.success),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildInjuryOption(String label, String value) {
    final isSelected = _selectedInjuries.contains(value);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _toggleInjury(value),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.secondaryForeground.withValues(alpha: 0.08)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.secondaryForeground : AppColors.border,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Checkbox(
                value: isSelected,
                onChanged: (_) => _toggleInjury(value),
                activeColor: AppColors.secondaryForeground,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? AppColors.secondaryForeground : Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadioOption({
    required String title,
    String? subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondaryForeground.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.secondaryForeground : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Radio<bool>(
              value: true,
              groupValue: isSelected,
              onChanged: (_) => onTap(),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final List<Widget> children;

  const _StepSection({
    required this.icon,
    required this.title,
    required this.description,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          children: [
            Icon(icon, size: 56, color: AppColors.secondaryForeground),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        const SizedBox(height: 20),
        ...children,
      ],
    );
  }
}

class _GeneratingPlanScreen extends StatefulWidget {
  final LanguageProvider lang;

  const _GeneratingPlanScreen({required this.lang});

  @override
  State<_GeneratingPlanScreen> createState() => _GeneratingPlanScreenState();
}

class _GeneratingPlanScreenState extends State<_GeneratingPlanScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF4E9FF), Color(0xFFE7F0FF)],
          ),
        ),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.secondaryForeground,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.fitness_center, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.lang.t('intake_generating_title'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.lang.t('intake_generating_desc'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                const LinearProgressIndicator(
                  value: 0.75,
                  backgroundColor: AppColors.surface,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondaryForeground),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

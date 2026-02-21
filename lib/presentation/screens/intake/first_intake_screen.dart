import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../providers/language_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';

class FirstIntakeScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  const FirstIntakeScreen({
    super.key,
    required this.onComplete,
    required this.onSkip,
  });

  @override
  State<FirstIntakeScreen> createState() => _FirstIntakeScreenState();
}

class _FirstIntakeScreenState extends State<FirstIntakeScreen> {
  int _currentStep = 0;

  String? _selectedGender;
  String? _selectedGoal;
  String? _selectedLocation;

  Future<void> _submitIntake() async {
    if (_selectedGender == null || _selectedGoal == null || _selectedLocation == null) {
      _showError(context.read<LanguageProvider>().t('intake_incomplete'));
      return;
    }

    final userProvider = context.read<UserProvider>();
    final authProvider = context.read<AuthProvider>();

    final success = await userProvider.submitFirstIntake({
      'gender': _selectedGender,
      'mainGoal': _selectedGoal,
      'workoutLocation': _selectedLocation,
    });

    if (success && mounted) {
      if (userProvider.profile != null) {
        authProvider.updateUser(userProvider.profile!);
      }
      widget.onComplete();
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
              'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=1080',
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
                                  const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    languageProvider.t('intake_first_title'),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${_currentStep + 1}/3',
                              style: const TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          languageProvider.t('intake_first_subtitle'),
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: (_currentStep + 1) / 3,
                          backgroundColor: AppColors.surface,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                        const SizedBox(height: 24),
                        _buildCurrentStep(languageProvider),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _currentStep > 0 ? () {
                                  setState(() => _currentStep--);
                                } : widget.onSkip,
                                child: Text(languageProvider.t('back')),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: userProvider.isLoading
                                    ? null
                                    : () {
                                        if (!_canProceedToNext()) {
                                          _showError(languageProvider.t('intake_select_option'));
                                          return;
                                        }
                                        if (_currentStep < 2) {
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
                                            _currentStep == 2
                                                ? languageProvider.t('intake_first_complete')
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

  bool _canProceedToNext() {
    switch (_currentStep) {
      case 0:
        return _selectedGender != null;
      case 1:
        return _selectedGoal != null;
      case 2:
        return _selectedLocation != null;
      default:
        return false;
    }
  }

  Widget _buildCurrentStep(LanguageProvider lang) {
    switch (_currentStep) {
      case 0:
        return _buildGenderStep(lang);
      case 1:
        return _buildGoalStep(lang);
      case 2:
        return _buildLocationStep(lang);
      default:
        return const SizedBox();
    }
  }

  Widget _buildGenderStep(LanguageProvider lang) {
    return _StepSection(
      icon: Icons.people_alt,
      title: lang.t('intake_first_gender_title'),
      description: lang.t('intake_first_gender_desc'),
      children: [
        _buildRadioOption(
          title: lang.t('male'),
          isSelected: _selectedGender == 'male',
          onTap: () => setState(() => _selectedGender = 'male'),
        ),
        const SizedBox(height: 12),
        _buildRadioOption(
          title: lang.t('female'),
          isSelected: _selectedGender == 'female',
          onTap: () => setState(() => _selectedGender = 'female'),
        ),
        const SizedBox(height: 12),
        _buildRadioOption(
          title: lang.t('other'),
          isSelected: _selectedGender == 'other',
          onTap: () => setState(() => _selectedGender = 'other'),
        ),
      ],
    );
  }

  Widget _buildGoalStep(LanguageProvider lang) {
    return _StepSection(
      icon: Icons.track_changes,
      title: lang.t('intake_first_goal_title'),
      description: lang.t('intake_first_goal_desc'),
      children: [
        _buildRadioOption(
          title: lang.t('fat_loss'),
          subtitle: lang.t('intake_first_fat_loss_desc'),
          isSelected: _selectedGoal == 'fat_loss',
          onTap: () => setState(() => _selectedGoal = 'fat_loss'),
        ),
        const SizedBox(height: 12),
        _buildRadioOption(
          title: lang.t('muscle_gain'),
          subtitle: lang.t('intake_first_muscle_gain_desc'),
          isSelected: _selectedGoal == 'muscle_gain',
          onTap: () => setState(() => _selectedGoal = 'muscle_gain'),
        ),
        const SizedBox(height: 12),
        _buildRadioOption(
          title: lang.t('general_fitness'),
          subtitle: lang.t('intake_first_fitness_desc'),
          isSelected: _selectedGoal == 'general_fitness',
          onTap: () => setState(() => _selectedGoal = 'general_fitness'),
        ),
      ],
    );
  }

  Widget _buildLocationStep(LanguageProvider lang) {
    return _StepSection(
      icon: Icons.place,
      title: lang.t('intake_first_location_title'),
      description: lang.t('intake_first_location_desc'),
      children: [
        _buildRadioOption(
          title: lang.t('gym'),
          subtitle: lang.t('intake_first_gym_desc'),
          isSelected: _selectedLocation == 'gym',
          onTap: () => setState(() => _selectedLocation = 'gym'),
        ),
        const SizedBox(height: 12),
        _buildRadioOption(
          title: lang.t('home_location'),
          subtitle: lang.t('intake_first_home_desc'),
          isSelected: _selectedLocation == 'home',
          onTap: () => setState(() => _selectedLocation = 'home'),
        ),
      ],
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
          color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
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
            Icon(icon, size: 56, color: AppColors.primary),
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

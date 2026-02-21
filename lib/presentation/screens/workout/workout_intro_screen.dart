import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../providers/language_provider.dart';
import '../../widgets/animated_reveal.dart';

class WorkoutIntroScreen extends StatelessWidget {
  final VoidCallback onGetStarted;

  const WorkoutIntroScreen({
    super.key,
    required this.onGetStarted,
  });

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final isArabic = languageProvider.isArabic;
    final featureCards = [
      {
        'icon': Icons.track_changes,
        'color': AppColors.chart1,
        'title': languageProvider.t('workouts_intro_feature1_title'),
        'description': languageProvider.t('workouts_intro_feature1_desc'),
      },
      {
        'icon': Icons.check_circle_outline,
        'color': AppColors.chart4,
        'title': languageProvider.t('workouts_intro_feature2_title'),
        'description': languageProvider.t('workouts_intro_feature2_desc'),
      },
      {
        'icon': Icons.trending_up,
        'color': AppColors.chart2,
        'title': languageProvider.t('workouts_intro_feature3_title'),
        'description': languageProvider.t('workouts_intro_feature3_desc'),
      },
      {
        'icon': Icons.calendar_today,
        'color': AppColors.chart3,
        'title': languageProvider.t('workouts_intro_feature4_title'),
        'description': languageProvider.t('workouts_intro_feature4_desc'),
      },
    ];

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.8,
              child: Image.asset(
                'assets/placeholders/splash_onboarding/workout_onboarding.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.backgroundDark.withValues(alpha: 0.8),
                    AppColors.backgroundDark.withValues(alpha: 0.65),
                    AppColors.backgroundDark.withValues(alpha: 0.85),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  AnimatedReveal(
                    initialScale: 0.85,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.textPrimary.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.fitness_center,
                        color: AppColors.textWhite,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AnimatedReveal(
                    delay: const Duration(milliseconds: 80),
                    offset: Offset(isArabic ? -0.24 : 0.24, 0),
                    initialScale: 0.9,
                    child: Text(
                      languageProvider.t('workouts_intro_title'),
                      style: AppTextStyles.h2.copyWith(color: AppColors.textWhite),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedReveal(
                    delay: const Duration(milliseconds: 140),
                    offset: Offset(isArabic ? -0.22 : 0.22, 0),
                    initialScale: 0.92,
                    child: Text(
                      languageProvider.t('workouts_intro_subtitle'),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textWhite.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: featureCards.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final data = featureCards[index];
                        return AnimatedReveal(
                          delay: Duration(milliseconds: 220 + index * 100),
                          offset: Offset(isArabic ? -0.2 : 0.2, 0),
                          initialScale: 0.9,
                          child: _FeatureCard(
                            icon: data['icon'] as IconData,
                            iconColor: data['color'] as Color,
                            title: data['title'] as String,
                            description: data['description'] as String,
                            isArabic: isArabic,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnimatedReveal(
                    delay: const Duration(milliseconds: 520),
                    offset: const Offset(0, 0.2),
                    initialScale: 0.9,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onGetStarted,
                        icon: Icon(
                          isArabic ? Icons.arrow_back : Icons.arrow_forward,
                          color: AppColors.textWhite,
                        ),
                        label: Text(languageProvider.t('workouts_get_started')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedReveal(
                    delay: const Duration(milliseconds: 600),
                    offset: Offset(isArabic ? -0.2 : 0.2, 0),
                    initialScale: 0.95,
                    child: Text(
                      languageProvider.t('workouts_intro_note'),
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.textWhite.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final bool isArabic;

  const _FeatureCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.textWhite.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textWhite.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: isArabic
            ? [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textWhite,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textWhite.withValues(alpha: 0.7),
                          height: 1.4,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
              ]
            : [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textWhite,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textWhite.withValues(alpha: 0.7),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
      ),
    );
  }
}

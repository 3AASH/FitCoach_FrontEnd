import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../widgets/animated_reveal.dart';

class NutritionIntroScreen extends StatelessWidget {
  final VoidCallback onGetStarted;

  const NutritionIntroScreen({
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
        'color': const Color(0xFF22C55E),
        'title': languageProvider.t('nutrition_intro_feature1_title'),
        'description': languageProvider.t('nutrition_intro_feature1_desc'),
      },
      {
        'icon': Icons.restaurant_menu,
        'color': const Color(0xFF2563EB),
        'title': languageProvider.t('nutrition_intro_feature2_title'),
        'description': languageProvider.t('nutrition_intro_feature2_desc'),
      },
      {
        'icon': Icons.trending_up,
        'color': const Color(0xFF7C3AED),
        'title': languageProvider.t('nutrition_intro_feature3_title'),
        'description': languageProvider.t('nutrition_intro_feature3_desc'),
      },
      {
        'icon': Icons.local_florist,
        'color': const Color(0xFFF97316),
        'title': languageProvider.t('nutrition_intro_feature4_title'),
        'description': languageProvider.t('nutrition_intro_feature4_desc'),
      },
    ];

    return Scaffold(
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
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xB3000000),
                    Color(0x99000000),
                    Color(0xCC000000),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  AnimatedReveal(
                    initialScale: 0.85,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: Color(0xFF16A34A),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.local_florist, color: Colors.white, size: 40),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AnimatedReveal(
                    delay: const Duration(milliseconds: 80),
                    offset: Offset(isArabic ? -0.24 : 0.24, 0),
                    initialScale: 0.9,
                    child: Text(
                      languageProvider.t('nutrition_intro_title'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedReveal(
                    delay: const Duration(milliseconds: 140),
                    offset: Offset(isArabic ? -0.22 : 0.22, 0),
                    initialScale: 0.92,
                    child: Text(
                      languageProvider.t('nutrition_intro_subtitle'),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
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
                          child: _IntroFeatureCard(
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
                      height: 56,
                      child: ElevatedButton(
                        onPressed: onGetStarted,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(languageProvider.t('nutrition_intro_get_started')),
                            const SizedBox(width: 8),
                            Icon(isArabic ? Icons.arrow_back : Icons.arrow_forward),
                          ],
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
                      languageProvider.t('nutrition_intro_note'),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
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

class _IntroFeatureCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final bool isArabic;

  const _IntroFeatureCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
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
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.right,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _IntroIcon(icon: icon, color: iconColor),
                  ]
                : [
                    _IntroIcon(icon: icon, color: iconColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
          ),
        ),
      ),
    );
  }
}

class _IntroIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IntroIcon({
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: 26),
    );
  }
}

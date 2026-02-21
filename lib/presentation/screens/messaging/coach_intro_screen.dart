import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../widgets/animated_reveal.dart';

class CoachIntroScreen extends StatelessWidget {
  final VoidCallback onGetStarted;

  const CoachIntroScreen({
    super.key,
    required this.onGetStarted,
  });

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final isArabic = languageProvider.isArabic;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.8,
              child: Image.asset(
                'assets/placeholders/splash_onboarding/coach_onboarding.png',
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
                    Color(0x99000000),
                    Color(0x80000000),
                    Color(0xB3000000),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AnimatedReveal(
                          offset: Offset(isArabic ? -0.2 : 0.2, 0),
                          child: Text(
                            languageProvider.t('coach_intro_title'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: isArabic ? TextAlign.right : TextAlign.left,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AnimatedReveal(
                          delay: const Duration(milliseconds: 100),
                          offset: Offset(isArabic ? -0.18 : 0.18, 0),
                          child: Text(
                            languageProvider.t('coach_intro_subtitle'),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 18,
                            ),
                            textAlign: isArabic ? TextAlign.right : TextAlign.left,
                          ),
                        ),
                        const SizedBox(height: 20),
                        AnimatedReveal(
                          delay: const Duration(milliseconds: 220),
                          offset: Offset(isArabic ? -0.14 : 0.14, 0),
                          child: _IntroFeatureCard(
                            icon: Icons.message_outlined,
                            iconColor: const Color(0xFF8B5CF6),
                            title: languageProvider.t('coach_intro_feature1_title'),
                            description: languageProvider.t('coach_intro_feature1_desc'),
                            isArabic: isArabic,
                          ),
                        ),
                        const SizedBox(height: 12),
                        AnimatedReveal(
                          delay: const Duration(milliseconds: 300),
                          offset: Offset(isArabic ? -0.14 : 0.14, 0),
                          child: _IntroFeatureCard(
                            icon: Icons.videocam_outlined,
                            iconColor: const Color(0xFF3B82F6),
                            title: languageProvider.t('coach_intro_feature2_title'),
                            description: languageProvider.t('coach_intro_feature2_desc'),
                            isArabic: isArabic,
                          ),
                        ),
                        const SizedBox(height: 12),
                        AnimatedReveal(
                          delay: const Duration(milliseconds: 380),
                          offset: Offset(isArabic ? -0.14 : 0.14, 0),
                          child: _IntroFeatureCard(
                            icon: Icons.calendar_today_outlined,
                            iconColor: const Color(0xFF22C55E),
                            title: languageProvider.t('coach_intro_feature3_title'),
                            description: languageProvider.t('coach_intro_feature3_desc'),
                            isArabic: isArabic,
                          ),
                        ),
                        const SizedBox(height: 12),
                        AnimatedReveal(
                          delay: const Duration(milliseconds: 460),
                          offset: Offset(isArabic ? -0.14 : 0.14, 0),
                          child: _IntroFeatureCard(
                            icon: Icons.star_outline,
                            iconColor: const Color(0xFFF59E0B),
                            title: languageProvider.t('coach_intro_feature4_title'),
                            description: languageProvider.t('coach_intro_feature4_desc'),
                            isArabic: isArabic,
                          ),
                        ),
                        const SizedBox(height: 20),
                        AnimatedReveal(
                          delay: const Duration(milliseconds: 520),
                          offset: const Offset(0, 0.18),
                          child: SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: onGetStarted,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7C3AED),
                                foregroundColor: Colors.white,
                                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                              child: Text(languageProvider.t('coach_intro_get_started')),
                            ),
                          ),
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
        borderRadius: BorderRadius.circular(24),
      ),
      child: Icon(icon, color: color, size: 26),
    );
  }
}

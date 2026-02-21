import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../widgets/animated_reveal.dart';

class StoreIntroScreen extends StatelessWidget {
  final VoidCallback onGetStarted;
  final VoidCallback? onBack;

  const StoreIntroScreen({
    super.key,
    required this.onGetStarted,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final isArabic = languageProvider.isArabic;
    final featureCards = [
      {
        'icon': Icons.shopping_bag_outlined,
        'color': const Color(0xFFF59E0B),
        'title': languageProvider.t('store_intro_feature1_title'),
        'description': languageProvider.t('store_intro_feature1_desc'),
      },
      {
        'icon': Icons.auto_awesome,
        'color': const Color(0xFF3B82F6),
        'title': languageProvider.t('store_intro_feature2_title'),
        'description': languageProvider.t('store_intro_feature2_desc'),
      },
      {
        'icon': Icons.local_shipping_outlined,
        'color': const Color(0xFF22C55E),
        'title': languageProvider.t('store_intro_feature3_title'),
        'description': languageProvider.t('store_intro_feature3_desc'),
      },
      {
        'icon': Icons.inventory_2_outlined,
        'color': const Color(0xFF8B5CF6),
        'title': languageProvider.t('store_intro_feature4_title'),
        'description': languageProvider.t('store_intro_feature4_desc'),
      },
    ];

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.8,
              child: Image.asset(
                'assets/placeholders/splash_onboarding/store_onboarding.png',
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
          if (onBack != null)
            SafeArea(
              child: Align(
                alignment: isArabic ? Alignment.topRight : Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: Icon(
                        isArabic ? Icons.chevron_right : Icons.chevron_left,
                        color: Colors.white,
                      ),
                      onPressed: onBack,
                    ),
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
                          offset: Offset(isArabic ? -0.24 : 0.24, 0),
                          initialScale: 0.9,
                          child: Text(
                            languageProvider.t('store_intro_title'),
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
                          offset: Offset(isArabic ? -0.22 : 0.22, 0),
                          initialScale: 0.92,
                          child: Text(
                            languageProvider.t('store_intro_subtitle'),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 18,
                            ),
                            textAlign: isArabic ? TextAlign.right : TextAlign.left,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
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
                        const SizedBox(height: 20),
                        AnimatedReveal(
                          delay: const Duration(milliseconds: 520),
                            offset: const Offset(0, 0.2),
                            initialScale: 0.9,
                            child: SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: onGetStarted,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEA580C),
                                foregroundColor: Colors.white,
                                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                              child: Text(languageProvider.t('store_intro_start_shopping')),
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

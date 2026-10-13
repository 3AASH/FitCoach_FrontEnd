import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../providers/language_provider.dart';
import '../../core/theme/app_palette.dart';
import '../widgets/aash_brand_mark.dart';

class LanguageSelectionScreen extends StatefulWidget {
  final VoidCallback onLanguageSelected;

  const LanguageSelectionScreen({
    super.key,
    required this.onLanguageSelected,
  });

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoRotation;
  late final Animation<double> _optionsFade;
  late final Animation<double> _footerFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _headerFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    ));
    _logoScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.1, 0.55, curve: Curves.easeOutBack),
    );
    _logoRotation = Tween<double>(begin: -0.06, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.55, curve: Curves.easeOutCubic),
      ),
    );
    _optionsFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 0.8, curve: Curves.easeOut),
    );
    _footerFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.75, 1.0, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    LanguageProvider languageProvider;
    try {
      languageProvider = context.watch<LanguageProvider>();
    } catch (_) {
      languageProvider = LanguageProvider();
    }

    Future<void> setLanguage(String code) async {
      try {
        await context.read<LanguageProvider>().setLanguage(code);
      } catch (_) {
        await LanguageProvider().setLanguage(code);
      }
    }

    final isArabic = languageProvider.isArabic;

    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: AlignmentDirectional.topStart,
                    end: AlignmentDirectional.bottomEnd,
                    colors: [
                      AppColors.headerGradientStart,
                      AppColors.primaryDark,
                      AppColors.headerGradientEnd,
                    ],
                  ),
                ),
              ),
            ),
            const Positioned(
              top: -88,
              right: -72,
              child: _AmbientOrb(size: 240, color: AppColors.accent),
            ),
            const Positioned(
              bottom: 36,
              left: -110,
              child: _AmbientOrb(size: 270, color: AppColors.primaryLight),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FadeTransition(
                      opacity: _headerFade,
                      child: SlideTransition(
                        position: _headerSlide,
                        child: Column(
                          children: [
                            RotationTransition(
                              turns: _logoRotation,
                              child: ScaleTransition(
                                scale: _logoScale,
                                child: const AashBrandMark(
                                  size: 100,
                                  showWordmark: false,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              languageProvider.t('language_title'),
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: context.palette.textOnBrand,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              languageProvider.t('language_subtitle'),
                              style: TextStyle(
                                fontSize: 16,
                                color: context.palette.textOnBrand70,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    FadeTransition(
                      opacity: _optionsFade,
                      child: SlideTransition(
                        position: _optionSlide(0, isArabic),
                        child: _LanguageCard(
                          flag: '\u{1F1FA}\u{1F1F8}',
                          language: languageProvider.t('english'),
                          isRtl: isArabic,
                          onTap: () async {
                            await setLanguage('en');
                            widget.onLanguageSelected();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeTransition(
                      opacity: _optionsFade,
                      child: SlideTransition(
                        position: _optionSlide(1, isArabic),
                        child: _LanguageCard(
                          flag: '\u{1F1F8}\u{1F1E6}',
                          language: languageProvider.t('arabic'),
                          isRtl: isArabic,
                          onTap: () async {
                            await setLanguage('ar');
                            widget.onLanguageSelected();
                          },
                        ),
                      ),
                    ),
                    const Spacer(),
                    FadeTransition(
                      opacity: _footerFade,
                      child: Text(
                        languageProvider.t('language_footer'),
                        style: TextStyle(
                          fontSize: 13,
                          color: context.palette.textOnBrand70,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Animation<Offset> _optionSlide(int index, bool isArabic) {
    final start = 0.45 + (index * 0.1);
    final end = (start + 0.3).clamp(0.0, 1.0);
    return Tween<Offset>(
      begin: Offset(isArabic ? 0.12 : -0.12, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(start, end, curve: Curves.easeOut),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final String flag;
  final String language;
  final VoidCallback onTap;
  final bool isRtl;

  const _LanguageCard({
    required this.flag,
    required this.language,
    required this.onTap,
    required this.isRtl,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          decoration: BoxDecoration(
            color: context.palette.surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: context.palette.textOnBrand.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Text(
                flag,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  language,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: context.palette.textPrimary,
                  ),
                ),
              ),
              Icon(
                isRtl ? Icons.arrow_back_ios : Icons.arrow_forward_ios,
                color: context.palette.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmbientOrb extends StatelessWidget {
  const _AmbientOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.14),
              blurRadius: size * 0.35,
              spreadRadius: size * 0.05,
            ),
          ],
        ),
      ),
    );
  }
}

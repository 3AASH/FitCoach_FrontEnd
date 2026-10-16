import '../widgets/aash_backdrop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/theme/app_palette.dart';
import '../providers/language_provider.dart';
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

    return AashScaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: Theme.of(context).brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: ColoredBox(
          color: context.palette.background,
          child: Stack(
            children: [
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
                                style: AppTextStyles.h1.copyWith(
                                  fontSize: 28,
                                  color: context.palette.textPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                languageProvider.t('language_subtitle'),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: context.palette.textSecondary,
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
                            color: context.palette.textSecondary,
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
            color: context.palette.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: context.palette.border,
              width: 1,
            ),
            boxShadow: Theme.of(context).brightness == Brightness.light
                ? [
                    BoxShadow(
                      color: context.palette.primary.withValues(alpha: 0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : const [],
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
                  style: AppTextStyles.h3.copyWith(
                    fontSize: 20,
                    color: context.palette.textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
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

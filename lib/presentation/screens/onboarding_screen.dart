import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../providers/language_provider.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  
  const OnboardingScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  @override
  void dispose() {
    _pageController.dispose();
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
    final isArabic = languageProvider.isArabic;
    
    final slides = _getSlides(languageProvider);
    final currentSlide = slides[_currentPage];
    
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 700),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: currentSlide.gradientColors,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Skip button
              Positioned(
                top: 8,
                right: isArabic ? null : 16,
                left: isArabic ? 16 : null,
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    backgroundColor: AppColors.textWhite.withValues(alpha: 0.2),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.small),
                    ),
                  ),
                  onPressed: widget.onComplete,
                  child: Text(languageProvider.t('skip')),
                ),
              ),
              
              // Page view
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 140),
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: slides.length,
                    itemBuilder: (context, index) {
                      return _OnboardingSlide(
                        slide: slides[index],
                        isArabic: isArabic,
                      );
                    },
                  ),
                ),
              ),
              
              // Bottom navigation
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      decoration: BoxDecoration(
                        color: AppColors.textWhite.withValues(alpha: 0.8),
                        border: Border(
                          top: BorderSide(color: AppColors.border.withValues(alpha: 0.8)),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Page indicator
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              slides.length,
                              (index) => _PageIndicator(
                                isActive: index == _currentPage,
                                accentColor: currentSlide.accentColor,
                                label: languageProvider.t('onboarding_go_to_slide', args: {
                                  'index': '${index + 1}',
                                }),
                                onTap: () {
                                  _pageController.animateToPage(
                                    index,
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeInOut,
                                  );
                                },
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Navigation buttons
                          Row(
                            children: [
                              OutlinedButton(
                                onPressed: _currentPage == 0
                                    ? null
                                    : () {
                                        _pageController.previousPage(
                                          duration: const Duration(milliseconds: 500),
                                          curve: Curves.easeInOut,
                                        );
                                      },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.all(12),
                                  minimumSize: const Size(48, 48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.small),
                                  ),
                                ),
                                child: Icon(
                                  isArabic ? Icons.chevron_right : Icons.chevron_left,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: currentSlide.accentColor,
                                    minimumSize: const Size(0, 48),
                                  ),
                                  onPressed: () {
                                    if (_currentPage < slides.length - 1) {
                                      _pageController.nextPage(
                                        duration: const Duration(milliseconds: 500),
                                        curve: Curves.easeInOut,
                                      );
                                    } else {
                                      widget.onComplete();
                                    }
                                  },
                                  child: Text(
                                    _currentPage < slides.length - 1
                                        ? languageProvider.t('next')
                                        : languageProvider.t('get_started'),
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textWhite,
                                    ),
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
            ],
          ),
        ),
      ),
    );
  }
  
  List<OnboardingSlideData> _getSlides(LanguageProvider lang) {
    return [
      OnboardingSlideData(
        title: lang.t('onboarding_coaching_title'),
        description: lang.t('onboarding_coaching_desc'),
        imagePath: 'assets/placeholders/splash_onboarding/coach_onboarding.png',
        gradientColors: [
          AppColors.secondaryForeground.withValues(alpha: 0.2),
          AppColors.primary.withValues(alpha: 0.2),
        ],
        accentColor: AppColors.secondaryForeground,
      ),
      OnboardingSlideData(
        title: lang.t('onboarding_nutrition_title'),
        description: lang.t('onboarding_nutrition_desc'),
        imagePath: 'assets/placeholders/splash_onboarding/nuitration_onboarding.png',
        gradientColors: [
          AppColors.accent.withValues(alpha: 0.2),
          AppColors.primary.withValues(alpha: 0.2),
        ],
        accentColor: AppColors.accent,
      ),
      OnboardingSlideData(
        title: lang.t('onboarding_workouts_title'),
        description: lang.t('onboarding_workouts_desc'),
        imagePath: 'assets/placeholders/splash_onboarding/workout_onboarding.png',
        gradientColors: [
          AppColors.primary.withValues(alpha: 0.2),
          AppColors.secondaryForeground.withValues(alpha: 0.2),
        ],
        accentColor: AppColors.primary,
      ),
      OnboardingSlideData(
        title: lang.t('onboarding_store_title'),
        description: lang.t('onboarding_store_desc'),
        imagePath: 'assets/placeholders/splash_onboarding/store_onboarding.png',
        gradientColors: [
          AppColors.accent.withValues(alpha: 0.2),
          AppColors.secondaryForeground.withValues(alpha: 0.2),
        ],
        accentColor: AppColors.accent,
      ),
    ];
  }
}

class OnboardingSlideData {
  final String title;
  final String description;
  final String imagePath;
  final List<Color> gradientColors;
  final Color accentColor;
  
  OnboardingSlideData({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.gradientColors,
    required this.accentColor,
  });
}

class _OnboardingSlide extends StatefulWidget {
  final OnboardingSlideData slide;
  final bool isArabic;

  const _OnboardingSlide({
    required this.slide,
    required this.isArabic,
  });

  @override
  State<_OnboardingSlide> createState() => _OnboardingSlideState();
}

class _OnboardingSlideState extends State<_OnboardingSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _imageFade;
  late final Animation<Offset> _imageSlide;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _descFade;
  late final Animation<Offset> _descSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _imageFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );
    _imageSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    ));
    _titleFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.25, 0.7, curve: Curves.easeOut),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.25, 0.7, curve: Curves.easeOut),
    ));
    _descFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 0.9, curve: Curves.easeOut),
    );
    _descSlide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 0.9, curve: Curves.easeOut),
    ));

    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _OnboardingSlide oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slide.imagePath != widget.slide.imagePath) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeTransition(
                    opacity: _imageFade,
                    child: SlideTransition(
                      position: _imageSlide,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            AspectRatio(
                              aspectRatio: 1,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Image.asset(
                                  widget.slide.imagePath,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: AppColors.surface,
                                      alignment: Alignment.center,
                                      child: Icon(
                                        Icons.image_not_supported_outlined,
                                        color: AppColors.textDisabled,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            Positioned(
                              top: -12,
                              right: -12,
                              child: _BlurAccent(
                                color: widget.slide.accentColor,
                                size: 96,
                              ),
                            ),
                            Positioned(
                              bottom: -16,
                              left: -16,
                              child: _BlurAccent(
                                color: widget.slide.accentColor,
                                size: 120,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  FadeTransition(
                    opacity: _titleFade,
                    child: SlideTransition(
                      position: _titleSlide,
                      child: SizedBox(
                        width: double.infinity,
                        child: Text(
                          widget.slide.title,
                          style: AppTextStyles.h1.copyWith(
                            color: AppColors.textPrimary,
                          ),
                          textAlign: widget.isArabic ? TextAlign.right : TextAlign.left,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  FadeTransition(
                    opacity: _descFade,
                    child: SlideTransition(
                      position: _descSlide,
                      child: SizedBox(
                        width: double.infinity,
                        child: Text(
                          widget.slide.description,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: widget.isArabic ? TextAlign.right : TextAlign.left,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final bool isActive;
  final Color accentColor;
  final String label;
  final VoidCallback onTap;
  
  const _PageIndicator({
    required this.isActive,
    required this.accentColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          width: isActive ? 32 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? accentColor : AppColors.border,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

class _BlurAccent extends StatelessWidget {
  final Color color;
  final double size;

  const _BlurAccent({
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../providers/language_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/animated_reveal.dart';
import '../../../core/theme/app_palette.dart';

class FeatureIntroScreen extends StatefulWidget {
  final String feature; // 'workout', 'nutrition', 'store', 'coach'
  final VoidCallback onComplete;
  
  const FeatureIntroScreen({
    super.key,
    required this.feature,
    required this.onComplete,
  });

  @override
  State<FeatureIntroScreen> createState() => _FeatureIntroScreenState();
}

class _FeatureIntroScreenState extends State<FeatureIntroScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final slides = _getSlides(widget.feature, lang);
    
    return Scaffold(
      // Match the glassy coach intro style with better contrast
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: widget.onComplete,
            child: Text(
              lang.t('skip'),
              style: TextStyle(
                color: context.palette.textSecondary,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: slides.length,
              itemBuilder: (context, index) {
                return _buildSlide(slides[index]);
              },
            ),
          ),
          
          // Page indicator
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    slides.length,
                    (index) => Container(
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? AppColors.primary
                            : context.palette.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Navigation button
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: _currentPage == slides.length - 1
                        ? (lang.t('workouts_get_started'))
                        : (lang.t('next')),
                    onPressed: () {
                      if (_currentPage < slides.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        widget.onComplete();
                      }
                    },
                    variant: ButtonVariant.primary,
                    size: ButtonSize.large,
                    fullWidth: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSlide(Map<String, dynamic> slide) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with soft colored circle on dark background
          // Use default 1s duration for clear visibility
          AnimatedReveal(
            offset: const Offset(0, 0.22),
            initialScale: 0.8,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: (slide['color'] as Color).withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(
                slide['icon'] as IconData,
                size: 60,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 48),
          
          // Title (1s duration with slight delay)
          AnimatedReveal(
            delay: const Duration(milliseconds: 100),
            offset: const Offset(0, 0.18),
            initialScale: 0.9,
            child: Text(
              slide['title'] as String,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          
          // Description
          AnimatedReveal(
            delay: const Duration(milliseconds: 220),
            offset: const Offset(0, 0.16),
            initialScale: 0.95,
            child: Text(
              slide['description'] as String,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.85),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
  
  List<Map<String, dynamic>> _getSlides(String feature, LanguageProvider lang) {
    switch (feature) {
      case 'workout':
        return [
          {
            'icon': Icons.fitness_center,
            'color': AppColors.primary,
            'title': lang.t('feature_intro_personalized_workouts'),
            'description': lang.t('feature_intro_get_workout_plans_tailored_to_your'),
          },
          {
            'icon': Icons.calendar_today,
            'color': AppColors.primary,
            'title': lang.t('feature_intro_weekly_schedule'),
            'description': lang.t('feature_intro_track_your_weekly_workouts_and_tap'),
          },
          {
            'icon': Icons.swap_horiz,
            'color': AppColors.primary,
            'title': lang.t('feature_intro_exercise_substitution'),
            'description': lang.t('feature_intro_get_safe_alternatives_for_exercises_that'),
          },
        ];
        
      case 'nutrition':
        return [
          {
            'icon': Icons.restaurant,
            'color': AppColors.success,
            'title': lang.t('feature_intro_complete_nutrition_plans'),
            'description': lang.t('feature_intro_get_detailed_meal_plans_with_macro'),
          },
          {
            'icon': Icons.pie_chart,
            'color': AppColors.success,
            'title': lang.t('feature_intro_track_macros'),
            'description': lang.t('feature_intro_monitor_calories_protein_carbs_and_fats'),
          },
          {
            'icon': Icons.timer,
            'color': AppColors.success,
            'title': lang.t('feature_intro_14_day_free_trial'),
            'description': lang.t('feature_intro_enjoy_full_nutrition_access_for_14'),
          },
        ];
        
      case 'store':
        return [
          {
            'icon': Icons.shopping_bag,
            'color': AppColors.warning,
            'title': lang.t('feature_intro_shop_products'),
            'description': lang.t('feature_intro_browse_and_buy_high_quality_supplements'),
          },
          {
            'icon': Icons.local_shipping,
            'color': AppColors.warning,
            'title': lang.t('store_intro_feature3_title'),
            'description': lang.t('feature_intro_get_your_orders_with_fast_and'),
          },
          {
            'icon': Icons.star,
            'color': AppColors.warning,
            'title': lang.t('feature_intro_ratings_reviews'),
            'description': lang.t('feature_intro_read_real_reviews_from_other_users'),
          },
        ];
        
      case 'coach':
        return [
          {
            'icon': Icons.chat,
            'color': AppColors.primary,
            'title': lang.t('feature_intro_connect_with_coach'),
            'description': lang.t('feature_intro_chat_with_your_coach_in_real'),
          },
          {
            'icon': Icons.video_call,
            'color': AppColors.primary,
            'title': lang.t('feature_intro_video_calls'),
            'description': lang.t('feature_intro_book_live_video_calls_with_your'),
          },
          {
            'icon': Icons.attach_file,
            'color': AppColors.primary,
            'title': lang.t('feature_intro_share_progress'),
            'description': lang.t('feature_intro_send_photos_and_videos_to_track'),
          },
        ];
        
      default:
        return [];
    }
  }
}

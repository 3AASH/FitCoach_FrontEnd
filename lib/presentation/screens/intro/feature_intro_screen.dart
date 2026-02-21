import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../providers/language_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/animated_reveal.dart';

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
    final languageProvider = context.watch<LanguageProvider>();
    final isArabic = languageProvider.isArabic;
    final slides = _getSlides(widget.feature, isArabic);
    
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
              isArabic ? 'تخطي' : 'Skip',
              style: const TextStyle(
                color: AppColors.textSecondary,
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
                            : AppColors.border,
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
                        ? (isArabic ? 'ابدأ الآن' : 'Get Started')
                        : (isArabic ? 'التالي' : 'Next'),
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
  
  List<Map<String, dynamic>> _getSlides(String feature, bool isArabic) {
    switch (feature) {
      case 'workout':
        return [
          {
            'icon': Icons.fitness_center,
            'color': AppColors.primary,
            'title': isArabic ? 'خطط تمرين مخصصة' : 'Personalized Workouts',
            'description': isArabic
                ? 'احصل على خطط تمرين مصممة خصيصاً لأهدافك ومستوى لياقتك'
                : 'Get workout plans tailored to your goals and fitness level',
          },
          {
            'icon': Icons.calendar_today,
            'color': AppColors.primary,
            'title': isArabic ? 'جدولة أسبوعية' : 'Weekly Schedule',
            'description': isArabic
                ? 'تابع تمارينك الأسبوعية واضغط على أي يوم لرؤية التفاصيل'
                : 'Track your weekly workouts and tap any day to see details',
          },
          {
            'icon': Icons.swap_horiz,
            'color': AppColors.primary,
            'title': isArabic ? 'استبدال التمارين' : 'Exercise Substitution',
            'description': isArabic
                ? 'احصل على بدائل آمنة للتمارين التي قد تسبب إصابات'
                : 'Get safe alternatives for exercises that may cause injuries',
          },
        ];
        
      case 'nutrition':
        return [
          {
            'icon': Icons.restaurant,
            'color': AppColors.success,
            'title': isArabic ? 'خطط تغذية متكاملة' : 'Complete Nutrition Plans',
            'description': isArabic
                ? 'احصل على خطط وجبات مفصلة مع تتبع المغذيات الكبرى'
                : 'Get detailed meal plans with macro nutrient tracking',
          },
          {
            'icon': Icons.pie_chart,
            'color': AppColors.success,
            'title': isArabic ? 'تتبع المغذيات' : 'Track Macros',
            'description': isArabic
                ? 'تابع السعرات والبروتين والكربوهيدرات والدهون يومياً'
                : 'Monitor calories, protein, carbs, and fats daily',
          },
          {
            'icon': Icons.timer,
            'color': AppColors.success,
            'title': isArabic ? 'تجربة مجانية 14 يوم' : '14-Day Free Trial',
            'description': isArabic
                ? 'استمتع بالوصول الكامل للتغذية لمدة 14 يوماً مع الاشتراك المجاني'
                : 'Enjoy full nutrition access for 14 days with Freemium',
          },
        ];
        
      case 'store':
        return [
          {
            'icon': Icons.shopping_bag,
            'color': AppColors.warning,
            'title': isArabic ? 'تسوق المنتجات' : 'Shop Products',
            'description': isArabic
                ? 'تصفح وشراء مكملات ومعدات رياضية عالية الجودة'
                : 'Browse and buy high-quality supplements and equipment',
          },
          {
            'icon': Icons.local_shipping,
            'color': AppColors.warning,
            'title': isArabic ? 'توصيل سريع' : 'Fast Delivery',
            'description': isArabic
                ? 'احصل على طلباتك مع توصيل سريع وموثوق'
                : 'Get your orders with fast and reliable delivery',
          },
          {
            'icon': Icons.star,
            'color': AppColors.warning,
            'title': isArabic ? 'تقييمات ومراجعات' : 'Ratings & Reviews',
            'description': isArabic
                ? 'اقرأ تقييمات حقيقية من مستخدمين آخرين'
                : 'Read real reviews from other users',
          },
        ];
        
      case 'coach':
        return [
          {
            'icon': Icons.chat,
            'color': AppColors.primary,
            'title': isArabic ? 'تواصل مع مدربك' : 'Connect with Coach',
            'description': isArabic
                ? 'تحدث مع مدربك في الوقت الفعلي واحصل على إرشادات شخصية'
                : 'Chat with your coach in real-time and get personalized guidance',
          },
          {
            'icon': Icons.video_call,
            'color': AppColors.primary,
            'title': isArabic ? 'مكالمات فيديو' : 'Video Calls',
            'description': isArabic
                ? 'احجز مكالمات فيديو مباشرة مع مدربك للحصول على الدعم'
                : 'Book live video calls with your coach for support',
          },
          {
            'icon': Icons.attach_file,
            'color': AppColors.primary,
            'title': isArabic ? 'شارك التقدم' : 'Share Progress',
            'description': isArabic
                ? 'أرسل صور وفيديوهات لتتبع تقدمك'
                : 'Send photos and videos to track your progress',
          },
        ];
        
      default:
        return [];
    }
  }
}

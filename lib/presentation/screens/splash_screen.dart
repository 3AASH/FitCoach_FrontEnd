import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/theme/app_palette.dart';
import '../providers/language_provider.dart';
import '../widgets/aash_brand_mark.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showContent = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _showContent = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    LanguageProvider languageProvider;
    try {
      languageProvider = context.watch<LanguageProvider>();
    } catch (_) {
      languageProvider = LanguageProvider();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: context.palette.background,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(24, 24, 24, 28),
            child: Column(
              children: [
                const Spacer(flex: 2),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 500),
                  opacity: _showContent ? 1 : 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AashBrandMark(size: 154),
                      const SizedBox(height: 26),
                      Text(
                        languageProvider.t('splash_headline_en'),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.h1.copyWith(
                          color: context.palette.textPrimary,
                          fontSize: 30,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        languageProvider.t('splash_headline_ar'),
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: AppTextStyles.h3.copyWith(
                          color: context.palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 3),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: widget.onStart,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: Text(languageProvider.t('splash_start')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.palette.primary,
                      foregroundColor: context.palette.textOnBrand,
                      minimumSize: const Size(0, 58),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

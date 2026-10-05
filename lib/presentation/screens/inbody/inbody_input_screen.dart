import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../../core/config/demo_config.dart';
import '../../../core/constants/colors.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/models/inbody_model.dart';
import '../../providers/language_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/coach_provider.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';
import '../subscription/subscription_manager_screen.dart';
import '../subscription/subscription_upgrade_screen.dart';
import '../../../core/theme/app_palette.dart';
import '../../widgets/unsaved_changes_guard.dart';

class InBodyInputScreen extends StatefulWidget {
  const InBodyInputScreen({super.key});

  @override
  State<InBodyInputScreen> createState() => _InBodyInputScreenState();
}

class _InBodyInputScreenState extends State<InBodyInputScreen> {
  String _inputMode = 'selection'; // 'selection', 'ai-scan', 'manual'
  Uint8List? _selectedImageBytes;
  XFile? _selectedImageFile;
  bool _isAnalyzing = false;
  bool _isSaving = false;
  bool _extractionComplete = false;
  Map<String, dynamic>? _extractedData;
  final ImagePicker _picker = ImagePicker();

  // InBody metrics
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _bodyFatController = TextEditingController();
  final TextEditingController _muscleMassController = TextEditingController();
  final TextEditingController _bmiController = TextEditingController();
  final TextEditingController _visceralFatController = TextEditingController();
  final TextEditingController _bodyWaterController = TextEditingController();
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _mineralController = TextEditingController();
  final TextEditingController _bmrController = TextEditingController();

  @override
  void dispose() {
    _weightController.dispose();
    _bodyFatController.dispose();
    _muscleMassController.dispose();
    _bmiController.dispose();
    _visceralFatController.dispose();
    _bodyWaterController.dispose();
    _proteinController.dispose();
    _mineralController.dispose();
    _bmrController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final authProvider = context.watch<AuthProvider>();
        final subscriptionTier = authProvider.user?.subscriptionTier ?? 'Freemium';
    final isPremium =
        subscriptionTier == 'Premium' || subscriptionTier == 'Smart Premium';

    return UnsavedChangesGuard(
      hasUnsavedChanges: _hasUnsavedWork,
      child: Scaffold(
        appBar: AppBar(
          title: Text(lang.t('inbody_input_inbody_analysis')),
        ),
        body: _inputMode == 'selection'
            ? _buildModeSelection(lang, isPremium)
            : _inputMode == 'ai-scan'
                ? _buildAIScan(lang)
                : _buildManualInput(lang),
      ),
    );
  }

  /// A scan's measurements live only in these controllers until save, and
  /// re-measuring is not something a user can redo from memory.
  bool get _hasUnsavedWork {
    if (_isSaving || _isAnalyzing) return false;
    return [
      _weightController,
      _bodyFatController,
      _muscleMassController,
      _bmiController,
      _visceralFatController,
      _bodyWaterController,
      _proteinController,
      _mineralController,
      _bmrController,
    ].any((c) => c.text.trim().isNotEmpty);
  }

  Widget _buildModeSelection(LanguageProvider lang, bool isPremium) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang.t('inbody_input_choose_input_method'),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            lang.t('inbody_input_how_would_you_like_to_enter'),
            style: TextStyle(
              fontSize: 14,
              color: context.palette.textSecondary,
            ),
          ),
          const SizedBox(height: 32),

          // AI Scan option
          Stack(
            children: [
              Opacity(
                opacity: isPremium ? 1.0 : 0.6,
                child: CustomCard(
                  onTap: isPremium
                      ? () {
                          setState(() {
                            _inputMode = 'ai-scan';
                          });
                        }
                      : () {
                          // Show upgrade dialog
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SubscriptionManagerScreen(),
                            ),
                          );
                        },
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: isPremium
                              ? const LinearGradient(
                                  colors: [AppColors.primary, AppColors.accent],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isPremium
                              ? null
                              : context.palette.textDisabled.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.auto_awesome,
                          color:
                              isPremium ? Colors.white : context.palette.textDisabled,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  lang.t('inbody_input_ai_scan'),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (!isPremium)
                                  Icon(
                                    Icons.lock,
                                    size: 16,
                                    color: context.palette.textDisabled,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              lang.t('inbody_input_take_a_photo_of_your_inbody'),
                              style: TextStyle(
                                fontSize: 13,
                                color: context.palette.textSecondary,
                              ),
                            ),
                            if (isPremium)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      size: 16,
                                      color: AppColors.success,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      lang.t('inbody_input_instant_data_extraction'),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: CustomButton(
                                  text: lang.t('inbody_input_upgrade_for_ai'),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const SubscriptionManagerScreen(),
                                      ),
                                    );
                                  },
                                  size: ButtonSize.small,
                                  variant: ButtonVariant.outline,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: isPremium
                            ? context.palette.textSecondary
                            : context.palette.textDisabled,
                      ),
                    ],
                  ),
                ),
              ),
              // Premium badge
              if (!isPremium)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF97316), Color(0xFFEC4899)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.workspace_premium,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          lang.t('inbody_input_premium_feature'),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Manual input option
          CustomCard(
            onTap: () {
              setState(() {
                _inputMode = 'manual';
              });
            },
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: AppColors.success,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang.t('inbody_input_manual_input'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lang.t('inbody_input_enter_measurements_manually'),
                        style: TextStyle(
                          fontSize: 13,
                          color: context.palette.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 16,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            lang.t('inbody_input_available_for_all_users'),
                            style: TextStyle(
                              fontSize: 12,
                              color: context.palette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: context.palette.textDisabled,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Info card
          CustomCard(
            color: AppColors.primary.withValues(alpha: 0.05),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    lang.t('inbody_input_inbody_analysis_helps_you_track_your'),
                    style: TextStyle(
                      fontSize: 13,
                      color: context.palette.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIScan(LanguageProvider lang) {
        return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: _selectedImageBytes == null
                ? _buildAiIntro(lang)
                : _buildAiPreview(lang),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () {
              _clearAiCapture();
              setState(() => _inputMode = 'selection');
            },
            child: Text(lang.t('back')),
          ),
        ],
      ),
    );
  }

  Widget _buildAiIntro(LanguageProvider lang) {
    return Column(
      key: const ValueKey('ai-intro'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: context.palette.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.palette.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.auto_awesome,
                    color: Colors.white, size: 36),
              ),
              const SizedBox(height: 16),
              Text(
                lang.t('inbody_input_ai_powered_inbody_analysis'),
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                lang.t('inbody_input_capture_a_clear_photo_of_your'),
                style: TextStyle(color: context.palette.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Column(
                children: [
                  _buildAiHintRow(
                    Icons.photo_camera_outlined,
                    lang.t('inbody_input_use_good_lighting_and_a_clean'),
                  ),
                  const SizedBox(height: 12),
                  _buildAiHintRow(
                    Icons.crop_free,
                    lang.t('inbody_input_align_the_entire_report_inside_the'),
                  ),
                  const SizedBox(height: 12),
                  _buildAiHintRow(
                    Icons.timer,
                    lang.t('inbody_input_analysis_takes_only_a_few_seconds'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        CustomButton(
          text: lang.t('inbody_input_open_camera'),
          onPressed: _openCamera,
          variant: ButtonVariant.primary,
          size: ButtonSize.large,
          icon: Icons.camera_alt,
          fullWidth: true,
        ),
        const SizedBox(height: 12),
        CustomButton(
          text: lang.t('inbody_input_choose_from_gallery'),
          onPressed: _openGallery,
          variant: ButtonVariant.secondary,
          size: ButtonSize.large,
          icon: Icons.photo_library,
          fullWidth: true,
        ),
        const SizedBox(height: 8),
        CustomButton(
          text: lang.t('inbody_input_switch_to_manual_entry'),
          onPressed: () => setState(() => _inputMode = 'manual'),
          variant: ButtonVariant.ghost,
          size: ButtonSize.medium,
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildAiPreview(LanguageProvider lang) {
    final summary = _extractedData;
    return Column(
      key: const ValueKey('ai-preview'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.palette.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.palette.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _selectedImageBytes == null
                        ? const SizedBox.shrink()
                        : Image.memory(
                            _selectedImageBytes!,
                            height: 280,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                  ),
                  PositionedDirectional(
                    top: 12,
                    end: 12,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: const CircleBorder(),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: _isAnalyzing ? null : _clearAiCapture,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_isAnalyzing) ...[
                const SizedBox(height: 8),
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                Text(
                  lang.t('inbody_input_analyzing_your_scan'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  lang.t('inbody_input_we_extract_every_important_metric_from'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.palette.textSecondary),
                ),
                const SizedBox(height: 12),
                const LinearProgressIndicator(value: 0.65, minHeight: 6),
              ] else if (_extractionComplete && summary != null) ...[
                Text(
                  lang.t('inbody_input_data_extraction_complete'),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  lang.t('inbody_input_review_the_highlighted_metrics_then_continue'),
                  style: TextStyle(color: context.palette.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                _buildAiSummaryGrid(summary, lang),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: lang.t('inbody_input_retake_photo'),
                        onPressed: _clearAiCapture,
                        variant: ButtonVariant.outline,
                        size: ButtonSize.medium,
                        icon: Icons.refresh,
                        fullWidth: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        text: lang.t('inbody_input_use_extracted_data'),
                        onPressed: () => _applyExtractedDataAndContinue(lang),
                        variant: ButtonVariant.primary,
                        size: ButtonSize.medium,
                        icon: Icons.arrow_forward,
                        fullWidth: true,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Text(
                  lang.t('inbody_input_preparing_preview'),
                  style: TextStyle(color: context.palette.textSecondary),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAiHintRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: context.palette.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: context.palette.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildAiSummaryGrid(Map<String, dynamic> summary, LanguageProvider lang) {
    final weightValue = _formatNumber(summary['weight'] as num?);
    final bmiValue = _formatNumber(summary['bmi'] as num?);
    final fatValue = _formatNumber(summary['bodyFat'] as num?);
    final muscleValue = _formatNumber(summary['muscleMass'] as num?);
    final stats = [
      {
        'label': lang.t('weight'),
        'value': weightValue == '--' ? weightValue : '$weightValue kg',
        'color': AppColors.primary,
      },
      {
        'label': 'BMI',
        'value': bmiValue,
        'color': AppColors.secondaryForeground,
      },
      {
        'label': lang.t('inbody_input_body_fat'),
        'value': fatValue == '--' ? fatValue : '$fatValue%',
        'color': const Color(0xFF22C55E),
      },
      {
        'label': lang.t('inbody_input_muscle_mass'),
        'value': muscleValue == '--' ? muscleValue : '$muscleValue kg',
        'color': const Color(0xFF0EA5E9),
      },
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.7,
      children: stats
          .map(
            (stat) => _buildAiStatTile(
              stat['label'] as String,
              stat['value'] as String,
              stat['color'] as Color,
              lang,
            ),
          )
          .toList(),
    );
  }

  Widget _buildAiStatTile(
      String label, String value, Color color, LanguageProvider lang) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment:
            lang.isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style:
                TextStyle(color: context.palette.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> _openCamera() async {
    try {
      final result = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
      );
      if (result != null) {
        await _handlePickedImage(result);
      }
    } catch (error) {
      _showImageError();
    }
  }

  Future<void> _openGallery() async {
    try {
      final result = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (result != null) {
        await _handlePickedImage(result);
      }
    } catch (error) {
      _showImageError();
    }
  }

  Future<void> _handlePickedImage(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _selectedImageBytes = bytes;
        _selectedImageFile = file;
        _isAnalyzing = true;
        _extractionComplete = false;
        _extractedData = null;
      });
      if (DemoConfig.isDemo) {
        await _simulateExtraction();
        return;
      }

      final repository = WorkoutRepository();
      final result = await repository.uploadInBodyImage(file.path);
      final extracted =
          (result['extractedData'] as Map?)?.cast<String, dynamic>();

      if (!mounted) return;

      if (extracted == null) {
        throw Exception('No extracted data returned');
      }

      setState(() {
        _isAnalyzing = false;
        _extractionComplete = true;
        _extractedData = {
          'weight': extracted['weight'],
          'bmi': extracted['bmi'],
          'bodyFat': extracted['percentBodyFat'],
          'muscleMass': extracted['skeletalMuscleMass'],
          'visceralFat': extracted['visceralFatLevel'],
          'bodyWater': extracted['totalBodyWater'],
          'bmr': extracted['basalMetabolicRate'],
        };
      });
    } on InBodyUploadException catch (error) {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        if (!error.retryable || error.upgradeRequired) {
          _selectedImageBytes = null;
          _selectedImageFile = null;
        }
      });
      if (error.upgradeRequired) {
        _showUpgradePrompt();
      } else {
        _showImageError(
          message: error.message,
          retryable: error.retryable,
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _selectedImageBytes = null;
          _selectedImageFile = null;
        });
      }
      _showImageError();
    }
  }

  Future<void> _retrySelectedImage() async {
    final file = _selectedImageFile;
    if (file == null) {
      await _openGallery();
      return;
    }
    await _handlePickedImage(file);
  }

  Future<void> _simulateExtraction() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final inferredWeight = double.tryParse(_weightController.text) ?? 72.4;
    final extractedData = {
      'weight': inferredWeight,
      'bmi': double.tryParse(_bmiController.text) ?? 23.4,
      'bodyFat': double.tryParse(_bodyFatController.text) ?? 17.8,
      'muscleMass': double.tryParse(_muscleMassController.text) ??
          (inferredWeight * 0.42),
      'visceralFat': int.tryParse(_visceralFatController.text) ?? 8,
      'bodyWater':
          double.tryParse(_bodyWaterController.text) ?? (inferredWeight * 0.62),
      'protein':
          double.tryParse(_proteinController.text) ?? (inferredWeight * 0.18),
      'mineral':
          double.tryParse(_mineralController.text) ?? (inferredWeight * 0.045),
      'bmr': int.tryParse(_bmrController.text) ?? 1580,
    };

    setState(() {
      _isAnalyzing = false;
      _extractionComplete = true;
      _extractedData = extractedData;
    });
  }

  void _showImageError({String? message, bool retryable = false}) {
    if (!mounted) return;
    final lang = context.read<LanguageProvider>();
    final fallback = lang.t('inbody_input_something_went_wrong_while_processing_the');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message ?? fallback),
        backgroundColor: retryable ? AppColors.warning : AppColors.error,
        action: retryable
            ? SnackBarAction(
                label: lang.t('retry'),
                textColor: Colors.white,
                onPressed: _retrySelectedImage,
              )
            : null,
      ),
    );
  }

  void _showUpgradePrompt() {
    if (!mounted) return;
    final lang = context.read<LanguageProvider>();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          lang.t('inbody_input_ai_extraction_is_available_for_subscribers'),
        ),
        backgroundColor: AppColors.warning,
        action: SnackBarAction(
          label: lang.t('subscription_upgrade_cta'),
          textColor: Colors.white,
          onPressed: () {
            if (!mounted) return;
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const SubscriptionUpgradeScreen(
                  requiredTier: 'premium',
                  featureName: 'AI InBody Extraction',
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _clearAiCapture() {
    setState(() {
      _selectedImageBytes = null;
      _selectedImageFile = null;
      _isAnalyzing = false;
      _extractionComplete = false;
      _extractedData = null;
    });
  }

  void _applyExtractedDataAndContinue(LanguageProvider lang) {
    final data = _extractedData;
    if (data == null) return;

    _weightController.text =
        _formatNumber(data['weight'] as num?, emptyIfNull: true);
    _bodyFatController.text =
        _formatNumber(data['bodyFat'] as num?, emptyIfNull: true);
    _muscleMassController.text =
        _formatNumber(data['muscleMass'] as num?, emptyIfNull: true);
    _bmiController.text = _formatNumber(data['bmi'] as num?, emptyIfNull: true);
    _visceralFatController.text = _formatNumber(
      data['visceralFat'] as num?,
      fractionDigits: 0,
      emptyIfNull: true,
    );
    _bodyWaterController.text =
        _formatNumber(data['bodyWater'] as num?, emptyIfNull: true);
    _proteinController.text =
        _formatNumber(data['protein'] as num?, emptyIfNull: true);
    _mineralController.text =
        _formatNumber(data['mineral'] as num?, emptyIfNull: true);
    _bmrController.text = _formatNumber(
      data['bmr'] as num?,
      fractionDigits: 0,
      emptyIfNull: true,
    );

    setState(() {
      _inputMode = 'manual';
      _selectedImageBytes = null;
      _selectedImageFile = null;
      _isAnalyzing = false;
      _extractionComplete = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          lang.t('inbody_input_extracted_metrics_applied_review_them_before'),
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }

  String _formatNumber(num? value,
      {int fractionDigits = 1, bool emptyIfNull = false}) {
    if (value == null) {
      return emptyIfNull ? '' : '--';
    }
    if (value is int || fractionDigits == 0) {
      return value.toString();
    }
    return value.toStringAsFixed(fractionDigits);
  }

  Widget _buildManualInput(LanguageProvider lang) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang.t('inbody_input_enter_your_measurements'),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Weight
          _buildInputField(
            controller: _weightController,
            label: lang.t('progress_weight_kg'),
            hint: '70.5',
            icon: Icons.monitor_weight,
          ),

          const SizedBox(height: 16),

          // Body Fat %
          _buildInputField(
            controller: _bodyFatController,
            label: lang.t('inbody_input_body_fat_2'),
            hint: '18.5',
            icon: Icons.pie_chart,
          ),

          const SizedBox(height: 16),

          // Muscle Mass
          _buildInputField(
            controller: _muscleMassController,
            label: lang.t('inbody_input_muscle_mass_kg'),
            hint: '35.2',
            icon: Icons.fitness_center,
          ),

          const SizedBox(height: 16),

          // BMI
          _buildInputField(
            controller: _bmiController,
            label: lang.t('inbody_input_bmi'),
            hint: '23.4',
            icon: Icons.straighten,
          ),

          const SizedBox(height: 24),

          Text(
            lang.t('inbody_input_additional_measurements_optional'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Visceral Fat
          _buildInputField(
            controller: _visceralFatController,
            label: lang.t('inbody_input_visceral_fat'),
            hint: '8',
            icon: Icons.health_and_safety,
          ),

          const SizedBox(height: 16),

          // Body Water
          _buildInputField(
            controller: _bodyWaterController,
            label: lang.t('inbody_input_body_water'),
            hint: '60.2',
            icon: Icons.water_drop,
          ),

          const SizedBox(height: 16),

          // Protein
          _buildInputField(
            controller: _proteinController,
            label: lang.t('inbody_input_protein_kg'),
            hint: '12.5',
            icon: Icons.restaurant,
          ),

          const SizedBox(height: 16),

          // Mineral
          _buildInputField(
            controller: _mineralController,
            label: lang.t('inbody_input_mineral_kg'),
            hint: '3.2',
            icon: Icons.science,
          ),

          const SizedBox(height: 16),

          // BMR
          _buildInputField(
            controller: _bmrController,
            label: lang.t('inbody_input_bmr_kcal'),
            hint: '1650',
            icon: Icons.local_fire_department,
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: lang.t('inbody_input_save_results'),
              onPressed: _isSaving ? null : () => _saveResults(lang),
              isLoading: _isSaving,
              variant: ButtonVariant.primary,
              size: ButtonSize.large,
              fullWidth: true,
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: lang.t('cancel'),
              onPressed: _isSaving
                  ? null
                  : () {
                      setState(() {
                        _inputMode = 'selection';
                      });
                    },
              variant: ButtonVariant.secondary,
              size: ButtonSize.large,
              fullWidth: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _saveResults(LanguageProvider lang) async {
    if (_isSaving) {
      return;
    }

    if (_weightController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang.t('inbody_input_please_enter_at_least_weight'),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final weight = double.parse(_weightController.text);
      final bodyFat = double.tryParse(_bodyFatController.text) ?? 18.0;
      final muscleMass =
          double.tryParse(_muscleMassController.text) ?? weight * 0.4;
      final bmi =
          double.tryParse(_bmiController.text) ?? weight / ((1.70 * 1.70));
      final visceralFat = int.tryParse(_visceralFatController.text) ?? 8;
      final bodyWater =
          double.tryParse(_bodyWaterController.text) ?? weight * 0.6;
      final protein = double.tryParse(_proteinController.text) ?? weight * 0.18;
      final mineral =
          double.tryParse(_mineralController.text) ?? weight * 0.045;
      final bmr = int.tryParse(_bmrController.text) ?? 1650;

      final bodyFatMass = (weight * bodyFat) / 100;
      final dryLeanMass = protein + mineral;
      final totalBodyWater = bodyWater;
      final intracellularWater = totalBodyWater * 0.625;
      final extracellularWater = totalBodyWater * 0.375;

      final scan = InBodyScan(
        userId: 'user',
        weight: weight,
        bmi: bmi,
        percentBodyFat: bodyFat,
        skeletalMuscleMass: muscleMass,
        bodyFatMass: bodyFatMass,
        totalBodyWater: totalBodyWater,
        intracellularWater: intracellularWater,
        extracellularWater: extracellularWater,
        dryLeanMass: dryLeanMass,
        basalMetabolicRate: bmr,
        visceralFatLevel: visceralFat,
        ecwTbwRatio: extracellularWater / totalBodyWater,
        inBodyScore: 75 + ((muscleMass / weight) * 100).toInt(),
        segmentalLean: SegmentalLean(
          leftArm: 100,
          rightArm: 100,
          trunk: 100,
          leftLeg: 100,
          rightLeg: 100,
        ),
        scanDate: DateTime.now(),
      );

      final authProvider = context.read<AuthProvider>();
      final coachProvider = context.read<CoachProvider>();
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);

      if (!DemoConfig.isDemo) {
        final repository = WorkoutRepository();
        await repository.saveInBodyScan(scan);
        await authProvider.refreshUserProfile(notify: false);

        final coachId = authProvider.user?.coachId;
        if (coachId != null && coachId.isNotEmpty) {
          await coachProvider.loadClients(coachId: coachId);
        }
      }

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            lang.t('inbody_input_inbody_results_saved_successfully'),
          ),
          backgroundColor: AppColors.success,
        ),
      );
      navigator.pop();
      return;
    } catch (e) {
      if (!mounted) return;

      final raw = e.toString().replaceFirst('Exception: ', '').trim();
      final message = raw.contains("type 'Null' is not a subtype")
          ? (lang.t('inbody_input_the_scan_was_saved_but_the'))
          : (raw.isNotEmpty
              ? raw
              : (lang.t('inbody_input_failed_to_save_results_please_try')));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted && _isSaving) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}

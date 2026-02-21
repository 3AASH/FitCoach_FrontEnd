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
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';
import '../subscription/subscription_manager_screen.dart';

class InBodyInputScreen extends StatefulWidget {
  const InBodyInputScreen({super.key});

  @override
  State<InBodyInputScreen> createState() => _InBodyInputScreenState();
}

class _InBodyInputScreenState extends State<InBodyInputScreen> {
  String _inputMode = 'selection'; // 'selection', 'ai-scan', 'manual'
  Uint8List? _selectedImageBytes;
  bool _isAnalyzing = false;
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
    final languageProvider = context.watch<LanguageProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isArabic = languageProvider.isArabic;
    final subscriptionTier = authProvider.user?.subscriptionTier ?? 'Freemium';
    final isPremium = subscriptionTier == 'Premium' || subscriptionTier == 'Smart Premium';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'تحليل InBody' : 'InBody Analysis'),
      ),
        body: _inputMode == 'selection'
          ? _buildModeSelection(isArabic, isPremium)
          : _inputMode == 'ai-scan'
            ? _buildAIScan(languageProvider)
            : _buildManualInput(isArabic),
    );
  }
  
  Widget _buildModeSelection(bool isArabic, bool isPremium) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
            child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? 'اختر طريقة الإدخال' : 'Choose Input Method',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isArabic
                ? 'كيف تريد إدخال بيانات InBody الخاصة بك؟'
                : 'How would you like to enter your InBody data?',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
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
                          color: isPremium ? null : AppColors.textDisabled.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.auto_awesome,
                          color: isPremium ? Colors.white : AppColors.textDisabled,
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
                                  isArabic ? 'مسح بالذكاء الاصطناعي' : 'AI Scan',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (!isPremium)
                                  const Icon(
                                    Icons.lock,
                                    size: 16,
                                    color: AppColors.textDisabled,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isArabic
                                  ? 'التقط صورة لتقرير InBody الخاص بك'
                                  : 'Take a photo of your InBody report',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
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
                                      isArabic ? 'استخراج فوري للبيانات' : 'Instant data extraction',
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
                                  text: isArabic ? 'ترقية للذكاء الاصطناعي' : 'Upgrade for AI',
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const SubscriptionManagerScreen(),
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
                        color: isPremium ? AppColors.textSecondary : AppColors.textDisabled,
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                          isArabic ? 'ميزة بريميوم' : 'Premium Feature',
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
                        isArabic ? 'إدخال يدوي' : 'Manual Input',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isArabic
                            ? 'أدخل القياسات يدوياً'
                            : 'Enter measurements manually',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
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
                            isArabic ? 'متاح لجميع المستخدمين' : 'Available for all users',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  isArabic ? Icons.chevron_left : Icons.chevron_right,
                  color: AppColors.textDisabled,
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
                    isArabic
                        ? 'يساعدك تحليل InBody على تتبع تكوين جسمك بدقة وتحديد أهداف واقعية'
                        : 'InBody analysis helps you track your body composition accurately and set realistic goals',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
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
    final isArabic = lang.isArabic;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: _selectedImageBytes == null
                ? _buildAiIntro(lang, isArabic)
                : _buildAiPreview(lang, isArabic),
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

  Widget _buildAiIntro(LanguageProvider lang, bool isArabic) {
    return Column(
      key: const ValueKey('ai-intro'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
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
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 16),
              Text(
                isArabic ? 'تحليل InBody بالذكاء الاصطناعي' : 'AI-powered InBody analysis',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isArabic
                    ? 'التقط صورة واضحة لتقرير InBody وسنملأ الأرقام تلقائياً.'
                    : 'Capture a clear photo of your InBody report and we will fill every metric for you.',
                style: const TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Column(
                children: [
                  _buildAiHintRow(
                    Icons.photo_camera_outlined,
                    isArabic ? 'احرص على إضاءة جيدة وخلفية نظيفة.' : 'Use good lighting and a clean background.',
                  ),
                  const SizedBox(height: 12),
                  _buildAiHintRow(
                    Icons.crop_free,
                    isArabic ? 'قم بمحاذاة التقرير بالكامل داخل الإطار.' : 'Align the entire report inside the frame.',
                  ),
                  const SizedBox(height: 12),
                  _buildAiHintRow(
                    Icons.timer,
                    isArabic ? 'يستغرق التحليل ثوانٍ معدودة.' : 'Analysis takes only a few seconds.',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        CustomButton(
          text: isArabic ? 'فتح الكاميرا' : 'Open Camera',
          onPressed: _openCamera,
          variant: ButtonVariant.primary,
          size: ButtonSize.large,
          icon: Icons.camera_alt,
          fullWidth: true,
        ),
        const SizedBox(height: 12),
        CustomButton(
          text: isArabic ? 'اختيار من المعرض' : 'Choose from Gallery',
          onPressed: _openGallery,
          variant: ButtonVariant.secondary,
          size: ButtonSize.large,
          icon: Icons.photo_library,
          fullWidth: true,
        ),
        const SizedBox(height: 8),
        CustomButton(
          text: isArabic ? 'الانتقال للإدخال اليدوي' : 'Switch to manual entry',
          onPressed: () => setState(() => _inputMode = 'manual'),
          variant: ButtonVariant.ghost,
          size: ButtonSize.medium,
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildAiPreview(LanguageProvider lang, bool isArabic) {
    final summary = _extractedData;
    return Column(
      key: const ValueKey('ai-preview'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
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
                  isArabic ? 'يتم الآن تحليل الصورة...' : 'Analyzing your scan...',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  isArabic
                      ? 'نستخرج تلقائياً كل البيانات المهمة من تقريرك.'
                      : 'We extract every important metric from your report.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                const LinearProgressIndicator(value: 0.65, minHeight: 6),
              ]
              else if (_extractionComplete && summary != null) ...[
                Text(
                  isArabic ? 'تم استخراج البيانات' : 'Data extraction complete',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  isArabic
                      ? 'راجع أبرز القياسات ثم تابع لتعديل أي قيمة قبل الحفظ.'
                      : 'Review the highlighted metrics, then continue to fine-tune before saving.',
                  style: const TextStyle(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                _buildAiSummaryGrid(summary, isArabic),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: isArabic ? 'إعادة الالتقاط' : 'Retake photo',
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
                        text: isArabic ? 'استخدام هذه البيانات' : 'Use extracted data',
                        onPressed: () => _applyExtractedDataAndContinue(lang),
                        variant: ButtonVariant.primary,
                        size: ButtonSize.medium,
                        icon: isArabic ? Icons.arrow_back : Icons.arrow_forward,
                        fullWidth: true,
                      ),
                    ),
                  ],
                ),
              ]
              else ...[
                Text(
                  isArabic ? 'جارٍ تجهيز المعاينة...' : 'Preparing preview...',
                  style: const TextStyle(color: AppColors.textSecondary),
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
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildAiSummaryGrid(Map<String, dynamic> summary, bool isArabic) {
    final weightValue = _formatNumber(summary['weight'] as num?);
    final bmiValue = _formatNumber(summary['bmi'] as num?);
    final fatValue = _formatNumber(summary['bodyFat'] as num?);
    final muscleValue = _formatNumber(summary['muscleMass'] as num?);
    final stats = [
      {
        'label': isArabic ? 'الوزن' : 'Weight',
        'value': weightValue == '--' ? weightValue : '$weightValue kg',
        'color': AppColors.primary,
      },
      {
        'label': 'BMI',
        'value': bmiValue,
        'color': AppColors.secondaryForeground,
      },
      {
        'label': isArabic ? 'دهون الجسم' : 'Body fat',
        'value': fatValue == '--' ? fatValue : '$fatValue%',
        'color': const Color(0xFF22C55E),
      },
      {
        'label': isArabic ? 'الكتلة العضلية' : 'Muscle mass',
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
              isArabic,
            ),
          )
          .toList(),
    );
  }

  Widget _buildAiStatTile(String label, String value, Color color, bool isArabic) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
      final extracted = (result['extractedData'] as Map?)?.cast<String, dynamic>();

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
    } catch (error) {
      _showImageError();
    }
  }

  Future<void> _simulateExtraction() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final inferredWeight = double.tryParse(_weightController.text) ?? 72.4;
    final extractedData = {
      'weight': inferredWeight,
      'bmi': double.tryParse(_bmiController.text) ?? 23.4,
      'bodyFat': double.tryParse(_bodyFatController.text) ?? 17.8,
      'muscleMass': double.tryParse(_muscleMassController.text) ?? (inferredWeight * 0.42),
      'visceralFat': int.tryParse(_visceralFatController.text) ?? 8,
      'bodyWater': double.tryParse(_bodyWaterController.text) ?? (inferredWeight * 0.62),
      'protein': double.tryParse(_proteinController.text) ?? (inferredWeight * 0.18),
      'mineral': double.tryParse(_mineralController.text) ?? (inferredWeight * 0.045),
      'bmr': int.tryParse(_bmrController.text) ?? 1580,
    };

    setState(() {
      _isAnalyzing = false;
      _extractionComplete = true;
      _extractedData = extractedData;
    });
  }

  void _showImageError() {
    if (!mounted) return;
    final lang = context.read<LanguageProvider>();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          lang.isArabic
              ? 'حدث خطأ أثناء معالجة الصورة. حاول مرة أخرى.'
              : 'Something went wrong while processing the image. Please try again.',
        ),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _clearAiCapture() {
    setState(() {
      _selectedImageBytes = null;
      _isAnalyzing = false;
      _extractionComplete = false;
      _extractedData = null;
    });
  }

  void _applyExtractedDataAndContinue(LanguageProvider lang) {
    final data = _extractedData;
    if (data == null) return;

    _weightController.text = _formatNumber(data['weight'] as num?, emptyIfNull: true);
    _bodyFatController.text = _formatNumber(data['bodyFat'] as num?, emptyIfNull: true);
    _muscleMassController.text = _formatNumber(data['muscleMass'] as num?, emptyIfNull: true);
    _bmiController.text = _formatNumber(data['bmi'] as num?, emptyIfNull: true);
    _visceralFatController.text = _formatNumber(
      data['visceralFat'] as num?,
      fractionDigits: 0,
      emptyIfNull: true,
    );
    _bodyWaterController.text = _formatNumber(data['bodyWater'] as num?, emptyIfNull: true);
    _proteinController.text = _formatNumber(data['protein'] as num?, emptyIfNull: true);
    _mineralController.text = _formatNumber(data['mineral'] as num?, emptyIfNull: true);
    _bmrController.text = _formatNumber(
      data['bmr'] as num?,
      fractionDigits: 0,
      emptyIfNull: true,
    );

    setState(() {
      _inputMode = 'manual';
      _selectedImageBytes = null;
      _isAnalyzing = false;
      _extractionComplete = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          lang.isArabic
              ? 'تمت إضافة القياسات المستخرجة، تأكد منها قبل الحفظ.'
              : 'Extracted metrics applied. Review them before saving.',
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }

  String _formatNumber(num? value, {int fractionDigits = 1, bool emptyIfNull = false}) {
    if (value == null) {
      return emptyIfNull ? '' : '--';
    }
    if (value is int || fractionDigits == 0) {
      return value.toString();
    }
    return value.toStringAsFixed(fractionDigits);
  }
  
  Widget _buildManualInput(bool isArabic) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? 'أدخل قياساتك' : 'Enter Your Measurements',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Weight
          _buildInputField(
            controller: _weightController,
            label: isArabic ? 'الوزن (كجم)' : 'Weight (kg)',
            hint: '70.5',
            icon: Icons.monitor_weight,
          ),
          
          const SizedBox(height: 16),
          
          // Body Fat %
          _buildInputField(
            controller: _bodyFatController,
            label: isArabic ? 'نسبة الدهون (%)' : 'Body Fat (%)',
            hint: '18.5',
            icon: Icons.pie_chart,
          ),
          
          const SizedBox(height: 16),
          
          // Muscle Mass
          _buildInputField(
            controller: _muscleMassController,
            label: isArabic ? 'الكتلة العضلية (كجم)' : 'Muscle Mass (kg)',
            hint: '35.2',
            icon: Icons.fitness_center,
          ),
          
          const SizedBox(height: 16),
          
          // BMI
          _buildInputField(
            controller: _bmiController,
            label: isArabic ? 'مؤشر كتلة الجسم' : 'BMI',
            hint: '23.4',
            icon: Icons.straighten,
          ),
          
          const SizedBox(height: 24),
          
          Text(
            isArabic ? 'قياسات إضافية (اختياري)' : 'Additional Measurements (Optional)',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Visceral Fat
          _buildInputField(
            controller: _visceralFatController,
            label: isArabic ? 'الدهون الحشوية' : 'Visceral Fat',
            hint: '8',
            icon: Icons.health_and_safety,
          ),
          
          const SizedBox(height: 16),
          
          // Body Water
          _buildInputField(
            controller: _bodyWaterController,
            label: isArabic ? 'ماء الجسم (%)' : 'Body Water (%)',
            hint: '60.2',
            icon: Icons.water_drop,
          ),
          
          const SizedBox(height: 16),
          
          // Protein
          _buildInputField(
            controller: _proteinController,
            label: isArabic ? 'البروتين (كجم)' : 'Protein (kg)',
            hint: '12.5',
            icon: Icons.restaurant,
          ),
          
          const SizedBox(height: 16),
          
          // Mineral
          _buildInputField(
            controller: _mineralController,
            label: isArabic ? 'المعادن (كجم)' : 'Mineral (kg)',
            hint: '3.2',
            icon: Icons.science,
          ),
          
          const SizedBox(height: 16),
          
          // BMR
          _buildInputField(
            controller: _bmrController,
            label: isArabic ? 'معدل الأيض الأساسي' : 'BMR (kcal)',
            hint: '1650',
            icon: Icons.local_fire_department,
          ),
          
          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: isArabic ? 'حفظ النتائج' : 'Save Results',
              onPressed: () => _saveResults(isArabic),
              variant: ButtonVariant.primary,
              size: ButtonSize.large,
              fullWidth: true,
            ),
          ),
          
          const SizedBox(height: 12),
          
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: isArabic ? 'إلغاء' : 'Cancel',
              onPressed: () {
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
  
  void _saveResults(bool isArabic) async {
    if (_weightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic ? 'الرجاء إدخال الوزن على الأقل' : 'Please enter at least weight',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    try {
      // Parse inputs
      final weight = double.parse(_weightController.text);
      final bodyFat = double.tryParse(_bodyFatController.text) ?? 18.0;
      final muscleMass = double.tryParse(_muscleMassController.text) ?? weight * 0.4;
      final bmi = double.tryParse(_bmiController.text) ?? weight / ((1.70 * 1.70)); // Estimate
      final visceralFat = int.tryParse(_visceralFatController.text) ?? 8;
      final bodyWater = double.tryParse(_bodyWaterController.text) ?? weight * 0.6;
      final protein = double.tryParse(_proteinController.text) ?? weight * 0.18;
      final mineral = double.tryParse(_mineralController.text) ?? weight * 0.045;
      final bmr = int.tryParse(_bmrController.text) ?? 1650;
      
      // Calculate derived values
      final bodyFatMass = (weight * bodyFat) / 100;
      final dryLeanMass = protein + mineral;
      final totalBodyWater = bodyWater;
      final intracellularWater = totalBodyWater * 0.625;
      final extracellularWater = totalBodyWater * 0.375;
      
      // Create InBody scan object
      final scan = InBodyScan(
        userId: 'user', // Will be set by backend
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
        inBodyScore: 75 + ((muscleMass / weight) * 100).toInt(), // Simple score calculation
        segmentalLean: SegmentalLean(
          leftArm: 100,
          rightArm: 100,
          trunk: 100,
          leftLeg: 100,
          rightLeg: 100,
        ),
        scanDate: DateTime.now(),
      );
      
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic ? 'جاري الحفظ...' : 'Saving...',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
      
      if (!DemoConfig.isDemo) {
        // Save to backend
        final repository = WorkoutRepository();
        await repository.saveInBodyScan(scan);
      }
      
      // Success
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic ? 'تم حفظ نتائج InBody بنجاح' : 'InBody results saved successfully',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      // Error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic 
              ? 'فشل في حفظ النتائج: ${e.toString()}' 
              : 'Failed to save results: ${e.toString()}',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/demo_config.dart';
import '../../../core/constants/colors.dart';
import '../../../data/repositories/payment_repository.dart';
import '../../providers/language_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/subscription_plan_provider.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';
import '../../../data/models/subscription_plan.dart';

class SubscriptionUpgradeScreen extends StatefulWidget {
  final String? requiredTier; // 'premium' or 'smart_premium'
  final String? featureName; // Feature that triggered upgrade
  
  const SubscriptionUpgradeScreen({
    super.key,
    this.requiredTier,
    this.featureName,
  });

  @override
  State<SubscriptionUpgradeScreen> createState() => _SubscriptionUpgradeScreenState();
}

class _SubscriptionUpgradeScreenState extends State<SubscriptionUpgradeScreen> {
  String? _selectedPlanId;
  String _selectedCycle = 'monthly'; // 'monthly' or 'yearly'
  String _selectedPaymentMethod = 'stripe'; // 'stripe' or 'tap'
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _selectedPlanId = widget.requiredTier;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionPlanProvider>().loadPlans();
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final authProvider = context.watch<AuthProvider>();
    final planProvider = context.watch<SubscriptionPlanProvider>();
    String tr(String key, {Map<String, String>? args}) =>
        languageProvider.t(key, args: args);
    final currentTier = authProvider.user?.subscriptionTier ?? 'freemium';
    final paidPlans = _paidPlans(planProvider.plans);
    SubscriptionPlan? selectedPlan = _findPlanByIdentifier(paidPlans, _selectedPlanId);
    selectedPlan ??= paidPlans.isNotEmpty ? paidPlans.first : null;
    final requiredPlanName = planProvider.matchTier(widget.requiredTier ?? '')?.name ?? widget.requiredTier;

    if (selectedPlan != null && selectedPlan.id != _selectedPlanId) {
      final targetId = selectedPlan.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _selectedPlanId = targetId);
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('subscription_upgrade_title')),
      ),
      body: planProvider.isLoading && !planProvider.hasLoaded
          ? const Center(child: CircularProgressIndicator())
          : paidPlans.isEmpty
              ? const _EmptyPlansState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.featureName != null) ...[
                        CustomCard(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          child: Row(
                            children: [
                              const Icon(Icons.lock, color: AppColors.warning),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  tr(
                                    'subscription_feature_requires_plan',
                                    args: {
                                      'feature': widget.featureName!,
                                      'plan': (requiredPlanName ?? widget.requiredTier ?? 'Premium'),
                                    },
                                  ),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      Text(
                        tr('subscription_choose_plan'),
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tr('subscription_upgrade_subtitle'),
                        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 24),
                      _buildBillingCycleToggle(languageProvider),
                      const SizedBox(height: 24),
                      ...paidPlans.map((plan) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildPlanCard(
                              plan: plan,
                              languageProvider: languageProvider,
                              currentTier: currentTier,
                              isSelected: selectedPlan?.id == plan.id,
                              onSelected: () {
                                setState(() => _selectedPlanId = plan.id);
                              },
                            ),
                          )),
                      const SizedBox(height: 32),
                      Text(
                        tr('subscription_payment_method'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildPaymentMethodSelector(languageProvider),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          text: _isProcessing
                              ? tr('processing')
                              : tr('subscription_continue_to_payment'),
                            onPressed: _isProcessing || selectedPlan == null
                              ? null
                              : () => _handlePayment(languageProvider, selectedPlan!),
                          variant: ButtonVariant.primary,
                          size: ButtonSize.large,
                          fullWidth: true,
                          icon: Icons.payment,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        tr('subscription_payment_disclaimer'),
                        style: const TextStyle(fontSize: 12, color: AppColors.textDisabled),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
    );
  }
  
  Widget _buildBillingCycleToggle(LanguageProvider languageProvider) {
    String tr(String key, {Map<String, String>? args}) =>
        languageProvider.t(key, args: args);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _buildCycleOption(
              'monthly',
              tr('subscription_billing_monthly'),
              languageProvider,
            ),
          ),
          Expanded(
            child: _buildCycleOption(
              'yearly',
              tr('subscription_billing_yearly'),
              languageProvider,
              badge: tr('subscription_yearly_badge'),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCycleOption(
    String cycle,
    String label,
    LanguageProvider languageProvider, {
    String? badge,
  }) {
    final isSelected = _selectedCycle == cycle;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCycle = cycle;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : AppColors.success,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppColors.primary : Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildPlanCard({
    required SubscriptionPlan plan,
    required LanguageProvider languageProvider,
    required String currentTier,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    final isCurrent = _isCurrentPlan(plan, currentTier);
    final price = _selectedCycle == 'monthly'
        ? plan.monthlyPrice
        : (plan.yearlyPrice ?? plan.monthlyPrice * 12);
    final monthlyBreakdown = _selectedCycle == 'yearly'
        ? price / 12
        : plan.monthlyPrice;
    final featureList = [...plan.features]
      ..sort((a, b) => a.order.compareTo(b.order));
    final planName = _localizedPlanName(plan, languageProvider.isArabic);
    final planDescription = _localizedPlanDescription(plan, languageProvider.isArabic);
    final accentColor = _planAccentColor(plan);
    String tr(String key, {Map<String, String>? args}) =>
        languageProvider.t(key, args: args);
    final cycleUnitShort = _selectedCycle == 'monthly'
        ? tr('subscription_unit_month_short')
        : tr('subscription_unit_year_short');
    final monthUnitFull = tr('subscription_unit_month_full');

    return GestureDetector(
      onTap: isCurrent ? null : onSelected,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          color: isCurrent ? AppColors.surface : Colors.white,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      planName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (plan.badge != null || plan.isRecommended) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          plan.badge ?? tr('subscription_best_value_badge'),
                          style: TextStyle(
                            fontSize: 10,
                            color: accentColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    if (isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tr('subscription_status_current'),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (!isCurrent)
                  Radio<String>(
                    value: plan.id,
                    groupValue: _selectedPlanId,
                    onChanged: (_) => onSelected(),
                    activeColor: AppColors.primary,
                  ),
              ],
            ),
            if (planDescription != null && planDescription.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                planDescription,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${price.toStringAsFixed(0)} ${plan.currency}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '/$cycleUnitShort',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            if (_selectedCycle == 'yearly') ...[
              const SizedBox(height: 4),
              Text(
                '${monthlyBreakdown.toStringAsFixed(0)} ${plan.currency}/$monthUnitFull',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textDisabled,
                ),
              ),
            ],
            const SizedBox(height: 16),
            ...featureList.take(5).map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            feature.value == null
                                ? feature.label
                                : '${feature.label}: ${feature.value}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
            if (featureList.length > 5)
              Text(
                tr('subscription_more_perks'),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<SubscriptionPlan> _paidPlans(List<SubscriptionPlan> plans) {
    final paid = plans.where((plan) => !plan.isFree).toList();
    paid.sort((a, b) => a.monthlyPrice.compareTo(b.monthlyPrice));
    return paid;
  }

  SubscriptionPlan? _findPlanByIdentifier(
    List<SubscriptionPlan> plans,
    String? identifier,
  ) {
    if (identifier == null || identifier.isEmpty) return null;
    final query = identifier.trim().toLowerCase();
    for (final plan in plans) {
      final slug = (plan.metadata['tier'] as String?)?.trim().toLowerCase();
      if (plan.id.toLowerCase() == query ||
          plan.name.toLowerCase() == query ||
          slug == query) {
        return plan;
      }
    }
    return null;
  }

  bool _isCurrentPlan(SubscriptionPlan plan, String currentTier) {
    if (currentTier.isEmpty) return false;
    final query = currentTier.trim().toLowerCase();
    final slug = (plan.metadata['tier'] as String?)?.trim().toLowerCase();
    return plan.id.toLowerCase() == query || plan.name.toLowerCase() == query || slug == query;
  }

  String _localizedPlanName(SubscriptionPlan plan, bool isArabic) {
    if (!isArabic) return plan.name;
    final arabicName = plan.metadata['name_ar'] as String?;
    if (arabicName != null && arabicName.trim().isNotEmpty) {
      return arabicName.trim();
    }
    return plan.name;
  }

  String? _localizedPlanDescription(SubscriptionPlan plan, bool isArabic) {
    if (!isArabic) return plan.description.isEmpty ? null : plan.description;
    final arabicDescription = plan.metadata['description_ar'] as String?;
    if (arabicDescription != null && arabicDescription.trim().isNotEmpty) {
      return arabicDescription.trim();
    }
    return plan.description.isEmpty ? null : plan.description;
  }

  Color _planAccentColor(SubscriptionPlan plan) {
    final hex = plan.accentColor.replaceAll('#', '');
    final parsed = int.tryParse(hex, radix: 16);
    if (parsed == null) {
      return AppColors.primary;
    }
    return Color(0xFF000000 | parsed);
  }
  
  Widget _buildPaymentMethodSelector(LanguageProvider languageProvider) {
    String tr(String key, {Map<String, String>? args}) =>
        languageProvider.t(key, args: args);
    return Row(
      children: [
        Expanded(
          child: _buildPaymentMethodCard(
            'stripe',
            tr('payment_method_credit_card'),
            Icons.credit_card,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildPaymentMethodCard(
            'tap',
            tr('payment_method_tap'),
            Icons.payment,
          ),
        ),
      ],
    );
  }
  
  Widget _buildPaymentMethodCard(
    String method,
    String label,
    IconData icon,
  ) {
    final isSelected = _selectedPaymentMethod == method;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = method;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textDisabled,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _handlePayment(LanguageProvider languageProvider, SubscriptionPlan plan) async {
    setState(() {
      _isProcessing = true;
    });
    String tr(String key, {Map<String, String>? args}) =>
        languageProvider.t(key, args: args);
    final tierCode = _resolveTierCode(plan);
    
    try {
      if (DemoConfig.isDemo) {
        final userProvider = context.read<UserProvider>();
        final authProvider = context.read<AuthProvider>();
        final success = await userProvider.updateSubscription(plan.name);
        if (success && userProvider.profile != null) {
          authProvider.updateUser(userProvider.profile!);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                tr('subscription_demo_activation_success'),
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
        return;
      }
      final repository = PaymentRepository();
      
      Map<String, dynamic> paymentResult;
      
      if (_selectedPaymentMethod == 'stripe') {
        // Create Stripe payment
        paymentResult = await repository.createStripePayment(
          tier: tierCode,
          billingCycle: _selectedCycle,
        );
        
        // Launch Stripe checkout URL
        final checkoutUrl = paymentResult['checkoutUrl'] as String;
        await _launchPaymentUrl(checkoutUrl);
        
      } else {
        // Create Tap payment
        paymentResult = await repository.createTapPayment(
          tier: tierCode,
          billingCycle: _selectedCycle,
        );
        
        // Launch Tap payment URL
        final paymentUrl = paymentResult['paymentUrl'] as String;
        await _launchPaymentUrl(paymentUrl);
      }
      
      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr('subscription_payment_redirect'),
            ),
            backgroundColor: AppColors.success,
          ),
        );
        
        // After payment completes (webhook will update backend)
        // User needs to restart app or pull to refresh
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr('subscription_payment_failed', args: {'error': e.toString()}),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  String _resolveTierCode(SubscriptionPlan plan) {
    const supported = {'freemium', 'premium', 'smart_premium'};
    final idValue = plan.id.toLowerCase();
    if (supported.contains(idValue)) return idValue;

    final normalizedName = plan.name
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('-', '_');
    if (supported.contains(normalizedName)) return normalizedName;

    return idValue;
  }
  
  Future<void> _launchPaymentUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not launch payment URL');
    }
  }
}

class _EmptyPlansState extends StatelessWidget {
  const _EmptyPlansState();

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    String tr(String key, {Map<String, String>? args}) =>
        languageProvider.t(key, args: args);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_graph, size: 72, color: AppColors.textDisabled.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              tr('subscription_empty_title'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              tr('subscription_empty_subtitle'),
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

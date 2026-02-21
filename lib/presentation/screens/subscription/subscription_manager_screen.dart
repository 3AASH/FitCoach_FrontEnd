import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../../core/config/demo_config.dart';
import '../../../core/constants/colors.dart';
import '../../providers/language_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/subscription_plan_provider.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/subscription_comparison_table.dart';
import '../../../data/models/subscription_plan.dart';

class SubscriptionManagerScreen extends StatefulWidget {
  const SubscriptionManagerScreen({super.key});

  @override
  State<SubscriptionManagerScreen> createState() => _SubscriptionManagerScreenState();
}

class _SubscriptionManagerScreenState extends State<SubscriptionManagerScreen> {
  @override
  void initState() {
    super.initState();
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
    final currentTier = authProvider.user?.subscriptionTier ?? 'Freemium';
    final plans = _sortedPlans(planProvider.plans);
    SubscriptionPlan? currentPlan = planProvider.matchTier(currentTier);
    currentPlan ??= planProvider.freemiumPlan ?? (plans.isNotEmpty ? plans.first : null);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('subscription_manage_title')),
      ),
      body: planProvider.isLoading && !planProvider.hasLoaded
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => planProvider.loadPlans(forceRefresh: true),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildCurrentPlanCard(currentPlan, currentTier, languageProvider),
                  const SizedBox(height: 24),
                  if (planProvider.error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        planProvider.error!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  if (plans.isNotEmpty) ...[
                    Text(
                      tr('subscription_compare_title'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SubscriptionComparisonTable(
                      plans: plans,
                      featureLabels: planProvider.comparisonFeatureLabels,
                      currentPlanId: currentPlan?.id,
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (plans.isNotEmpty)
                    Text(
                      tr('subscription_choose_plan'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (plans.isNotEmpty)
                    ...plans.map((plan) => _buildPlanCard(
                          plan,
                          currentPlan,
                          plans,
                          languageProvider,
                        )),
                ],
              ),
            ),
    );
  }

  Widget _buildCurrentPlanCard(
    SubscriptionPlan? plan,
    String fallbackTier,
    LanguageProvider languageProvider,
  ) {
    final metadata = plan?.metadata ?? const {};
    String tr(String key, {Map<String, String>? args}) =>
        languageProvider.t(key, args: args);
    return CustomCard(
      color: AppColors.primary.withValues(alpha: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('subscription_current_plan_label'),
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                plan?.name ?? fallbackTier,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              if (plan != null && !plan.isFree)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tr('subscription_status_active'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (plan != null)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetricChip(
                  icon: Icons.chat_bubble_outline,
                  label: tr('subscription_coach_messages'),
                  value: _formatLimit(metadata['messagesLimit'], languageProvider),
                ),
                _MetricChip(
                  icon: Icons.videocam_outlined,
                  label: tr('subscription_video_calls'),
                  value: _formatLimit(metadata['videoCallsLimit'], languageProvider),
                ),
              ],
            )
          else
            Text(
              tr('subscription_plan_loading_message'),
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(
    SubscriptionPlan plan,
    SubscriptionPlan? currentPlan,
    List<SubscriptionPlan> allPlans,
    LanguageProvider languageProvider,
  ) {
    final isCurrent = currentPlan != null && plan.id == currentPlan.id;
    final isUpgrade = currentPlan == null || _isUpgrade(plan, currentPlan, allPlans);
    final metadata = plan.metadata;
    String tr(String key, {Map<String, String>? args}) =>
        languageProvider.t(key, args: args);
    final monthUnitShort = tr('subscription_unit_month_short');
    final yearUnitShort = tr('subscription_unit_year_short');

    return CustomCard(
      margin: const EdgeInsets.only(bottom: 16),
      border: isCurrent ? Border.all(color: AppColors.primary, width: 2) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan.description,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (plan.badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    plan.badge!,
                    style: const TextStyle(fontSize: 11, color: AppColors.primary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                plan.isFree
                    ? tr('subscription_free_label')
                    : '${plan.monthlyPrice.toStringAsFixed(0)} ${plan.currency}/$monthUnitShort',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              if (plan.yearlyPrice != null && plan.yearlyPrice! > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 2),
                  child: Text(
                    tr(
                      'subscription_yearly_price_label',
                      args: {
                        'price': plan.yearlyPrice!.toStringAsFixed(0),
                        'currency': plan.currency,
                        'unit': yearUnitShort,
                      },
                    ),
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetricChip(
                icon: Icons.chat_bubble_outline,
                label: tr('subscription_coach_messages'),
                value: _formatLimit(metadata['messagesLimit'], languageProvider),
              ),
              _MetricChip(
                icon: Icons.videocam_outlined,
                label: tr('subscription_video_calls'),
                value: _formatLimit(metadata['videoCallsLimit'], languageProvider),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...plan.features.take(5).map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.success, size: 18),
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
              )),
          const SizedBox(height: 16),
          CustomButton(
            text: isCurrent
                ? tr('subscription_current_plan_button')
                : _getButtonLabel(isUpgrade, languageProvider),
            onPressed: isCurrent
                ? null
                : () => _handlePlanAction(plan, currentPlan, languageProvider, allPlans),
            variant: isUpgrade ? ButtonVariant.primary : ButtonVariant.secondary,
            size: ButtonSize.large,
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  String _formatLimit(dynamic value, LanguageProvider languageProvider) {
    String tr(String key, {Map<String, String>? args}) =>
        languageProvider.t(key, args: args);
    if (value == null) return tr('subscription_limit_flexible');
    if (value is num && value.toInt() < 0) {
      return tr('subscription_limit_unlimited');
    }
    final parsed = value is num ? value.toInt() : int.tryParse(value.toString());
    if (parsed == null) return value.toString();
    return tr('subscription_limit_value', args: {'value': parsed.toString()});
  }

  void _handlePlanAction(
    SubscriptionPlan targetPlan,
    SubscriptionPlan? currentPlan,
    LanguageProvider languageProvider,
    List<SubscriptionPlan> plans,
  ) {
    final isUpgrade = currentPlan == null || _isUpgrade(targetPlan, currentPlan, plans);
    String tr(String key, {Map<String, String>? args}) =>
        languageProvider.t(key, args: args);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isUpgrade
              ? tr('subscription_upgrade_confirm_title')
              : tr('subscription_switch_confirm_title'),
        ),
        content: Text(
          isUpgrade
              ? tr('subscription_upgrade_confirm_body', args: {'plan': targetPlan.name})
              : tr('subscription_switch_confirm_body', args: {'plan': targetPlan.name}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _processPlanChange(targetPlan, currentPlan, languageProvider);
            },
            child: Text(tr('confirm')),
          ),
        ],
      ),
    );
  }

  Future<void> _processPlanChange(
    SubscriptionPlan targetPlan,
    SubscriptionPlan? currentPlan,
    LanguageProvider languageProvider,
  ) async {
    final authProvider = context.read<AuthProvider>();
    final userProvider = context.read<UserProvider>();
    String tr(String key, {Map<String, String>? args}) =>
        languageProvider.t(key, args: args);

    final wasFreemium =
        currentPlan?.isFree ?? (authProvider.user?.subscriptionTier == 'Freemium');

    final updated = await userProvider.updateSubscription(targetPlan.name);
    if (!mounted) return;

    if (!updated) {
      final message = userProvider.error ?? tr('subscription_update_failed');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    await userProvider.loadProfile();
    if (!mounted) return;

    if (userProvider.profile != null) {
      authProvider.updateUser(userProvider.profile!);
    } else {
      await authProvider.refreshUserProfile();
      if (!mounted) return;
    }

    if (wasFreemium && !targetPlan.isFree) {
      final authUserId = authProvider.user?.id;
      final userId = authUserId ?? (DemoConfig.isDemo ? DemoConfig.demoUserId : null);
      if (userId != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('pending_nutrition_intake_$userId', true);
        await prefs.setBool('nutrition_preferences_completed_$userId', false);
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tr('subscription_update_success'),
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }

  bool _isUpgrade(
    SubscriptionPlan target,
    SubscriptionPlan current,
    List<SubscriptionPlan> plans,
  ) {
    final ids = plans.map((plan) => plan.id).toList();
    final targetIndex = ids.indexOf(target.id);
    final currentIndex = ids.indexOf(current.id);
    if (targetIndex == -1 || currentIndex == -1) {
      return target.monthlyPrice > current.monthlyPrice;
    }
    return targetIndex > currentIndex;
  }

  String _getButtonLabel(bool isUpgrade, LanguageProvider languageProvider) {
    return isUpgrade
        ? languageProvider.t('subscription_upgrade_cta')
        : languageProvider.t('subscription_switch_cta');
  }

  List<SubscriptionPlan> _sortedPlans(List<SubscriptionPlan> plans) {
    final sorted = [...plans];
    sorted.sort((a, b) => a.monthlyPrice.compareTo(b.monthlyPrice));
    return sorted;
  }

}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

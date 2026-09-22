import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../data/models/subscription_plan.dart';
import '../providers/language_provider.dart';
import '../../core/theme/app_palette.dart';

class SubscriptionComparisonTable extends StatelessWidget {
  final List<SubscriptionPlan> plans;
  final List<String>? featureLabels;
  final String? currentPlanId;

  const SubscriptionComparisonTable({
    super.key,
    required this.plans,
    this.featureLabels,
    this.currentPlanId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final languageProvider = context.watch<LanguageProvider>();
    final isArabic = languageProvider.isArabic;
    String tr(String key, {Map<String, String>? args}) =>
        languageProvider.t(key, args: args);

    if (plans.isEmpty) {
      return const SizedBox.shrink();
    }

    final labels = featureLabels ?? _collectFeatureLabels();
    final tableWidth = 180 + plans.length * 180;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        width: tableWidth.toDouble(),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.8)),
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 10),
              blurRadius: 25,
              color: Colors.black.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.16 : 0.08,
              ),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeaderRow(context, tr, isArabic),
            const Divider(height: 28),
            ...labels
                .map((label) => _buildFeatureRow(context, label, tr, isArabic))
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderRow(
    BuildContext context,
    String Function(String, {Map<String, String>? args}) tr,
    bool isArabic,
  ) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 180,
          child: Text(
            tr('subscription_features_header'),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: context.palette.textSecondary,
            ),
          ),
        ),
        ...plans.map((plan) {
          final isActive = currentPlanId != null &&
              plan.id.toLowerCase() == currentPlanId!.toLowerCase();
          final monthUnit = tr('subscription_unit_month_short');
          return SizedBox(
            width: 180,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        plan.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              isActive ? FontWeight.w800 : FontWeight.w600,
                          color: isActive
                              ? AppColors.primary
                              : theme.colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (plan.badge != null)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          plan.badge!,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  plan.isFree
                      ? tr('subscription_free_label')
                      : '${plan.monthlyPrice.toStringAsFixed(0)} ${plan.currency}/$monthUnit',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (plan.yearlyPrice != null && plan.yearlyPrice! > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      tr(
                        'subscription_yearly_equivalent',
                        args: {
                          'price': (plan.yearlyPrice! / 12).toStringAsFixed(0),
                          'currency': plan.currency,
                          'unit': monthUnit,
                          'note': tr('subscription_yearly_note'),
                        },
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: context.palette.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFeatureRow(
    BuildContext context,
    String label,
    String Function(String, {Map<String, String>? args}) tr,
    bool isArabic,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.dividerColor, width: 0.6),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ...plans.map((plan) {
            final feature = _findFeature(plan, label);
            final included = feature != null;
            final includeFallback = included
                ? tr('subscription_feature_included')
                : tr('subscription_feature_not_included');
            return SizedBox(
              width: 180,
              child: Row(
                children: [
                  Icon(
                    included ? Icons.check_circle : Icons.cancel,
                    size: 18,
                    color:
                        included ? AppColors.success : context.palette.textDisabled,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      included
                          ? (feature.value ?? includeFallback)
                          : includeFallback,
                      style: TextStyle(
                        fontSize: 12,
                        color: included
                            ? context.palette.textPrimary
                            : context.palette.textSecondary,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  List<String> _collectFeatureLabels() {
    final labels = <String>{};
    for (final plan in plans) {
      for (final feature in plan.features) {
        labels.add(feature.label);
      }
    }
    return labels.toList();
  }

  SubscriptionPlanFeature? _findFeature(SubscriptionPlan plan, String label) {
    for (final feature in plan.features) {
      if (feature.label == label) {
        return feature;
      }
    }
    return null;
  }
}

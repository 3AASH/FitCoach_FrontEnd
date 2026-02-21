import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../data/models/subscription_plan.dart';
import '../../providers/language_provider.dart';
import '../../providers/subscription_plan_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/subscription_comparison_table.dart';

class SubscriptionManagementScreen extends StatefulWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  State<SubscriptionManagementScreen> createState() => _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState extends State<SubscriptionManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SubscriptionPlanProvider>().loadPlans();
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final planProvider = context.watch<SubscriptionPlanProvider>();
    final plans = planProvider.plans;
    String tr(String key, {Map<String, String>? args}) =>
        languageProvider.t(key, args: args);

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context, languageProvider, planProvider),
          Expanded(
            child: planProvider.isLoading && !planProvider.hasLoaded
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => planProvider.loadPlans(forceRefresh: true),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 140),
                      children: [
                        if (planProvider.error != null)
                          _ErrorBanner(message: planProvider.error!),
                        if (planProvider.isSaving)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: LinearProgressIndicator(minHeight: 4),
                          ),
                        if (plans.isEmpty)
                          const _EmptyState()
                        else
                          ...plans
                              .map((plan) => _buildPlanCard(plan, languageProvider))
                              .toList(),
                        const SizedBox(height: 24),
                        if (plans.isNotEmpty) ...[
                          Text(
                            tr('subscription_admin_comparison_preview'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SubscriptionComparisonTable(
                            plans: plans,
                            featureLabels: planProvider.comparisonFeatureLabels,
                            currentPlanId: planProvider.freemiumPlan?.id,
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openPlanEditor(languageProvider),
        icon: const Icon(Icons.add_chart),
        label: Text(tr('subscription_admin_new_plan')),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    LanguageProvider languageProvider,
    SubscriptionPlanProvider planProvider,
  ) {
    final isArabic = languageProvider.isArabic;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondaryForeground],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: Icon(
                    isArabic ? Icons.arrow_forward : Icons.arrow_back,
                    color: AppColors.textWhite,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        languageProvider.t('admin_subscription_management'),
                        style: const TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        languageProvider.t('admin_manage_plans'),
                        style: const TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => planProvider.loadPlans(forceRefresh: true),
                  icon: const Icon(Icons.refresh, color: AppColors.textWhite),
                  label: Text(
                    languageProvider.t('refresh'),
                    style: const TextStyle(color: AppColors.textWhite),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              languageProvider.t('subscription_admin_header_description'),
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan, LanguageProvider languageProvider) {
    String tr(String key, {Map<String, String>? args}) =>
        languageProvider.t(key, args: args);
    final metadata = plan.metadata;
    final messagesLimit = metadata['messagesLimit'];
    final videoCallsLimit = metadata['videoCallsLimit'];

    return CustomCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            plan.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (plan.isRecommended)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              tr('subscription_recommended_label'),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      plan.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    plan.isFree
                        ? tr('subscription_free_label')
                        : '${plan.monthlyPrice.toStringAsFixed(0)} ${plan.currency}/${tr('subscription_unit_month_short')}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  if (plan.yearlyPrice != null && plan.yearlyPrice! > 0)
                    Text(
                      '${plan.yearlyPrice!.toStringAsFixed(0)} ${plan.currency}/${tr('subscription_unit_year_short')}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetricChip(
                label: tr('subscription_coach_messages'),
                value: _formatLimit(messagesLimit, languageProvider),
              ),
              _MetricChip(
                label: tr('subscription_video_calls'),
                value: _formatLimit(videoCallsLimit, languageProvider),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            tr('subscription_admin_key_features'),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          if (plan.features.isEmpty)
            Text(
              tr('subscription_admin_add_features_hint'),
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: plan.features.take(6).map((feature) {
                final text = feature.value == null ? feature.label : '${feature.label}: ${feature.value}';
                return Chip(
                  label: Text(text, style: const TextStyle(fontSize: 12)),
                  backgroundColor: AppColors.background,
                );
              }).toList(),
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: tr('subscription_admin_edit_plan'),
                  onPressed: () => _openPlanEditor(languageProvider, plan: plan),
                  icon: Icons.edit,
                  fullWidth: true,
                  size: ButtonSize.large,
                ),
              ),
              const SizedBox(width: 12),
              CustomButton(
                text: tr('delete'),
                onPressed: plan.isFree ? null : () => _confirmDeletePlan(plan, languageProvider),
                icon: Icons.delete_forever,
                variant: ButtonVariant.danger,
              ),
            ],
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
    if (parsed == null) {
      return value.toString();
    }
    return tr('subscription_limit_value', args: {'value': parsed.toString()});
  }

  void _openPlanEditor(LanguageProvider languageProvider, {SubscriptionPlan? plan}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _PlanEditorSheet(
          initialPlan: plan,
          onSubmit: (payload) async {
            final provider = context.read<SubscriptionPlanProvider>();
            final success = await provider.savePlan(payload);
            if (!mounted) return success;

            if (success) {
              Navigator.of(sheetContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(languageProvider.t('subscription_admin_save_success')),
                  backgroundColor: AppColors.success,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(languageProvider.t('subscription_admin_save_error')),
                  backgroundColor: AppColors.error,
                ),
              );
            }
            return success;
          },
        );
      },
    );
  }

  void _confirmDeletePlan(SubscriptionPlan plan, LanguageProvider languageProvider) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(languageProvider.t('subscription_admin_delete_title')),
        content: Text(
          languageProvider.t(
            'subscription_admin_delete_body',
            args: {'plan': plan.name},
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(languageProvider.t('cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final provider = context.read<SubscriptionPlanProvider>();
              final success = await provider.deletePlan(plan.id);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? languageProvider.t('subscription_admin_delete_success')
                        : languageProvider.t('subscription_admin_delete_failure'),
                  ),
                  backgroundColor: success ? AppColors.success : AppColors.error,
                ),
              );
            },
            child: Text(languageProvider.t('delete')),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;

  const _MetricChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
            child: Text(languageProvider.t('dismiss')),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Column(
        children: [
          Icon(Icons.auto_graph, size: 72, color: AppColors.textDisabled.withOpacity(0.7)),
          const SizedBox(height: 16),
          Text(
            languageProvider.t('subscription_admin_empty_title'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            languageProvider.t('subscription_admin_empty_subtitle'),
            style: const TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PlanEditorSheet extends StatefulWidget {
  final SubscriptionPlan? initialPlan;
  final Future<bool> Function(SubscriptionPlan plan) onSubmit;

  const _PlanEditorSheet({
    required this.initialPlan,
    required this.onSubmit,
  });

  @override
  State<_PlanEditorSheet> createState() => _PlanEditorSheetState();
}

class _PlanEditorSheetState extends State<_PlanEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _monthlyPriceController;
  late final TextEditingController _yearlyPriceController;
  late final TextEditingController _currencyController;
  late final TextEditingController _badgeController;
  late final TextEditingController _accentColorController;
  late final TextEditingController _messagesLimitController;
  late final TextEditingController _videoLimitController;
  late final List<_FeatureField> _featureFields;
  bool _isRecommended = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final plan = widget.initialPlan;
    _nameController = TextEditingController(text: plan?.name ?? '');
    _descriptionController = TextEditingController(text: plan?.description ?? '');
    _monthlyPriceController = TextEditingController(
      text: plan != null ? plan.monthlyPrice.toStringAsFixed(0) : '',
    );
    _yearlyPriceController = TextEditingController(
      text: plan?.yearlyPrice != null ? plan!.yearlyPrice!.toStringAsFixed(0) : '',
    );
    _currencyController = TextEditingController(text: plan?.currency ?? 'SAR');
    _badgeController = TextEditingController(text: plan?.badge ?? '');
    _accentColorController = TextEditingController(text: plan?.accentColor ?? '#7C3AED');
    _messagesLimitController = TextEditingController(
      text: plan?.metadata['messagesLimit']?.toString() ?? '',
    );
    _videoLimitController = TextEditingController(
      text: plan?.metadata['videoCallsLimit']?.toString() ?? '',
    );
    _isRecommended = plan?.isRecommended ?? false;
    _featureFields = [];
    if (plan?.features.isNotEmpty ?? false) {
      for (final feature in plan!.features) {
        _featureFields.add(_FeatureField.fromFeature(feature));
      }
    } else {
      _featureFields.add(_FeatureField.empty());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _monthlyPriceController.dispose();
    _yearlyPriceController.dispose();
    _currencyController.dispose();
    _badgeController.dispose();
    _accentColorController.dispose();
    _messagesLimitController.dispose();
    _videoLimitController.dispose();
    for (final field in _featureFields) {
      field.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    String tr(String key, {Map<String, String>? args}) =>
        languageProvider.t(key, args: args);

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Text(
                widget.initialPlan == null
                    ? tr('subscription_admin_modal_create_title')
                    : tr('subscription_admin_modal_edit_title'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: tr('subscription_admin_form_plan_name'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty
                        ? tr('subscription_admin_form_name_required')
                        : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: tr('subscription_admin_form_plan_description'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _monthlyPriceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: tr('subscription_admin_form_monthly_price'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return tr('subscription_admin_form_price_required');
                        }
                        return double.tryParse(value.trim()) == null
                            ? tr('subscription_admin_form_invalid_amount')
                            : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _yearlyPriceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: tr('subscription_admin_form_yearly_price_optional'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _currencyController,
                      decoration: InputDecoration(
                        labelText: tr('subscription_admin_form_currency'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _badgeController,
                      decoration: InputDecoration(
                        labelText: tr('subscription_admin_form_badge_optional'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _accentColorController,
                decoration: InputDecoration(
                  labelText: tr('subscription_admin_form_accent_color'),
                  hintText: '#7C3AED',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                value: _isRecommended,
                onChanged: (value) => setState(() => _isRecommended = value),
                title: Text(tr('subscription_admin_form_recommended_toggle')),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _messagesLimitController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: tr('subscription_admin_form_messages_limit'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _videoLimitController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: tr('subscription_admin_form_video_limit'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tr('subscription_admin_form_features'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  TextButton.icon(
                    onPressed: _addFeatureField,
                    icon: const Icon(Icons.add),
                    label: Text(tr('subscription_admin_form_add_feature')),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Column(
                children: _featureFields.asMap().entries.map((entry) {
                  final index = entry.key;
                  final field = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: field.labelController,
                          decoration: InputDecoration(
                            labelText: tr('subscription_admin_form_feature_label'),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: field.valueController,
                          decoration: InputDecoration(
                            labelText: tr('subscription_admin_form_feature_value'),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            onPressed: _featureFields.length == 1
                                ? null
                                : () {
                                    setState(() {
                                      _featureFields.removeAt(index);
                                    });
                                  },
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              CustomButton(
                text: _isSaving
                    ? tr('subscription_admin_form_saving')
                    : tr('subscription_admin_form_save'),
                onPressed: _isSaving ? null : _handleSubmit,
                fullWidth: true,
                size: ButtonSize.large,
                icon: Icons.save_alt,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addFeatureField() {
    setState(() {
      _featureFields.add(_FeatureField.empty());
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final features = <SubscriptionPlanFeature>[];
    for (var i = 0; i < _featureFields.length; i++) {
      final field = _featureFields[i];
      final label = field.labelController.text.trim();
      if (label.isEmpty) continue;
      features.add(
        field.toFeature().copyWith(order: i),
      );
    }

    final plan = SubscriptionPlan(
      id: widget.initialPlan?.id ?? _generatePlanId(_nameController.text.trim()),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      monthlyPrice: double.tryParse(_monthlyPriceController.text.trim()) ?? 0,
      yearlyPrice: _yearlyPriceController.text.trim().isEmpty
          ? null
          : double.tryParse(_yearlyPriceController.text.trim()),
      currency: _currencyController.text.trim().isEmpty
          ? 'SAR'
          : _currencyController.text.trim(),
      isRecommended: _isRecommended,
      badge: _badgeController.text.trim().isEmpty ? null : _badgeController.text.trim(),
      accentColor: _accentColorController.text.trim().isEmpty
          ? '#7C3AED'
          : _accentColorController.text.trim(),
      features: features,
      metadata: {
        if (_messagesLimitController.text.trim().isNotEmpty)
          'messagesLimit': int.tryParse(_messagesLimitController.text.trim()),
        if (_videoLimitController.text.trim().isNotEmpty)
          'videoCallsLimit': int.tryParse(_videoLimitController.text.trim()),
      }..removeWhere((key, value) => value == null),
    );

    final success = await widget.onSubmit(plan);

    if (mounted && !success) {
      setState(() => _isSaving = false);
    }
  }

  String _generatePlanId(String name) {
    final base = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    if (base.isEmpty) {
      return 'plan_${DateTime.now().millisecondsSinceEpoch}';
    }
    return base;
  }
}

class _FeatureField {
  final String id;
  final TextEditingController labelController;
  final TextEditingController valueController;

  _FeatureField({
    required this.id,
    required this.labelController,
    required this.valueController,
  });

  factory _FeatureField.empty() {
    return _FeatureField(
      id: 'feat_${DateTime.now().microsecondsSinceEpoch}',
      labelController: TextEditingController(),
      valueController: TextEditingController(),
    );
  }

  factory _FeatureField.fromFeature(SubscriptionPlanFeature feature) {
    return _FeatureField(
      id: feature.id,
      labelController: TextEditingController(text: feature.label),
      valueController: TextEditingController(text: feature.value ?? ''),
    );
  }

  SubscriptionPlanFeature toFeature() {
    return SubscriptionPlanFeature(
      id: id,
      label: labelController.text.trim(),
      value: valueController.text.trim().isEmpty ? null : valueController.text.trim(),
      order: 0,
    );
  }

  void dispose() {
    labelController.dispose();
    valueController.dispose();
  }
}


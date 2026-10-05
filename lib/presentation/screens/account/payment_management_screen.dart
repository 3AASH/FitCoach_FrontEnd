import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/demo_config.dart';
import '../../../core/constants/colors.dart';
import '../../../data/repositories/payment_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_card.dart';
import '../../../core/theme/app_palette.dart';
import '../../widgets/sheet_header.dart';

class PaymentManagementScreen extends StatefulWidget {
  const PaymentManagementScreen({super.key});

  @override
  State<PaymentManagementScreen> createState() =>
      _PaymentManagementScreenState();
}

class _PaymentManagementScreenState extends State<PaymentManagementScreen> {
  final PaymentRepository _paymentRepository = PaymentRepository();
  final List<_PaymentMethod> _methods = [
    const _PaymentMethod(
      id: 'visa',
      brand: 'Visa',
      last4: '8821',
      expiry: '08/27',
      holder: 'Layla Ibrahim',
      type: 'card',
    ),
    const _PaymentMethod(
      id: 'apple_pay',
      brand: 'Apple Pay',
      last4: 'â€”',
      expiry: '',
      holder: 'Layla iPhone',
      type: 'wallet',
    ),
  ];

  String _defaultMethodId = 'visa';
  bool _cancelling = false;
  bool _historyLoading = false;
  String? _historyError;
  List<Map<String, dynamic>> _paymentHistory = [];

  @override
  void initState() {
    super.initState();
    if (!DemoConfig.isDemo) {
      _loadPaymentHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.t('payment_management_title')),
      ),
      floatingActionButton: DemoConfig.isDemo
          ? FloatingActionButton.extended(
              onPressed: _showAddMethodSheet,
              icon: const Icon(Icons.add),
              label: Text(lang.t('payment_add_method')),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Text(
            lang.t('payment_management_subtitle'),
            style: TextStyle(color: context.palette.textSecondary),
          ),
          const SizedBox(height: 16),
          DemoConfig.isDemo
              ? _buildMethodsCard(lang)
              : _buildProductionMethodsCard(lang),
          const SizedBox(height: 16),
          _buildHistoryCard(lang),
          const SizedBox(height: 16),
          _buildRenewalCard(lang),
        ],
      ),
    );
  }

  Widget _buildMethodsCard(LanguageProvider lang) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang.t('payment_methods'),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ..._methods.map(
            (method) => Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    method.id == _defaultMethodId
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: method.id == _defaultMethodId
                        ? AppColors.primary
                        : context.palette.textSecondary,
                  ),
                  title: Text('${method.brand} â€¢â€¢â€¢â€¢ ${method.last4}'),
                  subtitle: Text(method.type == 'card'
                      ? 'Exp ${method.expiry}'
                      : method.holder),
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline,
                        color: context.palette.textSecondary),
                    tooltip: lang.t('delete'),
                    onPressed: () => _removeMethod(method.id),
                  ),
                  onTap: () => setState(() => _defaultMethodId = method.id),
                ),
                if (method != _methods.last) const Divider(height: 0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductionMethodsCard(LanguageProvider lang) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang.t('payment_methods_title'),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            lang.t('payment_methods_managed_externally'),
            style: TextStyle(fontSize: 12, color: context.palette.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(LanguageProvider lang) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                lang.t('payment_recent'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              if (!DemoConfig.isDemo)
                IconButton(
                  onPressed: _loadPaymentHistory,
                  tooltip: lang.t('refresh'),
                  icon: const Icon(Icons.refresh),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_historyLoading)
            const Center(child: CircularProgressIndicator())
          else if (_historyError != null)
            Text(
              _historyError!,
              style: const TextStyle(color: AppColors.error),
            )
          else if (_paymentHistory.isEmpty)
            Text(
              DemoConfig.isDemo
                  ? lang.t('payment_history_empty_demo')
                  : lang.t('payment_history_empty'),
              style: TextStyle(color: context.palette.textSecondary),
            )
          else
            ..._paymentHistory.take(5).map((payment) {
              final amount = payment['amount'];
              final currency =
                  (payment['currency'] ?? 'SAR').toString().toUpperCase();
              final status = (payment['status'] ?? '').toString();
              final tier = (payment['tier'] ?? '').toString();
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading:
                    const Icon(Icons.receipt_long, color: AppColors.primary),
                title: Text(
                  '$tier ${amount ?? '-'} $currency',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(status),
              );
            }),
        ],
      ),
    );
  }

  /// Renewal + cancellation.
  ///
  /// This replaces a switch that only ever called `setState` -- it never
  /// reached the backend, so a user who turned auto-pay off was still charged.
  /// There is no auto-renew endpoint to wire it to; `POST /payments/cancel`
  /// (already in [PaymentRepository]) is the real control, and until now
  /// nothing in the app called it, so a subscriber could not cancel in-app at
  /// all.
  Widget _buildRenewalCard(LanguageProvider lang) {
    final tier = context.watch<AuthProvider>().user?.subscriptionTier ??
        'Freemium';
    final hasPaidPlan = tier != 'Freemium';

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang.t('subscription_renewal_title'),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            lang.t('subscription_renewal_desc'),
            style: TextStyle(color: context.palette.textSecondary),
          ),
          if (hasPaidPlan) ...[
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: _cancelling ? null : _confirmCancelSubscription,
                icon: _cancelling
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.cancel_outlined,
                        color: context.palette.error),
                label: Text(
                  lang.t('subscription_cancel_action'),
                  style: TextStyle(color: context.palette.error),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmCancelSubscription() async {
    final lang = context.read<LanguageProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(lang.t('subscription_cancel_title')),
        content: Text(lang.t('subscription_cancel_prompt')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(lang.t('subscription_cancel_keep')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              lang.t('subscription_cancel_confirm'),
              style: TextStyle(color: context.palette.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _cancelling = true);
    try {
      await _paymentRepository.cancelSubscription();
      if (!mounted) return;
      await context.read<AuthProvider>().refreshUser();
      if (!mounted) return;
      _showSnack(lang.t('subscription_cancel_success'));
    } catch (_) {
      if (!mounted) return;
      _showSnack(lang.t('subscription_cancel_failed'));
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  void _removeMethod(String id) {
    setState(() {
      _methods.removeWhere((method) => method.id == id);
      if (_defaultMethodId == id && _methods.isNotEmpty) {
        _defaultMethodId = _methods.first.id;
      }
    });
  }

  void _showAddMethodSheet() {
    final lang = context.read<LanguageProvider>();
    if (!DemoConfig.isDemo) {
      _showSnack(lang.t('payment_add_demo_only'));
      return;
    }
    final cardNumberController = TextEditingController();
    final holderController = TextEditingController();
    final expiryController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SheetHeader(title: lang.t('payment_add_method')),
            const SizedBox(height: 16),
            TextField(
              controller: cardNumberController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: lang.t('auth_card_number'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: holderController,
              decoration: InputDecoration(
                labelText: lang.t('auth_full_name'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: expiryController,
              keyboardType: TextInputType.datetime,
              decoration: const InputDecoration(
                labelText: 'MM/YY',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: lang.t('save'),
              onPressed: () {
                setState(() {
                  _methods.add(
                    _PaymentMethod(
                      id: 'card_${DateTime.now().millisecondsSinceEpoch}',
                      brand: 'Visa',
                      last4: cardNumberController.text
                          .substring(cardNumberController.text.length - 4),
                      expiry: expiryController.text,
                      holder: holderController.text,
                      type: 'card',
                    ),
                  );
                });
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _loadPaymentHistory() async {
    setState(() {
      _historyLoading = true;
      _historyError = null;
    });

    try {
      final history = await _paymentRepository.getPaymentHistory();
      if (!mounted) return;
      setState(() {
        _paymentHistory = history;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _historyError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _historyLoading = false;
        });
      }
    }
  }
}

class _PaymentMethod {
  final String id;
  final String brand;
  final String last4;
  final String expiry;
  final String holder;
  final String type;

  const _PaymentMethod({
    required this.id,
    required this.brand,
    required this.last4,
    required this.expiry,
    required this.holder,
    required this.type,
  });
}


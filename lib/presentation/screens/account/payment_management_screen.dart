import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/demo_config.dart';
import '../../../core/constants/colors.dart';
import '../../../data/repositories/payment_repository.dart';
import '../../providers/language_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_card.dart';

class PaymentManagementScreen extends StatefulWidget {
  const PaymentManagementScreen({super.key});

  @override
  State<PaymentManagementScreen> createState() => _PaymentManagementScreenState();
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
      last4: '—',
      expiry: '',
      holder: 'Layla iPhone',
      type: 'wallet',
    ),
  ];

  String _defaultMethodId = 'visa';
  bool _autoPayEnabled = true;
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
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          DemoConfig.isDemo ? _buildMethodsCard(lang) : _buildProductionMethodsCard(),
          const SizedBox(height: 16),
          _buildHistoryCard(lang),
          const SizedBox(height: 16),
          _buildBillingCard(lang),
          const SizedBox(height: 16),
          CustomCard(
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(lang.t('payment_auto_pay')),
              subtitle: Text(lang.t('payment_auto_pay_desc')),
              value: _autoPayEnabled,
              onChanged: (value) => setState(() => _autoPayEnabled = value),
            ),
          ),
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
                RadioListTile<String>(
                  value: method.id,
                  groupValue: _defaultMethodId,
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.primary,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _defaultMethodId = value);
                  },
                  title: Text('${method.brand} •••• ${method.last4}'),
                  subtitle: Text(method.type == 'card' ? 'Exp ${method.expiry}' : method.holder),
                  secondary: IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.textSecondary),
                    onPressed: () => _removeMethod(method.id),
                  ),
                ),
                if (method != _methods.last) const Divider(height: 0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductionMethodsCard() {
    return const CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Methods',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 8),
          Text(
            'Payment methods are managed securely by your payment provider in production mode.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
                'Recent Payments',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              if (!DemoConfig.isDemo)
                IconButton(
                  onPressed: _loadPaymentHistory,
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
                  ? 'No demo transactions available.'
                  : 'No payment history found yet.',
              style: const TextStyle(color: AppColors.textSecondary),
            )
          else
            ..._paymentHistory.take(5).map((payment) {
              final amount = payment['amount'];
              final currency = (payment['currency'] ?? 'SAR').toString().toUpperCase();
              final status = (payment['status'] ?? '').toString();
              final tier = (payment['tier'] ?? '').toString();
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.receipt_long, color: AppColors.primary),
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

  Widget _buildBillingCard(LanguageProvider lang) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang.t('payment_billing_info'),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.home_outlined, color: AppColors.primary),
            title: Text(lang.t('payment_primary_address')),
            subtitle: const Text('Prince Turki St, Riyadh 12345'),
            trailing: TextButton(
              onPressed: () => _showSnack(lang.t('save')),
              child: Text(lang.t('edit')),
            ),
          ),
          const Divider(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.work_outline, color: AppColors.secondaryForeground),
            title: Text(lang.t('payment_secondary_address')),
            subtitle: const Text('Remote Office Hub, Dammam 12211'),
            trailing: TextButton(
              onPressed: () => _showSnack(lang.t('save')),
              child: Text(lang.t('edit')),
            ),
          ),
        ],
      ),
    );
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
    if (!DemoConfig.isDemo) {
      _showSnack('Adding methods in-app is only available in demo mode.');
      return;
    }
    final lang = context.read<LanguageProvider>();
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
            Text(
              lang.t('payment_add_method'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: cardNumberController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: lang.t('auth_card_number'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: holderController,
              decoration: InputDecoration(
                labelText: lang.t('auth_full_name'),
                border: const OutlineInputBorder(),
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
                      last4: cardNumberController.text.substring(cardNumberController.text.length - 4),
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

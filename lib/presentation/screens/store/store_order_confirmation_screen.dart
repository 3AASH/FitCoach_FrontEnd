import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/colors.dart';
import '../../providers/language_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_card.dart';
import 'store_checkout_screen.dart';

class StoreOrderConfirmationScreen extends StatelessWidget {
  final StoreCheckoutResult order;
  final VoidCallback? onViewOrder;
  final VoidCallback? onTrackOrder;
  final VoidCallback? onContinueShopping;

  const StoreOrderConfirmationScreen({
    super.key,
    required this.order,
    this.onViewOrder,
    this.onTrackOrder,
    this.onContinueShopping,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final total = (order['total'] as num?)?.toDouble() ?? 0;
    final date = _resolveDate(order['date']);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE6F4FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: AppColors.primary,
                        size: 42,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      lang.t('order_confirmation_title'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      lang.t(
                        'order_confirmation_subtitle',
                        args: {'email': (order['shippingInfo']?['email'] ?? 'you') as String},
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    _buildSummaryCard(lang, total, date),
                    const SizedBox(height: 24),
                    _buildMiniList(lang),
                    const SizedBox(height: 32),
                    CustomButton(
                      text: lang.t('order_view_details'),
                      onPressed: onViewOrder ?? () {},
                      size: ButtonSize.large,
                      fullWidth: true,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: onTrackOrder ?? () {},
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppColors.primary),
                      ),
                      child: Text(
                        lang.t('order_track_delivery'),
                        style: const TextStyle(color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        onContinueShopping?.call();
                        Navigator.of(context).maybePop();
                      },
                      child: Text(lang.t('store_order_continue_shopping')),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(LanguageProvider lang, double total, DateTime? date) {
    return CustomCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                lang.t('total'),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              Text(
                '${total.toStringAsFixed(2)} ${lang.t('currency_sar')}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lang.t('store_order_status'), style: const TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text(
                      lang.t('store_status_processing'),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              if (date != null)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(lang.t('date'), style: const TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text(DateFormat('MMM d, HH:mm').format(date)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniList(LanguageProvider lang) {
    final shippingInfo = (order['shippingInfo'] as Map<String, dynamic>?) ?? const {};
    final address = shippingInfo['address'] ?? '-';
    final paymentMethod = order['paymentMethod']?.toString().toUpperCase() ?? 'CARD';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MiniInfoRow(
          title: lang.t('store_order_shipping_to'),
          value: address,
          icon: Icons.location_pin,
        ),
        const SizedBox(height: 12),
        _MiniInfoRow(
          title: lang.t('store_order_payment_method'),
          value: paymentMethod,
          icon: Icons.credit_card,
        ),
        const SizedBox(height: 12),
        _MiniInfoRow(
          title: lang.t('store_order_items'),
          value: '${(order['items'] as List?)?.length ?? 0} ${lang.t('items')}',
          icon: Icons.inventory_2_outlined,
        ),
      ],
    );
  }

  DateTime? _resolveDate(dynamic dateValue) {
    if (dateValue is DateTime) return dateValue;
    if (dateValue is String && dateValue.isNotEmpty) {
      return DateTime.tryParse(dateValue);
    }
    return null;
  }
}

class _MiniInfoRow extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MiniInfoRow({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

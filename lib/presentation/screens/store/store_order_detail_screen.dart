import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/colors.dart';
import '../../providers/language_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_card.dart';
import 'store_checkout_screen.dart';

class StoreOrderDetailScreen extends StatelessWidget {
  final StoreCheckoutResult order;

  const StoreOrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final isArabic = lang.isArabic;
    final status = (order['status'] as String?)?.toLowerCase() ?? 'processing';
    final date = _resolveDate(order['date']);
    final items = (order['items'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final shippingInfo = (order['shippingInfo'] as Map<String, dynamic>?) ?? const {};

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.t('store_order_details_title')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CustomCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order['id']?.toString() ?? 'ORD-XXXX',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildStatusChip(status, lang),
                    const SizedBox(width: 12),
                    if (date != null)
                      Text(
                        DateFormat('MMM d, HH:mm').format(date),
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildProgressTimeline(status, lang),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            lang.t('store_order_items'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...items.map((item) => _OrderItemTile(item: item, isArabic: isArabic, lang: lang)),
          const SizedBox(height: 16),
          _buildSummaryCard(lang),
          const SizedBox(height: 16),
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang.t('store_order_shipping_to'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  shippingInfo['address'] ?? '-',
                  style: const TextStyle(height: 1.4),
                ),
                if ((shippingInfo['notes'] as String?)?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Text(
                    shippingInfo['notes'] as String,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
                const Divider(height: 24),
                Text(
                  lang.t('store_order_payment_method'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(order['paymentMethod']?.toString().toUpperCase() ?? 'CARD'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: lang.t('store_order_track_package'),
            onPressed: () => _showSnack(context, lang.t('store_order_track_package')), // Placeholder action
            size: ButtonSize.large,
            fullWidth: true,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => _showSnack(context, lang.t('store_order_contact_support')),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: AppColors.primary),
            ),
            child: Text(
              lang.t('store_order_contact_support'),
              style: const TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(LanguageProvider lang) {
    final subtotal = (order['subtotal'] as num?)?.toDouble();
    final shipping = (order['shipping'] as num?)?.toDouble();
    final tax = (order['tax'] as num?)?.toDouble();
    final total = (order['total'] as num?)?.toDouble() ?? 0;

    return CustomCard(
      child: Column(
        children: [
          if (subtotal != null)
            _SummaryRow(
              label: lang.t('subtotal'),
              value: '${subtotal.toStringAsFixed(2)} ${lang.t('currency_sar')}',
            ),
          if (shipping != null)
            _SummaryRow(
              label: lang.t('shipping_fee'),
              value: shipping == 0 ? lang.t('free') : '${shipping.toStringAsFixed(2)} ${lang.t('currency_sar')}',
            ),
          if (tax != null)
            _SummaryRow(
              label: lang.t('tax_vat'),
              value: '${tax.toStringAsFixed(2)} ${lang.t('currency_sar')}',
            ),
          const Divider(height: 20),
          _SummaryRow(
            label: lang.t('total'),
            value: '${total.toStringAsFixed(2)} ${lang.t('currency_sar')}',
            emphasized: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, LanguageProvider lang) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        _statusLabel(status, lang),
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }

  Widget _buildProgressTimeline(String status, LanguageProvider lang) {
    final steps = [
      'processing',
      'confirmed',
      'shipped',
      'delivered',
    ];
    final currentIndex = steps.indexOf(status);

    return Column(
      children: steps.map((step) {
        final stepIndex = steps.indexOf(step);
        final isCompleted = currentIndex >= stepIndex;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isCompleted ? AppColors.primary : AppColors.border,
                    shape: BoxShape.circle,
                  ),
                ),
                if (step != steps.last)
                  Container(
                    width: 2,
                    height: 28,
                    color: isCompleted ? AppColors.primary : AppColors.border,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  _statusLabel(step, lang),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isCompleted ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'delivered':
        return AppColors.success;
      case 'shipped':
        return AppColors.primary;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.accent;
    }
  }

  String _statusLabel(String status, LanguageProvider lang) {
    switch (status) {
      case 'confirmed':
        return lang.t('store_status_confirmed');
      case 'shipped':
        return lang.t('store_status_shipped');
      case 'delivered':
        return lang.t('store_status_delivered');
      case 'cancelled':
        return lang.t('store_status_cancelled');
      default:
        return lang.t('store_status_processing');
    }
  }

  DateTime? _resolveDate(dynamic dateValue) {
    if (dateValue is DateTime) return dateValue;
    if (dateValue is String && dateValue.isNotEmpty) {
      return DateTime.tryParse(dateValue);
    }
    return null;
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasized;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
                color: emphasized ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderItemTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isArabic;
  final LanguageProvider lang;

  const _OrderItemTile({
    required this.item,
    required this.isArabic,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    final name = isArabic ? (item['nameAr'] ?? item['nameEn']) : (item['nameEn'] ?? item['nameAr']);
    final price = (item['price'] as num?)?.toDouble() ?? 0;
    final quantity = item['quantity'] as int? ?? 1;

    return CustomCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              (item['image'] as String?) ?? '',
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 56,
                height: 56,
                color: AppColors.surface,
                child: const Icon(Icons.image_not_supported, color: AppColors.textDisabled),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name?.toString() ?? '-',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '${lang.t('quantity')}: $quantity',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${(price * quantity).toStringAsFixed(2)} ${lang.t('currency_sar')}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

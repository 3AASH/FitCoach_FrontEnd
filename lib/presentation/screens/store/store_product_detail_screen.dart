import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/colors.dart';
import '../../providers/language_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_card.dart';

class StoreProductDetailData {
  final String id;
  final String title;
  final String? subtitle;
  final String description;
  final String imageUrl;
  final double price;
  final double? originalPrice;
  final double rating;
  final int reviews;
  final bool inStock;
  final List<String> highlights;
  final List<String> badges;
  final Map<String, String>? specifications;
  final Map<String, String>? nutritionFacts;

  const StoreProductDetailData({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.rating,
    required this.reviews,
    required this.inStock,
    this.subtitle,
    this.originalPrice,
    this.highlights = const [],
    this.badges = const [],
    this.specifications,
    this.nutritionFacts,
  });
}

class StoreProductDetailScreen extends StatelessWidget {
  final StoreProductDetailData data;
  final VoidCallback? onAddToCart;

  const StoreProductDetailScreen({
    super.key,
    required this.data,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final isArabic = lang.isArabic;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, isArabic, lang),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: Image.network(
                          data.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.surface,
                            child: const Icon(
                              Icons.image_not_supported,
                              color: AppColors.textDisabled,
                              size: 48,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data.title,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (data.subtitle != null && data.subtitle!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    data.subtitle!,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: data.inStock
                                ? AppColors.success.withValues(alpha: 0.14)
                                : AppColors.error.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            data.inStock ? lang.t('in_stock') : lang.t('out_of_stock'),
                            style: TextStyle(
                              color: data.inStock ? AppColors.success : AppColors.error,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          '${data.price.toStringAsFixed(2)} ${lang.t('currency_sar')}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        if (data.originalPrice != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              data.originalPrice!.toStringAsFixed(2),
                              style: const TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        const Spacer(),
                        const Icon(Icons.star, color: AppColors.warning, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          data.rating.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          lang.t('reviews_count', args: {'count': data.reviews.toString()}),
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                    if (data.badges.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: data.badges
                            .map(
                              (badge) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: AppColors.surface,
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  badge,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text(
                      lang.t('description'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      data.description,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    if (data.highlights.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        lang.t('store_product_highlights'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: data.highlights
                            .map(
                              (highlight) => Chip(
                                label: Text(highlight),
                                backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                                labelStyle: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    if (data.specifications != null && data.specifications!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        lang.t('store_product_specs'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      CustomCard(
                        child: Column(
                          children: data.specifications!.entries
                              .map(
                                (entry) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          entry.key,
                                          style: const TextStyle(color: AppColors.textSecondary),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          entry.value,
                                          textAlign: TextAlign.end,
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                    if (data.nutritionFacts != null && data.nutritionFacts!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        lang.t('store_product_nutrition'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      CustomCard(
                        child: Column(
                          children: data.nutritionFacts!.entries
                              .map(
                                (entry) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    children: [
                                      Expanded(child: Text(entry.key)),
                                      Text(
                                        entry.value,
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (onAddToCart != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: CustomButton(
                  text: lang.t('add_to_cart'),
                  onPressed: data.inStock ? onAddToCart : null,
                  size: ButtonSize.large,
                  fullWidth: true,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isArabic, LanguageProvider lang) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(
              isArabic ? Icons.arrow_forward : Icons.arrow_back,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              lang.t('store_product_details'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

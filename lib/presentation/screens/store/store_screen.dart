import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/demo_config.dart';
import '../../../core/constants/colors.dart';
import '../../../data/models/product.dart';
import '../../../data/models/order.dart';
import '../../providers/language_provider.dart';
import '../../providers/store_provider.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';
import 'store_intro_screen.dart';
import 'store_checkout_screen.dart';

class StoreScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const StoreScreen({super.key, this.onBack});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  String _selectedCategory = 'all';
  String _searchQuery = '';
  bool _showIntro = false;
  bool _introLoaded = false;
  TabController? _tabController;

  final List<Map<String, dynamic>> _cartItems = [];
  final List<String> _categories = [
    'all',
    'Protein',
    'Pre-Workout',
    'Recovery',
    'Vitamins',
    'Fat Burners',
  ];

  final List<Map<String, dynamic>> _products = [
    {
      'id': '1',
      'nameEn': 'Whey Protein Isolate',
      'nameAr': 'عزل بروتين مصل اللبن',
      'brand': 'FitNutrition',
      'descriptionEn': 'Premium whey protein isolate for muscle building.',
      'descriptionAr': 'عزل بروتين مصل اللبن عالي الجودة لبناء العضلات.',
      'price': 59.99,
      'originalPrice': 69.99,
      'discount': 15,
      'category': 'Protein',
      'image': 'https://images.unsplash.com/photo-1579722821273-0f6c7d44362f?w=400',
      'rating': 4.8,
      'reviews': 1247,
      'inStock': true,
      'isPopular': true,
    },
    {
      'id': '2',
      'nameEn': 'Creatine Monohydrate',
      'nameAr': 'كرياتين مونوهيدرات',
      'brand': 'PowerSupps',
      'descriptionEn': 'Pure creatine for increased strength.',
      'descriptionAr': 'كرياتين نقي لزيادة القوة.',
      'price': 29.99,
      'category': 'Pre-Workout',
      'image': 'https://images.unsplash.com/photo-1593095948071-474c5cc2989d?w=400',
      'rating': 4.9,
      'reviews': 892,
      'inStock': true,
    },
    {
      'id': '3',
      'nameEn': 'BCAA Recovery',
      'nameAr': 'بي سي إيه إيه للتعافي',
      'brand': 'RecoverMax',
      'descriptionEn': 'BCAA blend for recovery.',
      'descriptionAr': 'مزيج بي سي إيه إيه لدعم التعافي.',
      'price': 39.99,
      'category': 'Recovery',
      'image': 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=400',
      'rating': 4.6,
      'reviews': 654,
      'inStock': true,
    },
    {
      'id': '4',
      'nameEn': 'Pre-Workout Boost',
      'nameAr': 'دفعة ما قبل التمرين',
      'brand': 'EnergyCore',
      'descriptionEn': 'High-energy pre-workout formula.',
      'descriptionAr': 'تركيبة عالية الطاقة لما قبل التمرين.',
      'price': 44.99,
      'originalPrice': 49.99,
      'discount': 10,
      'category': 'Pre-Workout',
      'image': 'https://images.unsplash.com/photo-1556909212-d5b604d0c90d?w=400',
      'rating': 4.7,
      'reviews': 423,
      'inStock': false,
    },
    {
      'id': '5',
      'nameEn': 'Multivitamin Complex',
      'nameAr': 'مركب متعدد الفيتامينات',
      'brand': 'VitalHealth',
      'descriptionEn': 'Daily vitamin and mineral support.',
      'descriptionAr': 'دعم يومي للفيتامينات والمعادن.',
      'price': 24.99,
      'category': 'Vitamins',
      'image': 'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=400',
      'rating': 4.5,
      'reviews': 332,
      'inStock': true,
    },
    {
      'id': '6',
      'nameEn': 'Fat Burner Pro',
      'nameAr': 'حارق الدهون برو',
      'brand': 'LeanLife',
      'descriptionEn': 'Thermogenic formula for weight management.',
      'descriptionAr': 'تركيبة حرارية لإدارة الوزن.',
      'price': 49.99,
      'category': 'Fat Burners',
      'image': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400',
      'rating': 4.3,
      'reviews': 267,
      'inStock': true,
    },
  ];

  final List<Map<String, dynamic>> _orders = [
    {
      'id': 'ORD-2024-001',
      'status': 'delivered',
      'total': 89.98,
      'date': DateTime.now().subtract(const Duration(days: 5)),
    },
    {
      'id': 'ORD-2024-002',
      'status': 'shipped',
      'total': 39.99,
      'date': DateTime.now().subtract(const Duration(days: 2)),
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadIntroFlag();

    if (!DemoConfig.isDemo) {
      Future.microtask(() {
        final storeProvider = context.read<StoreProvider>();
        storeProvider.loadCategories();
        storeProvider.loadProducts();
        storeProvider.loadOrders();
      });
    }
  }

  @override
  void dispose() {
    _tabController = null;
    super.dispose();
  }

  Future<void> _handleBack() async {
    // If a dialog / bottom sheet is open, close it first.
    final poppedOverlay = await Navigator.of(context).maybePop();
    if (poppedOverlay) return;

    if (!mounted) return;

    // Otherwise, defer to the host app navigation (App-level screen switch).
    if (widget.onBack != null) {
      widget.onBack!();
    }
  }

  Future<void> _loadIntroFlag() async {
    final prefs = await SharedPreferences.getInstance();
    final seenIntro = prefs.getBool('store_intro_seen') ?? false;
    if (mounted) {
      setState(() {
        _showIntro = !seenIntro;
        _introLoaded = true;
      });
    }
  }

  Future<void> _completeIntro() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('store_intro_seen', true);
    if (mounted) {
      setState(() {
        _showIntro = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final isArabic = languageProvider.isArabic;

    if (!DemoConfig.isDemo) {
      final storeProvider = context.watch<StoreProvider>();

      if (!_introLoaded) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      if (_showIntro) {
        return StoreIntroScreen(
          onGetStarted: _completeIntro,
          onBack: _handleBack,
        );
      }

      return _buildBackendStore(languageProvider, storeProvider, isArabic);
    }

    if (!_introLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_showIntro) {
      return StoreIntroScreen(
        onGetStarted: _completeIntro,
        onBack: _handleBack,
      );
    }

    final filteredProducts = _products.where((product) {
      final matchesSearch = product['nameEn']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          product['brand'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'all' || product['category'] == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    final cartItemCount = _cartItems.fold<int>(
      0,
      (sum, item) => sum + (item['quantity'] as int),
    );

    return DefaultTabController(
      length: 3,
      child: Builder(
        builder: (tabContext) {
          _tabController = DefaultTabController.of(tabContext);
          return Scaffold(
            body: Stack(
              children: [
                Positioned.fill(
                  child: Image.network(
                    'https://images.unsplash.com/photo-1736236560164-bc741c70bca5?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=1080',
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned.fill(
                  child: Container(color: Colors.black.withValues(alpha: 0.15)),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      _buildHeader(languageProvider, cartItemCount, tabContext),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TabBar(
                          labelColor: AppColors.primary,
                          unselectedLabelColor: AppColors.textSecondary,
                          indicatorColor: AppColors.primary,
                          tabs: [
                            Tab(text: languageProvider.t('store_products')),
                            Tab(text: languageProvider.t('store_cart')),
                            Tab(text: languageProvider.t('store_orders')),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildProductsTab(filteredProducts, languageProvider, isArabic),
                            _buildCartTab(languageProvider, isArabic),
                            _buildOrdersTab(languageProvider),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBackendStore(
    LanguageProvider lang,
    StoreProvider storeProvider,
    bool isArabic,
  ) {
    final categories = <String>['all', ...storeProvider.categories];

    List<Product> products = storeProvider.products;
    if (_selectedCategory != 'all') {
      products = products.where((p) => p.category == _selectedCategory).toList();
    }
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      products = products.where((p) {
        return p.name.toLowerCase().contains(q) ||
            p.nameEn.toLowerCase().contains(q) ||
            p.nameAr.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q);
      }).toList();
    }

    final cartItemCount = storeProvider.cartItemCount;

    return DefaultTabController(
      length: 3,
      child: Builder(
        builder: (tabContext) {
          _tabController = DefaultTabController.of(tabContext);
          return Scaffold(
            body: Stack(
              children: [
                Positioned.fill(
                  child: Image.network(
                    'https://images.unsplash.com/photo-1736236560164-bc741c70bca5?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=1080',
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned.fill(
                  child: Container(color: Colors.black.withValues(alpha: 0.15)),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      _buildHeader(lang, cartItemCount, tabContext),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TabBar(
                          labelColor: AppColors.primary,
                          unselectedLabelColor: AppColors.textSecondary,
                          indicatorColor: AppColors.primary,
                          tabs: [
                            Tab(text: lang.t('store_products')),
                            Tab(text: lang.t('store_cart')),
                            Tab(text: lang.t('store_orders')),
                          ],
                        ),
                      ),
                      if (storeProvider.isLoading && storeProvider.products.isEmpty)
                        const LinearProgressIndicator(minHeight: 2),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildBackendProductsTab(products, categories, storeProvider, lang, isArabic),
                            _buildBackendCartTab(storeProvider, lang, isArabic),
                            _buildBackendOrdersTab(storeProvider, lang),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBackendProductsTab(
    List<Product> products,
    List<String> categories,
    StoreProvider storeProvider,
    LanguageProvider lang,
    bool isArabic,
  ) {
    return Column(
      children: [
        _buildBackendCategoryFilters(categories, storeProvider, lang),
        Expanded(
          child: products.isEmpty
              ? _buildEmptyState(lang, isArabic, messageKey: 'store_no_products')
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.68,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return _buildBackendProductCard(
                      products[index],
                      storeProvider,
                      lang,
                      isArabic,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildBackendCategoryFilters(
    List<String> categories,
    StoreProvider storeProvider,
    LanguageProvider lang,
  ) {
    return Container(
      height: 60,
      color: AppColors.surface,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_categoryLabel(category, lang)),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedCategory = category;
                });
                // Optional server-side filtering (safe even if server ignores).
                storeProvider.loadProducts(category: category);
              },
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              checkmarkColor: AppColors.primary,
            ),
          );
        },
      ),
    );
  }

  Widget _buildBackendProductCard(
    Product product,
    StoreProvider storeProvider,
    LanguageProvider lang,
    bool isArabic,
  ) {
    final inStock = product.inStock;
    final imageUrl = product.mainImage ?? (product.images?.isNotEmpty == true ? product.images!.first : null);

    return CustomCard(
      padding: EdgeInsets.zero,
      onTap: () => _showBackendProductDetail(product, lang, isArabic, storeProvider),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: imageUrl == null
                    ? Container(
                        height: 140,
                        width: double.infinity,
                        color: AppColors.surface,
                        child: const Icon(Icons.image_not_supported, color: AppColors.textDisabled),
                      )
                    : Image.network(
                        imageUrl,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
              ),
              if (product.hasDiscount)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '-${product.discountPercentage!.round()}%',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
              if (product.isFeatured)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      lang.t('store_popular'),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
              if (!inStock)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: Center(
                      child: Text(
                        lang.t('out_of_stock'),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.category,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isArabic ? product.nameAr : product.nameEn,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, color: AppColors.warning, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${(product.rating ?? 0).toStringAsFixed(1)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${lang.t('reviews_count', args: {'count': '${product.reviewCount}'})}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textDisabled),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${product.finalPrice.toStringAsFixed(2)} ${lang.t('currency_sar')}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_shopping_cart, size: 20),
                        onPressed: inStock
                            ? () async {
                                final ok = await storeProvider.addToCart(product, 1);
                                if (!mounted) return;
                                if (ok) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(lang.t('store_added_to_cart')),
                                      backgroundColor: AppColors.success,
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(storeProvider.error ?? lang.t('error_generic')),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              }
                            : null,
                        color: AppColors.primary,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBackendProductDetail(
    Product product,
    LanguageProvider lang,
    bool isArabic,
    StoreProvider storeProvider,
  ) {
    final imageUrl = product.mainImage ?? (product.images?.isNotEmpty == true ? product.images!.first : null);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imageUrl == null
                      ? Container(
                          height: 250,
                          width: double.infinity,
                          color: AppColors.surface,
                          child: const Icon(Icons.image_not_supported, color: AppColors.textDisabled),
                        )
                      : Image.network(
                          imageUrl,
                          height: 250,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                ),
                const SizedBox(height: 24),
                Text(
                  isArabic ? product.nameAr : product.nameEn,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: AppColors.warning, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '${(product.rating ?? 0).toStringAsFixed(1)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${lang.t('reviews_count', args: {'count': '${product.reviewCount}'})}',
                      style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '${product.finalPrice.toStringAsFixed(2)} ${lang.t('currency_sar')}',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const SizedBox(height: 24),
                Text(
                  lang.t('description'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  isArabic
                      ? (product.descriptionAr ?? product.description ?? '')
                      : (product.descriptionEn ?? product.description ?? ''),
                  style: const TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: lang.t('add_to_cart'),
                    onPressed: product.inStock
                        ? () async {
                            final ok = await storeProvider.addToCart(product, 1);
                            if (!mounted) return;
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(ok ? lang.t('store_added_to_cart') : (storeProvider.error ?? lang.t('error_generic'))),
                                backgroundColor: ok ? AppColors.success : AppColors.error,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackendCartTab(StoreProvider storeProvider, LanguageProvider lang, bool isArabic) {
    final cartItems = storeProvider.cart.values.toList();
    if (cartItems.isEmpty) {
      return _buildEmptyState(lang, isArabic, messageKey: 'cart_empty');
    }

    final total = storeProvider.cartSubtotal;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...cartItems.map((item) {
          final product = item.product;
          final imageUrl = product.mainImage ?? (product.images?.isNotEmpty == true ? product.images!.first : null);
          return CustomCard(
            margin: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imageUrl == null
                      ? Container(
                          width: 60,
                          height: 60,
                          color: AppColors.surface,
                          child: const Icon(Icons.image_not_supported, color: AppColors.textDisabled),
                        )
                      : Image.network(
                          imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isArabic ? product.nameAr : product.nameEn),
                      const SizedBox(height: 4),
                      Text(
                        '${product.finalPrice.toStringAsFixed(2)} ${lang.t('currency_sar')}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () => storeProvider.updateCartQuantity(product.id, item.quantity - 1),
                    ),
                    Text('${item.quantity}'),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => storeProvider.updateCartQuantity(product.id, item.quantity + 1),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(lang.t('total'), style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
              '${total.toStringAsFixed(2)} ${lang.t('currency_sar')}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CustomButton(
          text: lang.t('checkout'),
          onPressed: () => _checkoutBackend(storeProvider, lang, isArabic),
          fullWidth: true,
          size: ButtonSize.large,
        ),
      ],
    );
  }

  Widget _buildBackendOrdersTab(StoreProvider storeProvider, LanguageProvider lang) {
    final orders = storeProvider.orders;
    if (storeProvider.isLoading && orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (orders.isEmpty) {
      return _buildEmptyState(lang, lang.isArabic, messageKey: 'store_no_orders');
    }

    Map<String, dynamic> toUiOrder(Order order) {
      return {
        'id': order.orderNumber.isNotEmpty ? order.orderNumber : order.id,
        'status': order.status,
        'total': order.total,
        'date': order.createdAt,
        'subtotal': order.subtotal,
        'shipping': order.shippingCost,
        'tax': order.tax,
        'items': order.items
            .map((oi) => {
                  'id': oi.productId,
                  'nameEn': oi.productNameEn ?? oi.productName,
                  'nameAr': oi.productNameAr ?? oi.productName,
                  'image': oi.productImage,
                  'price': oi.finalPrice,
                  'quantity': oi.quantity,
                })
            .toList(),
      };
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = toUiOrder(orders[index]);
        return CustomCard(
          margin: const EdgeInsets.only(bottom: 12),
          onTap: () => _showOrderDetails(order, lang),
          child: Row(
            children: [
              Icon(_statusIcon(order['status']), color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order['id'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      _statusLabel(order['status'], lang),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Text(
                '${(order['total'] as num).toDouble().toStringAsFixed(2)} ${lang.t('currency_sar')}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      },
    );
  }

  void _checkoutBackend(StoreProvider storeProvider, LanguageProvider lang, bool isArabic) {
    final cartItems = storeProvider.cart.values.map((ci) {
      final p = ci.product;
      final imageUrl = p.mainImage ?? (p.images?.isNotEmpty == true ? p.images!.first : null);
      return <String, dynamic>{
        'id': p.id,
        'nameEn': p.nameEn,
        'nameAr': p.nameAr,
        'price': p.finalPrice,
        'quantity': ci.quantity,
        'image': imageUrl,
      };
    }).toList();

    Navigator.of(context)
        .push<StoreCheckoutResult>(
          MaterialPageRoute(
            builder: (_) => StoreCheckoutScreen(
              cartItems: cartItems,
            ),
          ),
        )
        .then((result) async {
      if (!mounted || result == null) return;

      // Refresh orders after successful placement.
      await storeProvider.loadOrders();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang.t('order_success_toast')),
          backgroundColor: AppColors.success,
        ),
      );

      final controller = _tabController ?? DefaultTabController.maybeOf(context);
      controller?.animateTo(2);
    });
  }

  Widget _buildHeader(LanguageProvider lang, int cartItemCount, BuildContext tabContext) {
    final isRTL = Directionality.of(tabContext) == TextDirection.rtl;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFB45309)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(isRTL ? Icons.arrow_forward : Icons.arrow_back, color: Colors.white),
                onPressed: _handleBack,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang.t('store_title'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      lang.t('store_subtitle'),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart, color: Colors.white),
                    onPressed: () {
                      final controller = _tabController ?? DefaultTabController.maybeOf(tabContext);
                      controller?.animateTo(1);
                    },
                  ),
                  if (cartItemCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Text(
                          '$cartItemCount',
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: lang.t('store_search_placeholder'),
              prefixIcon: const Icon(Icons.search, color: Colors.white),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.15),
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTab(
    List<Map<String, dynamic>> products,
    LanguageProvider lang,
    bool isArabic,
  ) {
    return Column(
      children: [
        _buildCategoryFilters(lang, isArabic),
        Expanded(
          child: products.isEmpty
              ? _buildEmptyState(lang, isArabic, messageKey: 'store_no_products')
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.68,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return _buildProductCard(
                      products[index],
                      lang,
                      isArabic,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCartTab(LanguageProvider lang, bool isArabic) {
    if (_cartItems.isEmpty) {
      return _buildEmptyState(lang, isArabic, messageKey: 'cart_empty');
    }
    final total = _cartItems.fold<double>(
      0,
      (sum, item) => sum + (item['price'] as double) * (item['quantity'] as int),
    );
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ..._cartItems.map((item) {
          return CustomCard(
            margin: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item['image'],
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isArabic ? item['nameAr'] : item['nameEn']),
                      const SizedBox(height: 4),
                      Text(
                        '${item['price']} ${lang.t('currency_sar')}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () => _updateQuantity(item['id'], item['quantity'] - 1),
                    ),
                    Text('${item['quantity']}'),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => _updateQuantity(item['id'], item['quantity'] + 1),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              lang.t('total'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '${total.toStringAsFixed(2)} ${lang.t('currency_sar')}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CustomButton(
          text: lang.t('checkout'),
          onPressed: () => _checkout(lang, isArabic),
          fullWidth: true,
          size: ButtonSize.large,
        ),
      ],
    );
  }

  Widget _buildOrdersTab(LanguageProvider lang) {
    if (_orders.isEmpty) {
      return _buildEmptyState(lang, lang.isArabic, messageKey: 'store_no_orders');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];
        return CustomCard(
          margin: const EdgeInsets.only(bottom: 12),
          onTap: () => _showOrderDetails(order, lang),
          child: Row(
            children: [
              Icon(_statusIcon(order['status']), color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order['id'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      _statusLabel(order['status'], lang),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Text(
                '${(order['total'] as num).toDouble().toStringAsFixed(2)} ${lang.t('currency_sar')}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showOrderDetails(Map<String, dynamic> order, LanguageProvider lang) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          final items = (order['items'] as List?)?.cast<Map<String, dynamic>>() ?? const <Map<String, dynamic>>[];
          final subtotal = (order['subtotal'] as num?)?.toDouble();
          final shipping = (order['shipping'] as num?)?.toDouble();
          final tax = (order['tax'] as num?)?.toDouble();
          final total = (order['total'] as num?)?.toDouble() ?? 0;

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  order['id'].toString(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  _statusLabel(order['status']?.toString() ?? 'processing', lang),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                if (items.isNotEmpty) ...[
                  Text(lang.t('checkout_items'), style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  ...items.map((item) {
                    final isArabic = lang.isArabic;
                    final name = isArabic ? (item['nameAr'] ?? item['nameEn']) : (item['nameEn'] ?? item['nameAr']);
                    final price = (item['price'] as num).toDouble();
                    final qty = item['quantity'] as int;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              item['image'] as String,
                              width: 46,
                              height: 46,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name.toString(), maxLines: 2, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text(
                                  '${qty} × ${price.toStringAsFixed(2)} ${lang.t('currency_sar')}',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 4),
                ],
                CustomCard(
                  child: Column(
                    children: [
                      if (subtotal != null)
                        _summaryRow(lang.t('subtotal'), '${subtotal.toStringAsFixed(2)} ${lang.t('currency_sar')}'),
                      if (shipping != null)
                        _summaryRow(
                          lang.t('shipping_fee'),
                          shipping == 0
                              ? lang.t('free')
                              : '${shipping.toStringAsFixed(2)} ${lang.t('currency_sar')}',
                        ),
                      if (tax != null)
                        _summaryRow(lang.t('tax_vat'), '${tax.toStringAsFixed(2)} ${lang.t('currency_sar')}'),
                      const Divider(height: 20),
                      _summaryRow(
                        lang.t('total'),
                        '${total.toStringAsFixed(2)} ${lang.t('currency_sar')}',
                        strong: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool strong = false}) {
    final style = TextStyle(
      fontWeight: strong ? FontWeight.w800 : FontWeight.w500,
      color: strong ? AppColors.textPrimary : AppColors.textSecondary,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(label, style: style),
          const Spacer(),
          Text(value, style: style),
        ],
      ),
    );
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'processing':
      case 'pending':
      case 'confirmed':
        return Icons.schedule;
      case 'shipped':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.inventory_2;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.schedule;
    }
  }

  String _statusLabel(String status, LanguageProvider lang) {
    switch (status) {
      case 'processing':
        return lang.t('store_status_processing');
      case 'pending':
        return lang.t('store_status_pending');
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

  Widget _buildCategoryFilters(LanguageProvider lang, bool isArabic) {
    return Container(
      height: 60,
      color: AppColors.surface,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_categoryLabel(category, lang)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              checkmarkColor: AppColors.primary,
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(
    Map<String, dynamic> product,
    LanguageProvider lang,
    bool isArabic,
  ) {
    final inStock = product['inStock'] as bool;

    return CustomCard(
      padding: EdgeInsets.zero,
      onTap: () => _showProductDetail(product, lang, isArabic),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image.network(
                  product['image'],
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              if (product['discount'] != null)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '-${product['discount']}%',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
              if (product['isPopular'] == true)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      lang.t('store_popular'),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
              if (!inStock)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        lang.t('out_of_stock'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['brand'],
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isArabic ? product['nameAr'] : product['nameEn'],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, color: AppColors.warning, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${product['rating']}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${lang.t('reviews_count', args: {'count': '${product['reviews']}'})}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textDisabled,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${product['price']} ${lang.t('currency_sar')}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_shopping_cart, size: 20),
                        onPressed: inStock
                            ? () => _addToCart(product, lang, isArabic)
                            : null,
                        color: AppColors.primary,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _categoryLabel(String category, LanguageProvider lang) {
    switch (category) {
      case 'all':
        return lang.t('store_all');
      case 'Protein':
        return lang.t('store_category_protein');
      case 'Pre-Workout':
        return lang.t('store_category_pre_workout');
      case 'Recovery':
        return lang.t('store_category_recovery');
      case 'Vitamins':
        return lang.t('store_category_vitamins');
      case 'Fat Burners':
        return lang.t('store_category_fat_burners');
      default:
        return category;
    }
  }

  Widget _buildEmptyState(LanguageProvider lang, bool isArabic, {String? messageKey}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 80,
            color: AppColors.textDisabled,
          ),
          const SizedBox(height: 24),
          Text(
            messageKey != null ? lang.t(messageKey) : lang.t('store_no_products'),
            style: const TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _addToCart(
    Map<String, dynamic> product,
    LanguageProvider lang,
    bool isArabic,
  ) {
    setState(() {
      final existingIndex = _cartItems.indexWhere((item) => item['id'] == product['id']);
      if (existingIndex >= 0) {
        _cartItems[existingIndex]['quantity'] =
            (_cartItems[existingIndex]['quantity'] as int) + 1;
      } else {
        _cartItems.add({...product, 'quantity': 1});
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(lang.t('store_added_to_cart')),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _updateQuantity(String productId, int newQuantity) {
    setState(() {
      if (newQuantity <= 0) {
        _cartItems.removeWhere((item) => item['id'] == productId);
        return;
      }
      final index = _cartItems.indexWhere((item) => item['id'] == productId);
      if (index >= 0) {
        _cartItems[index]['quantity'] = newQuantity;
      }
    });
  }

  void _showProductDetail(
    Map<String, dynamic> product,
    LanguageProvider lang,
    bool isArabic,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    product['image'],
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isArabic ? product['nameAr'] : product['nameEn'],
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: AppColors.warning, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '${product['rating']}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${lang.t('reviews_count', args: {'count': '${product['reviews']}'})}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '${product['price']} ${lang.t('currency_sar')}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  lang.t('description'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isArabic ? product['descriptionAr'] : product['descriptionEn'],
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: lang.t('add_to_cart'),
                    onPressed: product['inStock'] == true
                        ? () {
                            Navigator.pop(context);
                            _addToCart(product, lang, isArabic);
                          }
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _checkout(LanguageProvider lang, bool isArabic) {
    Navigator.of(context)
        .push<StoreCheckoutResult>(
          MaterialPageRoute(
            builder: (_) => StoreCheckoutScreen(
              cartItems: List<Map<String, dynamic>>.from(_cartItems),
            ),
          ),
        )
        .then((result) {
      if (!mounted || result == null) return;

      setState(() {
        _orders.insert(0, result);
        _cartItems.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang.t('order_success_toast')),
          backgroundColor: AppColors.success,
        ),
      );

      final controller = _tabController ?? DefaultTabController.maybeOf(context);
      controller?.animateTo(2);
    });
  }
}

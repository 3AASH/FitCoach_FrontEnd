import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/config/demo_config.dart';
import '../../../core/constants/colors.dart';
import '../../../data/repositories/store_repository.dart';
import '../../providers/language_provider.dart';
import '../../widgets/custom_card.dart';
// ...existing code...

class StoreManagementScreen extends StatefulWidget {
  const StoreManagementScreen({super.key});

  @override
  State<StoreManagementScreen> createState() => _StoreManagementScreenState();
}

class _StoreManagementScreenState extends State<StoreManagementScreen> {
  String _selectedTab = 'products'; // products, categories, orders
  String _searchQuery = '';

  bool _loading = false;
  String? _error;

  List<Map<String, dynamic>> _products = [
    {
      'id': '1',
      'name': 'Whey Protein',
      'category': 'Supplements',
      'price': 299,
      'stock': 45,
      'status': 'active',
      'sales': 128,
    },
    {
      'id': '2',
      'name': 'Resistance Bands',
      'category': 'Equipment',
      'price': 79,
      'stock': 8,
      'status': 'low_stock',
      'sales': 56,
    },
    {
      'id': '3',
      'name': 'Yoga Mat',
      'category': 'Equipment',
      'price': 149,
      'stock': 0,
      'status': 'out_of_stock',
      'sales': 234,
    },
  ];

  List<Map<String, dynamic>> _categories = [
    {
      'id': 'c1',
      'name': 'Supplements',
      'count': 24,
      'icon': Icons.medical_services
    },
    {
      'id': 'c2',
      'name': 'Equipment',
      'count': 18,
      'icon': Icons.fitness_center
    },
    {'id': 'c3', 'name': 'Apparel', 'count': 32, 'icon': Icons.checkroom},
    {'id': 'c4', 'name': 'Accessories', 'count': 15, 'icon': Icons.watch},
  ];

  List<Map<String, dynamic>> _orders = [
    {
      'id': '#1234',
      'customer': 'Ahmed Ali',
      'total': 599,
      'status': 'pending',
      'date': '2024-12-21',
      'items': 2,
      'address': 'Riyadh, KSA',
    },
    {
      'id': '#1233',
      'customer': 'Sara Mohammed',
      'total': 299,
      'status': 'shipped',
      'date': '2024-12-20',
      'items': 1,
      'address': 'Jeddah, KSA',
    },
    {
      'id': '#1232',
      'customer': 'Omar Hassan',
      'total': 449,
      'status': 'delivered',
      'date': '2024-12-19',
      'items': 3,
      'address': 'Dammam, KSA',
    },
  ];

  @override
  void initState() {
    super.initState();
    if (!DemoConfig.isDemo) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repository = StoreRepository();
      final products = await repository.getProducts(limit: 100, offset: 0);
      final categories = await repository.getCategories();
      final orders = await repository.getAllOrdersAdmin(limit: 50, offset: 0);

      if (!mounted) return;

      setState(() {
        _products = products
            .map((product) {
              final stock = product.stockQuantity;
              final status = stock == 0
                  ? 'out_of_stock'
                  : stock <= 10
                      ? 'low_stock'
                      : 'active';
              return {
                'id': product.id,
                'name': product.name,
                'category': product.category,
                'price': product.price,
                'stock': stock,
                'status': status,
                'sales': 0,
              };
            })
            .toList();

        _categories = categories
            .map((name) => {
                  'id': name,
                  'name': name,
                  'count': 0,
                  'icon': Icons.category,
                })
            .toList();

        _orders = orders
            .map((order) => {
                  'id': order['order_number'] ?? order['id'],
                  'customer': order['user_name'] ?? 'Unknown',
                  'total': order['total'] ?? 0,
                  'status': order['status'] ?? 'pending',
                  'date': order['created_at'] ?? '',
                  'items': order['item_count'] ?? 0,
                  'address': order['shipping_address'] ?? '',
                })
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final lang = languageProvider;

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.t('store_management_title')),
      ),
      body: Column(
        children: [
          if (_loading)
            const LinearProgressIndicator(minHeight: 4),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.error, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          // Tabs
          Container(
            color: AppColors.background,
            child: Row(
              children: [
                _buildTab(
                    'products', lang.t('store_tab_products'), lang),
                _buildTab(
                    'categories', lang.t('store_tab_categories'), lang),
                _buildTab('orders', lang.t('store_tab_orders'), lang),
              ],
            ),
          ),

          // Search
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: lang.t('store_search_hint'),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.surface,
              ),
            ),
          ),

          // Content
          Expanded(
            child: _selectedTab == 'products'
                ? _buildProductsList(lang)
                : _selectedTab == 'categories'
                    ? _buildCategoriesList(lang)
                    : _buildOrdersList(lang),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addNew(lang),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: Text(
          _selectedTab == 'products'
              ? (lang.t('store_add_product'))
              : _selectedTab == 'categories'
                  ? (lang.t('store_add_category'))
                  : (lang.t('store_new_order')),
        ),
      ),
    );
  }

  Widget _buildTab(String tab, String label, LanguageProvider lang) {
    final isSelected = _selectedTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = tab;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.background,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductsList(LanguageProvider lang) {
    final filteredProducts = _products.where((product) {
      final query = _searchQuery.toLowerCase();
      return product['name'].toString().toLowerCase().contains(query) ||
          product['category'].toString().toLowerCase().contains(query);
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        return CustomCard(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.shopping_bag, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['name'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product['category'],
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(product['status'], lang),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem(
                    lang.t('store_price_label'),
                    '${product['price']} ${lang.t('store_currency')}',
                    AppColors.primary,
                  ),
                  _buildStatItem(
                    lang.t('store_stock_label'),
                    '${product['stock']}',
                    product['stock'] == 0
                        ? AppColors.error
                        : product['stock'] < 10
                            ? AppColors.warning
                            : AppColors.success,
                  ),
                  _buildStatItem(
                    lang.t('store_sales_label'),
                    '${product['sales']}',
                    AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _openProductForm(lang, product: product),
                      icon: const Icon(Icons.edit, size: 18),
                      label: Text(lang.t('store_edit')),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmDeleteProduct(lang, product),
                      icon: const Icon(Icons.delete, size: 18),
                      label: Text(lang.t('store_delete')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoriesList(LanguageProvider lang) {
    final filteredCategories = _categories.where((category) {
      final query = _searchQuery.toLowerCase();
      return category['name'].toString().toLowerCase().contains(query);
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredCategories.length,
      itemBuilder: (context, index) {
        final category = filteredCategories[index];
        return CustomCard(
          margin: const EdgeInsets.only(bottom: 12),
          onTap: () {
            _openCategoryDetails(lang, category);
          },
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  category['icon'] as IconData,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category['name'] as String,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${category['count']} ${lang.t('store_products_label')}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left : Icons.chevron_right,
                color: AppColors.textDisabled,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrdersList(LanguageProvider lang) {
    final filteredOrders = _orders.where((order) {
      final query = _searchQuery.toLowerCase();
      return order['id'].toString().toLowerCase().contains(query) ||
          order['customer'].toString().toLowerCase().contains(query) ||
          order['status'].toString().toLowerCase().contains(query);
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        final order = filteredOrders[index];
        return CustomCard(
          margin: const EdgeInsets.only(bottom: 12),
          onTap: () {
            _openOrderDetails(lang, order);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order['id'] as String,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildStatusBadge(order['status'] as String, lang),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                order['customer'] as String,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order['date'] as String,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${order['total']} ${lang.t('store_currency')}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status, LanguageProvider lang) {
    Color color;
    String label;

    switch (status) {
      case 'active':
        color = AppColors.success;
        label = lang.t('store_status_active');
        break;
      case 'low_stock':
        color = AppColors.warning;
        label = lang.t('store_status_low_stock');
        break;
      case 'out_of_stock':
        color = AppColors.error;
        label = lang.t('store_status_out_of_stock');
        break;
      case 'pending':
        color = AppColors.warning;
        label = lang.t('store_status_pending');
        break;
      case 'shipped':
        color = AppColors.primary;
        label = lang.t('store_status_shipped');
        break;
      case 'delivered':
        color = AppColors.success;
        label = lang.t('store_status_delivered');
        break;
      default:
        color = AppColors.textSecondary;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  void _addNew(LanguageProvider lang) {
    if (_selectedTab == 'products') {
      _openProductForm(lang);
      return;
    }
    if (_selectedTab == 'categories') {
      if (!DemoConfig.isDemo) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(lang.t('store_demo_only')),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      _openCategoryForm(lang);
      return;
    }
    _openOrderForm(lang);
  }

  Future<void> _openProductForm(LanguageProvider lang,
      {Map<String, dynamic>? product}) async {
    final isEdit = product != null;
    final nameController =
        TextEditingController(text: product?['name']?.toString() ?? '');
    final categoryController =
        TextEditingController(text: product?['category']?.toString() ?? '');
    final priceController =
        TextEditingController(text: product?['price']?.toString() ?? '');
    final stockController =
        TextEditingController(text: product?['stock']?.toString() ?? '');
    String status = product?['status']?.toString() ?? 'active';

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit
            ? (lang.t('store_edit_product'))
            : (lang.t('store_add_product'))),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration:
                    InputDecoration(labelText: lang.t('store_name_label')),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: categoryController,
                decoration:
                    InputDecoration(labelText: lang.t('store_category_label')),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration:
                    InputDecoration(labelText: lang.t('store_price_label')),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: stockController,
                keyboardType: TextInputType.number,
                decoration:
                    InputDecoration(labelText: lang.t('store_stock_label')),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: status,
                items: [
                  DropdownMenuItem(
                    value: 'active',
                    child: Text(lang.t('store_status_active')),
                  ),
                  DropdownMenuItem(
                    value: 'low_stock',
                    child: Text(lang.t('store_status_low_stock')),
                  ),
                  DropdownMenuItem(
                    value: 'out_of_stock',
                    child: Text(lang.t('store_status_out_of_stock')),
                  ),
                ],
                onChanged: (v) => status = v ?? status,
                decoration:
                    InputDecoration(labelText: lang.t('store_status_label')),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.t('cancel')),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              final category = categoryController.text.trim().isEmpty
                  ? 'General'
                  : categoryController.text.trim();
              final price = double.tryParse(priceController.text.trim()) ?? 0;
              final stock = int.tryParse(stockController.text.trim()) ?? 0;

              if (DemoConfig.isDemo) {
                setState(() {
                  if (isEdit) {
                    final index =
                        _products.indexWhere((p) => p['id'] == product['id']);
                    if (index != -1) {
                      _products[index] = {
                        ..._products[index],
                        'name': name,
                        'category': category,
                        'price': price,
                        'stock': stock,
                        'status': status,
                      };
                    }
                  } else {
                    _products.insert(0, {
                      'id': DateTime.now().millisecondsSinceEpoch.toString(),
                      'name': name,
                      'category': category,
                      'price': price,
                      'stock': stock,
                      'status': status,
                      'sales': 0,
                    });
                  }
                });

                Navigator.pop(context);
                return;
              }

              try {
                final repository = StoreRepository();
                if (isEdit) {
                  await repository.updateProductAdmin(
                    productId: product['id'] as String,
                    name: name,
                    category: category,
                    price: price,
                    stockQuantity: stock,
                    isActive: status != 'out_of_stock',
                  );
                } else {
                  await repository.createProductAdmin(
                    name: name,
                    category: category,
                    price: price,
                    stockQuantity: stock,
                  );
                }

                if (!mounted) return;
                await _loadData();
                Navigator.pop(context);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: Text(lang.t('save')),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteProduct(
      LanguageProvider lang, Map<String, dynamic> product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.t('store_delete_product')),
        content: Text(
          lang.t('store_delete_product_confirm', args: {'name': product['name'].toString()}),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(lang.t('cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(lang.t('store_delete')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (DemoConfig.isDemo) {
        setState(() {
          _products.removeWhere((p) => p['id'] == product['id']);
        });
        return;
      }

      try {
        final repository = StoreRepository();
        await repository.deleteProductAdmin(product['id'] as String);
        if (!mounted) return;
        await _loadData();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _openCategoryForm(LanguageProvider lang,
      {Map<String, dynamic>? category}) async {
    if (!DemoConfig.isDemo) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang.t('store_demo_only')),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    final isEdit = category != null;
    final nameController =
        TextEditingController(text: category?['name']?.toString() ?? '');
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit
            ? (lang.t('store_edit_category'))
            : (lang.t('store_add_category'))),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
              labelText: lang.t('store_category_name')),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(lang.t('cancel'))),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              setState(() {
                if (isEdit) {
                  final index =
                      _categories.indexWhere((c) => c['id'] == category['id']);
                  if (index != -1) {
                    _categories[index] = {..._categories[index], 'name': name};
                  }
                } else {
                  _categories.insert(0, {
                    'id': 'c-${DateTime.now().millisecondsSinceEpoch}',
                    'name': name,
                    'count': 0,
                    'icon': Icons.category,
                  });
                }
              });
              Navigator.pop(context);
            },
            child: Text(lang.t('save')),
          ),
        ],
      ),
    );
  }

  void _openCategoryDetails(LanguageProvider lang, Map<String, dynamic> category) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category['name'] as String,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '${category['count']} ${lang.t('store_products_label')}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _openCategoryForm(lang, category: category);
                      },
                      icon: const Icon(Icons.edit),
                      label: Text(lang.t('store_edit')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _products.removeWhere(
                              (p) => p['category'] == category['name']);
                          _categories
                              .removeWhere((c) => c['id'] == category['id']);
                        });
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: Text(lang.t('store_delete')),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openOrderForm(LanguageProvider lang,
      {Map<String, dynamic>? order}) async {
    final isEdit = order != null;
    final idController = TextEditingController(
        text: order?['id']?.toString() ??
            '#${DateTime.now().millisecondsSinceEpoch % 10000}');
    final customerController =
        TextEditingController(text: order?['customer']?.toString() ?? '');
    final totalController =
        TextEditingController(text: order?['total']?.toString() ?? '');
    String status = order?['status']?.toString() ?? 'pending';
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit
            ? (lang.t('store_edit_order'))
            : (lang.t('store_new_order'))),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idController,
                decoration: InputDecoration(
                    labelText: lang.t('store_order_id')),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: customerController,
                decoration: InputDecoration(
                    labelText: lang.t('store_customer')),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: totalController,
                keyboardType: TextInputType.number,
                decoration:
                    InputDecoration(labelText: lang.t('store_total')),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: status,
                items: [
                  DropdownMenuItem(
                    value: 'pending',
                    child: Text(lang.t('store_status_pending')),
                  ),
                  DropdownMenuItem(
                    value: 'shipped',
                    child: Text(lang.t('store_status_shipped')),
                  ),
                  DropdownMenuItem(
                    value: 'delivered',
                    child: Text(lang.t('store_status_delivered')),
                  ),
                ],
                onChanged: (v) => status = v ?? status,
                decoration:
                    InputDecoration(labelText: lang.t('store_status_label')),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(lang.t('cancel'))),
          TextButton(
            onPressed: () {
              final id = idController.text.trim();
              final customer = customerController.text.trim();
              final total = int.tryParse(totalController.text.trim()) ?? 0;
              if (id.isEmpty || customer.isEmpty) return;
              setState(() {
                if (isEdit) {
                  final index =
                      _orders.indexWhere((o) => o['id'] == order['id']);
                  if (index != -1) {
                    _orders[index] = {
                      ..._orders[index],
                      'id': id,
                      'customer': customer,
                      'total': total,
                      'status': status
                    };
                  }
                } else {
                  _orders.insert(0, {
                    'id': id,
                    'customer': customer,
                    'total': total,
                    'status': status,
                    'date': DateTime.now().toIso8601String().substring(0, 10),
                    'items': 1,
                    'address': '—',
                  });
                }
              });
              Navigator.pop(context);
            },
            child: Text(lang.t('save')),
          ),
        ],
      ),
    );
  }

  void _openOrderDetails(LanguageProvider lang, Map<String, dynamic> order) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order['id'] as String,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  _buildStatusBadge(order['status'] as String, lang),
                ],
              ),
              const SizedBox(height: 12),
              Text('${lang.t('store_customer')}: ${order['customer']}'),
              const SizedBox(height: 6),
              Text('${lang.t('store_date')}: ${order['date']}'),
              const SizedBox(height: 6),
              Text('${lang.t('store_items')}: ${order['items'] ?? 0}'),
              const SizedBox(height: 6),
              Text(
                  '${lang.t('store_address')}: ${order['address'] ?? '—'}'),
              const SizedBox(height: 12),
              Text(
                '${lang.t('store_total')}: ${order['total']} ${lang.t('store_currency')}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _openOrderForm(lang, order: order);
                      },
                      icon: const Icon(Icons.edit),
                      label: Text(lang.t('store_edit')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _orders.removeWhere((o) => o['id'] == order['id']);
                        });
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: Text(lang.t('store_delete')),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

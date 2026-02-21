import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/config/demo_config.dart';
import '../../../core/constants/colors.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/store_repository.dart';
import '../../providers/language_provider.dart';
import '../../providers/store_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_card.dart';

enum StorePaymentMethod { card, cod }

typedef StoreCartItem = Map<String, dynamic>;

typedef StoreCheckoutResult = Map<String, dynamic>;

class StoreCheckoutScreen extends StatefulWidget {
  final List<StoreCartItem> cartItems;

  const StoreCheckoutScreen({
    super.key,
    required this.cartItems,
  });

  @override
  State<StoreCheckoutScreen> createState() => _StoreCheckoutScreenState();
}

class _StoreCheckoutScreenState extends State<StoreCheckoutScreen> {
  int _stepIndex = 0;
  bool _isSubmitting = false;

  // Shipping
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _notesController = TextEditingController();
  final _countryController = TextEditingController();

  // Payment
  StorePaymentMethod _paymentMethod = StorePaymentMethod.card;
  final _cardNumberController = TextEditingController();
  final _cardNameController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _cardCvvController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _notesController.dispose();
    _countryController.dispose();
    _cardNumberController.dispose();
    _cardNameController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    super.dispose();
  }

  double get _subtotal {
    return widget.cartItems.fold<double>(
      0,
      (sum, item) => sum + (item['price'] as num).toDouble() * (item['quantity'] as int),
    );
  }

  double get _shipping {
    // Simple rule: free shipping for bigger baskets.
    return _subtotal >= 100 ? 0 : 15;
  }

  double get _tax {
    // KSA VAT (15%)
    return _subtotal * 0.15;
  }

  double get _total => _subtotal + _shipping + _tax;

  bool _validateShipping(LanguageProvider lang) {
    if (_fullNameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty) {
      _showError(lang.t('checkout_fill_required'));
      return false;
    }
    return true;
  }

  bool _validatePayment(LanguageProvider lang) {
    if (_paymentMethod == StorePaymentMethod.cod) return true;

    if (_cardNumberController.text.trim().isEmpty ||
        _cardNameController.text.trim().isEmpty ||
        _cardExpiryController.text.trim().isEmpty ||
        _cardCvvController.text.trim().isEmpty) {
      _showError(lang.t('checkout_fill_payment_details'));
      return false;
    }

    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  Future<void> _onPrimaryAction(LanguageProvider lang) async {
    if (_isSubmitting) return;

    if (_stepIndex == 0) {
      if (!_validateShipping(lang)) return;
      setState(() => _stepIndex = 1);
      return;
    }

    if (_stepIndex == 1) {
      if (!_validatePayment(lang)) return;
      setState(() => _stepIndex = 2);
      return;
    }

    if (_stepIndex == 2) {
      await _placeOrder(lang);
      return;
    }

    if (_stepIndex == 3) {
      Navigator.of(context).pop(_lastResult);
    }
  }

  String _buildShippingAddressString(LanguageProvider lang) {
    final parts = <String>[
      _addressController.text.trim(),
      _cityController.text.trim(),
      _stateController.text.trim(),
      _zipController.text.trim(),
      _countryController.text.trim().isEmpty ? lang.t('checkout_country_default') : _countryController.text.trim(),
    ].where((p) => p.isNotEmpty).toList();

    return parts.join(', ');
  }

  String _mapBackendStatusToUi(String status) {
    switch (status) {
      case 'pending':
      case 'confirmed':
        return 'processing';
      case 'shipped':
        return 'shipped';
      case 'delivered':
        return 'delivered';
      case 'cancelled':
        return 'cancelled';
      default:
        return 'processing';
    }
  }

  StoreRepository? _tryGetStoreRepository() {
    try {
      return context.read<StoreRepository>();
    } catch (_) {
      return null;
    }
  }

  StoreProvider? _tryGetStoreProvider() {
    try {
      return context.read<StoreProvider>();
    } catch (_) {
      return null;
    }
  }

  Future<void> _placeOrder(LanguageProvider lang) async {
    setState(() => _isSubmitting = true);

    try {
      final shippingAddress = _buildShippingAddressString(lang);
      final notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();

      // Preferred: use StoreProvider (backend + cart clearing) in non-demo mode.
      if (!DemoConfig.isDemo) {
        final storeProvider = _tryGetStoreProvider();
        if (storeProvider != null && storeProvider.cart.isNotEmpty) {
          final Order? order = await storeProvider.createOrder(
            shippingAddress: shippingAddress,
            notes: notes,
          );

          if (order == null) {
            throw Exception(storeProvider.error ?? 'Failed to create order');
          }

          final cartById = <String, StoreCartItem>{
            for (final ci in widget.cartItems) (ci['id']?.toString() ?? ''): ci,
          };

          final resultItems = order.items.map((oi) {
            final fallback = cartById[oi.productId];
            return <String, dynamic>{
              'id': oi.productId,
              'nameEn': oi.productNameEn ?? oi.productName,
              'nameAr': oi.productNameAr ?? oi.productName,
              'image': oi.productImage ?? fallback?['image'],
              'price': oi.finalPrice,
              'quantity': oi.quantity,
            };
          }).toList();

          final result = <String, dynamic>{
            'id': order.orderNumber.isNotEmpty ? order.orderNumber : order.id,
            'status': _mapBackendStatusToUi(order.status),
            'backendStatus': order.status,
            'date': order.createdAt,
            'subtotal': order.subtotal,
            'shipping': order.shippingCost,
            'tax': order.tax,
            'total': order.total,
            'items': resultItems,
            'shippingInfo': {
              'fullName': _fullNameController.text.trim(),
              'email': _emailController.text.trim(),
              'phone': _phoneController.text.trim(),
              'address': _addressController.text.trim(),
              'city': _cityController.text.trim(),
              'state': _stateController.text.trim(),
              'zip': _zipController.text.trim(),
              'notes': _notesController.text.trim(),
            },
            'paymentMethod': _paymentMethod == StorePaymentMethod.card ? 'card' : 'cod',
          };

          _lastResult = result;
          setState(() => _stepIndex = 3);
          return;
        }
      }

      final repo = _tryGetStoreRepository();

      // If repository is registered, place a real backend order.
      if (repo != null) {
        final items = widget.cartItems.map((item) {
          return {
            'productId': item['id'],
            'quantity': item['quantity'],
            'price': item['price'],
          };
        }).toList();

        final Order order = await repo.createOrder(
          items: items,
          shippingAddress: shippingAddress,
          notes: notes,
        );

        final cartById = <String, StoreCartItem>{
          for (final ci in widget.cartItems) (ci['id']?.toString() ?? ''): ci,
        };

        final resultItems = order.items.map((oi) {
          final fallback = cartById[oi.productId];
          return <String, dynamic>{
            'id': oi.productId,
            'nameEn': oi.productNameEn ?? oi.productName,
            'nameAr': oi.productNameAr ?? oi.productName,
            'image': oi.productImage ?? fallback?['image'],
            'price': oi.finalPrice,
            'quantity': oi.quantity,
          };
        }).toList();

        final result = <String, dynamic>{
          'id': order.orderNumber.isNotEmpty ? order.orderNumber : order.id,
          'status': _mapBackendStatusToUi(order.status),
          'backendStatus': order.status,
          'date': order.createdAt,
          'subtotal': order.subtotal,
          'shipping': order.shippingCost,
          'tax': order.tax,
          'total': order.total,
          'items': resultItems,
          'shippingInfo': {
            'fullName': _fullNameController.text.trim(),
            'email': _emailController.text.trim(),
            'phone': _phoneController.text.trim(),
            'address': _addressController.text.trim(),
            'city': _cityController.text.trim(),
            'state': _stateController.text.trim(),
            'zip': _zipController.text.trim(),
            'notes': _notesController.text.trim(),
          },
          'paymentMethod': _paymentMethod == StorePaymentMethod.card ? 'card' : 'cod',
        };

        _lastResult = result;
        setState(() => _stepIndex = 3);
        return;
      }

      if (!DemoConfig.isDemo) {
        throw Exception('Store backend is not available');
      }

      // Fallback: demo/offline order.
      final orderId = 'ORD-${DateTime.now().millisecondsSinceEpoch}';
      final result = <String, dynamic>{
        'id': orderId,
        'status': 'processing',
        'date': DateTime.now(),
        'subtotal': _subtotal,
        'shipping': _shipping,
        'tax': _tax,
        'total': _total,
        'items': widget.cartItems,
        'shippingInfo': {
          'fullName': _fullNameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'city': _cityController.text.trim(),
          'state': _stateController.text.trim(),
          'zip': _zipController.text.trim(),
          'notes': _notesController.text.trim(),
        },
        'paymentMethod': _paymentMethod == StorePaymentMethod.card ? 'card' : 'cod',
      };

      _lastResult = result;
      setState(() => _stepIndex = 3);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  StoreCheckoutResult? _lastResult;

  String _primaryCtaText(LanguageProvider lang) {
    switch (_stepIndex) {
      case 0:
      case 1:
        return lang.t('checkout_continue');
      case 2:
        return lang.t('checkout_place_order');
      case 3:
        return lang.t('checkout_done');
      default:
        return lang.t('checkout_continue');
    }
  }

  Future<void> _onBack(LanguageProvider lang) async {
    if (_stepIndex == 0) {
      Navigator.of(context).maybePop();
      return;
    }

    if (_stepIndex == 3) {
      Navigator.of(context).pop(_lastResult);
      return;
    }

    setState(() => _stepIndex -= 1);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final isArabic = lang.isArabic;

    // Keep a stable value in the disabled field.
    _countryController.text = lang.t('checkout_country_default');

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(lang, isArabic),
            _buildProgress(lang),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: _buildStepContent(lang, isArabic),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: CustomButton(
                text: _primaryCtaText(lang),
                onPressed: _isSubmitting ? null : () => _onPrimaryAction(lang),
                isLoading: _isSubmitting,
                fullWidth: true,
                size: ButtonSize.large,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(LanguageProvider lang, bool isArabic) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 16, 10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF06B6D4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _onBack(lang),
            icon: Icon(
              isArabic ? Icons.arrow_forward : Icons.arrow_back,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang.t('checkout'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  lang.t('checkout_subtitle'),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.security, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildProgress(LanguageProvider lang) {
    Widget stepDot(int index, String label) {
      final isActive = _stepIndex == index;
      final isComplete = _stepIndex > index;

      Color borderColor;
      Color fillColor;
      Color textColor;

      if (isComplete) {
        borderColor = AppColors.success;
        fillColor = AppColors.success;
        textColor = Colors.white;
      } else if (isActive) {
        borderColor = AppColors.primary;
        fillColor = AppColors.primary;
        textColor = Colors.white;
      } else {
        borderColor = AppColors.border;
        fillColor = Colors.white;
        textColor = AppColors.textSecondary;
      }

      return Expanded(
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor, width: 2),
              ),
              child: Center(
                child: isComplete
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : Text(
                        '${index + 1}',
                        style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive || isComplete ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    Widget connector(bool complete) {
      return Expanded(
        child: Container(
          height: 2,
          margin: const EdgeInsets.only(bottom: 18),
          color: complete ? AppColors.success : AppColors.border,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      color: AppColors.surface,
      child: Row(
        children: [
          stepDot(0, lang.t('checkout_step_shipping')),
          connector(_stepIndex > 0),
          stepDot(1, lang.t('checkout_step_payment')),
          connector(_stepIndex > 1),
          stepDot(2, lang.t('checkout_step_review')),
        ],
      ),
    );
  }

  Widget _buildStepContent(LanguageProvider lang, bool isArabic) {
    if (_stepIndex == 0) return _buildShippingStep(lang, isArabic);
    if (_stepIndex == 1) return _buildPaymentStep(lang, isArabic);
    if (_stepIndex == 2) return _buildReviewStep(lang, isArabic);
    return _buildSuccessStep(lang);
  }

  Widget _buildShippingStep(LanguageProvider lang, bool isArabic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lang.t('checkout_shipping_information'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        CustomCard(
          child: Column(
            children: [
              _field(
                lang: lang,
                controller: _fullNameController,
                labelKey: 'checkout_full_name',
                icon: Icons.person,
                required: true,
                textInputType: TextInputType.name,
              ),
              const SizedBox(height: 12),
              _field(
                lang: lang,
                controller: _emailController,
                labelKey: 'checkout_email',
                icon: Icons.email,
                required: true,
                textInputType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              _field(
                lang: lang,
                controller: _phoneController,
                labelKey: 'checkout_phone',
                icon: Icons.phone,
                required: true,
                textInputType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              _field(
                lang: lang,
                controller: _addressController,
                labelKey: 'checkout_address',
                icon: Icons.location_on,
                required: true,
                textInputType: TextInputType.streetAddress,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      lang: lang,
                      controller: _cityController,
                      labelKey: 'checkout_city',
                      icon: Icons.location_city,
                      textInputType: TextInputType.text,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      lang: lang,
                      controller: _stateController,
                      labelKey: 'checkout_state',
                      icon: Icons.map,
                      textInputType: TextInputType.text,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      lang: lang,
                      controller: _zipController,
                      labelKey: 'checkout_zip',
                      icon: Icons.local_post_office,
                      textInputType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      lang: lang,
                      controller: _countryController,
                      labelKey: 'checkout_country',
                      icon: Icons.public,
                      enabled: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _field(
                lang: lang,
                controller: _notesController,
                labelKey: 'checkout_notes',
                icon: Icons.notes,
                maxLines: 3,
                textInputType: TextInputType.multiline,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildOrderSummary(lang),
      ],
    );
  }

  Widget _buildPaymentStep(LanguageProvider lang, bool isArabic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lang.t('checkout_payment'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lang.t('checkout_payment_method'),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              RadioListTile<StorePaymentMethod>(
                value: StorePaymentMethod.card,
                groupValue: _paymentMethod,
                onChanged: (value) => setState(() => _paymentMethod = value ?? StorePaymentMethod.card),
                title: Text(lang.t('payment_method_card')),
              ),
              RadioListTile<StorePaymentMethod>(
                value: StorePaymentMethod.cod,
                groupValue: _paymentMethod,
                onChanged: (value) => setState(() => _paymentMethod = value ?? StorePaymentMethod.card),
                title: Text(lang.t('payment_method_cod')),
              ),
              if (_paymentMethod == StorePaymentMethod.card) ...[
                const Divider(height: 24),
                _field(
                  lang: lang,
                  controller: _cardNumberController,
                  labelKey: 'checkout_card_number',
                  icon: Icons.credit_card,
                  required: true,
                  textInputType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _field(
                  lang: lang,
                  controller: _cardNameController,
                  labelKey: 'checkout_card_name',
                  icon: Icons.badge,
                  required: true,
                  textInputType: TextInputType.name,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        lang: lang,
                        controller: _cardExpiryController,
                        labelKey: 'checkout_card_expiry',
                        icon: Icons.calendar_today,
                        required: true,
                        textInputType: TextInputType.datetime,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(
                        lang: lang,
                        controller: _cardCvvController,
                        labelKey: 'checkout_card_cvv',
                        icon: Icons.lock,
                        required: true,
                        textInputType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildOrderSummary(lang),
      ],
    );
  }

  Widget _buildReviewStep(LanguageProvider lang, bool isArabic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lang.t('checkout_review'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        _buildOrderItems(lang, isArabic),
        const SizedBox(height: 12),
        _buildOrderSummary(lang),
        const SizedBox(height: 12),
        CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(lang.t('checkout_shipping_to'), style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(_fullNameController.text.trim()),
              const SizedBox(height: 2),
              Text(_addressController.text.trim()),
              const SizedBox(height: 2),
              Text(_phoneController.text.trim()),
              const SizedBox(height: 12),
              Text(lang.t('checkout_payment_method'), style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                _paymentMethod == StorePaymentMethod.card
                    ? lang.t('payment_method_card')
                    : lang.t('payment_method_cod'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessStep(LanguageProvider lang) {
    final orderId = (_lastResult?['id'] ?? '').toString();

    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
          ),
          child: const Icon(Icons.check_circle, color: AppColors.success, size: 40),
        ),
        const SizedBox(height: 12),
        Text(
          lang.t('order_success_title'),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          lang.t('order_success_message'),
          style: const TextStyle(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        if (orderId.isNotEmpty)
          CustomCard(
            child: Row(
              children: [
                Text(
                  lang.t('order_id'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text(orderId),
              ],
            ),
          ),
        const SizedBox(height: 16),
        _buildOrderSummary(lang),
      ],
    );
  }

  Widget _buildOrderItems(LanguageProvider lang, bool isArabic) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(lang.t('checkout_items'), style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...widget.cartItems.map((item) {
            final name = isArabic ? (item['nameAr'] ?? item['nameEn']) : (item['nameEn'] ?? item['nameAr']);
            final price = (item['price'] as num).toDouble();
            final qty = item['quantity'] as int;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
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
        ],
      ),
    );
  }

  Widget _buildOrderSummary(LanguageProvider lang) {
    Widget row(String label, String value, {bool strong = false}) {
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

    return CustomCard(
      child: Column(
        children: [
          row(lang.t('subtotal'), '${_subtotal.toStringAsFixed(2)} ${lang.t('currency_sar')}'),
          row(
            lang.t('shipping_fee'),
            _shipping == 0
                ? lang.t('free')
                : '${_shipping.toStringAsFixed(2)} ${lang.t('currency_sar')}',
          ),
          row(lang.t('tax_vat'), '${_tax.toStringAsFixed(2)} ${lang.t('currency_sar')}'),
          const Divider(height: 20),
          row(
            lang.t('total'),
            '${_total.toStringAsFixed(2)} ${lang.t('currency_sar')}',
            strong: true,
          ),
        ],
      ),
    );
  }

  Widget _field({
    required LanguageProvider lang,
    required TextEditingController controller,
    required String labelKey,
    required IconData icon,
    bool required = false,
    TextInputType? textInputType,
    bool enabled = true,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: textInputType,
      maxLines: maxLines,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        labelText: required ? '${lang.t(labelKey)} *' : lang.t(labelKey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

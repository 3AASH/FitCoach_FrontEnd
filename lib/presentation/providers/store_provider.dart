import 'package:flutter/material.dart';
import '../../data/repositories/store_repository.dart';
import '../../data/models/product.dart';
import '../../data/models/order.dart';

class StoreProvider extends ChangeNotifier {
  final StoreRepository _repository;

  StoreProvider(this._repository);

  // State
  bool _isLoading = false;
  String? _error;
  
  List<Product> _products = [];
  List<String> _categories = [];
  Product? _selectedProduct;
  List<Order> _orders = [];
  Order? _selectedOrder;
  
  // Cart state
  final Map<String, CartItem> _cart = {};
  String? _promoCode;
  double? _discount;
  double? _shippingCost;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Product> get products => _products;
  List<String> get categories => _categories;
  Product? get selectedProduct => _selectedProduct;
  List<Order> get orders => _orders;
  Order? get selectedOrder => _selectedOrder;
  
  Map<String, CartItem> get cart => _cart;
  int get cartItemCount => _cart.values.fold(0, (sum, item) => sum + item.quantity);
  double get cartSubtotal => _cart.values.fold(
    0.0,
    (sum, item) => sum + (item.product.finalPrice * item.quantity),
  );
  double get cartTotal {
    double total = cartSubtotal;
    if (_discount != null) total -= _discount!;
    if (_shippingCost != null) total += _shippingCost!;
    return total;
  }
  String? get promoCode => _promoCode;
  double? get discount => _discount;
  double? get shippingCost => _shippingCost;

  /// Load products
  Future<void> loadProducts({
    String? category,
    String? search,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
    String? sortOrder,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _products = await _repository.getProducts(
        category: category,
        search: search,
        minPrice: minPrice,
        maxPrice: maxPrice,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load product by ID
  Future<void> loadProduct(String productId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedProduct = await _repository.getProductById(productId);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load categories
  Future<void> loadCategories() async {
    try {
      _categories = await _repository.getCategories();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Add to cart
  Future<bool> addToCart(Product product, int quantity) async {
    try {
      // Check availability
      final available = await _repository.checkAvailability(
        product.id,
        quantity,
      );

      if (!available) {
        _error = 'Product not available in requested quantity';
        notifyListeners();
        return false;
      }

      if (_cart.containsKey(product.id)) {
        _cart[product.id]!.quantity += quantity;
      } else {
        _cart[product.id] = CartItem(product: product, quantity: quantity);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Remove from cart
  void removeFromCart(String productId) {
    _cart.remove(productId);
    notifyListeners();
  }

  /// Update cart item quantity
  Future<bool> updateCartQuantity(String productId, int quantity) async {
    if (quantity <= 0) {
      removeFromCart(productId);
      return true;
    }

    try {
      final product = _cart[productId]?.product;
      if (product == null) return false;

      // Check availability
      final available = await _repository.checkAvailability(
        productId,
        quantity,
      );

      if (!available) {
        _error = 'Product not available in requested quantity';
        notifyListeners();
        return false;
      }

      _cart[productId]!.quantity = quantity;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Clear cart
  void clearCart() {
    _cart.clear();
    _promoCode = null;
    _discount = null;
    _shippingCost = null;
    notifyListeners();
  }

  /// Apply promo code
  Future<bool> applyPromoCode(String code) async {
    try {
      final result = await _repository.applyPromoCode(code, cartSubtotal);
      
      if (result['valid'] == true) {
        _promoCode = code;
        _discount = (result['discount'] as num).toDouble();
        notifyListeners();
        return true;
      } else {
        _error = result['message'] as String? ?? 'Invalid promo code';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Remove promo code
  void removePromoCode() {
    _promoCode = null;
    _discount = null;
    notifyListeners();
  }

  /// Calculate shipping
  Future<void> calculateShipping(String address) async {
    try {
      // Calculate total weight (assuming 1kg per item for simplicity)
      final totalWeight = _cart.values.fold(
        0.0,
        (sum, item) => sum + (item.quantity * 1.0),
      );

      _shippingCost = await _repository.calculateShipping(
        address: address,
        weight: totalWeight,
      );
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Create order
  Future<Order?> createOrder({
    required String shippingAddress,
    String? notes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final items = _cart.values.map((cartItem) {
        return {
          'productId': cartItem.product.id,
          'quantity': cartItem.quantity,
          'price': cartItem.product.finalPrice,
        };
      }).toList();

      final order = await _repository.createOrder(
        items: items,
        shippingAddress: shippingAddress,
        notes: notes,
        promoCode: _promoCode,
      );

      // Clear cart after successful order
      clearCart();
      
      _isLoading = false;
      notifyListeners();
      
      return order;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Load orders
  Future<void> loadOrders({String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _orders = await _repository.getOrders(status: status);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load order by ID
  Future<void> loadOrder(String orderId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedOrder = await _repository.getOrderById(orderId);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cancel order
  Future<bool> cancelOrder(String orderId, String reason) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.cancelOrder(orderId, reason);
      
      // Reload orders
      await loadOrders();
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Submit product review
  Future<bool> submitReview({
    required String productId,
    required int rating,
    String? comment,
  }) async {
    try {
      await _repository.submitReview(
        productId: productId,
        rating: rating,
        comment: comment,
      );
      
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    required this.quantity,
  });
}

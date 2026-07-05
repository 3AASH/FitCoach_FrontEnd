import 'dart:convert';

class Order {
  final String id;
  final String userId;
  final String orderNumber;
  final List<OrderItem> items;
  final double subtotal;
  final double? discount;
  final double? shippingCost;
  final double? tax;
  final double total;
  final String status; // pending, confirmed, shipped, delivered, cancelled
  final String? statusAr;
  final String? statusEn;
  final String shippingAddress;
  final String? notes;
  final String? promoCode;
  final String? trackingNumber;
  final DateTime? estimatedDelivery;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Order({
    required this.id,
    required this.userId,
    required this.orderNumber,
    required this.items,
    required this.subtotal,
    this.discount,
    this.shippingCost,
    this.tax,
    required this.total,
    required this.status,
    this.statusAr,
    this.statusEn,
    required this.shippingAddress,
    this.notes,
    this.promoCode,
    this.trackingNumber,
    this.estimatedDelivery,
    this.deliveredAt,
    this.cancelledAt,
    this.cancellationReason,
    required this.createdAt,
    this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return Order(
      id: _string(json['id']),
      userId: _string(json['user_id'] ?? json['userId']),
      orderNumber: _string(json['order_number'] ?? json['orderNumber']),
      items: (rawItems is List ? rawItems : const [])
          .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      subtotal: _double(json['subtotal']),
      discount: json['discount'] != null ? _double(json['discount']) : null,
      shippingCost:
          json['shipping_cost'] != null || json['shippingCost'] != null
              ? _double(json['shipping_cost'] ?? json['shippingCost'])
              : null,
      tax: json['tax'] != null ? _double(json['tax']) : null,
      total: _double(json['total']),
      status: _string(json['status'], fallback: 'pending'),
      statusAr: json['status_ar'] ?? json['statusAr'] as String?,
      statusEn: json['status_en'] ?? json['statusEn'] as String?,
      shippingAddress:
          _addressString(json['shipping_address'] ?? json['shippingAddress']),
      notes: json['notes'] as String?,
      promoCode: json['promo_code'] ?? json['promoCode'] as String?,
      trackingNumber:
          json['tracking_number'] ?? json['trackingNumber'] as String?,
      estimatedDelivery: json['estimated_delivery'] != null ||
              json['estimatedDelivery'] != null
          ? DateTime.parse(
              json['estimated_delivery'] ?? json['estimatedDelivery'] as String)
          : null,
      deliveredAt: json['delivered_at'] != null || json['deliveredAt'] != null
          ? DateTime.parse(
              json['delivered_at'] ?? json['deliveredAt'] as String)
          : null,
      cancelledAt: json['cancelled_at'] != null || json['cancelledAt'] != null
          ? DateTime.parse(
              json['cancelled_at'] ?? json['cancelledAt'] as String)
          : null,
      cancellationReason:
          json['cancellation_reason'] ?? json['cancellationReason'] as String?,
      createdAt:
          DateTime.parse(json['created_at'] ?? json['createdAt'] as String),
      updatedAt: json['updated_at'] != null || json['updatedAt'] != null
          ? DateTime.parse(json['updated_at'] ?? json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'order_number': orderNumber,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'shipping_cost': shippingCost,
      'tax': tax,
      'total': total,
      'status': status,
      'status_ar': statusAr,
      'status_en': statusEn,
      'shipping_address': shippingAddress,
      'notes': notes,
      'promo_code': promoCode,
      'tracking_number': trackingNumber,
      'estimated_delivery': estimatedDelivery?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
      'cancellation_reason': cancellationReason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isShipped => status == 'shipped';
  bool get isDelivered => status == 'delivered';
  bool get isCancelled => status == 'cancelled';

  bool get canCancel => status == 'pending' || status == 'confirmed';
}

String _string(dynamic value, {String fallback = ''}) =>
    value?.toString() ?? fallback;

double _double(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String _addressString(dynamic value) {
  if (value == null) return '';
  if (value is Map) {
    return value.values
        .where((part) => part != null && part.toString().trim().isNotEmpty)
        .join(', ');
  }
  final raw = value.toString();
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map) return _addressString(decoded);
    if (decoded is String) return decoded;
  } catch (_) {
    // Keep the original value if it was not JSON.
  }
  return raw;
}

class OrderItem {
  final String id;
  final String productId;
  final String productName;
  final String? productNameEn;
  final String? productNameAr;
  final String? productImage;
  final int quantity;
  final double price;
  final double? discountedPrice;
  final double total;

  OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    this.productNameEn,
    this.productNameAr,
    this.productImage,
    required this.quantity,
    required this.price,
    this.discountedPrice,
    required this.total,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: _string(json['id']),
      productId: _string(json['product_id'] ?? json['productId']),
      productName: _string(
        json['product_name'] ?? json['productName'] ?? json['name'],
        fallback: 'Product',
      ),
      productNameEn:
          (json['product_name_en'] ?? json['productNameEn'])?.toString(),
      productNameAr:
          (json['product_name_ar'] ?? json['productNameAr'])?.toString(),
      productImage: (json['product_image'] ?? json['productImage'])?.toString(),
      quantity: int.tryParse(json['quantity']?.toString() ?? '') ?? 0,
      price: _double(json['price'] ?? json['price_at_time']),
      discountedPrice:
          json['discounted_price'] != null || json['discountedPrice'] != null
              ? _double(json['discounted_price'] ?? json['discountedPrice'])
              : null,
      total: _double(json['total']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'product_name_en': productNameEn,
      'product_name_ar': productNameAr,
      'product_image': productImage,
      'quantity': quantity,
      'price': price,
      'discounted_price': discountedPrice,
      'total': total,
    };
  }

  double get finalPrice => discountedPrice ?? price;
}

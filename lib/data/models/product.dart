import '../../core/config/api_config.dart';

class Product {
  final String id;
  final String name;
  final String nameEn;
  final String nameAr;
  final String? description;
  final String? descriptionEn;
  final String? descriptionAr;
  final double price;
  final String? currency;
  final String category;
  final String? categoryEn;
  final String? categoryAr;
  final List<String>? images;
  final String? mainImage;
  final bool inStock;
  final int stockQuantity;
  final double? rating;
  final int reviewCount;
  final Map<String, dynamic>? specifications;
  final List<String>? tags;
  final double? discountPercentage;
  final double? discountedPrice;
  final bool isFeatured;
  final bool isNew;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.nameAr,
    this.description,
    this.descriptionEn,
    this.descriptionAr,
    required this.price,
    this.currency,
    required this.category,
    this.categoryEn,
    this.categoryAr,
    this.images,
    this.mainImage,
    this.inStock = true,
    this.stockQuantity = 0,
    this.rating,
    this.reviewCount = 0,
    this.specifications,
    this.tags,
    this.discountPercentage,
    this.discountedPrice,
    this.isFeatured = false,
    this.isNew = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawName =
        _string(json['name'] ?? json['name_en'] ?? json['nameEn']) ?? 'Product';
    final rawCategory = _string(
            json['category'] ?? json['category_en'] ?? json['categoryEn']) ??
        'Store';
    final images = _stringList(json['images']).map(_assetUrl).nonNulls.toList();
    final mainImage =
        _assetUrl(_string(json['main_image'] ?? json['mainImage'])) ??
            (images.isNotEmpty ? images.first : null);

    return Product(
      id: json['id']?.toString() ?? '',
      name: rawName,
      nameEn: _string(json['name_en'] ?? json['nameEn']) ?? rawName,
      nameAr: _string(json['name_ar'] ?? json['nameAr']) ?? rawName,
      description: _string(json['description']),
      descriptionEn: _string(json['description_en'] ?? json['descriptionEn']),
      descriptionAr: _string(json['description_ar'] ?? json['descriptionAr']),
      price: _double(json['price']),
      currency: _string(json['currency']) ?? 'SAR',
      category: rawCategory,
      categoryEn:
          _string(json['category_en'] ?? json['categoryEn']) ?? rawCategory,
      categoryAr:
          _string(json['category_ar'] ?? json['categoryAr']) ?? rawCategory,
      images: images.isEmpty ? null : images,
      mainImage: mainImage,
      inStock: _bool(json['in_stock'] ?? json['inStock']) ??
          (_int(json['stock_quantity'] ?? json['stockQuantity']) > 0),
      stockQuantity: _int(json['stock_quantity'] ?? json['stockQuantity']),
      rating: json['rating'] != null
          ? _double(json['rating'])
          : json['average_rating'] != null
              ? _double(json['average_rating'])
              : null,
      reviewCount: _int(json['review_count'] ?? json['reviewCount']),
      specifications: json['specifications'] is Map
          ? Map<String, dynamic>.from(json['specifications'] as Map)
          : null,
      tags:
          _stringList(json['tags']).isEmpty ? null : _stringList(json['tags']),
      discountPercentage: json['discount_percentage'] != null
          ? (json['discount_percentage'] as num).toDouble()
          : null,
      discountedPrice: json['discounted_price'] != null
          ? (json['discounted_price'] as num).toDouble()
          : null,
      isFeatured: _bool(json['is_featured'] ?? json['isFeatured']) ?? false,
      isNew: _bool(json['is_new'] ?? json['isNew']) ?? false,
      createdAt:
          _date(json['created_at'] ?? json['createdAt']) ?? DateTime.now(),
      updatedAt: json['updated_at'] != null || json['updatedAt'] != null
          ? _date(json['updated_at'] ?? json['updatedAt'])
          : null,
    );
  }

  static String? _string(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static double _double(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool? _bool(dynamic value) {
    if (value is bool) return value;
    if (value == null) return null;
    final text = value.toString().toLowerCase();
    if (text == 'true' || text == '1') return true;
    if (text == 'false' || text == '0') return false;
    return null;
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }

  static String? _assetUrl(String? value) {
    final text = _string(value);
    if (text == null) return null;

    final uri = Uri.tryParse(text);
    if (uri != null && uri.hasScheme) return text;

    if (text.startsWith('/')) {
      final baseUri = Uri.parse(ApiConfig.baseUrl);
      return baseUri
          .replace(path: text, query: null, fragment: null)
          .toString();
    }

    return text;
  }

  static DateTime? _date(dynamic value) {
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '');
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_en': nameEn,
      'name_ar': nameAr,
      'description': description,
      'description_en': descriptionEn,
      'description_ar': descriptionAr,
      'price': price,
      'currency': currency,
      'category': category,
      'category_en': categoryEn,
      'category_ar': categoryAr,
      'images': images,
      'main_image': mainImage,
      'in_stock': inStock,
      'stock_quantity': stockQuantity,
      'rating': rating,
      'review_count': reviewCount,
      'specifications': specifications,
      'tags': tags,
      'discount_percentage': discountPercentage,
      'discounted_price': discountedPrice,
      'is_featured': isFeatured,
      'is_new': isNew,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  double get finalPrice => discountedPrice ?? price;

  bool get hasDiscount => discountPercentage != null && discountPercentage! > 0;
}

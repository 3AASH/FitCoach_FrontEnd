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
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      nameEn: json['name_en'] ?? json['nameEn'] as String,
      nameAr: json['name_ar'] ?? json['nameAr'] as String,
      description: json['description'] as String?,
      descriptionEn: json['description_en'] ?? json['descriptionEn'] as String?,
      descriptionAr: json['description_ar'] ?? json['descriptionAr'] as String?,
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'SAR',
      category: json['category'] as String,
      categoryEn: json['category_en'] ?? json['categoryEn'] as String?,
      categoryAr: json['category_ar'] ?? json['categoryAr'] as String?,
      images: json['images'] != null
          ? List<String>.from(json['images'] as List)
          : null,
      mainImage: json['main_image'] ?? json['mainImage'] as String?,
      inStock: json['in_stock'] ?? json['inStock'] as bool? ?? true,
      stockQuantity: json['stock_quantity'] ?? json['stockQuantity'] as int? ?? 0,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      reviewCount: json['review_count'] ?? json['reviewCount'] as int? ?? 0,
      specifications: json['specifications'] as Map<String, dynamic>?,
      tags: json['tags'] != null ? List<String>.from(json['tags'] as List) : null,
      discountPercentage: json['discount_percentage'] != null
          ? (json['discount_percentage'] as num).toDouble()
          : null,
      discountedPrice: json['discounted_price'] != null
          ? (json['discounted_price'] as num).toDouble()
          : null,
      isFeatured: json['is_featured'] ?? json['isFeatured'] as bool? ?? false,
      isNew: json['is_new'] ?? json['isNew'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt'] as String),
      updatedAt: json['updated_at'] != null || json['updatedAt'] != null
          ? DateTime.parse(json['updated_at'] ?? json['updatedAt'] as String)
          : null,
    );
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

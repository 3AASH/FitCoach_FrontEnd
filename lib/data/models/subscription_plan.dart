class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final double monthlyPrice;
  final double? yearlyPrice;
  final String currency;
  final bool isRecommended;
  final String? badge;
  final String accentColor;
  final List<SubscriptionPlanFeature> features;
  final Map<String, dynamic> metadata;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.monthlyPrice,
    this.yearlyPrice,
    this.currency = 'SAR',
    this.isRecommended = false,
    this.badge,
    this.accentColor = '#7C3AED',
    this.features = const [],
    this.metadata = const {},
  });

  bool get isFree => monthlyPrice == 0;
  double get effectiveYearlyPrice => yearlyPrice ?? (monthlyPrice * 12);

  SubscriptionPlan copyWith({
    String? id,
    String? name,
    String? description,
    double? monthlyPrice,
    double? yearlyPrice,
    String? currency,
    bool? isRecommended,
    String? badge,
    String? accentColor,
    List<SubscriptionPlanFeature>? features,
    Map<String, dynamic>? metadata,
  }) {
    return SubscriptionPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      monthlyPrice: monthlyPrice ?? this.monthlyPrice,
      yearlyPrice: yearlyPrice ?? this.yearlyPrice,
      currency: currency ?? this.currency,
      isRecommended: isRecommended ?? this.isRecommended,
      badge: badge ?? this.badge,
      accentColor: accentColor ?? this.accentColor,
      features: features ?? List<SubscriptionPlanFeature>.from(this.features),
      metadata: metadata ?? Map<String, dynamic>.from(this.metadata),
    );
  }

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    final rawFeatures = json['features'];
    final parsedFeatures = rawFeatures is List
        ? rawFeatures.map((item) {
            if (item is Map<String, dynamic>) {
              return SubscriptionPlanFeature.fromJson(item);
            }
            if (item is String) {
              return SubscriptionPlanFeature(
                id: item,
                label: item,
              );
            }
            return null;
          }).whereType<SubscriptionPlanFeature>().toList()
        : const <SubscriptionPlanFeature>[];

    final monthlyPrice = (json['monthlyPrice'] as num?)?.toDouble() ??
        (json['monthly_price'] as num?)?.toDouble() ??
        (json['price'] as num?)?.toDouble() ??
        0;

    final yearlyPrice = (json['yearlyPrice'] as num?)?.toDouble() ??
        (json['yearly_price'] as num?)?.toDouble();

    final metadata = <String, dynamic>{
      ...((json['metadata'] as Map<String, dynamic>?) ?? const {}),
      if (json['message_quota'] != null) 'messagesLimit': json['message_quota'],
      if (json['call_quota'] != null) 'videoCallsLimit': json['call_quota'],
      if (json['has_nutrition_access'] != null)
        'nutritionAccess': json['has_nutrition_access'],
      if (json['has_chat_attachments'] != null)
        'chatAttachments': json['has_chat_attachments'],
    };

    return SubscriptionPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      monthlyPrice: monthlyPrice,
      yearlyPrice: yearlyPrice,
      currency: json['currency'] as String? ?? 'SAR',
      isRecommended: json['isRecommended'] as bool? ?? false,
      badge: json['badge'] as String?,
      accentColor: json['accentColor'] as String? ?? '#7C3AED',
      features: parsedFeatures,
      metadata: metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'monthlyPrice': monthlyPrice,
      'yearlyPrice': yearlyPrice,
      'currency': currency,
      'isRecommended': isRecommended,
      'badge': badge,
      'accentColor': accentColor,
      'features': features.map((feature) => feature.toJson()).toList(),
      'metadata': metadata,
    };
  }
}

class SubscriptionPlanFeature {
  final String id;
  final String label;
  final String category;
  final String? value;
  final int order;

  const SubscriptionPlanFeature({
    required this.id,
    required this.label,
    this.category = 'general',
    this.value,
    this.order = 0,
  });

  SubscriptionPlanFeature copyWith({
    String? id,
    String? label,
    String? category,
    String? value,
    int? order,
  }) {
    return SubscriptionPlanFeature(
      id: id ?? this.id,
      label: label ?? this.label,
      category: category ?? this.category,
      value: value ?? this.value,
      order: order ?? this.order,
    );
  }

  factory SubscriptionPlanFeature.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanFeature(
      id: json['id'] as String,
      label: json['label'] as String,
      category: json['category'] as String? ?? 'general',
      value: json['value'] as String?,
      order: json['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'category': category,
      'value': value,
      'order': order,
    };
  }
}

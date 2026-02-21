class RevenueAnalytics {
  final double total;
  final int transactionCount;
  final List<RevenuePeriod> byPeriod;
  final List<RevenueTier> byTier;

  RevenueAnalytics({
    required this.total,
    required this.transactionCount,
    required this.byPeriod,
    required this.byTier,
  });

  factory RevenueAnalytics.fromJson(Map<String, dynamic> json) {
    return RevenueAnalytics(
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      transactionCount: json['transactionCount'] as int? ?? 0,
      byPeriod: (json['byPeriod'] as List)
          .map((e) => RevenuePeriod.fromJson(e as Map<String, dynamic>))
          .toList(),
      byTier: (json['byTier'] as List)
          .map((e) => RevenueTier.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'transactionCount': transactionCount,
      'byPeriod': byPeriod.map((e) => e.toJson()).toList(),
      'byTier': byTier.map((e) => e.toJson()).toList(),
    };
  }
}

class RevenuePeriod {
  final DateTime period;
  final double revenue;
  final int transactions;

  RevenuePeriod({
    required this.period,
    required this.revenue,
    required this.transactions,
  });

  factory RevenuePeriod.fromJson(Map<String, dynamic> json) {
    return RevenuePeriod(
      period: DateTime.parse(json['period'] as String),
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
      transactions: json['transactions'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'period': period.toIso8601String(),
      'revenue': revenue,
      'transactions': transactions,
    };
  }
}

class RevenueTier {
  final String subscriptionTier;
  final double revenue;
  final int count;

  RevenueTier({
    required this.subscriptionTier,
    required this.revenue,
    required this.count,
  });

  factory RevenueTier.fromJson(Map<String, dynamic> json) {
    return RevenueTier(
      subscriptionTier: json['subscription_tier'] as String,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
      count: json['count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subscription_tier': subscriptionTier,
      'revenue': revenue,
      'count': count,
    };
  }
}

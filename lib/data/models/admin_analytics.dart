class AdminAnalytics {
  final UserStats users;
  final CoachStats coaches;
  final List<SubscriptionDistribution> subscriptions;
  final RevenueStats revenue;
  final GrowthStats growth;
  final SessionStats sessions;

  AdminAnalytics({
    required this.users,
    required this.coaches,
    required this.subscriptions,
    required this.revenue,
    required this.growth,
    required this.sessions,
  });

  factory AdminAnalytics.fromJson(Map<String, dynamic> json) {
    return AdminAnalytics(
      users: UserStats.fromJson(json['users'] as Map<String, dynamic>),
      coaches: CoachStats.fromJson(json['coaches'] as Map<String, dynamic>),
      subscriptions: (json['subscriptions'] as List)
          .map((e) => SubscriptionDistribution.fromJson(e as Map<String, dynamic>))
          .toList(),
      revenue: RevenueStats.fromJson(json['revenue'] as Map<String, dynamic>),
      growth: GrowthStats.fromJson(json['growth'] as Map<String, dynamic>),
      sessions: SessionStats.fromJson(json['sessions'] as Map<String, dynamic>),
    );
  }
}

class UserStats {
  final int total;
  final int active;

  UserStats({required this.total, required this.active});

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      total: json['total'] as int? ?? 0,
      active: json['active'] as int? ?? 0,
    );
  }
}

class CoachStats {
  final int total;
  final int active;

  CoachStats({required this.total, required this.active});

  factory CoachStats.fromJson(Map<String, dynamic> json) {
    return CoachStats(
      total: json['total'] as int? ?? 0,
      active: json['active'] as int? ?? 0,
    );
  }
}

class SubscriptionDistribution {
  final String subscriptionTier;
  final int count;

  SubscriptionDistribution({
    required this.subscriptionTier,
    required this.count,
  });

  factory SubscriptionDistribution.fromJson(Map<String, dynamic> json) {
    return SubscriptionDistribution(
      subscriptionTier: json['subscription_tier'] as String,
      count: json['count'] as int? ?? 0,
    );
  }
}

class RevenueStats {
  final double last30Days;

  RevenueStats({required this.last30Days});

  factory RevenueStats.fromJson(Map<String, dynamic> json) {
    return RevenueStats(
      last30Days: (json['last30Days'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class GrowthStats {
  final int newUsersLast7Days;

  GrowthStats({required this.newUsersLast7Days});

  factory GrowthStats.fromJson(Map<String, dynamic> json) {
    return GrowthStats(
      newUsersLast7Days: json['newUsersLast7Days'] as int? ?? 0,
    );
  }
}

class SessionStats {
  final int today;

  SessionStats({required this.today});

  factory SessionStats.fromJson(Map<String, dynamic> json) {
    return SessionStats(
      today: json['today'] as int? ?? 0,
    );
  }
}

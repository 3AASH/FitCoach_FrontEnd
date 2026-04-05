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
    final root = _asMap(json['analytics']) ?? _asMap(json['data']) ?? json;
    return AdminAnalytics(
      users: UserStats.fromJson(_asMap(root['users']) ?? const {}),
      coaches: CoachStats.fromJson(_asMap(root['coaches']) ?? const {}),
      subscriptions: _asList(
              root['subscriptions'] ?? root['subscription_distribution'])
          .map((e) => SubscriptionDistribution.fromJson(_asMap(e) ?? const {}))
          .toList(),
      revenue: RevenueStats.fromJson(_asMap(root['revenue']) ?? const {}),
      growth: GrowthStats.fromJson(_asMap(root['growth']) ?? const {}),
      sessions: SessionStats.fromJson(_asMap(root['sessions']) ?? const {}),
    );
  }
}

class UserStats {
  final int total;
  final int active;

  UserStats({required this.total, required this.active});

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      total: _asInt(json['total'], fallback: 0),
      active: _asInt(json['active'], fallback: 0),
    );
  }
}

class CoachStats {
  final int total;
  final int active;

  CoachStats({required this.total, required this.active});

  factory CoachStats.fromJson(Map<String, dynamic> json) {
    return CoachStats(
      total: _asInt(json['total'], fallback: 0),
      active: _asInt(json['active'], fallback: 0),
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
      subscriptionTier: _asString(
        json['subscription_tier'] ?? json['subscriptionTier'] ?? json['tier'],
        fallback: 'freemium',
      ),
      count: _asInt(json['count'], fallback: 0),
    );
  }
}

class RevenueStats {
  final double last30Days;

  RevenueStats({required this.last30Days});

  factory RevenueStats.fromJson(Map<String, dynamic> json) {
    return RevenueStats(
      last30Days: _asDouble(
        json['last30Days'] ??
            json['last_30_days'] ??
            json['thirty_day_revenue'],
        fallback: 0,
      ),
    );
  }
}

class GrowthStats {
  final int newUsersLast7Days;

  GrowthStats({required this.newUsersLast7Days});

  factory GrowthStats.fromJson(Map<String, dynamic> json) {
    return GrowthStats(
      newUsersLast7Days: _asInt(
        json['newUsersLast7Days'] ??
            json['new_users_last_7_days'] ??
            json['new_users_7d'],
        fallback: 0,
      ),
    );
  }
}

class SessionStats {
  final int today;

  SessionStats({required this.today});

  factory SessionStats.fromJson(Map<String, dynamic> json) {
    return SessionStats(
      today: _asInt(json['today'] ?? json['today_sessions'], fallback: 0),
    );
  }
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

List<dynamic> _asList(dynamic value) {
  if (value is List) return value;
  return const [];
}

String _asString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

int _asInt(dynamic value, {required int fallback}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

double _asDouble(dynamic value, {required double fallback}) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

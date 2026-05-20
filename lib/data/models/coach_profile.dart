class CoachProfile {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String bio;
  final int yearsOfExperience;
  final List<String> specializations;
  final bool isVerified;
  final String? avatar;
  final CoachStats stats;
  final List<Map<String, dynamic>> certificates;
  final List<Map<String, dynamic>> experiences;
  final List<Map<String, dynamic>> achievements;

  CoachProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.bio,
    required this.yearsOfExperience,
    required this.specializations,
    required this.isVerified,
    required this.avatar,
    required this.stats,
    required this.certificates,
    required this.experiences,
    required this.achievements,
  });

  factory CoachProfile.fromJson(Map<String, dynamic> json) {
    return CoachProfile(
      id: _asString(json['id']) ??
          _asString(json['userId']) ??
          _asString(json['coachId']) ??
          '',
      name: _asString(json['name']) ??
          _asString(json['full_name']) ??
          _asString(json['fullName']) ??
          '',
      email: _asString(json['email']) ?? '',
      phone: _asString(json['phone']) ??
          _asString(json['phone_number']) ??
          _asString(json['phoneNumber']) ??
          '',
      bio: _asString(json['bio']) ?? _asString(json['description']) ?? '',
      yearsOfExperience: _asInt(
            json['yearsOfExperience'] ?? json['experience_years'],
          ) ??
          0,
      specializations: _parseSpecializations(json['specializations']),
      isVerified: _asBool(json['isVerified'] ?? json['is_verified']) ?? false,
      avatar: _asString(json['avatar']) ??
          _asString(json['profile_photo_url']) ??
          _asString(json['profilePhotoUrl']),
      stats: CoachStats.fromJson(_asMap(json['stats']) ?? const {}),
      certificates: _parseObjectList(json['certificates']),
      experiences: _parseObjectList(json['experiences']),
      achievements: _parseObjectList(json['achievements']),
    );
  }

  static String? _asString(dynamic value) {
    if (value == null) {
      return null;
    }
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static int? _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim());
    }
    return null;
  }

  static bool? _asBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') {
        return true;
      }
      if (normalized == 'false' || normalized == '0') {
        return false;
      }
    }
    return null;
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return null;
  }

  static List<Map<String, dynamic>> _parseObjectList(dynamic value) {
    if (value is! List) {
      return const [];
    }

    return value
        .map(_asMap)
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  static List<String> _parseSpecializations(dynamic value) {
    if (value is List) {
      return value
          .map((entry) => entry.toString().trim())
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false);
    }
    if (value is String) {
      final cleaned = value
          .replaceAll('[', '')
          .replaceAll(']', '')
          .trim();
      if (cleaned.isEmpty) {
        return const [];
      }
      return cleaned
          .split(',')
          .map((entry) => entry.trim())
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false);
    }
    return const [];
  }
}

class CoachStats {
  final int totalClients;
  final int activeClients;
  final int completedSessions;
  final double avgRating;
  final int reviewCount;
  final double totalRevenue;

  CoachStats({
    required this.totalClients,
    required this.activeClients,
    required this.completedSessions,
    required this.avgRating,
    required this.reviewCount,
    required this.totalRevenue,
  });

  factory CoachStats.fromJson(Map<String, dynamic> json) {
    return CoachStats(
      totalClients: _asInt(json['totalClients'] ?? json['total_clients']) ?? 0,
      activeClients:
          _asInt(json['activeClients'] ?? json['active_clients']) ?? 0,
      completedSessions:
          _asInt(json['completedSessions'] ?? json['completed_sessions']) ?? 0,
      avgRating:
          _asDouble(json['avgRating'] ?? json['average_rating']) ?? 0.0,
      reviewCount: _asInt(json['reviewCount'] ?? json['review_count']) ?? 0,
      totalRevenue:
          _asDouble(json['totalRevenue'] ?? json['total_revenue']) ?? 0.0,
    );
  }

  static int? _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim());
    }
    return null;
  }

  static double? _asDouble(dynamic value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value.trim());
    }
    return null;
  }
}

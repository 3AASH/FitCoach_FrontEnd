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
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      bio: json['bio'] as String,
      yearsOfExperience: json['yearsOfExperience'] as int? ?? 0,
      specializations: (json['specializations'] as List?)?.map((e) => e.toString()).toList() ?? [],
      isVerified: json['isVerified'] as bool? ?? false,
      avatar: json['avatar'] as String?,
      stats: CoachStats.fromJson(json['stats'] as Map<String, dynamic>),
      certificates: (json['certificates'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [],
      experiences: (json['experiences'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [],
      achievements: (json['achievements'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [],
    );
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
      totalClients: json['totalClients'] as int? ?? 0,
      activeClients: json['activeClients'] as int? ?? 0,
      completedSessions: json['completedSessions'] as int? ?? 0,
      avgRating: (json['avgRating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class Certificate {
  final String id;
  final String name;
  final String issuingOrganization;
  final DateTime dateObtained;
  final DateTime? expiryDate;
  final String? certificateUrl;

  Certificate({
    required this.id,
    required this.name,
    required this.issuingOrganization,
    required this.dateObtained,
    this.expiryDate,
    this.certificateUrl,
  });

  factory Certificate.fromJson(Map<String, dynamic> json) {
    return Certificate(
      id: json['id'] as String,
      name: json['name'] as String,
      issuingOrganization: json['issuing_organization'] as String,
      dateObtained: DateTime.parse(json['date_obtained'] as String),
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'] as String)
          : null,
      certificateUrl: json['certificate_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'issuing_organization': issuingOrganization,
      'date_obtained': dateObtained.toIso8601String(),
      'expiry_date': expiryDate?.toIso8601String(),
      'certificate_url': certificateUrl,
    };
  }
}

class WorkExperience {
  final String id;
  final String title;
  final String organization;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isCurrent;
  final String description;

  WorkExperience({
    required this.id,
    required this.title,
    required this.organization,
    required this.startDate,
    this.endDate,
    required this.isCurrent,
    required this.description,
  });

  factory WorkExperience.fromJson(Map<String, dynamic> json) {
    return WorkExperience(
      id: json['id'] as String,
      title: json['title'] as String,
      organization: json['organization'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      isCurrent: json['is_current'] as bool? ?? false,
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'organization': organization,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'is_current': isCurrent,
      'description': description,
    };
  }

  String get duration {
    final end = isCurrent ? DateTime.now() : (endDate ?? DateTime.now());
    final years = end.difference(startDate).inDays ~/ 365;
    final months = (end.difference(startDate).inDays % 365) ~/ 30;
    
    if (years > 0 && months > 0) {
      return '$years yr $months mo';
    } else if (years > 0) {
      return '$years year${years > 1 ? 's' : ''}';
    } else {
      return '$months month${months > 1 ? 's' : ''}';
    }
  }
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String type; // medal, award, recognition

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.type,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      date: DateTime.parse(json['date'] as String),
      type: json['type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'type': type,
    };
  }
}

class PublicCoachProfile {
  final String id;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? bio;
  final int yearsOfExperience;
  final List<String> specializations;
  final bool isVerified;
  final bool isApproved;
  final double? averageRating;
  final int totalClients;
  final int activeClients;
  final int completedSessions;
  final double successRate;
  final String? profilePhotoUrl;
  final List<Certificate> certificates;
  final List<WorkExperience> experiences;
  final List<Achievement> achievements;
  final DateTime createdAt;

  PublicCoachProfile({
    required this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.bio,
    required this.yearsOfExperience,
    required this.specializations,
    required this.isVerified,
    required this.isApproved,
    this.averageRating,
    required this.totalClients,
    required this.activeClients,
    required this.completedSessions,
    required this.successRate,
    this.profilePhotoUrl,
    required this.certificates,
    required this.experiences,
    required this.achievements,
    required this.createdAt,
  });

  factory PublicCoachProfile.fromJson(Map<String, dynamic> json) {
    return PublicCoachProfile(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      phoneNumber: json['phone_number'] as String?,
      bio: json['bio'] as String?,
      yearsOfExperience: json['years_of_experience'] as int? ?? 0,
      specializations: (json['specializations'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      isVerified: json['is_verified'] as bool? ?? false,
      isApproved: json['is_approved'] as bool? ?? false,
      averageRating: (json['average_rating'] as num?)?.toDouble(),
      totalClients: json['total_clients'] as int? ?? 0,
      activeClients: json['active_clients'] as int? ?? 0,
      completedSessions: json['completed_sessions'] as int? ?? 0,
      successRate: (json['success_rate'] as num?)?.toDouble() ?? 0.0,
      profilePhotoUrl: json['profile_photo_url'] as String?,
      certificates: (json['certificates'] as List<dynamic>?)
              ?.map((e) => Certificate.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      experiences: (json['experiences'] as List<dynamic>?)
              ?.map((e) => WorkExperience.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      achievements: (json['achievements'] as List<dynamic>?)
              ?.map((e) => Achievement.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'bio': bio,
      'years_of_experience': yearsOfExperience,
      'specializations': specializations,
      'is_verified': isVerified,
      'is_approved': isApproved,
      'average_rating': averageRating,
      'total_clients': totalClients,
      'active_clients': activeClients,
      'completed_sessions': completedSessions,
      'success_rate': successRate,
      'profile_photo_url': profilePhotoUrl,
      'certificates': certificates.map((c) => c.toJson()).toList(),
      'experiences': experiences.map((e) => e.toJson()).toList(),
      'achievements': achievements.map((a) => a.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get initials {
    final names = fullName.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return fullName.substring(0, 1).toUpperCase();
  }

  String get experienceText {
    if (yearsOfExperience == 1) {
      return '1 year';
    } else {
      return '$yearsOfExperience years';
    }
  }

  String get ratingText {
    if (averageRating == null) return 'No ratings';
    return averageRating!.toStringAsFixed(1);
  }

  bool get hasCredentials {
    return certificates.isNotEmpty || experiences.isNotEmpty || achievements.isNotEmpty;
  }
}

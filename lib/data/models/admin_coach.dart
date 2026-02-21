class AdminCoach {
  final String id;
  final String userId;
  final String fullName;
  final String? email;
  final String? phoneNumber;
  final String? profilePhotoUrl;
  final List<String> specializations;
  final int clientCount;
  final double totalEarnings;
  final double? averageRating;
  final bool isApproved;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? approvedAt;

  AdminCoach({
    required this.id,
    required this.userId,
    required this.fullName,
    this.email,
    this.phoneNumber,
    this.profilePhotoUrl,
    required this.specializations,
    required this.clientCount,
    required this.totalEarnings,
    this.averageRating,
    required this.isApproved,
    required this.isActive,
    required this.createdAt,
    this.approvedAt,
  });

  factory AdminCoach.fromJson(Map<String, dynamic> json) {
    return AdminCoach(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String?,
      phoneNumber: json['phone_number'] as String?,
      profilePhotoUrl: json['profile_photo_url'] as String?,
      specializations: json['specializations'] != null
          ? List<String>.from(json['specializations'] as List)
          : [],
      clientCount: int.tryParse(json['client_count'].toString()) ?? 0,
      totalEarnings: (json['total_earnings'] as num?)?.toDouble() ?? 0.0,
      averageRating: (json['average_rating'] as num?)?.toDouble(),
      isApproved: json['is_approved'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'profile_photo_url': profilePhotoUrl,
      'specializations': specializations,
      'client_count': clientCount,
      'total_earnings': totalEarnings,
      'average_rating': averageRating,
      'is_approved': isApproved,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'approved_at': approvedAt?.toIso8601String(),
    };
  }

  String get initials {
    final names = fullName.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }

  bool get isPending => !isApproved;
}

class AdminCoach {
  final String id;
  final String userId;
  final String fullName;
  final String? fullNameAr;
  final String? email;
  final String? phoneNumber;
  final String? profilePhotoUrl;
  final String? bio;
  final int? experienceYears;
  final List<String> specializations;
  final int clientCount;
  final double totalEarnings;
  final double? averageRating;
  final bool isApproved;
  final bool isActive;
  final String? status;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final DateTime? suspendedAt;
  final String? suspensionReason;
  final DateTime? updatedAt;

  AdminCoach({
    required this.id,
    required this.userId,
    required this.fullName,
    this.fullNameAr,
    this.email,
    this.phoneNumber,
    this.profilePhotoUrl,
    this.bio,
    this.experienceYears,
    required this.specializations,
    required this.clientCount,
    required this.totalEarnings,
    this.averageRating,
    required this.isApproved,
    required this.isActive,
    this.status,
    required this.createdAt,
    this.approvedAt,
    this.suspendedAt,
    this.suspensionReason,
    this.updatedAt,
  });

  AdminCoach copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? fullNameAr,
    String? email,
    String? phoneNumber,
    String? profilePhotoUrl,
    String? bio,
    int? experienceYears,
    List<String>? specializations,
    int? clientCount,
    double? totalEarnings,
    double? averageRating,
    bool? isApproved,
    bool? isActive,
    String? status,
    DateTime? createdAt,
    DateTime? approvedAt,
    DateTime? suspendedAt,
    String? suspensionReason,
    DateTime? updatedAt,
  }) {
    return AdminCoach(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      fullNameAr: fullNameAr ?? this.fullNameAr,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      bio: bio ?? this.bio,
      experienceYears: experienceYears ?? this.experienceYears,
      specializations: specializations ?? this.specializations,
      clientCount: clientCount ?? this.clientCount,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      averageRating: averageRating ?? this.averageRating,
      isApproved: isApproved ?? this.isApproved,
      isActive: isActive ?? this.isActive,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
      suspendedAt: suspendedAt ?? this.suspendedAt,
      suspensionReason: suspensionReason ?? this.suspensionReason,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory AdminCoach.fromJson(Map<String, dynamic> json) {
    final userMap = _asMap(json['user']);
    final resolvedStatus = _asNullableString(json['status']) ??
        _deriveStatus(
          isApproved: _asBool(
            json['is_approved'] ?? json['isApproved'],
            fallback: false,
          ),
          isActive: _asBool(
            json['is_active'] ?? json['isActive'],
            fallback: false,
          ),
          suspendedAt: _asNullableDateTime(
            json['suspended_at'] ?? json['suspendedAt'],
          ),
        );

    return AdminCoach(
      id: _asString(json['id'] ?? json['_id']),
      userId: _asString(
        json['user_id'] ??
            json['userId'] ??
            userMap?['id'] ??
            userMap?['_id'] ??
            json['id'],
      ),
      fullName: _asString(
        json['full_name'] ??
            json['fullName'] ??
            userMap?['full_name'] ??
            userMap?['fullName'] ??
            json['name'],
        fallback: 'Unknown Coach',
      ),
      fullNameAr: _asNullableString(
        json['full_name_ar'] ?? json['fullNameAr'] ?? userMap?['full_name_ar'],
      ),
      email: _asNullableString(json['email'] ?? userMap?['email']),
      phoneNumber: _asNullableString(
        json['phone_number'] ?? json['phoneNumber'],
      ),
      profilePhotoUrl: _asNullableString(
        json['profile_photo_url'] ??
            json['profilePhotoUrl'] ??
            userMap?['profile_photo_url'],
      ),
      bio: _asNullableString(json['bio'] ?? userMap?['bio']),
      experienceYears: _asNullableInt(
        json['experience_years'] ?? json['yearsOfExperience'],
      ),
      specializations: _asStringList(
        json['specializations'] ?? json['specialties'],
      ),
      clientCount:
          _asInt(json['client_count'] ?? json['clientCount'], fallback: 0),
      totalEarnings: _asDouble(
        json['total_earnings'] ?? json['totalEarnings'],
        fallback: 0,
      ),
      averageRating: _asNullableDouble(
        json['average_rating'] ?? json['averageRating'],
      ),
      isApproved: _asBool(
        json['is_approved'] ?? json['isApproved'],
        fallback: false,
      ),
      isActive: _asBool(
        json['is_active'] ?? json['isActive'],
        fallback: false,
      ),
      status: resolvedStatus,
      createdAt: _asDateTime(
        json['created_at'] ?? json['createdAt'],
        fallback: DateTime.now(),
      ),
      approvedAt:
          _asNullableDateTime(json['approved_at'] ?? json['approvedAt']),
      suspendedAt: _asNullableDateTime(
        json['suspended_at'] ?? json['suspendedAt'],
      ),
      suspensionReason: _asNullableString(
        json['suspension_reason'] ?? json['suspensionReason'],
      ),
      updatedAt: _asNullableDateTime(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'full_name': fullName,
      'full_name_ar': fullNameAr,
      'email': email,
      'phone_number': phoneNumber,
      'profile_photo_url': profilePhotoUrl,
      'bio': bio,
      'experience_years': experienceYears,
      'specializations': specializations,
      'client_count': clientCount,
      'total_earnings': totalEarnings,
      'average_rating': averageRating,
      'is_approved': isApproved,
      'is_active': isActive,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'approved_at': approvedAt?.toIso8601String(),
      'suspended_at': suspendedAt?.toIso8601String(),
      'suspension_reason': suspensionReason,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  String get initials {
    final names = fullName.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }

  bool get isPending => effectiveStatus == 'pending';
  bool get isSuspended => effectiveStatus == 'suspended';
  String get effectiveStatus => status?.trim().toLowerCase().isNotEmpty == true
      ? status!.trim().toLowerCase()
      : _deriveStatus(
          isApproved: isApproved,
          isActive: isActive,
          suspendedAt: suspendedAt,
        );
}

String _deriveStatus({
  required bool isApproved,
  required bool isActive,
  required DateTime? suspendedAt,
}) {
  if (suspendedAt != null || !isActive) {
    return 'suspended';
  }
  if (!isApproved) {
    return 'pending';
  }
  return 'approved';
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

String _asString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

String? _asNullableString(dynamic value) {
  final text = _asString(value);
  return text.isEmpty ? null : text;
}

List<String> _asStringList(dynamic value) {
  if (value is List) return value.map((e) => e.toString()).toList();
  if (value is String) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
  return const [];
}

int _asInt(dynamic value, {required int fallback}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

int? _asNullableInt(dynamic value) {
  if (value == null) return null;
  return _asInt(value, fallback: 0);
}

double _asDouble(dynamic value, {required double fallback}) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

double? _asNullableDouble(dynamic value) {
  if (value == null) return null;
  return _asDouble(value, fallback: 0);
}

bool _asBool(dynamic value, {required bool fallback}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
      return true;
    }
    if (normalized == 'false' || normalized == '0' || normalized == 'no') {
      return false;
    }
  }
  return fallback;
}

DateTime _asDateTime(dynamic value, {required DateTime fallback}) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value) ?? fallback;
  return fallback;
}

DateTime? _asNullableDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

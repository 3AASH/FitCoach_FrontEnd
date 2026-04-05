class AdminUser {
  final String id;
  final String fullName;
  final String? email;
  final String? phoneNumber;
  final String? profilePhotoUrl;
  final String subscriptionTier;
  final bool isActive;
  final String? coachId;
  final String? coachName;
  final DateTime createdAt;
  final DateTime? lastLogin;

  AdminUser({
    required this.id,
    required this.fullName,
    this.email,
    this.phoneNumber,
    this.profilePhotoUrl,
    required this.subscriptionTier,
    required this.isActive,
    this.coachId,
    this.coachName,
    required this.createdAt,
    this.lastLogin,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    final coachMap = _asMap(json['coach']);
    return AdminUser(
      id: _asString(json['id'] ?? json['_id']),
      fullName: _asString(
        json['full_name'] ?? json['fullName'] ?? json['name'],
        fallback: 'Unknown User',
      ),
      email: _asNullableString(json['email']),
      phoneNumber:
          _asNullableString(json['phone_number'] ?? json['phoneNumber']),
      profilePhotoUrl: _asNullableString(json['profile_photo_url'] ??
          json['profilePhotoUrl'] ??
          json['avatar']),
      subscriptionTier: _asString(
        json['subscription_tier'] ?? json['subscriptionTier'] ?? json['tier'],
        fallback: 'freemium',
      ),
      isActive: _asBool(json['is_active'] ?? json['isActive'], fallback: false),
      coachId: _asNullableString(
        json['coach_id'] ??
            json['coachId'] ??
            coachMap?['id'] ??
            coachMap?['_id'],
      ),
      coachName: _asNullableString(
        json['coach_name'] ??
            json['coachName'] ??
            coachMap?['full_name'] ??
            coachMap?['fullName'],
      ),
      createdAt: _asDateTime(
        json['created_at'] ?? json['createdAt'],
        fallback: DateTime.now(),
      ),
      lastLogin: _asNullableDateTime(json['last_login'] ?? json['lastLogin']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'profile_photo_url': profilePhotoUrl,
      'subscription_tier': subscriptionTier,
      'is_active': isActive,
      'coach_id': coachId,
      'coach_name': coachName,
      'created_at': createdAt.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
    };
  }

  String get initials {
    final names = fullName.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }
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

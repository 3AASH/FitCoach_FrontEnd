class CoachClient {
  final String id;
  final String fullName;
  final String? email;
  final String? phoneNumber;
  final String? profilePhotoUrl;
  final String subscriptionTier;
  final String? goal;
  final bool isActive;
  final bool? coachAssignmentActive;
  final DateTime? assignedDate;
  final DateTime? lastActivity;
  final DateTime? latestInbodyScanDate;
  final double? latestWeight;
  final double? latestBodyFatPercentage;
  final double? latestSkeletalMuscleMass;
  final int? fitnessScore;
  final String? workoutPlanId;
  final String? workoutPlanName;
  final String? nutritionPlanId;
  final String? nutritionPlanName;
  final int messageCount;

  CoachClient({
    required this.id,
    required this.fullName,
    this.email,
    this.phoneNumber,
    this.profilePhotoUrl,
    required this.subscriptionTier,
    this.goal,
    required this.isActive,
    this.coachAssignmentActive,
    this.assignedDate,
    this.lastActivity,
    this.latestInbodyScanDate,
    this.latestWeight,
    this.latestBodyFatPercentage,
    this.latestSkeletalMuscleMass,
    this.fitnessScore,
    this.workoutPlanId,
    this.workoutPlanName,
    this.nutritionPlanId,
    this.nutritionPlanName,
    this.messageCount = 0,
  });

  CoachClient copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? profilePhotoUrl,
    String? subscriptionTier,
    String? goal,
    bool? isActive,
    bool? coachAssignmentActive,
    DateTime? assignedDate,
    DateTime? lastActivity,
    DateTime? latestInbodyScanDate,
    double? latestWeight,
    double? latestBodyFatPercentage,
    double? latestSkeletalMuscleMass,
    int? fitnessScore,
    String? workoutPlanId,
    String? workoutPlanName,
    String? nutritionPlanId,
    String? nutritionPlanName,
    int? messageCount,
  }) {
    return CoachClient(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      goal: goal ?? this.goal,
      isActive: isActive ?? this.isActive,
      coachAssignmentActive:
          coachAssignmentActive ?? this.coachAssignmentActive,
      assignedDate: assignedDate ?? this.assignedDate,
      lastActivity: lastActivity ?? this.lastActivity,
      latestInbodyScanDate: latestInbodyScanDate ?? this.latestInbodyScanDate,
      latestWeight: latestWeight ?? this.latestWeight,
      latestBodyFatPercentage:
          latestBodyFatPercentage ?? this.latestBodyFatPercentage,
      latestSkeletalMuscleMass:
          latestSkeletalMuscleMass ?? this.latestSkeletalMuscleMass,
      fitnessScore: fitnessScore ?? this.fitnessScore,
      workoutPlanId: workoutPlanId ?? this.workoutPlanId,
      workoutPlanName: workoutPlanName ?? this.workoutPlanName,
      nutritionPlanId: nutritionPlanId ?? this.nutritionPlanId,
      nutritionPlanName: nutritionPlanName ?? this.nutritionPlanName,
      messageCount: messageCount ?? this.messageCount,
    );
  }

  factory CoachClient.fromJson(Map<String, dynamic> json) {
    final assignment = _asMap(json['coach_assignment']);
    return CoachClient(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      fullName: (json['full_name'] ?? json['fullName'] ?? json['name'] ?? '')
          .toString(),
      email: _asNullableString(json['email']),
      phoneNumber:
          _asNullableString(json['phone_number'] ?? json['phoneNumber']),
      profilePhotoUrl: _asNullableString(
        json['profile_photo_url'] ?? json['profilePhotoUrl'],
      ),
      subscriptionTier:
          (json['subscription_tier'] ?? json['subscriptionTier'] ?? 'freemium')
              .toString(),
      goal: _asNullableString(json['goal']),
      isActive: parseBool(json['is_active'] ?? json['isActive']) ?? true,
      coachAssignmentActive: parseBool(
        json['coach_assignment_active'] ??
            json['coachAssignmentActive'] ??
            assignment?['is_active'] ??
            assignment?['isActive'],
      ),
      assignedDate: _asDateTime(json['assigned_date'] ?? json['assignedDate']),
      lastActivity: _asDateTime(json['last_activity'] ?? json['lastActivity']),
      latestInbodyScanDate: _asDateTime(
        json['latest_inbody_scan_date'] ?? json['latestInbodyScanDate'],
      ),
      latestWeight: _asDouble(json['latest_weight'] ?? json['latestWeight']),
      latestBodyFatPercentage: _asDouble(
        json['latest_body_fat_percentage'] ?? json['latestBodyFatPercentage'],
      ),
      latestSkeletalMuscleMass: _asDouble(
        json['latest_skeletal_muscle_mass'] ?? json['latestSkeletalMuscleMass'],
      ),
      fitnessScore: _asInt(json['fitness_score'] ?? json['fitnessScore']),
      workoutPlanId:
          _asNullableString(json['workout_plan_id'] ?? json['workoutPlanId']),
      workoutPlanName: _asNullableString(
        json['workout_plan_name'] ?? json['workoutPlanName'],
      ),
      nutritionPlanId: _asNullableString(
        json['nutrition_plan_id'] ?? json['nutritionPlanId'],
      ),
      nutritionPlanName: _asNullableString(
        json['nutrition_plan_name'] ?? json['nutritionPlanName'],
      ),
      messageCount: _asInt(json['message_count'] ?? json['messageCount']) ?? 0,
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
      'goal': goal,
      'is_active': isActive,
      'coach_assignment_active': coachAssignmentActive,
      'assigned_date': assignedDate?.toIso8601String(),
      'last_activity': lastActivity?.toIso8601String(),
      'latest_inbody_scan_date': latestInbodyScanDate?.toIso8601String(),
      'latest_weight': latestWeight,
      'latest_body_fat_percentage': latestBodyFatPercentage,
      'latest_skeletal_muscle_mass': latestSkeletalMuscleMass,
      'fitness_score': fitnessScore,
      'workout_plan_id': workoutPlanId,
      'workout_plan_name': workoutPlanName,
      'nutrition_plan_id': nutritionPlanId,
      'nutrition_plan_name': nutritionPlanName,
      'message_count': messageCount,
    };
  }

  String get initials {
    final names = fullName.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }

  String get statusText {
    if (!isActive) return 'Inactive';
    if (lastActivity == null) return 'New';

    final daysSinceActivity = DateTime.now().difference(lastActivity!).inDays;
    if (daysSinceActivity < 1) return 'Active';
    if (daysSinceActivity < 7) return 'Recent';
    return 'Inactive';
  }
}

bool? parseBool(dynamic v) {
  if (v == null) return null;
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final normalized = v.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
      return true;
    }
    if (normalized == 'false' || normalized == '0' || normalized == 'no') {
      return false;
    }
  }
  return null;
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

String? _asNullableString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

DateTime? _asDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double? _asDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

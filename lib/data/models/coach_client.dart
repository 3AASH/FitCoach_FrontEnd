class CoachClient {
  final String id;
  final String fullName;
  final String? email;
  final String? phoneNumber;
  final String? profilePhotoUrl;
  final String subscriptionTier;
  final String? goal;
  final bool isActive;
  final DateTime? assignedDate;
  final DateTime? lastActivity;
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
    this.assignedDate,
    this.lastActivity,
    this.fitnessScore,
    this.workoutPlanId,
    this.workoutPlanName,
    this.nutritionPlanId,
    this.nutritionPlanName,
    this.messageCount = 0,
  });

  factory CoachClient.fromJson(Map<String, dynamic> json) {
    return CoachClient(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String?,
      phoneNumber: json['phone_number'] as String?,
      profilePhotoUrl: json['profile_photo_url'] as String?,
      subscriptionTier: json['subscription_tier'] as String? ?? 'freemium',
      goal: json['goal'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      assignedDate: json['assigned_date'] != null
          ? DateTime.parse(json['assigned_date'] as String)
          : null,
      lastActivity: json['last_activity'] != null
          ? DateTime.parse(json['last_activity'] as String)
          : null,
      fitnessScore: json['fitness_score'] as int?,
      workoutPlanId: json['workout_plan_id'] as String?,
      workoutPlanName: json['workout_plan_name'] as String?,
      nutritionPlanId: json['nutrition_plan_id'] as String?,
      nutritionPlanName: json['nutrition_plan_name'] as String?,
      messageCount: json['message_count'] as int? ?? 0,
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
      'assigned_date': assignedDate?.toIso8601String(),
      'last_activity': lastActivity?.toIso8601String(),
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

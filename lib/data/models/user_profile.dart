import 'package:hive/hive.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 0)
class UserProfile {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String phoneNumber;

  @HiveField(3)
  final String? email;

  @HiveField(4)
  final int? age;

  @HiveField(5)
  final double? weight;

  @HiveField(6)
  final int? height;

  @HiveField(7)
  final String? gender;

  @HiveField(8)
  final int? workoutFrequency;

  @HiveField(9)
  final String? workoutLocation;

  @HiveField(10)
  final String? experienceLevel;

  @HiveField(11)
  final String? mainGoal;

  @HiveField(12)
  final List<String> injuries;

  @HiveField(13)
  final String subscriptionTier;

  @HiveField(14)
  final String? coachId;

  @HiveField(15)
  final bool hasCompletedFirstIntake;

  @HiveField(16)
  final bool hasCompletedSecondIntake;

  @HiveField(17)
  final int? fitnessScore;

  @HiveField(18)
  final String? fitnessScoreUpdatedBy;

  @HiveField(19)
  final DateTime? fitnessScoreLastUpdated;

  @HiveField(20)
  final String role;

  UserProfile({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.email,
    this.age,
    this.weight,
    this.height,
    this.gender,
    this.workoutFrequency,
    this.workoutLocation,
    this.experienceLevel,
    this.mainGoal,
    this.injuries = const [],
    this.subscriptionTier = 'Freemium',
    this.coachId,
    this.hasCompletedFirstIntake = false,
    this.hasCompletedSecondIntake = false,
    this.fitnessScore,
    this.fitnessScoreUpdatedBy,
    this.fitnessScoreLastUpdated,
    this.role = 'user',
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final source = _profileMap(json);
    return UserProfile(
      id: source['id'] as String,
      name: (source['name'] ?? source['full_name'] ?? 'User') as String,
      phoneNumber:
          (source['phoneNumber'] ?? source['phone_number'] ?? '') as String,
      email: source['email'] as String?,
      age: source['age'] as int?,
      weight: source['weight'] != null
          ? (source['weight'] as num).toDouble()
          : null,
      height: source['height'] as int?,
      gender: source['gender'] as String?,
      workoutFrequency: source['workoutFrequency'] as int? ??
          source['workout_frequency'] as int?,
      workoutLocation: source['workoutLocation'] as String? ??
          source['workout_location'] as String?,
      experienceLevel: source['experienceLevel'] as String? ??
          source['experience_level'] as String?,
      mainGoal: source['mainGoal'] as String? ?? source['goal'] as String?,
      injuries: source['injuries'] != null
          ? List<String>.from(source['injuries'] as List)
          : [],
      subscriptionTier: source['subscriptionTier'] as String? ??
          source['subscription_tier'] as String? ??
          'Freemium',
      coachId: source['coachId'] as String? ??
          source['coach_id'] as String? ??
          source['assigned_coach_id'] as String?,
      hasCompletedFirstIntake: source['hasCompletedFirstIntake'] as bool? ??
          source['first_intake_completed'] as bool? ??
          false,
      hasCompletedSecondIntake: source['hasCompletedSecondIntake'] as bool? ??
          source['second_intake_completed'] as bool? ??
          false,
      fitnessScore:
          source['fitnessScore'] as int? ?? source['fitness_score'] as int?,
      fitnessScoreUpdatedBy: source['fitnessScoreUpdatedBy'] as String? ??
          source['fitness_score_updated_by'] as String?,
      fitnessScoreLastUpdated: source['fitnessScoreLastUpdated'] != null
          ? DateTime.parse(source['fitnessScoreLastUpdated'] as String)
          : source['fitness_score_last_updated'] != null
              ? DateTime.parse(source['fitness_score_last_updated'] as String)
              : null,
      role: source['role'] as String? ?? 'user',
    );
  }

  static Map<String, dynamic> _profileMap(Map<String, dynamic> json) {
    final nested = json['user'] ?? json['profile'] ?? json['data'];
    if (nested is Map<String, dynamic>) {
      return nested;
    }
    if (nested is Map) {
      return Map<String, dynamic>.from(nested);
    }
    return json;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'age': age,
      'weight': weight,
      'height': height,
      'gender': gender,
      'workoutFrequency': workoutFrequency,
      'workoutLocation': workoutLocation,
      'experienceLevel': experienceLevel,
      'mainGoal': mainGoal,
      'injuries': injuries,
      'subscriptionTier': subscriptionTier,
      'coachId': coachId,
      'hasCompletedFirstIntake': hasCompletedFirstIntake,
      'hasCompletedSecondIntake': hasCompletedSecondIntake,
      'fitnessScore': fitnessScore,
      'fitnessScoreUpdatedBy': fitnessScoreUpdatedBy,
      'fitnessScoreLastUpdated': fitnessScoreLastUpdated?.toIso8601String(),
      'role': role,
    };
  }

  UserProfile copyWith({
    String? name,
    String? email,
    int? age,
    double? weight,
    int? height,
    String? gender,
    int? workoutFrequency,
    String? workoutLocation,
    String? experienceLevel,
    String? mainGoal,
    List<String>? injuries,
    String? subscriptionTier,
    String? coachId,
    bool? hasCompletedFirstIntake,
    bool? hasCompletedSecondIntake,
    int? fitnessScore,
    String? fitnessScoreUpdatedBy,
    DateTime? fitnessScoreLastUpdated,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      phoneNumber: phoneNumber,
      email: email ?? this.email,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      gender: gender ?? this.gender,
      workoutFrequency: workoutFrequency ?? this.workoutFrequency,
      workoutLocation: workoutLocation ?? this.workoutLocation,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      mainGoal: mainGoal ?? this.mainGoal,
      injuries: injuries ?? this.injuries,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      coachId: coachId ?? this.coachId,
      hasCompletedFirstIntake:
          hasCompletedFirstIntake ?? this.hasCompletedFirstIntake,
      hasCompletedSecondIntake:
          hasCompletedSecondIntake ?? this.hasCompletedSecondIntake,
      fitnessScore: fitnessScore ?? this.fitnessScore,
      fitnessScoreUpdatedBy:
          fitnessScoreUpdatedBy ?? this.fitnessScoreUpdatedBy,
      fitnessScoreLastUpdated:
          fitnessScoreLastUpdated ?? this.fitnessScoreLastUpdated,
      role: role,
    );
  }

  bool get isPremiumOrHigher =>
      subscriptionTier == 'Premium' || subscriptionTier == 'Smart Premium';

  bool get isSmartPremium => subscriptionTier == 'Smart Premium';

  bool get canAccessSecondIntake => isPremiumOrHigher;
}

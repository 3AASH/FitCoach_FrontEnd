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
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String,
      email: json['email'] as String?,
      age: json['age'] as int?,
      weight: json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      height: json['height'] as int?,
      gender: json['gender'] as String?,
      workoutFrequency: json['workoutFrequency'] as int?,
      workoutLocation: json['workoutLocation'] as String?,
      experienceLevel: json['experienceLevel'] as String?,
      mainGoal: json['mainGoal'] as String?,
      injuries: json['injuries'] != null 
          ? List<String>.from(json['injuries'] as List)
          : [],
      subscriptionTier: json['subscriptionTier'] as String? ?? 'Freemium',
      coachId: json['coachId'] as String?,
      hasCompletedFirstIntake: json['hasCompletedFirstIntake'] as bool? ?? false,
      hasCompletedSecondIntake: json['hasCompletedSecondIntake'] as bool? ?? false,
      fitnessScore: json['fitnessScore'] as int?,
      fitnessScoreUpdatedBy: json['fitnessScoreUpdatedBy'] as String?,
      fitnessScoreLastUpdated: json['fitnessScoreLastUpdated'] != null
          ? DateTime.parse(json['fitnessScoreLastUpdated'] as String)
          : null,
      role: json['role'] as String? ?? 'user',
    );
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
      hasCompletedFirstIntake: hasCompletedFirstIntake ?? this.hasCompletedFirstIntake,
      hasCompletedSecondIntake: hasCompletedSecondIntake ?? this.hasCompletedSecondIntake,
      fitnessScore: fitnessScore ?? this.fitnessScore,
      fitnessScoreUpdatedBy: fitnessScoreUpdatedBy ?? this.fitnessScoreUpdatedBy,
      fitnessScoreLastUpdated: fitnessScoreLastUpdated ?? this.fitnessScoreLastUpdated,
      role: role,
    );
  }
  
  bool get isPremiumOrHigher => 
      subscriptionTier == 'Premium' || subscriptionTier == 'Smart Premium';
  
  bool get isSmartPremium => subscriptionTier == 'Smart Premium';
  
  bool get canAccessSecondIntake => isPremiumOrHigher;
}

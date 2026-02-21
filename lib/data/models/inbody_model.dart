class InBodyScan {
  final String? id;
  final String userId;
  
  // Body Composition
  final double totalBodyWater;
  final double intracellularWater;
  final double extracellularWater;
  final double dryLeanMass;
  final double bodyFatMass;
  final double weight;
  
  // Muscle-Fat Analysis
  final double skeletalMuscleMass;
  final String? bodyShape; // 'C', 'I', or 'D'
  
  // Obesity Analysis
  final double bmi;
  final double percentBodyFat;
  
  // Segmental Lean Analysis
  final SegmentalLean segmentalLean;
  
  // Other Parameters
  final int basalMetabolicRate;
  final int visceralFatLevel;
  final double? ecwTbwRatio;
  final int? inBodyScore;
  
  // Metadata
  final DateTime scanDate;
  final String? scanLocation;
  final String? notes;
  final bool extractedViaAi;
  final double? aiConfidenceScore;
  final String? originalImageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  InBodyScan({
    this.id,
    required this.userId,
    required this.totalBodyWater,
    required this.intracellularWater,
    required this.extracellularWater,
    required this.dryLeanMass,
    required this.bodyFatMass,
    required this.weight,
    required this.skeletalMuscleMass,
    this.bodyShape,
    required this.bmi,
    required this.percentBodyFat,
    required this.segmentalLean,
    required this.basalMetabolicRate,
    required this.visceralFatLevel,
    this.ecwTbwRatio,
    this.inBodyScore,
    required this.scanDate,
    this.scanLocation,
    this.notes,
    this.extractedViaAi = false,
    this.aiConfidenceScore,
    this.originalImageUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory InBodyScan.fromJson(Map<String, dynamic> json) {
    return InBodyScan(
      id: json['id'],
      userId: json['user_id'],
      totalBodyWater: (json['total_body_water'] as num).toDouble(),
      intracellularWater: (json['intracellular_water'] as num).toDouble(),
      extracellularWater: (json['extracellular_water'] as num).toDouble(),
      dryLeanMass: (json['dry_lean_mass'] as num).toDouble(),
      bodyFatMass: (json['body_fat_mass'] as num).toDouble(),
      weight: (json['weight'] as num).toDouble(),
      skeletalMuscleMass: (json['skeletal_muscle_mass'] as num).toDouble(),
      bodyShape: json['body_shape'],
      bmi: (json['bmi'] as num).toDouble(),
      percentBodyFat: (json['percent_body_fat'] as num).toDouble(),
      segmentalLean: SegmentalLean.fromJson({
        'leftArm': json['left_arm_muscle_percent'],
        'rightArm': json['right_arm_muscle_percent'],
        'trunk': json['trunk_muscle_percent'],
        'leftLeg': json['left_leg_muscle_percent'],
        'rightLeg': json['right_leg_muscle_percent'],
      }),
      basalMetabolicRate: json['basal_metabolic_rate'] as int,
      visceralFatLevel: json['visceral_fat_level'] as int,
      ecwTbwRatio: json['ecw_tbw_ratio'] != null 
          ? (json['ecw_tbw_ratio'] as num).toDouble() 
          : null,
      inBodyScore: json['inbody_score'] as int?,
      scanDate: DateTime.parse(json['scan_date']),
      scanLocation: json['scan_location'],
      notes: json['notes'],
      extractedViaAi: json['extracted_via_ai'] ?? false,
      aiConfidenceScore: json['ai_confidence_score'] != null
          ? (json['ai_confidence_score'] as num).toDouble()
          : null,
      originalImageUrl: json['original_image_url'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'totalBodyWater': totalBodyWater,
      'intracellularWater': intracellularWater,
      'extracellularWater': extracellularWater,
      'dryLeanMass': dryLeanMass,
      'bodyFatMass': bodyFatMass,
      'weight': weight,
      'skeletalMuscleMass': skeletalMuscleMass,
      'bodyShape': bodyShape,
      'bmi': bmi,
      'percentBodyFat': percentBodyFat,
      'segmentalLean': {
        'leftArm': segmentalLean.leftArm,
        'rightArm': segmentalLean.rightArm,
        'trunk': segmentalLean.trunk,
        'leftLeg': segmentalLean.leftLeg,
        'rightLeg': segmentalLean.rightLeg,
      },
      'basalMetabolicRate': basalMetabolicRate,
      'visceralFatLevel': visceralFatLevel,
      'ecwTbwRatio': ecwTbwRatio,
      'inBodyScore': inBodyScore,
      'scanDate': scanDate.toIso8601String(),
      'scanLocation': scanLocation,
      'notes': notes,
      'extractedViaAi': extractedViaAi,
      'aiConfidenceScore': aiConfidenceScore,
      'originalImageUrl': originalImageUrl,
    };
  }

  // Helper: Calculate body shape
  static String calculateBodyShape(double weight, double smm, double bodyFatMass) {
    final smmRatio = smm / weight;
    
    if (smmRatio < 0.35) return 'C'; // Less muscle, more fat
    if (smmRatio > 0.42) return 'D'; // High muscle, lower fat (athletic)
    return 'I'; // Balanced
  }

  // Helper: BMI category
  static String getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal weight';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  // Helper: Body fat category (gender-specific)
  static String getBodyFatCategory(double pbf, String gender) {
    if (gender.toLowerCase() == 'male') {
      if (pbf < 6) return 'Essential fat';
      if (pbf < 14) return 'Athletic';
      if (pbf < 18) return 'Fitness';
      if (pbf < 25) return 'Average';
      return 'Obese';
    } else if (gender.toLowerCase() == 'female') {
      if (pbf < 14) return 'Essential fat';
      if (pbf < 21) return 'Athletic';
      if (pbf < 25) return 'Fitness';
      if (pbf < 32) return 'Average';
      return 'Obese';
    }
    return 'N/A';
  }

  // Helper: Visceral fat category
  static String getVisceralFatCategory(int vfl) {
    if (vfl < 10) return 'Normal';
    if (vfl < 15) return 'Elevated';
    return 'High Risk';
  }

  // Helper: InBody score category
  static String getInBodyScoreCategory(int score) {
    if (score >= 90) return 'Excellent';
    if (score >= 80) return 'Good';
    if (score >= 70) return 'Average';
    return 'Needs Improvement';
  }
}

class SegmentalLean {
  final int leftArm;
  final int rightArm;
  final int trunk;
  final int leftLeg;
  final int rightLeg;

  SegmentalLean({
    required this.leftArm,
    required this.rightArm,
    required this.trunk,
    required this.leftLeg,
    required this.rightLeg,
  });

  factory SegmentalLean.fromJson(Map<String, dynamic> json) {
    return SegmentalLean(
      leftArm: json['leftArm'] as int? ?? 100,
      rightArm: json['rightArm'] as int? ?? 100,
      trunk: json['trunk'] as int? ?? 100,
      leftLeg: json['leftLeg'] as int? ?? 100,
      rightLeg: json['rightLeg'] as int? ?? 100,
    );
  }
}

class InBodyProgress {
  final int daysElapsed;
  final double weightLost;
  final double bodyFatReduced;
  final double muscleGained;
  final double? progressPercentage;

  InBodyProgress({
    required this.daysElapsed,
    required this.weightLost,
    required this.bodyFatReduced,
    required this.muscleGained,
    this.progressPercentage,
  });

  factory InBodyProgress.fromJson(Map<String, dynamic> json) {
    return InBodyProgress(
      daysElapsed: json['days_elapsed'] as int,
      weightLost: (json['weight_lost'] as num).toDouble(),
      bodyFatReduced: (json['body_fat_reduced'] as num).toDouble(),
      muscleGained: (json['muscle_gained'] as num).toDouble(),
      progressPercentage: json['progress_percentage'] != null
          ? (json['progress_percentage'] as num).toDouble()
          : null,
    );
  }
}

class InBodyGoals {
  final String? id;
  final String userId;
  final double? targetWeight;
  final double? targetBmi;
  final double? targetBodyFatPercent;
  final double? targetSkeletalMuscleMass;
  final int? targetVisceralFatLevel;
  final DateTime? targetDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  InBodyGoals({
    this.id,
    required this.userId,
    this.targetWeight,
    this.targetBmi,
    this.targetBodyFatPercent,
    this.targetSkeletalMuscleMass,
    this.targetVisceralFatLevel,
    this.targetDate,
    this.createdAt,
    this.updatedAt,
  });

  factory InBodyGoals.fromJson(Map<String, dynamic> json) {
    return InBodyGoals(
      id: json['id'],
      userId: json['user_id'],
      targetWeight: json['target_weight'] != null 
          ? (json['target_weight'] as num).toDouble() 
          : null,
      targetBmi: json['target_bmi'] != null 
          ? (json['target_bmi'] as num).toDouble() 
          : null,
      targetBodyFatPercent: json['target_body_fat_percent'] != null
          ? (json['target_body_fat_percent'] as num).toDouble()
          : null,
      targetSkeletalMuscleMass: json['target_skeletal_muscle_mass'] != null
          ? (json['target_skeletal_muscle_mass'] as num).toDouble()
          : null,
      targetVisceralFatLevel: json['target_visceral_fat_level'] as int?,
      targetDate: json['target_date'] != null
          ? DateTime.parse(json['target_date'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'targetWeight': targetWeight,
      'targetBmi': targetBmi,
      'targetBodyFatPercent': targetBodyFatPercent,
      'targetSkeletalMuscleMass': targetSkeletalMuscleMass,
      'targetVisceralFatLevel': targetVisceralFatLevel,
      'targetDate': targetDate?.toIso8601String(),
    };
  }
}

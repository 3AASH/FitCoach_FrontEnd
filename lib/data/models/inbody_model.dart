class InBodyScan {
  final String? id;
  final String userId;

  // Body Composition
  final double? totalBodyWater;
  final double? intracellularWater;
  final double? extracellularWater;
  final double? dryLeanMass;
  final double? bodyFatMass;
  final double weight;

  // Muscle-Fat Analysis
  final double? skeletalMuscleMass;
  final String? bodyShape;

  // Obesity Analysis
  final double? bmi;
  final double? percentBodyFat;

  // Segmental Lean Analysis
  final SegmentalLean? segmentalLean;

  // Other Parameters
  final int? basalMetabolicRate;
  final int? visceralFatLevel;
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
    this.totalBodyWater,
    this.intracellularWater,
    this.extracellularWater,
    this.dryLeanMass,
    this.bodyFatMass,
    required this.weight,
    this.skeletalMuscleMass,
    this.bodyShape,
    this.bmi,
    this.percentBodyFat,
    this.segmentalLean,
    this.basalMetabolicRate,
    this.visceralFatLevel,
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
    final segmentalPayload = <String, dynamic>{
      'leftArm': json['left_arm_muscle_percent'] ?? json['leftArm'],
      'rightArm': json['right_arm_muscle_percent'] ?? json['rightArm'],
      'trunk': json['trunk_muscle_percent'] ?? json['trunk'],
      'leftLeg': json['left_leg_muscle_percent'] ?? json['leftLeg'],
      'rightLeg': json['right_leg_muscle_percent'] ?? json['rightLeg'],
    };

    final hasSegmentalValues =
        segmentalPayload.values.any((value) => value != null);

    return InBodyScan(
      id: _asString(json['id'] ?? json['_id']),
      userId: _asString(json['user_id'] ?? json['userId']) ?? '',
      totalBodyWater:
          _asDouble(json['total_body_water'] ?? json['totalBodyWater']),
      intracellularWater: _asDouble(
        json['intracellular_water'] ?? json['intracellularWater'],
      ),
      extracellularWater: _asDouble(
        json['extracellular_water'] ?? json['extracellularWater'],
      ),
      dryLeanMass: _asDouble(json['dry_lean_mass'] ?? json['dryLeanMass']),
      bodyFatMass: _asDouble(json['body_fat_mass'] ?? json['bodyFatMass']),
      weight: _asDouble(json['weight']) ?? 0,
      skeletalMuscleMass: _asDouble(
        json['skeletal_muscle_mass'] ?? json['skeletalMuscleMass'],
      ),
      bodyShape: _asString(json['body_shape'] ?? json['bodyShape']),
      bmi: _asDouble(json['bmi']),
      percentBodyFat: _asDouble(
        json['percent_body_fat'] ?? json['percentBodyFat'],
      ),
      segmentalLean:
          hasSegmentalValues ? SegmentalLean.fromJson(segmentalPayload) : null,
      basalMetabolicRate: _asInt(
        json['basal_metabolic_rate'] ?? json['basalMetabolicRate'],
      ),
      visceralFatLevel: _asInt(
        json['visceral_fat_level'] ?? json['visceralFatLevel'],
      ),
      ecwTbwRatio: _asDouble(json['ecw_tbw_ratio'] ?? json['ecwTbwRatio']),
      inBodyScore: _asInt(json['inbody_score'] ?? json['inBodyScore']),
      scanDate: _asDateTime(json['scan_date'] ?? json['scanDate']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      scanLocation: _asString(json['scan_location'] ?? json['scanLocation']),
      notes: _asString(json['notes']),
      extractedViaAi: _asBool(
            json['extracted_via_ai'] ?? json['extractedViaAi'],
          ) ??
          false,
      aiConfidenceScore: _asDouble(
        json['ai_confidence_score'] ?? json['aiConfidenceScore'],
      ),
      originalImageUrl: _asString(
        json['original_image_url'] ?? json['originalImageUrl'],
      ),
      createdAt: _asDateTime(json['created_at'] ?? json['createdAt']),
      updatedAt: _asDateTime(json['updated_at'] ?? json['updatedAt']),
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
      'segmentalLean': segmentalLean == null
          ? null
          : {
              'leftArm': segmentalLean!.leftArm,
              'rightArm': segmentalLean!.rightArm,
              'trunk': segmentalLean!.trunk,
              'leftLeg': segmentalLean!.leftLeg,
              'rightLeg': segmentalLean!.rightLeg,
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

  static String calculateBodyShape(
      double weight, double smm, double bodyFatMass) {
    final smmRatio = smm / weight;

    if (smmRatio < 0.35) return 'C';
    if (smmRatio > 0.42) return 'D';
    return 'I';
  }

  static String getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal weight';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

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

  static String getVisceralFatCategory(int vfl) {
    if (vfl < 10) return 'Normal';
    if (vfl < 15) return 'Elevated';
    return 'High Risk';
  }

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
      leftArm: _asInt(json['leftArm']) ?? 100,
      rightArm: _asInt(json['rightArm']) ?? 100,
      trunk: _asInt(json['trunk']) ?? 100,
      leftLeg: _asInt(json['leftLeg']) ?? 100,
      rightLeg: _asInt(json['rightLeg']) ?? 100,
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
      daysElapsed: _asInt(json['days_elapsed']) ?? 0,
      weightLost: _asDouble(json['weight_lost']) ?? 0,
      bodyFatReduced: _asDouble(json['body_fat_reduced']) ?? 0,
      muscleGained: _asDouble(json['muscle_gained']) ?? 0,
      progressPercentage: _asDouble(
        json['progress_percentage'] ?? json['progressPercentage'],
      ),
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
      id: _asString(json['id'] ?? json['_id']),
      userId: _asString(json['user_id'] ?? json['userId']) ?? '',
      targetWeight: _asDouble(json['target_weight'] ?? json['targetWeight']),
      targetBmi: _asDouble(json['target_bmi'] ?? json['targetBmi']),
      targetBodyFatPercent: _asDouble(
        json['target_body_fat_percent'] ?? json['targetBodyFatPercent'],
      ),
      targetSkeletalMuscleMass: _asDouble(
        json['target_skeletal_muscle_mass'] ?? json['targetSkeletalMuscleMass'],
      ),
      targetVisceralFatLevel: _asInt(
        json['target_visceral_fat_level'] ?? json['targetVisceralFatLevel'],
      ),
      targetDate: _asDateTime(json['target_date'] ?? json['targetDate']),
      createdAt: _asDateTime(json['created_at'] ?? json['createdAt']),
      updatedAt: _asDateTime(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'targetWeight': targetWeight,
      'targetBmi': targetBmi,
      'targetBodyFatPercent': targetBodyFatPercent,
      'targetSkeletalMuscleMass': targetSkeletalMuscleMass,
      'targetVisceralFatLevel': targetVisceralFatLevel,
      'targetDate': targetDate?.toIso8601String(),
    };
  }
}

String? _asString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

double? _asDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

bool? _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  return null;
}

DateTime? _asDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

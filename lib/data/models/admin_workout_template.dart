class AdminWorkoutTemplate {
  final String planId;
  final String type;
  final String? nameEn;
  final String? nameAr;
  final String? goal;
  final String? location;
  final int? trainingDays;
  final int? weeks;
  final int? sessionCount;

  const AdminWorkoutTemplate({
    required this.planId,
    required this.type,
    this.nameEn,
    this.nameAr,
    this.goal,
    this.location,
    this.trainingDays,
    this.weeks,
    this.sessionCount,
  });

  factory AdminWorkoutTemplate.fromJson(Map<String, dynamic> json) {
    return AdminWorkoutTemplate(
      planId: (json['plan_id'] ?? json['planId'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      nameEn: _string(json['name_en'] ?? json['nameEn']),
      nameAr: _string(json['name_ar'] ?? json['nameAr']),
      goal: _string(json['goal']),
      location: _string(json['location']),
      trainingDays: _int(json['training_days'] ?? json['trainingDays']),
      weeks: _int(json['weeks']),
      sessionCount: _int(json['session_count'] ?? json['sessionCount']),
    );
  }

  static String? _string(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static int? _int(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}

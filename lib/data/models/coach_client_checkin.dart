class CoachClientCheckInResponse {
  final CoachClientCheckIn? latestCheckIn;
  final List<CoachClientCheckIn> checkIns;
  final int total;

  const CoachClientCheckInResponse({
    required this.latestCheckIn,
    required this.checkIns,
    required this.total,
  });

  factory CoachClientCheckInResponse.fromJson(Map<String, dynamic> json) {
    final latestMap = _asMap(json['latestCheckIn']);
    final list = _asList(json['checkIns'])
        .map((item) => CoachClientCheckIn.fromJson(_asMap(item) ?? const {}))
        .toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return CoachClientCheckInResponse(
      latestCheckIn:
          latestMap == null ? null : CoachClientCheckIn.fromJson(latestMap),
      checkIns: list,
      total: _asInt(json['total']) ?? list.length,
    );
  }
}

class CoachClientCheckIn {
  final String id;
  final String type;
  final String title;
  final DateTime occurredAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? source;
  final String? stage;
  final CoachClientCheckInMetrics? metrics;
  final CoachClientCheckInChanges? changes;
  final String? notes;
  final Map<String, dynamic>? context;

  const CoachClientCheckIn({
    required this.id,
    required this.type,
    required this.title,
    required this.occurredAt,
    this.createdAt,
    this.updatedAt,
    this.source,
    this.stage,
    this.metrics,
    this.changes,
    this.notes,
    this.context,
  });

  factory CoachClientCheckIn.fromJson(Map<String, dynamic> json) {
    final metricsMap = _asMap(json['metrics']);
    final changesMap = _asMap(json['changes']);
    return CoachClientCheckIn(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? 'checkin').toString(),
      title: (json['title'] ?? 'Check-In').toString(),
      occurredAt: _asDateTime(json['occurredAt']) ??
          _asDateTime(json['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      createdAt: _asDateTime(json['createdAt']),
      updatedAt: _asDateTime(json['updatedAt']),
      source: _asNullableString(json['source']),
      stage: _asNullableString(json['stage']),
      metrics: metricsMap == null
          ? null
          : CoachClientCheckInMetrics.fromJson(metricsMap),
      changes: changesMap == null
          ? null
          : CoachClientCheckInChanges.fromJson(changesMap),
      notes: _asNullableString(json['notes']),
      context: _asMap(json['context']),
    );
  }

  bool get hasMetrics => metrics != null && metrics!.hasValues;
  bool get hasChanges => changes != null && changes!.hasValues;
  bool get isIntake => type.toLowerCase() == 'intake';
}

class CoachClientCheckInMetrics {
  final double? weight;
  final double? bodyFatPercentage;
  final double? skeletalMuscleMass;
  final double? bmi;
  final double? waist;
  final double? chest;
  final double? hips;

  const CoachClientCheckInMetrics({
    this.weight,
    this.bodyFatPercentage,
    this.skeletalMuscleMass,
    this.bmi,
    this.waist,
    this.chest,
    this.hips,
  });

  factory CoachClientCheckInMetrics.fromJson(Map<String, dynamic> json) {
    return CoachClientCheckInMetrics(
      weight: _asDouble(json['weight']),
      bodyFatPercentage:
          _asDouble(json['bodyFatPercentage'] ?? json['body_fat_percentage']),
      skeletalMuscleMass:
          _asDouble(json['skeletalMuscleMass'] ?? json['skeletal_muscle_mass']),
      bmi: _asDouble(json['bmi']),
      waist: _asDouble(json['waist']),
      chest: _asDouble(json['chest']),
      hips: _asDouble(json['hips']),
    );
  }

  bool get hasValues =>
      weight != null ||
      bodyFatPercentage != null ||
      skeletalMuscleMass != null ||
      bmi != null ||
      waist != null ||
      chest != null ||
      hips != null;
}

class CoachClientCheckInChanges {
  final double? weight;
  final double? bodyFatPercentage;
  final double? skeletalMuscleMass;
  final double? bmi;
  final double? waist;
  final double? chest;
  final double? hips;

  const CoachClientCheckInChanges({
    this.weight,
    this.bodyFatPercentage,
    this.skeletalMuscleMass,
    this.bmi,
    this.waist,
    this.chest,
    this.hips,
  });

  factory CoachClientCheckInChanges.fromJson(Map<String, dynamic> json) {
    return CoachClientCheckInChanges(
      weight: _asDouble(json['weight']),
      bodyFatPercentage:
          _asDouble(json['bodyFatPercentage'] ?? json['body_fat_percentage']),
      skeletalMuscleMass:
          _asDouble(json['skeletalMuscleMass'] ?? json['skeletal_muscle_mass']),
      bmi: _asDouble(json['bmi']),
      waist: _asDouble(json['waist']),
      chest: _asDouble(json['chest']),
      hips: _asDouble(json['hips']),
    );
  }

  bool get hasValues =>
      weight != null ||
      bodyFatPercentage != null ||
      skeletalMuscleMass != null ||
      bmi != null ||
      waist != null ||
      chest != null ||
      hips != null;
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

List<dynamic> _asList(dynamic value) {
  if (value is List) return value;
  return const [];
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

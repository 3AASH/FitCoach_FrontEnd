import 'dart:convert';

import 'package:flutter/foundation.dart';

class WorkoutPlan {
  final String id;
  final String userId;
  final String? coachId;
  final String? name;
  final String? nameAr;
  final String? description;
  final String? descriptionAr;
  final Map<String, dynamic>? planData;
  final String? notes;
  final List<WorkoutDay>? days;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final bool? customizedByCoach;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int? currentDayNumber;
  final String? currentDayId;
  final int? completedDays;
  final int? totalDays;
  final double? dayProgressPercent;

  WorkoutPlan({
    required this.id,
    required this.userId,
    this.coachId,
    this.name,
    this.nameAr,
    this.description,
    this.descriptionAr,
    this.planData,
    this.notes,
    this.days,
    this.startDate,
    this.endDate,
    this.isActive = true,
    this.customizedByCoach,
    required this.createdAt,
    this.updatedAt,
    this.currentDayNumber,
    this.currentDayId,
    this.completedDays,
    this.totalDays,
    this.dayProgressPercent,
  });

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) {
    final createdAtValue = json['created_at'] ?? json['createdAt'];
    return WorkoutPlan(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? json['userId'] ?? '').toString(),
      coachId: asString(json['coach_id'] ?? json['coachId']),
      name: asString(json['name']),
      nameAr: asString(json['nameAr']),
      description: asString(json['description']),
      descriptionAr: asString(json['descriptionAr']),
      planData: _asMap(json['plan_data']) ?? _asMap(json['planData']),
      notes: asString(json['notes']),
      days: _asList(json['days'] ?? json['workoutDays'] ?? json['workout_days'])
          ?.map((day) => WorkoutDay.fromJson(_asMap(day) ?? const {}))
          .toList(),
      startDate: _asDateTime(json['start_date'] ?? json['startDate']),
      endDate: _asDateTime(json['end_date'] ?? json['endDate']),
      isActive: _asBool(json['is_active'] ?? json['isActive'], fallback: true),
      customizedByCoach: _asNullableBool(
          json['customized_by_coach'] ?? json['customizedByCoach']),
      createdAt: _asDateTime(createdAtValue) ?? DateTime.now(),
      updatedAt: json['updated_at'] != null || json['updatedAt'] != null
          ? _asDateTime(json['updated_at'] ?? json['updatedAt'])
          : null,
      currentDayNumber: _asInt(
                  json['currentDayNumber'] ?? json['current_day_number'],
                  fallback: 0) ==
              0
          ? null
          : _asInt(json['currentDayNumber'] ?? json['current_day_number'],
              fallback: 0),
      currentDayId: asString(json['currentDayId'] ?? json['current_day_id']),
      completedDays:
          _asNullableInt(json['completedDays'] ?? json['completed_days']),
      totalDays: _asNullableInt(json['totalDays'] ?? json['total_days']),
      dayProgressPercent: _asNullableDouble(
          json['dayProgressPercent'] ?? json['day_progress_percent']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'coach_id': coachId,
      'userId': userId,
      'coachId': coachId,
      'name': name,
      'nameAr': nameAr,
      'description': description,
      'descriptionAr': descriptionAr,
      'plan_data': planData,
      'planData': planData,
      'notes': notes,
      'days': days?.map((day) => day.toJson()).toList(),
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'is_active': isActive,
      'customized_by_coach': customizedByCoach,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'currentDayNumber': currentDayNumber,
      'currentDayId': currentDayId,
      'completedDays': completedDays,
      'totalDays': totalDays,
      'dayProgressPercent': dayProgressPercent,
    };
  }
}

class WorkoutDay {
  final String id;
  final String dayName;
  final String? dayNameAr;
  final int dayNumber;
  final List<Exercise> exercises;
  final String? notes;
  final bool isCompleted;
  final int? completedExercises;
  final int? totalExercises;

  WorkoutDay({
    required this.id,
    required this.dayName,
    this.dayNameAr,
    required this.dayNumber,
    required this.exercises,
    this.notes,
    this.isCompleted = false,
    this.completedExercises,
    this.totalExercises,
  });

  factory WorkoutDay.fromJson(Map<String, dynamic> json) {
    final dayNumber =
        _asInt(json['dayNumber'] ?? json['day_number'], fallback: 1);
    return WorkoutDay(
      id: (json['id'] ?? '').toString(),
      dayName: resolveWorkoutDayName(json, 0, dayNumber: dayNumber),
      dayNameAr: asString(json['dayNameAr']),
      dayNumber: dayNumber,
      exercises: (_asList(json['exercises']) ?? const [])
          .map((ex) => Exercise.fromJson(_asMap(ex) ?? const {}))
          .toList(),
      notes: asString(json['notes']),
      isCompleted:
          _asBool(json['isCompleted'] ?? json['is_completed'], fallback: false),
      completedExercises: _asNullableInt(
          json['completedExercises'] ?? json['completed_exercises']),
      totalExercises:
          _asNullableInt(json['totalExercises'] ?? json['total_exercises']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dayName': dayName,
      'dayNameAr': dayNameAr,
      'dayNumber': dayNumber,
      'exercises': exercises.map((ex) => ex.toJson()).toList(),
      'notes': notes,
      'isCompleted': isCompleted,
      'completedExercises': completedExercises,
      'totalExercises': totalExercises,
    };
  }
}

class Exercise {
  final String id;
  final String? exerciseId;
  final String name;
  final String nameAr;
  final String nameEn;
  final String? category;
  final String? muscleGroup;
  final String? equipment;
  final String? difficulty;
  final String? videoUrl;
  final String? thumbnailUrl;
  final String? instructions;
  final String? instructionsAr;
  final String? instructionsEn;
  final int sets;
  final String reps;
  final String? restTime;
  final String? tempo;
  final String? notes;
  final List<String> contraindications;
  final List<String> alternatives;
  final bool isCompleted;
  final int order;

  Exercise({
    required this.id,
    this.exerciseId,
    required this.name,
    required this.nameAr,
    required this.nameEn,
    this.category,
    this.muscleGroup,
    this.equipment,
    this.difficulty,
    this.videoUrl,
    this.thumbnailUrl,
    this.instructions,
    this.instructionsAr,
    this.instructionsEn,
    required this.sets,
    required this.reps,
    this.restTime,
    this.tempo,
    this.notes,
    this.contraindications = const [],
    this.alternatives = const [],
    this.isCompleted = false,
    this.order = 0,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    final resolvedName = resolveExerciseName(json);
    final nameEn = (json['nameEn'] ??
            json['name_en'] ??
            json['name'] ??
            json['exerciseName'] ??
            json['exercise_name'] ??
            json['title'] ??
            '')
        .toString();
    final nameAr = (json['nameAr'] ??
            json['name_ar'] ??
            json['name'] ??
            json['exerciseName'] ??
            json['exercise_name'] ??
            json['title'] ??
            '')
        .toString();
    return Exercise(
      id: (json['id'] ?? '').toString(),
      exerciseId: asString(
        json['exerciseId'] ?? json['exercise_id'] ?? json['ex_id'],
      ),
      name: resolvedName,
      nameAr: nameAr,
      nameEn: nameEn,
      category: asString(json['category']),
      muscleGroup: asString(json['muscleGroup']),
      equipment: asString(json['equipment']),
      difficulty: asString(json['difficulty']),
      videoUrl: asString(json['videoUrl'] ?? json['video_url']),
      thumbnailUrl: asString(json['thumbnailUrl'] ?? json['thumbnail_url']),
      instructions: asString(json['instructions']),
      instructionsAr:
          asString(json['instructionsAr'] ?? json['instructions_ar']),
      instructionsEn:
          asString(json['instructionsEn'] ?? json['instructions_en']),
      sets: _asInt(json['sets'], fallback: 0),
      reps: (json['reps'] ?? '').toString(),
      restTime: asString(json['restTime']),
      tempo: asString(json['tempo']),
      notes: asString(json['notes']),
      contraindications: _stringList(json['contraindications']),
      alternatives: _stringList(json['alternatives']),
      isCompleted: _asBool(json['isCompleted'], fallback: false),
      order: _asInt(json['order'], fallback: 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exerciseId': exerciseId,
      'name': name,
      'nameAr': nameAr,
      'nameEn': nameEn,
      'category': category,
      'muscleGroup': muscleGroup,
      'equipment': equipment,
      'difficulty': difficulty,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'instructions': instructions,
      'instructionsAr': instructionsAr,
      'instructionsEn': instructionsEn,
      'sets': sets,
      'reps': reps,
      'restTime': restTime,
      'tempo': tempo,
      'notes': notes,
      'contraindications': contraindications,
      'alternatives': alternatives,
      'isCompleted': isCompleted,
      'order': order,
    };
  }

  Exercise copyWith({
    String? name,
    String? nameAr,
    String? nameEn,
    String? category,
    String? muscleGroup,
    String? equipment,
    String? difficulty,
    String? videoUrl,
    String? thumbnailUrl,
    String? instructions,
    String? instructionsAr,
    String? instructionsEn,
    bool? isCompleted,
    String? notes,
  }) {
    return Exercise(
      id: id,
      exerciseId: exerciseId,
      name: name ?? this.name,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      category: category ?? this.category,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      equipment: equipment ?? this.equipment,
      difficulty: difficulty ?? this.difficulty,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      instructions: instructions ?? this.instructions,
      instructionsAr: instructionsAr ?? this.instructionsAr,
      instructionsEn: instructionsEn ?? this.instructionsEn,
      sets: sets,
      reps: reps,
      restTime: restTime,
      tempo: tempo,
      notes: notes ?? this.notes,
      contraindications: contraindications,
      alternatives: alternatives,
      isCompleted: isCompleted ?? this.isCompleted,
      order: order,
    );
  }

  bool hasInjuryConflict(List<String> userInjuries) {
    String normalize(String input) {
      return input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    }

    return contraindications.any((injury) {
      final normalizedInjury = normalize(injury);
      return userInjuries.any((userInjury) {
        return normalize(userInjury).contains(normalizedInjury);
      });
    });
  }
}

int _asInt(dynamic value, {required int fallback}) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }
  return fallback;
}

int? _asNullableInt(dynamic value) {
  if (value == null) return null;
  return _asInt(value, fallback: 0);
}

bool _asBool(dynamic value, {required bool fallback}) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
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

bool? _asNullableBool(dynamic value) {
  if (value == null) {
    return null;
  }
  return _asBool(value, fallback: false);
}

double? _asNullableDouble(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is double) {
    return value;
  }
  if (value is int) {
    return value.toDouble();
  }
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
}

String? asString(dynamic v) {
  return readString(v);
}

String? readString(dynamic v) {
  if (v == null) return null;
  if (v is String) return v;
  if (v is List || v is Map) {
    return jsonEncode(v);
  }
  if (v is num || v is bool) {
    return v.toString();
  }
  if (kDebugMode) {
    debugPrint('[WorkoutPlan] Unexpected type for asString: ${v.runtimeType}');
  }
  return v.toString();
}

String resolveExerciseName(Map<String, dynamic> json) {
  final prioritized = [
    readString(json['name']),
    readString(json['exerciseName']),
    readString(json['exercise_name']),
    readString(json['title']),
    readString(json['nameEn']),
    readString(json['name_en']),
    readString(json['nameAr']),
    readString(json['name_ar']),
    readString(json['exerciseId']),
    readString(json['id']),
  ];
  for (final candidate in prioritized) {
    final value = candidate?.trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
  }
  return 'Exercise';
}

String resolveWorkoutDayName(
  Map<String, dynamic> json,
  int index, {
  int? dayNumber,
}) {
  final prioritized = [
    readString(json['dayName']),
    readString(json['day_name']),
    readString(json['name']),
    readString(json['title']),
  ];
  for (final candidate in prioritized) {
    final value = candidate?.trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
  }
  final resolvedNumber = dayNumber ??
      _asInt(json['dayNumber'] ?? json['day_number'] ?? json['day'],
          fallback: index + 1);
  return 'Day $resolvedNumber';
}

bool? asBool(dynamic v) {
  if (v == null) return null;
  if (v is bool) return v;
  if (v is int) return v == 1;
  if (v is String) {
    final normalized = v.trim().toLowerCase();
    return ['true', '1', 'yes'].contains(normalized);
  }
  if (kDebugMode) {
    debugPrint('[WorkoutPlan] Unexpected type for asBool: ${v.runtimeType}');
  }
  return null;
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  if (value != null && kDebugMode) {
    debugPrint('[WorkoutPlan] Unexpected map type: ${value.runtimeType}');
  }
  return null;
}

List<dynamic>? _asList(dynamic value) {
  if (value is List) return value;
  if (value != null && kDebugMode) {
    debugPrint('[WorkoutPlan] Unexpected list type: ${value.runtimeType}');
  }
  return null;
}

List<String> _stringList(dynamic value) {
  final list = _asList(value);
  if (list == null) {
    return const [];
  }
  return list
      .map((item) => asString(item) ?? '')
      .where((e) => e.isNotEmpty)
      .toList();
}

DateTime? _asDateTime(dynamic value) {
  final raw = asString(value);
  if (raw == null || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}

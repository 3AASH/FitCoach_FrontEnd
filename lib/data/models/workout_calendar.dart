class WorkoutCalendarResponse {
  final WorkoutCalendarPlan? plan;
  final List<WorkoutCalendarDayEntry> previous;
  final WorkoutCalendarDayEntry? today;
  final List<WorkoutCalendarDayEntry> upcoming;
  final List<WorkoutCalendarDayEntry> allDays;

  WorkoutCalendarResponse({
    required this.plan,
    required this.previous,
    required this.today,
    required this.upcoming,
    required this.allDays,
  });

  factory WorkoutCalendarResponse.fromJson(Map<String, dynamic> json) {
    return WorkoutCalendarResponse(
      plan: _asMap(json['plan']) != null
          ? WorkoutCalendarPlan.fromJson(_asMap(json['plan'])!)
          : null,
      previous: _asList(json['previous'])
          .map((e) => WorkoutCalendarDayEntry.fromJson(_asMap(e) ?? const {}))
          .toList(),
      today: _asMap(json['today']) != null
          ? WorkoutCalendarDayEntry.fromJson(_asMap(json['today'])!)
          : null,
      upcoming: _asList(json['upcoming'])
          .map((e) => WorkoutCalendarDayEntry.fromJson(_asMap(e) ?? const {}))
          .toList(),
      allDays: _asList(json['allDays'] ?? json['all_days'])
          .map((e) => WorkoutCalendarDayEntry.fromJson(_asMap(e) ?? const {}))
          .toList(),
    );
  }
}

class WorkoutCalendarPlan {
  final String id;
  final String name;
  final DateTime? startDate;
  final DateTime? endDate;
  final int daysPerWeek;

  WorkoutCalendarPlan({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.daysPerWeek,
  });

  factory WorkoutCalendarPlan.fromJson(Map<String, dynamic> json) {
    return WorkoutCalendarPlan(
      id: _asString(json['id']),
      name: _asString(json['name']),
      startDate: _asDateTime(json['startDate'] ?? json['start_date']),
      endDate: _asDateTime(json['endDate'] ?? json['end_date']),
      daysPerWeek: _asInt(json['daysPerWeek'] ?? json['days_per_week']),
    );
  }
}

class WorkoutCalendarDayEntry {
  final String id;
  final String? workoutDayId;
  final int dayNumber;
  final String dayName;
  final String? dayNameAr;
  final String date;
  final int totalExercises;
  final int completedExercises;
  final bool completed;
  final double progressPercent;
  final String? notes;

  WorkoutCalendarDayEntry({
    required this.id,
    required this.workoutDayId,
    required this.dayNumber,
    required this.dayName,
    required this.dayNameAr,
    required this.date,
    required this.totalExercises,
    required this.completedExercises,
    required this.completed,
    required this.progressPercent,
    required this.notes,
  });

  factory WorkoutCalendarDayEntry.fromJson(Map<String, dynamic> json) {
    final dayNumber = _asInt(json['dayNumber'] ?? json['day_number'] ?? json['day']);
    final dayName = _asString(json['dayName'] ?? json['day_name'] ?? json['name']);
    return WorkoutCalendarDayEntry(
      id: _asString(json['id']),
      workoutDayId: _asNullableString(json['workoutDayId'] ?? json['workout_day_id']),
      dayNumber: dayNumber,
      dayName: dayName.isEmpty ? 'Day $dayNumber' : dayName,
      dayNameAr: _asNullableString(json['dayNameAr'] ?? json['day_name_ar']),
      date: _asString(json['date']),
      totalExercises: _asInt(json['totalExercises'] ?? json['total_exercises']),
      completedExercises:
          _asInt(json['completedExercises'] ?? json['completed_exercises']),
      completed:
          _asBool(json['completed'] ?? json['isCompleted'] ?? json['is_completed']),
      progressPercent:
          _asDouble(json['progressPercent'] ?? json['progress_percent']),
      notes: _asNullableString(json['notes']),
    );
  }
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

String _asString(dynamic value) {
  if (value == null) return '';
  if (value is String) return value;
  return value.toString();
}

String? _asNullableString(dynamic value) {
  final text = _asString(value).trim();
  return text.isEmpty ? null : text;
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double _asDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final n = value.trim().toLowerCase();
    return n == 'true' || n == '1' || n == 'yes';
  }
  return false;
}

DateTime? _asDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

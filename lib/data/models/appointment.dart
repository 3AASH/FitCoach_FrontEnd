class Appointment {
  final String id;
  final String coachId;
  final String userId;
  final String scheduledAt;
  final int? durationMinutes;
  final String status; // pending, confirmed, in_progress, completed, cancelled
  final String? type;
  final String? notes;
  final String? coachName;
  final String? userName;
  final String? createdAt;
  final String? updatedAt;

  Appointment({
    required this.id,
    required this.coachId,
    required this.userId,
    required this.scheduledAt,
    this.durationMinutes,
    required this.status,
    this.type,
    this.notes,
    this.coachName,
    this.userName,
    this.createdAt,
    this.updatedAt,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as String,
      coachId: json['coach_id'] as String,
      userId: json['user_id'] as String,
      scheduledAt: json['scheduled_at'] as String,
      durationMinutes: json['duration_minutes'] as int?,
      status: json['status'] as String,
      type: json['type'] as String?,
      notes: json['notes'] as String?,
      coachName: json['coach_name'] as String?,
      userName: json['user_name'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'coach_id': coachId,
      'user_id': userId,
      'scheduled_at': scheduledAt,
      'duration_minutes': durationMinutes,
      'status': status,
      'type': type,
      'notes': notes,
      'coach_name': coachName,
      'user_name': userName,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  Appointment copyWith({
    String? id,
    String? coachId,
    String? userId,
    String? scheduledAt,
    int? durationMinutes,
    String? status,
    String? type,
    String? notes,
    String? coachName,
    String? userName,
    String? createdAt,
    String? updatedAt,
  }) {
    return Appointment(
      id: id ?? this.id,
      coachId: coachId ?? this.coachId,
      userId: userId ?? this.userId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      type: type ?? this.type,
      notes: notes ?? this.notes,
      coachName: coachName ?? this.coachName,
      userName: userName ?? this.userName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

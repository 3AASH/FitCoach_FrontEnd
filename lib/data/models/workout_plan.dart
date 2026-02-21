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
  });
  
  factory WorkoutPlan.fromJson(Map<String, dynamic> json) {
    final createdAtValue = json['created_at'] ?? json['createdAt'];
    return WorkoutPlan(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? json['userId'] ?? '').toString(),
      coachId: json['coach_id'] as String? ?? json['coachId'] as String?,
      name: json['name'] as String?,
      nameAr: json['nameAr'] as String?,
      description: json['description'] as String?,
      descriptionAr: json['descriptionAr'] as String?,
      planData: json['plan_data'] as Map<String, dynamic>? ?? json['planData'] as Map<String, dynamic>?,
      notes: json['notes'] as String?,
      days: json['days'] != null
          ? (json['days'] as List)
              .map((day) => WorkoutDay.fromJson(day as Map<String, dynamic>))
              .toList()
          : null,
      startDate: json['start_date'] != null || json['startDate'] != null
          ? DateTime.parse(json['start_date'] ?? json['startDate'] as String)
          : null,
      endDate: json['end_date'] != null || json['endDate'] != null
          ? DateTime.parse(json['end_date'] ?? json['endDate'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
      customizedByCoach: json['customized_by_coach'] as bool?,
      createdAt: createdAtValue != null
          ? DateTime.parse(createdAtValue as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null || json['updatedAt'] != null
          ? DateTime.parse(json['updated_at'] ?? json['updatedAt'] as String)
          : null,
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
  
  WorkoutDay({
    required this.id,
    required this.dayName,
    this.dayNameAr,
    required this.dayNumber,
    required this.exercises,
    this.notes,
  });
  
  factory WorkoutDay.fromJson(Map<String, dynamic> json) {
    return WorkoutDay(
      id: json['id'] as String,
      dayName: json['dayName'] as String,
      dayNameAr: json['dayNameAr'] as String?,
      dayNumber: json['dayNumber'] as int,
      exercises: (json['exercises'] as List)
          .map((ex) => Exercise.fromJson(ex as Map<String, dynamic>))
          .toList(),
      notes: json['notes'] as String?,
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
    };
  }
}

class Exercise {
  final String id;
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
    return Exercise(
      id: json['id'] as String,
      name: json['name'] as String,
      nameAr: json['nameAr'] as String,
      nameEn: json['nameEn'] as String,
      category: json['category'] as String?,
      muscleGroup: json['muscleGroup'] as String?,
      equipment: json['equipment'] as String?,
      difficulty: json['difficulty'] as String?,
      videoUrl: json['videoUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      instructions: json['instructions'] as String?,
      instructionsAr: json['instructionsAr'] as String?,
      instructionsEn: json['instructionsEn'] as String?,
      sets: json['sets'] as int,
      reps: json['reps'] as String,
      restTime: json['restTime'] as String?,
      tempo: json['tempo'] as String?,
      notes: json['notes'] as String?,
      contraindications: json['contraindications'] != null
          ? List<String>.from(json['contraindications'] as List)
          : [],
      alternatives: json['alternatives'] != null
          ? List<String>.from(json['alternatives'] as List)
          : [],
      isCompleted: json['isCompleted'] as bool? ?? false,
      order: json['order'] as int? ?? 0,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
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

class AdminExercise {
  final String id;
  final String? exId;
  final String nameEn;
  final String? nameAr;
  final String? descriptionEn;
  final String? descriptionAr;
  final String? category;
  final String? difficulty;
  final List<String> muscleGroups;

  /// The primary muscle the exercise trains. The swap list groups on this, so a
  /// wrong value here shows a client the wrong alternatives.
  final String? mainMuscle;

  /// Where the exercise can be trained: `home`, `gym` or `both`. The swap list
  /// is filtered by the client's first-intake location.
  final String? locationType;
  final List<String> equipment;
  final List<String> alternatives;
  final int? alternativesCount;
  final String? videoUrl;
  final String? thumbnailUrl;
  final String? instructions;

  const AdminExercise({
    required this.id,
    this.exId,
    required this.nameEn,
    this.nameAr,
    this.descriptionEn,
    this.descriptionAr,
    this.category,
    this.difficulty,
    this.muscleGroups = const [],
    this.mainMuscle,
    this.locationType,
    this.equipment = const [],
    this.alternatives = const [],
    this.alternativesCount,
    this.videoUrl,
    this.thumbnailUrl,
    this.instructions,
  });

  factory AdminExercise.fromJson(Map<String, dynamic> json) {
    final parsedAlternatives = _stringList(
      json['alternatives'] ?? json['alternative_exercises'] ?? json['swapOptions'],
    );
    final parsedAlternativeCount = _int(
      json['alternatives_count'] ??
          json['alternative_count'] ??
          json['swapOptionsCount'],
    );

    return AdminExercise(
      id: _string(json['id']) ?? _string(json['ex_id']) ?? '',
      exId: _string(json['ex_id'] ?? json['exId']),
      nameEn: _string(json['name_en'] ?? json['nameEn'] ?? json['name']) ??
          _string(json['ex_id']) ??
          'Exercise',
      nameAr: _string(json['name_ar'] ?? json['nameAr']),
      descriptionEn: _string(json['description_en'] ?? json['descriptionEn']),
      descriptionAr: _string(json['description_ar'] ?? json['descriptionAr']),
      category: _string(json['category']),
      difficulty: _string(json['difficulty']),
      muscleGroups: _stringList(json['muscle_groups'] ?? json['muscleGroups']),
      mainMuscle: _string(
        json['main_muscle'] ?? json['mainMuscle'] ?? json['muscle_group'] ?? json['muscleGroup'],
      ),
      locationType: _string(
        json['location_type'] ?? json['locationType'] ?? json['location'],
      ),
      equipment: _stringList(json['equipment']),
      alternatives: parsedAlternatives,
      alternativesCount: parsedAlternativeCount ??
          (parsedAlternatives.isNotEmpty ? parsedAlternatives.length : null),
      videoUrl: _string(json['video_url'] ?? json['videoUrl']),
      thumbnailUrl: _string(json['thumbnail_url'] ?? json['thumbnailUrl']),
      instructions: _string(json['instructions'] ?? json['instructions_en']),
    );
  }

  Map<String, dynamic> toAdminPayload() {
    return {
      if (_nonEmpty(exId) != null) 'exId': _nonEmpty(exId),
      'name': nameEn,
      if (_nonEmpty(nameAr) != null) 'nameAr': _nonEmpty(nameAr),
      if (_nonEmpty(descriptionEn) != null)
        'description': _nonEmpty(descriptionEn),
      if (_nonEmpty(descriptionAr) != null)
        'descriptionAr': _nonEmpty(descriptionAr),
      if (_nonEmpty(category) != null) 'category': _nonEmpty(category),
      if (_nonEmpty(difficulty) != null) 'difficulty': _nonEmpty(difficulty),
      'muscleGroups': muscleGroups,
      if (_nonEmpty(mainMuscle) != null) 'mainMuscle': _nonEmpty(mainMuscle),
      if (_nonEmpty(locationType) != null)
        'locationType': _nonEmpty(locationType),
      'equipment': equipment,
      'alternatives': alternatives,
      if (_nonEmpty(videoUrl) != null) 'videoUrl': _nonEmpty(videoUrl),
      if (_nonEmpty(thumbnailUrl) != null)
        'thumbnailUrl': _nonEmpty(thumbnailUrl),
      if (_nonEmpty(instructions) != null)
        'instructions': _nonEmpty(instructions),
    };
  }

  AdminExercise copyWith({
    String? id,
    String? exId,
    String? nameEn,
    String? nameAr,
    String? descriptionEn,
    String? descriptionAr,
    String? category,
    String? difficulty,
    List<String>? muscleGroups,
    String? mainMuscle,
    String? locationType,
    List<String>? equipment,
    List<String>? alternatives,
    int? alternativesCount,
    String? videoUrl,
    String? thumbnailUrl,
    String? instructions,
  }) {
    return AdminExercise(
      id: id ?? this.id,
      exId: exId ?? this.exId,
      nameEn: nameEn ?? this.nameEn,
      nameAr: nameAr ?? this.nameAr,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      muscleGroups: muscleGroups ?? this.muscleGroups,
      mainMuscle: mainMuscle ?? this.mainMuscle,
      locationType: locationType ?? this.locationType,
      equipment: equipment ?? this.equipment,
      alternatives: alternatives ?? this.alternatives,
      alternativesCount: alternativesCount ?? this.alternativesCount,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      instructions: instructions ?? this.instructions,
    );
  }

  bool get hasAlternatives => (alternativesCount ?? alternatives.length) > 0;

  static String? _string(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static String? _nonEmpty(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    if (value is String && value.trim().isNotEmpty) {
      return value
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }

  static int? _int(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}

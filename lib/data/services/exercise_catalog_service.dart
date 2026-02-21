import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class ExerciseCatalogService {
  ExerciseCatalogService._();

  static final ExerciseCatalogService instance = ExerciseCatalogService._();

  ExerciseCatalog? _catalog;
  Future<ExerciseCatalog> load() async {
    if (_catalog != null) return _catalog!;
    final raw = await rootBundle.loadString('assets/data/exercises_catalog_v1.json');
    final data = json.decode(raw) as Map<String, dynamic>;
    _catalog = ExerciseCatalog.fromJson(data);
    return _catalog!;
  }

  ExerciseCatalog? get catalog => _catalog;

  ExerciseCatalogItem? getById(String id) {
    if (_catalog == null) return null;
    return _catalog!.byId[id];
  }

  String? getEquipLabel(String key, {required bool isArabic}) {
    if (!isArabic) return _titleize(key);
    return _catalog?.equipArMap[key] ?? key;
  }

  String? getMuscleLabel(String key, {required bool isArabic}) {
    if (!isArabic) return _titleize(key.replaceAll('_', ' '));
    return _catalog?.musclesArMap[key] ?? key;
  }

  String _titleize(String input) {
    if (input.isEmpty) return input;
    final words = input.replaceAll('_', ' ').split(' ');
    return words
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}

class ExerciseCatalog {
  final String? generatedAt;
  final String? source;
  final int? total;
  final Map<String, String> equipArMap;
  final Map<String, String> musclesArMap;
  final List<ExerciseCatalogItem> exercises;
  final Map<String, ExerciseCatalogItem> byId;

  ExerciseCatalog({
    this.generatedAt,
    this.source,
    this.total,
    required this.equipArMap,
    required this.musclesArMap,
    required this.exercises,
  }) : byId = {for (final ex in exercises) ex.id: ex};

  factory ExerciseCatalog.fromJson(Map<String, dynamic> json) {
    final equipMapRaw = json['equip_ar_map'] as Map<String, dynamic>? ?? {};
    final muscleMapRaw = json['muscles_ar_map'] as Map<String, dynamic>? ?? {};
    final exercisesRaw = json['exercises'] as List? ?? const [];

    return ExerciseCatalog(
      generatedAt: json['generated_at'] as String?,
      source: json['source'] as String?,
      total: json['total'] as int?,
      equipArMap: equipMapRaw.map((k, v) => MapEntry(k, v.toString())),
      musclesArMap: muscleMapRaw.map((k, v) => MapEntry(k, v.toString())),
      exercises: exercisesRaw
          .map((e) => ExerciseCatalogItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ExerciseCatalogItem {
  final String id;
  final String nameEn;
  final String nameAr;
  final List<String> equip;
  final List<String> muscles;
  final String? videoId;
  final String? videoUrl;
  final String? thumbnailUrl;
  final String? instructionsEn;
  final String? instructionsAr;
  final String? commonMistakesEn;
  final String? commonMistakesAr;
  final int? defaultSets;
  final String? defaultReps;
  final int? defaultRestSeconds;

  ExerciseCatalogItem({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.equip,
    required this.muscles,
    this.videoId,
    this.videoUrl,
    this.thumbnailUrl,
    this.instructionsEn,
    this.instructionsAr,
    this.commonMistakesEn,
    this.commonMistakesAr,
    this.defaultSets,
    this.defaultReps,
    this.defaultRestSeconds,
  });

  factory ExerciseCatalogItem.fromJson(Map<String, dynamic> json) {
    return ExerciseCatalogItem(
      id: (json['ex_id'] ?? '').toString(),
      nameEn: (json['name_en'] ?? '').toString(),
      nameAr: (json['name_ar'] ?? '').toString(),
      equip: (json['equip'] as List? ?? const []).map((e) => e.toString()).toList(),
      muscles: (json['muscles'] as List? ?? const []).map((e) => e.toString()).toList(),
      videoId: json['video_id'] as String?,
      videoUrl: json['video_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      instructionsEn: json['instructions_en'] as String?,
      instructionsAr: json['instructions_ar'] as String?,
      commonMistakesEn: json['common_mistakes_en'] as String?,
      commonMistakesAr: json['common_mistakes_ar'] as String?,
      defaultSets: json['default_sets'] as int?,
      defaultReps: json['default_reps'] as String?,
      defaultRestSeconds: json['default_rest_seconds'] as int?,
    );
  }
}

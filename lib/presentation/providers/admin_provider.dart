import 'package:flutter/material.dart';
import '../../core/config/demo_config.dart';
import '../../data/demo/demo_data.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/models/admin_analytics.dart';
import '../../data/models/admin_user.dart';
import '../../data/models/admin_coach.dart';
import '../../data/models/admin_exercise.dart';
import '../../data/models/admin_workout_template.dart';
import '../../data/models/revenue_analytics.dart';
import '../../data/models/audit_log.dart';

class AdminProvider extends ChangeNotifier {
  final AdminRepository _repository;

  AdminProvider(this._repository);

  // State
  bool _isLoading = false;
  String? _error;
  String? _usersError;
  String? _coachesError;

  AdminAnalytics? _analytics;
  List<AdminUser> _users = [];
  AdminUser? _selectedUser;
  List<AdminCoach> _coaches = [];
  List<AdminExercise> _exercises = [];
  List<AdminWorkoutTemplate> _workoutTemplates = [];
  List<Map<String, dynamic>> _nutritionMealTemplates = [];
  List<Map<String, dynamic>> _nutritionEngineRecipes = [];
  List<Map<String, dynamic>> _nutritionEnginePlans = [];
  List<Map<String, dynamic>> _nutritionEngineImports = [];
  RevenueAnalytics? _revenueAnalytics;
  List<AuditLog> _auditLogs = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get usersError => _usersError;
  String? get coachesError => _coachesError;
  AdminAnalytics? get analytics => _analytics;
  List<AdminUser> get users => _users;
  AdminUser? get selectedUser => _selectedUser;
  List<AdminCoach> get coaches => _coaches;
  List<AdminExercise> get exercises => _exercises;
  List<AdminWorkoutTemplate> get workoutTemplates => _workoutTemplates;
  List<Map<String, dynamic>> get nutritionMealTemplates =>
      _nutritionMealTemplates;
  List<Map<String, dynamic>> get nutritionEngineRecipes =>
      _nutritionEngineRecipes;
  List<Map<String, dynamic>> get nutritionEnginePlans => _nutritionEnginePlans;
  List<Map<String, dynamic>> get nutritionEngineImports =>
      _nutritionEngineImports;
  List<AdminCoach> get pendingCoaches =>
      _coaches.where((c) => c.isPending).toList();
  void _upsertCoach(AdminCoach coach) {
    final index = _coaches.indexWhere((item) => item.id == coach.id);
    if (index == -1) {
      _coaches = [coach, ..._coaches];
      return;
    }
    final updated = [..._coaches];
    updated[index] = coach;
    _coaches = updated;
  }

  void _removeCoach(String coachId) {
    _coaches = _coaches.where((coach) => coach.id != coachId).toList();
  }

  RevenueAnalytics? get revenueAnalytics => _revenueAnalytics;
  List<AuditLog> get auditLogs => _auditLogs;

  /// Load dashboard analytics
  Future<void> loadDashboardAnalytics() async {
    if (DemoConfig.isDemo) {
      _analytics = DemoData.adminAnalytics();
      _error = null;
      _isLoading = false;
      notifyListeners();
      return;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _analytics = await _repository.getDashboardAnalytics();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load users
  Future<void> loadUsers({
    String? search,
    String? subscriptionTier,
    String? status,
    String? coachId,
    String? role,
  }) async {
    if (DemoConfig.isDemo) {
      final users = DemoData.adminUsers();
      if (role == 'admins') {
        _users = users.where((user) => user.role == 'admin').toList();
      } else {
        _users = users.where((user) => user.role != 'admin').toList();
      }
      _error = null;
      _usersError = null;
      _isLoading = false;
      notifyListeners();
      return;
    }
    _isLoading = true;
    _usersError = null;
    _error = null;
    notifyListeners();

    try {
      _users = await _repository.getUsers(
        search: search,
        subscriptionTier: subscriptionTier,
        status: status,
        coachId: coachId,
        role: role,
      );
      _usersError = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _usersError = e.toString();
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load user by ID
  Future<void> loadUserById(String id) async {
    if (DemoConfig.isDemo) {
      _selectedUser = DemoData.adminUsers().firstWhere((user) => user.id == id,
          orElse: () => DemoData.adminUsers().first);
      _error = null;
      _isLoading = false;
      notifyListeners();
      return;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedUser = await _repository.getUserById(id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update user
  Future<bool> updateUser(
    String id, {
    String? fullName,
    String? email,
    String? subscriptionTier,
    bool? isActive,
    String? coachId,
  }) async {
    if (DemoConfig.isDemo) {
      final index = _users.indexWhere((u) => u.id == id);
      if (index != -1) {
        final user = _users[index];
        final resolvedCoachName = coachId == null
            ? null
            : DemoData.adminCoaches()
                .firstWhere(
                  (coach) => coach.id == coachId,
                  orElse: () => DemoData.adminCoaches().first,
                )
                .fullName;
        _users[index] = AdminUser(
          id: user.id,
          fullName: fullName ?? user.fullName,
          email: email ?? user.email,
          phoneNumber: user.phoneNumber,
          profilePhotoUrl: user.profilePhotoUrl,
          subscriptionTier: subscriptionTier ?? user.subscriptionTier,
          isActive: isActive ?? user.isActive,
          coachId: coachId ?? user.coachId,
          coachName: resolvedCoachName ?? user.coachName,
          createdAt: user.createdAt,
          lastLogin: user.lastLogin,
        );
        _selectedUser = _users[index];
        notifyListeners();
      }
      return true;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.updateUser(
        id,
        fullName: fullName,
        email: email,
        subscriptionTier: subscriptionTier,
        isActive: isActive,
        coachId: coachId,
      );

      // Ensure UI reflects backend source of truth after subscription/coach update.
      await Future.wait([
        loadUsers(),
        loadCoaches(),
      ]);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Suspend user
  Future<bool> suspendUser(String id, String reason) async {
    if (DemoConfig.isDemo) {
      await loadUsers();
      return true;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.suspendUser(id, reason);

      // Reload users
      await loadUsers();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete user
  Future<bool> deleteUser(String id) async {
    if (DemoConfig.isDemo) {
      _users.removeWhere((u) => u.id == id);
      notifyListeners();
      return true;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.deleteUser(id);

      // Remove from list
      _users.removeWhere((u) => u.id == id);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<AdminCreationResult?> createAdmin({
    required String fullName,
    required String email,
    String? phoneNumber,
    String? password,
  }) async {
    if (DemoConfig.isDemo) {
      final now = DateTime.now();
      final admin = AdminUser(
        id: 'admin_${now.microsecondsSinceEpoch}',
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        subscriptionTier: 'freemium',
        isActive: true,
        createdAt: now,
      );
      _users.insert(0, admin);
      notifyListeners();
      return AdminCreationResult(
        admin: admin,
        credentials: CoachCredentials(
          email: email,
          defaultPassword:
              password?.trim().isNotEmpty == true ? password!.trim() : '123456',
        ),
      );
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.createAdmin(
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Load coaches
  Future<void> loadCoaches({
    String? search,
    String? status,
    String? approved,
  }) async {
    if (DemoConfig.isDemo) {
      _coaches = DemoData.adminCoaches();
      _error = null;
      _coachesError = null;
      _isLoading = false;
      notifyListeners();
      return;
    }
    _isLoading = true;
    _coachesError = null;
    _error = null;
    notifyListeners();

    try {
      _coaches = await _repository.getCoaches(
        search: search,
        status: status,
        approved: approved,
      );
      _coachesError = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _coachesError = e.toString();
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create coach account directly and return login credentials
  Future<CoachCreationResult?> createCoach({
    required String fullName,
    required String email,
    required String phoneNumber,
    List<String> specializations = const [],
  }) async {
    if (DemoConfig.isDemo) {
      final now = DateTime.now();
      final tempId = now.microsecondsSinceEpoch.toString();
      final newCoach = AdminCoach(
        id: 'coach_$tempId',
        userId: 'user_$tempId',
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        profilePhotoUrl: null,
        specializations: specializations,
        clientCount: 0,
        totalEarnings: 0,
        averageRating: null,
        isApproved: true,
        isActive: true,
        createdAt: now,
        approvedAt: now,
      );
      _coaches = [newCoach, ..._coaches];
      notifyListeners();
      return CoachCreationResult(
        coach: newCoach,
        credentials: CoachCredentials(
          email: email,
          defaultPassword: '123456',
        ),
      );
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final created = await _repository.createCoach(
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        specializations: specializations,
      );
      final coach = AdminCoach(
        id: created.coach.id,
        userId: created.coach.userId,
        fullName: created.coach.fullName,
        email: created.coach.email,
        phoneNumber: created.coach.phoneNumber,
        profilePhotoUrl: created.coach.profilePhotoUrl,
        specializations: created.coach.specializations,
        clientCount: created.coach.clientCount,
        totalEarnings: created.coach.totalEarnings,
        averageRating: created.coach.averageRating,
        isApproved: true,
        isActive: true,
        createdAt: created.coach.createdAt,
        approvedAt: created.coach.approvedAt ?? DateTime.now(),
      );
      _coaches = [coach, ..._coaches];
      _isLoading = false;
      notifyListeners();
      return CoachCreationResult(
        coach: coach,
        credentials: created.credentials,
      );
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Approve coach
  Future<bool> approveCoach(String id) async {
    if (DemoConfig.isDemo) {
      await loadCoaches();
      return true;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.approveCoach(id);

      // Reload coaches
      await loadCoaches();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Suspend coach
  Future<bool> suspendCoach(String id, String reason) async {
    if (DemoConfig.isDemo) {
      final index = _coaches.indexWhere((coach) => coach.id == id);
      if (index != -1) {
        _upsertCoach(
          _coaches[index].copyWith(
            isActive: false,
            status: 'suspended',
            suspendedAt: DateTime.now(),
            suspensionReason: reason,
          ),
        );
        notifyListeners();
      }
      return true;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _repository.suspendCoach(id, reason);
      if (updated != null) {
        _upsertCoach(updated);
      } else {
        final existingIndex = _coaches.indexWhere((coach) => coach.id == id);
        if (existingIndex != -1) {
          _upsertCoach(
            _coaches[existingIndex].copyWith(
              isActive: false,
              status: 'suspended',
              suspendedAt: DateTime.now(),
              suspensionReason: reason,
            ),
          );
        }
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCoach(String id, AdminCoachUpdatePayload payload) async {
    if (DemoConfig.isDemo) {
      final index = _coaches.indexWhere((coach) => coach.id == id);
      if (index != -1) {
        final existing = _coaches[index];
        _upsertCoach(
          existing.copyWith(
            fullName: payload.fullName,
            fullNameAr: payload.fullNameAr,
            email: payload.email,
            phoneNumber: payload.phoneNumber,
            profilePhotoUrl: payload.profilePhotoUrl,
            bio: payload.bio,
            experienceYears: payload.yearsOfExperience,
            specializations: payload.specializations,
            isApproved: payload.isApproved,
            isActive: payload.isActive,
            status: payload.isActive
                ? (payload.isApproved ? 'approved' : 'pending')
                : 'suspended',
            approvedAt: payload.isApproved
                ? (existing.approvedAt ?? DateTime.now())
                : null,
            suspendedAt: payload.isActive
                ? null
                : existing.suspendedAt ?? DateTime.now(),
          ),
        );
        notifyListeners();
      }
      return true;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _repository.updateCoach(id, payload);
      _upsertCoach(updated);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCoach(String id) async {
    if (DemoConfig.isDemo) {
      _removeCoach(id);
      notifyListeners();
      return true;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.deleteCoach(id);
      _removeCoach(id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadExercises({
    String? search,
    String? category,
    String? difficulty,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _exercises = DemoConfig.isDemo
          ? DemoData.fallbackExerciseLibrary()
              .map(
                (exercise) => AdminExercise(
                  id: exercise.id,
                  exId: exercise.id,
                  nameEn: exercise.nameEn,
                  nameAr: exercise.nameAr,
                  category: exercise.category,
                  difficulty: exercise.difficulty,
                  muscleGroups: (exercise.muscleGroup ?? '')
                      .split(',')
                      .map((item) => item.trim())
                      .where((item) => item.isNotEmpty)
                      .toList(),
                  equipment: (exercise.equipment ?? '')
                      .split(',')
                      .map((item) => item.trim())
                      .where((item) => item.isNotEmpty)
                      .toList(),
                  alternatives: exercise.alternatives,
                  alternativesCount: exercise.alternatives.length,
                  videoUrl: exercise.videoUrl,
                  thumbnailUrl: exercise.thumbnailUrl,
                  instructions: exercise.instructions,
                ),
              )
              .toList()
          : await _repository.getExercises(
              search: search,
              category: category,
              difficulty: difficulty,
            );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createExercise(AdminExercise exercise) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final created = DemoConfig.isDemo
          ? exercise.copyWith(
              id: exercise.exId ??
                  DateTime.now().microsecondsSinceEpoch.toString(),
            )
          : await _repository.createExercise(exercise);
      _exercises = [created, ..._exercises];
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateExercise(AdminExercise exercise) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updated = DemoConfig.isDemo
          ? exercise
          : await _repository.updateExercise(exercise);
      final index = _exercises.indexWhere((item) => item.id == updated.id);
      if (index == -1) {
        _exercises = [updated, ..._exercises];
      } else {
        final next = [..._exercises];
        next[index] = updated;
        _exercises = next;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteExercise(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (!DemoConfig.isDemo) {
        await _repository.deleteExercise(id);
      }
      _exercises = _exercises.where((exercise) => exercise.id != id).toList();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadExerciseVideo(String id, String filePath) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _repository.uploadExerciseVideo(id, filePath);
      final index = _exercises.indexWhere((item) => item.id == updated.id);
      if (index != -1) {
        final next = [..._exercises];
        next[index] = updated;
        _exercises = next;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadWorkoutTemplates({
    String? type,
    String? goal,
    String? location,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _workoutTemplates = DemoConfig.isDemo
          ? const []
          : await _repository.getWorkoutTemplates(
              type: type,
              goal: goal,
              location: location,
            );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> getWorkoutTemplate(String planId) async {
    try {
      return await _repository.getWorkoutTemplate(planId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> saveWorkoutTemplate(
    Map<String, dynamic> template, {
    bool includeCoachEdited = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.saveWorkoutTemplate(
        template,
        includeCoachEdited: includeCoachEdited,
      );
      await loadWorkoutTemplates();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> importWorkoutTemplatesFromFile(String filePath) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.importWorkoutTemplatesFromFile(filePath);
      await loadWorkoutTemplates();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> refreshWorkoutTemplateUsers(
    String planId, {
    bool includeCoachEdited = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.refreshWorkoutTemplateUsers(
        planId,
        includeCoachEdited: includeCoachEdited,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadNutritionMealTemplates({
    String? mealType,
    bool? active,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _nutritionMealTemplates = DemoConfig.isDemo
          ? const []
          : await _repository.getNutritionMealTemplates(
              mealType: mealType,
              active: active,
            );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> getNutritionMealTemplate(
      String templateId) async {
    try {
      return await _repository.getNutritionMealTemplate(templateId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> saveNutritionMealTemplate(Map<String, dynamic> template) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (!DemoConfig.isDemo) {
        await _repository.saveNutritionMealTemplate(template);
      }
      await loadNutritionMealTemplates();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> importNutritionMealTemplatesFromFile(String filePath) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (!DemoConfig.isDemo) {
        await _repository.importNutritionMealTemplatesFromFile(filePath);
      }
      await loadNutritionMealTemplates();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadNutritionEngineRecipes({
    String? search,
    String? validationStatus,
    bool? active,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _nutritionEngineRecipes = DemoConfig.isDemo
          ? const []
          : await _repository.getNutritionEngineRecipes(
              search: search,
              validationStatus: validationStatus,
              active: active,
            );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> getNutritionEngineRecipe(
      String recipeId) async {
    try {
      return await _repository.getNutritionEngineRecipe(recipeId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> saveNutritionEngineRecipe(Map<String, dynamic> recipe) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (!DemoConfig.isDemo) {
        await _repository.saveNutritionEngineRecipe(recipe);
      }
      await loadNutritionEngineRecipes();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadNutritionEnginePlans({
    String? planType,
    String? market,
    int? calorieBand,
    String? macroProfile,
    String? validationStatus,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _nutritionEnginePlans = DemoConfig.isDemo
          ? const []
          : await _repository.getNutritionEnginePlans(
              planType: planType,
              market: market,
              calorieBand: calorieBand,
              macroProfile: macroProfile,
              validationStatus: validationStatus,
            );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> getNutritionEnginePlan(String planId) async {
    try {
      return await _repository.getNutritionEnginePlan(planId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> saveNutritionEnginePlan(
    Map<String, dynamic> plan, {
    bool includeCoachEdited = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (!DemoConfig.isDemo) {
        await _repository.saveNutritionEnginePlan(
          plan,
          includeCoachEdited: includeCoachEdited,
        );
      }
      await loadNutritionEnginePlans();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadNutritionEngineImports() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _nutritionEngineImports = DemoConfig.isDemo
          ? const []
          : await _repository.getNutritionEngineImports();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> importNutritionEngineSeed({String? packageRoot}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (!DemoConfig.isDemo) {
        await _repository.importNutritionEngineSeed(packageRoot: packageRoot);
      }
      await Future.wait([
        loadNutritionEngineRecipes(),
        loadNutritionEnginePlans(),
        loadNutritionEngineImports(),
      ]);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Load revenue analytics
  Future<void> loadRevenueAnalytics({
    String period = 'month',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (DemoConfig.isDemo) {
      _revenueAnalytics = DemoData.revenueAnalytics();
      _error = null;
      _isLoading = false;
      notifyListeners();
      return;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _revenueAnalytics = await _repository.getRevenueAnalytics(
        period: period,
        startDate: startDate,
        endDate: endDate,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load audit logs
  Future<void> loadAuditLogs({
    String? userId,
    String? action,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (DemoConfig.isDemo) {
      _auditLogs = DemoData.auditLogs();
      _error = null;
      _isLoading = false;
      notifyListeners();
      return;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _auditLogs = await _repository.getAuditLogs(
        userId: userId,
        action: action,
        startDate: startDate,
        endDate: endDate,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Refresh all
  Future<void> refreshAll() async {
    await Future.wait([
      loadDashboardAnalytics(),
      loadUsers(),
      loadCoaches(),
    ]);
  }
}

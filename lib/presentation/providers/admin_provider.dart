import 'package:flutter/material.dart';
import '../../core/config/demo_config.dart';
import '../../data/demo/demo_data.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/models/admin_analytics.dart';
import '../../data/models/admin_user.dart';
import '../../data/models/admin_coach.dart';
import '../../data/models/revenue_analytics.dart';
import '../../data/models/audit_log.dart';

class AdminProvider extends ChangeNotifier {
  final AdminRepository _repository;

  AdminProvider(this._repository);

  // State
  bool _isLoading = false;
  String? _error;

  AdminAnalytics? _analytics;
  List<AdminUser> _users = [];
  AdminUser? _selectedUser;
  List<AdminCoach> _coaches = [];
  RevenueAnalytics? _revenueAnalytics;
  List<AuditLog> _auditLogs = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  AdminAnalytics? get analytics => _analytics;
  List<AdminUser> get users => _users;
  AdminUser? get selectedUser => _selectedUser;
  List<AdminCoach> get coaches => _coaches;
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
  }) async {
    if (DemoConfig.isDemo) {
      _users = DemoData.adminUsers();
      _error = null;
      _isLoading = false;
      notifyListeners();
      return;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _users = await _repository.getUsers(
        search: search,
        subscriptionTier: subscriptionTier,
        status: status,
        coachId: coachId,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
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

  /// Load coaches
  Future<void> loadCoaches({
    String? search,
    String? status,
    String? approved,
  }) async {
    if (DemoConfig.isDemo) {
      _coaches = DemoData.adminCoaches();
      _error = null;
      _isLoading = false;
      notifyListeners();
      return;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _coaches = await _repository.getCoaches(
        search: search,
        status: status,
        approved: approved,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
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

import 'package:flutter/material.dart';
import '../../core/config/demo_config.dart';
import '../../data/demo/demo_data.dart';
import '../../data/repositories/coach_repository.dart';
import '../../data/models/coach_client.dart';
import '../../data/models/appointment.dart';
import '../../data/models/coach_analytics.dart';
import '../../data/models/coach_earnings.dart';
import '../../data/models/workout_plan.dart';
import '../../data/models/nutrition_plan.dart';

class CoachProvider extends ChangeNotifier {
  final CoachRepository _repository;

  CoachProvider(this._repository);

  // State
  bool _isLoading = false;
  bool _isAnalyticsLoading = false;
  bool _isAppointmentsLoading = false;
  String? _error;
  
  List<CoachClient> _clients = [];
  List<Appointment> _appointments = [];
  CoachAnalytics? _analytics;
  CoachEarnings? _earnings;
  CoachClient? _selectedClient;

  // Getters
  bool get isLoading => _isLoading;
  bool get isAnalyticsLoading => _isAnalyticsLoading;
  bool get isAppointmentsLoading => _isAppointmentsLoading;
  String? get error => _error;
  List<CoachClient> get clients => _clients;
  List<Appointment> get appointments => _appointments;
  CoachAnalytics? get analytics => _analytics;
  CoachEarnings? get earnings => _earnings;
  CoachClient? get selectedClient => _selectedClient;

  /// Load coach analytics
  Future<void> loadAnalytics(String coachId) async {
    _isAnalyticsLoading = true;
    _error = null;
    notifyListeners();

    if (DemoConfig.isDemo) {
      _analytics = DemoData.coachAnalytics();
      _isAnalyticsLoading = false;
      notifyListeners();
      return;
    }

    try {
      _analytics = await _repository.getAnalytics(coachId: coachId);
      _isAnalyticsLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isAnalyticsLoading = false;
      notifyListeners();
    }
  }

  /// Load clients
  Future<void> loadClients({
    required String coachId,
    String? status,
    String? search,
  }) async {
    if (DemoConfig.isDemo) {
      _clients = DemoData.coachClients();
      _error = null;
      _isLoading = false;
      notifyListeners();
      return;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _clients = await _repository.getClients(
        coachId: coachId,
        status: status,
        search: search,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load client details
  Future<void> loadClientDetails({
    required String coachId,
    required String clientId,
  }) async {
    if (DemoConfig.isDemo) {
      _selectedClient = DemoData.coachClients()
          .firstWhere((client) => client.id == clientId, orElse: () => DemoData.coachClients().first);
      _error = null;
      _isLoading = false;
      notifyListeners();
      return;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedClient = await _repository.getClientById(
        coachId: coachId,
        clientId: clientId,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load appointments
  Future<void> loadAppointments({
    required String coachId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _isAppointmentsLoading = true;
    _error = null;
    notifyListeners();

    if (DemoConfig.isDemo) {
      _appointments = DemoData.coachAppointments(
        coachId: coachId,
        userId: DemoConfig.demoUserId,
      );
      _isAppointmentsLoading = false;
      notifyListeners();
      return;
    }

    try {
      _appointments = await _repository.getAppointments(
        coachId: coachId,
        status: status,
        startDate: startDate,
        endDate: endDate,
      );
      _isAppointmentsLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isAppointmentsLoading = false;
      notifyListeners();
    }
  }

  /// Create appointment
  Future<bool> createAppointment({
    required String coachId,
    required String userId,
    required DateTime scheduledAt,
    required int duration,
    required String type,
    String? notes,
  }) async {
    if (DemoConfig.isDemo) {
      _appointments.add(
        Appointment(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          coachId: coachId,
          userId: userId,
          scheduledAt: scheduledAt.toIso8601String(),
          durationMinutes: duration,
          status: 'confirmed',
          type: type,
          notes: notes,
          coachName: 'Coach Sam',
          userName: 'Demo User',
        ),
      );
      notifyListeners();
      return true;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final appointment = await _repository.createAppointment(
        coachId: coachId,
        userId: userId,
        scheduledAt: scheduledAt,
        duration: duration,
        type: type,
        notes: notes,
      );

      _appointments.add(appointment);
      _appointments.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      
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

  /// Update appointment
  Future<bool> updateAppointment({
    required String coachId,
    required String appointmentId,
    DateTime? scheduledAt,
    int? duration,
    String? type,
    String? notes,
    String? status,
  }) async {
    if (DemoConfig.isDemo) {
      final index = _appointments.indexWhere((a) => a.id == appointmentId);
      if (index != -1) {
        final current = _appointments[index];
        _appointments[index] = current.copyWith(
          scheduledAt: scheduledAt?.toIso8601String(),
          durationMinutes: duration,
          type: type,
          notes: notes,
          status: status,
        );
      }
      notifyListeners();
      return true;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _repository.updateAppointment(
        coachId: coachId,
        appointmentId: appointmentId,
        scheduledAt: scheduledAt,
        duration: duration,
        type: type,
        notes: notes,
        status: status,
      );

      final index = _appointments.indexWhere((a) => a.id == appointmentId);
      if (index != -1) {
        _appointments[index] = updated;
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

  /// Load earnings
  Future<void> loadEarnings({
    required String coachId,
    String period = 'month',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (DemoConfig.isDemo) {
      _earnings = DemoData.coachEarnings();
      _error = null;
      _isLoading = false;
      notifyListeners();
      return;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _earnings = await _repository.getEarnings(
        coachId: coachId,
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

  /// Assign fitness score
  Future<bool> assignFitnessScore({
    required String coachId,
    required String clientId,
    required int fitnessScore,
    String? notes,
  }) async {
    if (DemoConfig.isDemo) {
      final index = _clients.indexWhere((c) => c.id == clientId);
      if (index != -1) {
        final client = _clients[index];
        _clients[index] = CoachClient(
          id: client.id,
          fullName: client.fullName,
          email: client.email,
          phoneNumber: client.phoneNumber,
          profilePhotoUrl: client.profilePhotoUrl,
          subscriptionTier: client.subscriptionTier,
          goal: client.goal,
          isActive: client.isActive,
          assignedDate: client.assignedDate,
          lastActivity: client.lastActivity,
          fitnessScore: fitnessScore,
          workoutPlanId: client.workoutPlanId,
          workoutPlanName: client.workoutPlanName,
          nutritionPlanId: client.nutritionPlanId,
          nutritionPlanName: client.nutritionPlanName,
          messageCount: client.messageCount,
        );
        notifyListeners();
      }
      return true;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.assignFitnessScore(
        coachId: coachId,
        clientId: clientId,
        fitnessScore: fitnessScore,
        notes: notes,
      );

      // Update client in list
      final index = _clients.indexWhere((c) => c.id == clientId);
      if (index != -1) {
        // Reload clients to get updated score
        await loadClients(coachId: coachId);
      }

      // Update selected client if it's the same
      if (_selectedClient?.id == clientId) {
        await loadClientDetails(coachId: coachId, clientId: clientId);
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

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Get client's workout plan
  Future<WorkoutPlan?> getClientWorkoutPlan(
    String coachId,
    String clientId,
  ) async {
    if (DemoConfig.isDemo) {
      return DemoData.workoutPlan(userId: clientId);
    }
    try {
      return await _repository.getClientWorkoutPlan(
        coachId: coachId,
        clientId: clientId,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Update client's workout plan
  Future<bool> updateClientWorkoutPlan(
    String coachId,
    String clientId,
    Map<String, dynamic> planData,
    String notes,
  ) async {
    if (DemoConfig.isDemo) {
      return true;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.updateClientWorkoutPlan(
        coachId: coachId,
        clientId: clientId,
        planData: planData,
        notes: notes,
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

  /// Get client's nutrition plan
  Future<NutritionPlan?> getClientNutritionPlan(
    String coachId,
    String clientId,
  ) async {
    if (DemoConfig.isDemo) {
      return DemoData.nutritionPlan(userId: clientId);
    }
    try {
      return await _repository.getClientNutritionPlan(
        coachId: coachId,
        clientId: clientId,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Update client's nutrition plan
  Future<bool> updateClientNutritionPlan(
    String coachId,
    String clientId,
    int dailyCalories,
    Map<String, dynamic> macros,
    Map<String, dynamic> mealPlan,
    String notes,
  ) async {
    if (DemoConfig.isDemo) {
      return true;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.updateClientNutritionPlan(
        coachId: coachId,
        clientId: clientId,
        dailyCalories: dailyCalories,
        macros: macros,
        mealPlan: mealPlan,
        notes: notes,
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

  /// Refresh all data
  Future<void> refreshAll(String coachId) async {
    await Future.wait([
      loadAnalytics(coachId),
      loadClients(coachId: coachId),
      loadAppointments(coachId: coachId),
    ]);
  }
}

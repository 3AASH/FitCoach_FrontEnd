import 'package:flutter/material.dart';
import '../../core/config/demo_mode.dart';
import '../../data/demo/repositories/demo_subscription_plan_repository.dart';
import '../../data/models/subscription_plan.dart';
import '../../data/repositories/subscription_plan_repository.dart';

class SubscriptionPlanProvider extends ChangeNotifier {
  final SubscriptionPlanRepository _repository;
  final DemoSubscriptionPlanRepository _demoRepository;
  final DemoModeConfig _demoConfig;

  SubscriptionPlanProvider(
    this._repository, {
    DemoSubscriptionPlanRepository? demoRepository,
    DemoModeConfig? demoConfig,
  })  : _demoRepository = demoRepository ?? DemoSubscriptionPlanRepository(),
        _demoConfig = demoConfig ?? const DemoModeConfig();

  List<SubscriptionPlan> _plans = [];
  bool _isLoading = false;
  bool _isSaving = false;
  bool _hasLoaded = false;
  String? _error;

  Map<String, dynamic>? _mySubscription;
  Map<String, dynamic>? _latestRequest;
  List<Map<String, dynamic>> _pendingRequests = [];
  bool _isLoadingRequests = false;

  List<SubscriptionPlan> get plans => _plans;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get hasLoaded => _hasLoaded;
  String? get error => _error;

  Map<String, dynamic>? get mySubscription => _mySubscription;
  Map<String, dynamic>? get latestRequest => _latestRequest;
  bool get hasPendingRequest => _latestRequest?['status'] == 'pending';
  List<Map<String, dynamic>> get pendingRequests => _pendingRequests;
  bool get isLoadingRequests => _isLoadingRequests;

  List<SubscriptionPlan> get paidPlans =>
      _plans.where((plan) => !plan.isFree).toList()
        ..sort((a, b) => a.monthlyPrice.compareTo(b.monthlyPrice));

  SubscriptionPlan? get freemiumPlan {
    try {
      return _plans.firstWhere((plan) => plan.isFree);
    } catch (_) {
      return _plans.isNotEmpty ? _plans.first : null;
    }
  }

  List<String> get comparisonFeatureLabels {
    final orderMap = <String, int>{};
    for (final plan in _plans) {
      for (final feature in plan.features) {
        if (!orderMap.containsKey(feature.label) ||
            feature.order < (orderMap[feature.label] ?? feature.order)) {
          orderMap[feature.label] = feature.order;
        }
      }
    }
    final labels = orderMap.keys.toList();
    labels.sort((a, b) => (orderMap[a] ?? 0).compareTo(orderMap[b] ?? 0));
    return labels;
  }

  Future<void> loadPlans({bool forceRefresh = false}) async {
    if (_isLoading) return;
    if (_hasLoaded && !forceRefresh) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_demoConfig.isDemo) {
        _plans = await _demoRepository.getPlans();
      } else {
        _plans = await _repository.getPlans();
      }
      _hasLoaded = true;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> savePlan(SubscriptionPlan plan) async {
    if (_demoConfig.isDemo) {
      _upsertPlan(plan);
      notifyListeners();
      return true;
    }

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final exists = _plans.any((p) => p.id == plan.id);
      final persisted = exists
          ? await _repository.updatePlan(plan)
          : await _repository.createPlan(plan);
      _upsertPlan(persisted);
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePlan(String id) async {
    if (_demoConfig.isDemo) {
      _plans.removeWhere((plan) => plan.id == id);
      notifyListeners();
      return true;
    }

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.deletePlan(id);
      _plans.removeWhere((plan) => plan.id == id);
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  SubscriptionPlan? findById(String id) {
    final query = id.toLowerCase();
    for (final plan in _plans) {
      if (plan.id.toLowerCase() == query) {
        return plan;
      }
    }
    return null;
  }

  SubscriptionPlan? matchTier(String tier) {
    final query = tier.toLowerCase();
    for (final plan in _plans) {
      if (plan.id.toLowerCase() == query || plan.name.toLowerCase() == query) {
        return plan;
      }
    }
    return null;
  }

  /// Load the user's current subscription and latest request state.
  Future<void> loadMySubscription() async {
    if (_demoConfig.isDemo) return;
    try {
      final data = await _repository.getMySubscription();
      _mySubscription = data['subscription'] as Map<String, dynamic>?;
      _latestRequest = data['latestRequest'] as Map<String, dynamic>?;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Submit a subscription request for [planId].
  /// Payment is settled manually with the admin; access is granted on approval.
  Future<bool> submitRequest(String planId) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      _latestRequest = await _repository.requestSubscription(planId);
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelRequest() async {
    final requestId = _latestRequest?['id'] as String?;
    if (requestId == null) return false;

    try {
      await _repository.cancelRequest(requestId);
      _latestRequest = {..._latestRequest!, 'status': 'cancelled'};
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Admin: load pending subscription requests.
  Future<void> loadRequests({String status = 'pending'}) async {
    if (_isLoadingRequests) return;
    _isLoadingRequests = true;
    _error = null;
    notifyListeners();

    try {
      _pendingRequests = await _repository.getRequests(status: status);
      _isLoadingRequests = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoadingRequests = false;
      notifyListeners();
    }
  }

  /// Admin: approve or reject a request, then drop it from the local list.
  Future<bool> decideRequest(String requestId, {required bool approve, String? notes}) async {
    try {
      if (approve) {
        await _repository.approveRequest(requestId, adminNotes: notes);
      } else {
        await _repository.rejectRequest(requestId, adminNotes: notes);
      }
      _pendingRequests.removeWhere((r) => r['id'] == requestId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void _upsertPlan(SubscriptionPlan plan) {
    final index = _plans.indexWhere((p) => p.id == plan.id);
    if (index != -1) {
      _plans[index] = plan;
    } else {
      _plans = [..._plans, plan];
    }
  }
}

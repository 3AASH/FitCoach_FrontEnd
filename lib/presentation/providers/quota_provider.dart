import 'package:flutter/material.dart';
import '../../core/config/demo_config.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/models/quota_status.dart';

class QuotaProvider extends ChangeNotifier {
  final UserRepository _repository;
  
  int _messagesUsed = 0;
  int _messagesLimit = 0;
  int _videoCallsUsed = 0;
  int _videoCallsLimit = 0;
  int _messagePercentage = 0;
  int _callPercentage = 0;
  bool _messageWarning = false;
  bool _callWarning = false;
  String _subscriptionTier = '';
  int? _trialDaysRemaining;
  DateTime? _quotaResetDate;
  bool _isLoading = false;
  String? _error;
  
  // Quota limits by tier
  static const Map<String, Map<String, int>> quotaLimits = {
    'Freemium': {
      'messages': 20,
      'videoCalls': 1,
    },
    'Premium': {
      'messages': 200,
      'videoCalls': 2,
    },
    'Smart Premium': {
      'messages': -1, // Unlimited
      'videoCalls': 4,
    },
  };
  
  QuotaProvider(this._repository);
  
  // Getters
  int get messagesUsed => _messagesUsed;
  int get messagesLimit => _messagesLimit;
  int get messagesRemaining => _messagesLimit == -1 ? -1 : _messagesLimit - _messagesUsed;
  int get videoCallsUsed => _videoCallsUsed;
  int get videoCallsLimit => _videoCallsLimit;
  int get videoCallsRemaining => _videoCallsLimit == -1 ? -1 : _videoCallsLimit - _videoCallsUsed;
  int get messagePercentage => _messagePercentage;
  int get callPercentage => _callPercentage;
  bool get messageWarning => _messageWarning;
  bool get callWarning => _callWarning;
  String get subscriptionTier => _subscriptionTier;
  int? get trialDaysRemaining => _trialDaysRemaining;
  DateTime? get quotaResetDate => _quotaResetDate;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMessagesRemaining => _messagesLimit == -1 || messagesRemaining > 0;
  bool get hasVideoCallsRemaining => _videoCallsLimit == -1 || videoCallsRemaining > 0;
  double get messagesUsagePercentage => _messagesLimit == -1 || _messagesLimit == 0 ? 0 : (_messagesUsed / _messagesLimit).clamp(0.0, 1.0);
  double get videoCallsUsagePercentage => _videoCallsLimit == -1 || _videoCallsLimit == 0 ? 0 : (_videoCallsUsed / _videoCallsLimit).clamp(0.0, 1.0);
  
  // Load quota usage (new API)
  Future<void> loadQuota(String userId) async {
    if (DemoConfig.isDemo) {
      _messagesUsed = 6;
      _messagesLimit = 200;
      _videoCallsUsed = 1;
      _videoCallsLimit = 4;
      _messagePercentage = 3;
      _callPercentage = 25;
      _messageWarning = false;
      _callWarning = false;
      _subscriptionTier = 'Smart Premium';
      _trialDaysRemaining = 11;
      _quotaResetDate = DateTime.now().add(const Duration(days: 12));
      _isLoading = false;
      _error = null;
      notifyListeners();
      return;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final QuotaStatus quota = await _repository.getUserQuota(userId);
      _messagesUsed = quota.messagesSentThisMonth;
      _messagesLimit = quota.messageQuota;
      _videoCallsUsed = quota.videoCallsThisMonth;
      _videoCallsLimit = quota.callQuota;
      _messagePercentage = quota.messagePercentage;
      _callPercentage = quota.callPercentage;
      _messageWarning = quota.messageWarning;
      _callWarning = quota.callWarning;
      _subscriptionTier = quota.subscriptionTier;
      _trialDaysRemaining = quota.trialDaysRemaining;
      _quotaResetDate = quota.quotaResetDate;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Set quota limits based on subscription tier
  void setLimitsForTier(String tier) {
    final limits = quotaLimits[tier];
    
    if (limits != null) {
      _messagesLimit = limits['messages'] ?? 0;
      _videoCallsLimit = limits['videoCalls'] ?? 0;
      notifyListeners();
    }
  }
  
  // Increment message count
  void incrementMessageCount() {
    _messagesUsed++;
    notifyListeners();
  }
  
  // Increment video call count
  void incrementVideoCallCount() {
    _videoCallsUsed++;
    notifyListeners();
  }
  
  // Check if user can send message
  bool canSendMessage() {
    return hasMessagesRemaining;
  }
  
  // Check if user can make video call
  bool canMakeVideoCall() {
    return hasVideoCallsRemaining;
  }
  
  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

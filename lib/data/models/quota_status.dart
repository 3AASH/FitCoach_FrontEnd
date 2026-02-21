class QuotaStatus {
  final String subscriptionTier;
  final int messagesSentThisMonth;
  final int videoCallsThisMonth;
  final DateTime? quotaResetDate;
  final int messageQuota;
  final int callQuota;
  final int? trialDaysRemaining;
  final int messagePercentage;
  final int callPercentage;
  final bool messageWarning;
  final bool callWarning;

  QuotaStatus({
    required this.subscriptionTier,
    required this.messagesSentThisMonth,
    required this.videoCallsThisMonth,
    required this.quotaResetDate,
    required this.messageQuota,
    required this.callQuota,
    required this.trialDaysRemaining,
    required this.messagePercentage,
    required this.callPercentage,
    required this.messageWarning,
    required this.callWarning,
  });

  factory QuotaStatus.fromJson(Map<String, dynamic> json) {
    return QuotaStatus(
      subscriptionTier: json['subscription_tier'] ?? '',
      messagesSentThisMonth: json['messages_sent_this_month'] ?? 0,
      videoCallsThisMonth: json['video_calls_this_month'] ?? 0,
      quotaResetDate: json['quota_reset_date'] != null ? DateTime.tryParse(json['quota_reset_date']) : null,
      messageQuota: json['message_quota'] ?? 0,
      callQuota: json['call_quota'] ?? 0,
      trialDaysRemaining: json['trial_days_remaining'],
      messagePercentage: json['messagePercentage'] ?? 0,
      callPercentage: json['callPercentage'] ?? 0,
      messageWarning: json['messageWarning'] ?? false,
      callWarning: json['callWarning'] ?? false,
    );
  }
}

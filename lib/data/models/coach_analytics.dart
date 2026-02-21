class CoachAnalytics {
  final int activeClients;
  final int upcomingAppointments;
  final double todayEarnings;
  final double monthEarnings;
  final int unreadMessages;

  CoachAnalytics({
    required this.activeClients,
    required this.upcomingAppointments,
    required this.todayEarnings,
    required this.monthEarnings,
    required this.unreadMessages,
  });

  factory CoachAnalytics.fromJson(Map<String, dynamic> json) {
    return CoachAnalytics(
      activeClients: json['activeClients'] as int? ?? 0,
      upcomingAppointments: json['upcomingAppointments'] as int? ?? 0,
      todayEarnings: (json['todayEarnings'] as num?)?.toDouble() ?? 0.0,
      monthEarnings: (json['monthEarnings'] as num?)?.toDouble() ?? 0.0,
      unreadMessages: json['unreadMessages'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activeClients': activeClients,
      'upcomingAppointments': upcomingAppointments,
      'todayEarnings': todayEarnings,
      'monthEarnings': monthEarnings,
      'unreadMessages': unreadMessages,
    };
  }
}

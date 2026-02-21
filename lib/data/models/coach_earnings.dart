class CoachEarnings {
  final EarningsSummary summary;
  final List<PeriodEarnings> periodBreakdown;
  final List<Transaction> recentTransactions;

  CoachEarnings({
    required this.summary,
    required this.periodBreakdown,
    required this.recentTransactions,
  });

  factory CoachEarnings.fromJson(Map<String, dynamic> json) {
    return CoachEarnings(
      summary: EarningsSummary.fromJson(json['summary'] as Map<String, dynamic>),
      periodBreakdown: (json['periodBreakdown'] as List)
          .map((e) => PeriodEarnings.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentTransactions: (json['recentTransactions'] as List)
          .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'summary': summary.toJson(),
      'periodBreakdown': periodBreakdown.map((e) => e.toJson()).toList(),
      'recentTransactions': recentTransactions.map((e) => e.toJson()).toList(),
    };
  }
}

class EarningsSummary {
  final double totalEarnings;
  final double totalCommission;
  final int totalTransactions;

  EarningsSummary({
    required this.totalEarnings,
    required this.totalCommission,
    required this.totalTransactions,
  });

  factory EarningsSummary.fromJson(Map<String, dynamic> json) {
    return EarningsSummary(
      totalEarnings: (json['total_earnings'] as num?)?.toDouble() ?? 0.0,
      totalCommission: (json['total_commission'] as num?)?.toDouble() ?? 0.0,
      totalTransactions: int.tryParse(json['total_transactions'].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_earnings': totalEarnings,
      'total_commission': totalCommission,
      'total_transactions': totalTransactions,
    };
  }
}

class PeriodEarnings {
  final DateTime period;
  final double earnings;
  final int transactions;

  PeriodEarnings({
    required this.period,
    required this.earnings,
    required this.transactions,
  });

  factory PeriodEarnings.fromJson(Map<String, dynamic> json) {
    return PeriodEarnings(
      period: DateTime.parse(json['period'] as String),
      earnings: (json['earnings'] as num?)?.toDouble() ?? 0.0,
      transactions: json['transactions'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'period': period.toIso8601String(),
      'earnings': earnings,
      'transactions': transactions,
    };
  }
}

class Transaction {
  final String id;
  final String clientName;
  final double amount;
  final double coachCommission;
  final String type;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.clientName,
    required this.amount,
    required this.coachCommission,
    required this.type,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      clientName: json['client_name'] as String,
      amount: (json['amount'] as num).toDouble(),
      coachCommission: (json['coach_commission'] as num).toDouble(),
      type: json['type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_name': clientName,
      'amount': amount,
      'coach_commission': coachCommission,
      'type': type,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class Loan {
  const Loan({
    required this.id,
    required this.clientId,
    required this.amount,
    this.interest,
    this.installments,
    this.periodicity,
    this.firstDueDate,
    this.quinzenalDay1,
    this.quinzenalDay2,
    this.status,
    this.createdAt,
  });

  final String id;
  final String clientId;
  final String amount;
  final String? interest;
  final int? installments;
  final String? periodicity;
  final String? firstDueDate;

  /// Dias fixos do mês para quinzenal (1–31). Ambos nulos = a cada 14 dias.
  final int? quinzenalDay1;
  final int? quinzenalDay2;
  final String? status;
  final String? createdAt;

  bool get hasQuinzenalFixedDays =>
      quinzenalDay1 != null &&
      quinzenalDay2 != null &&
      quinzenalDay1 != quinzenalDay2;

  Loan copyWith({
    String? amount,
    String? interest,
    int? installments,
    String? periodicity,
    String? firstDueDate,
    int? quinzenalDay1,
    int? quinzenalDay2,
    bool clearQuinzenalDays = false,
    String? status,
  }) {
    return Loan(
      id: id,
      clientId: clientId,
      amount: amount ?? this.amount,
      interest: interest ?? this.interest,
      installments: installments ?? this.installments,
      periodicity: periodicity ?? this.periodicity,
      firstDueDate: firstDueDate ?? this.firstDueDate,
      quinzenalDay1:
          clearQuinzenalDays ? null : (quinzenalDay1 ?? this.quinzenalDay1),
      quinzenalDay2:
          clearQuinzenalDays ? null : (quinzenalDay2 ?? this.quinzenalDay2),
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toSyncPayload() {
    return {
      'client_id': clientId,
      'amount': amount,
      if (interest != null) 'interest': interest,
      if (installments != null) 'installments': installments,
      if (periodicity != null) 'periodicity': periodicity,
      if (firstDueDate != null) 'first_due_date': firstDueDate,
      'quinzenal_day_1': quinzenalDay1,
      'quinzenal_day_2': quinzenalDay2,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
    };
  }
}

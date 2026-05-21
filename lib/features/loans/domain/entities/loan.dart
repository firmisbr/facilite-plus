class Loan {
  const Loan({
    required this.id,
    required this.clientId,
    required this.amount,
    this.interest,
    this.installments,
    this.periodicity,
    this.firstDueDate,
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
  final String? status;
  final String? createdAt;

  Loan copyWith({
    String? amount,
    String? interest,
    int? installments,
    String? periodicity,
    String? firstDueDate,
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
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
    };
  }
}

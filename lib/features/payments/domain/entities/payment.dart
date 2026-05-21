class Payment {
  const Payment({
    required this.id,
    required this.loanId,
    required this.amount,
    this.paymentDate,
    this.method,
    this.createdAt,
  });

  final String id;
  final String loanId;
  final String amount;
  final String? paymentDate;
  final String? method;
  final String? createdAt;

  Payment copyWith({
    String? amount,
    String? paymentDate,
    String? method,
  }) {
    return Payment(
      id: id,
      loanId: loanId,
      amount: amount ?? this.amount,
      paymentDate: paymentDate ?? this.paymentDate,
      method: method ?? this.method,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toSyncPayload() {
    return {
      'loan_id': loanId,
      'amount': amount,
      if (paymentDate != null) 'payment_date': paymentDate,
      if (method != null) 'method': method,
      if (createdAt != null) 'created_at': createdAt,
    };
  }
}

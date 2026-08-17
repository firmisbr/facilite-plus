import '../../clients/domain/entities/client.dart';
import '../../loans/domain/entities/loan.dart';
import '../../payments/domain/entities/payment.dart';
import '../domain/user_role.dart';

abstract final class AdminRowMapper {
  static Client clientFromRow(Map<String, dynamic> row) {
    return Client(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      name: row['name'] as String,
      phone: row['phone'] as String?,
      email: row['email'] as String?,
      document: row['document'] as String?,
      address: row['address'] as String?,
      notes: row['notes'] as String?,
      createdAt: _formatDate(row['created_at']),
    );
  }

  static Loan loanFromRow(Map<String, dynamic> row) {
    return Loan(
      id: row['id'] as String,
      clientId: row['client_id'] as String,
      amount: row['amount'] as String,
      interest: row['interest'] as String?,
      installments: _readInt(row['installments']),
      periodicity: row['periodicity'] as String?,
      firstDueDate: row['first_due_date'] as String?,
      quinzenalDay1: _readInt(row['quinzenal_day_1']),
      quinzenalDay2: _readInt(row['quinzenal_day_2']),
      status: row['status'] as String?,
      createdAt: _formatDate(row['created_at']),
    );
  }

  static int? _readInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static Payment paymentFromRow(Map<String, dynamic> row) {
    return Payment(
      id: row['id'] as String,
      loanId: row['loan_id'] as String,
      amount: row['amount'] as String,
      installmentNumber: row['installment_number'] as int?,
      paymentDate: row['payment_date'] as String?,
      method: row['method'] as String?,
      createdAt: _formatDate(row['created_at']),
    );
  }

  static UserRole roleFromRow(Map<String, dynamic>? row) {
    if (row == null) return UserRole.user;
    return UserRole.fromString(row['role'] as String?);
  }

  static String? _formatDate(Object? value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }
}

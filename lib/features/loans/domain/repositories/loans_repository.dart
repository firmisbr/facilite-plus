import '../entities/loan.dart';
import '../entities/loan_with_client.dart';

abstract class LoansRepository {
  Stream<List<LoanWithClient>> watchAllForUser(String userId);

  Stream<List<Loan>> watchByClient(String clientId);

  Future<Loan?> getById(String id);

  Future<Loan> create({
    required String clientId,
    required String amount,
    String? interest,
    int? installments,
    String? periodicity,
    String? firstDueDate,
    String? status,
  });

  Future<Loan> update(Loan loan);

  Future<void> delete(String id);
}

import '../entities/payment.dart';

abstract class PaymentsRepository {
  Stream<List<Payment>> watchByLoan(String loanId);

  Future<Payment?> getById(String id);

  Future<Payment?> getByLoanAndInstallment(
    String loanId,
    int installmentNumber,
  );

  Future<Payment> create({
    required String loanId,
    required String amount,
    int? installmentNumber,
    String? paymentDate,
    String? method,
  });

  Future<Payment> payInstallment({
    required String loanId,
    required int installmentNumber,
    required String amount,
    String? paymentDate,
  });

  Future<void> undoInstallment(String loanId, int installmentNumber);

  Future<Payment> update(Payment payment);

  Future<void> delete(String id);
}

import '../entities/payment.dart';

abstract class PaymentsRepository {
  Stream<List<Payment>> watchByLoan(String loanId);

  Future<Payment?> getById(String id);

  Future<Payment> create({
    required String loanId,
    required String amount,
    String? paymentDate,
    String? method,
  });

  Future<Payment> update(Payment payment);

  Future<void> delete(String id);
}

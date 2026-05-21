import '../../payments/domain/repositories/payments_repository.dart';
import 'loan_schedule_builder.dart';
import 'repositories/loans_repository.dart';

/// Atualiza status do empréstimo conforme parcelas pagas / em aberto.
abstract final class LoanStatusSync {
  static Future<void> refresh({
    required LoansRepository loansRepo,
    required PaymentsRepository paymentsRepo,
    required String loanId,
  }) async {
    final loan = await loansRepo.getById(loanId);
    if (loan == null) return;

    final payments = await paymentsRepo.watchByLoan(loanId).first;
    final detail = LoanScheduleBuilder.build(loan: loan, payments: payments);

    if (detail == null) return;

    final allPaid = detail.installments.isNotEmpty &&
        detail.installments.every((i) => i.isPaid);
    final hasOverdue = detail.overview.overdueInstallments > 0;

    String? nextStatus;
    if (allPaid) {
      nextStatus = 'quitado';
    } else if (hasOverdue) {
      nextStatus = 'atrasado';
    } else {
      nextStatus = 'ativo';
    }

    if (loan.status == nextStatus) return;

    await loansRepo.update(loan.copyWith(status: nextStatus));
  }
}

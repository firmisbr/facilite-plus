import '../../payments/domain/entities/payment.dart';
import 'entities/loan_with_client.dart';
import 'loan_schedule_builder.dart';

enum LoanListFilter { ativos, todos, quitados, atrasados }

class LoanScheduleFlags {
  const LoanScheduleFlags({
    required this.isQuitado,
    required this.hasOverdue,
    required this.hasOpenInstallments,
  });

  final bool isQuitado;
  final bool hasOverdue;
  final bool hasOpenInstallments;
}

/// Filtros da lista de empréstimos com base no cronograma (não só no campo status).
abstract final class LoanListFilterHelper {
  static LoanScheduleFlags flags({
    required LoanWithClient item,
    required List<Payment> payments,
    DateTime? asOf,
  }) {
    final detail = LoanScheduleBuilder.build(
      loan: item.loan,
      payments: payments.where((p) => p.loanId == item.loan.id).toList(),
      asOf: asOf,
    );

    if (detail == null) {
      final status = item.loan.status ?? 'ativo';
      return LoanScheduleFlags(
        isQuitado: status == 'quitado',
        hasOverdue: status == 'atrasado',
        hasOpenInstallments: status != 'quitado',
      );
    }

    final allPaid = detail.installments.isNotEmpty &&
        detail.installments.every((i) => i.isPaid);

    return LoanScheduleFlags(
      isQuitado: allPaid,
      hasOverdue: detail.overview.overdueInstallments > 0,
      hasOpenInstallments: !allPaid,
    );
  }

  static bool matches({
    required LoanWithClient item,
    required List<Payment> payments,
    required LoanListFilter filter,
    DateTime? asOf,
  }) {
    final f = flags(item: item, payments: payments, asOf: asOf);

    return switch (filter) {
      LoanListFilter.todos => true,
      LoanListFilter.ativos => f.hasOpenInstallments,
      LoanListFilter.quitados => f.isQuitado,
      LoanListFilter.atrasados => f.hasOverdue && f.hasOpenInstallments,
    };
  }

  static List<LoanWithClient> apply({
    required List<LoanWithClient> items,
    required List<Payment> payments,
    required LoanListFilter filter,
    DateTime? asOf,
  }) {
    return items
        .where(
          (item) => matches(
            item: item,
            payments: payments,
            filter: filter,
            asOf: asOf,
          ),
        )
        .toList();
  }
}

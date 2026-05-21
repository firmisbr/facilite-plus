import '../../payments/domain/entities/payment.dart';
import 'entities/loan.dart' show Loan;
import 'loan_installment_status.dart';
import 'loan_periodicity.dart';
import 'loan_simulator.dart';

/// Monta cronograma, status das parcelas e resumos a partir do empréstimo e pagamentos.
abstract final class LoanScheduleBuilder {
  static LoanDetailData? build({
    required Loan loan,
    required List<Payment> payments,
    DateTime? asOf,
  }) {
    final principal = LoanSimulator.parseAmount(loan.amount);
    final installments = loan.installments;
    final interest = double.tryParse(
      (loan.interest ?? '0').replaceAll(',', '.'),
    );
    final due = loan.firstDueDate != null
        ? DateTime.tryParse(loan.firstDueDate!)
        : null;

    if (principal == null ||
        installments == null ||
        installments < 1 ||
        interest == null ||
        due == null) {
      return null;
    }

    final periodicity = LoanPeriodicity.fromValue(loan.periodicity);
    final schedule = LoanSimulator.buildFullSchedule(
      principal: principal,
      installments: installments,
      interestPercent: interest,
      periodicity: periodicity,
      firstDueDate: due,
    );
    if (schedule == null || schedule.isEmpty) return null;

    final installmentAmount = schedule.first.amount;
    final totalWithInterest = installmentAmount * installments;
    final totalProfit = totalWithInterest - principal;
    final now = asOf ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final byInstallment = <int, Payment>{};
    final legacyPool = <Payment>[];

    for (final payment in payments) {
      final n = payment.installmentNumber;
      if (n != null && n >= 1) {
        byInstallment.putIfAbsent(n, () => payment);
      } else {
        legacyPool.add(payment);
      }
    }

    legacyPool.sort((a, b) {
      final da = _paymentDate(a) ?? DateTime(1970);
      final db = _paymentDate(b) ?? DateTime(1970);
      return da.compareTo(db);
    });

    var legacyIndex = 0;
    var legacyPoolAmount = 0.0;
    final items = <LoanInstallmentItem>[];
    var paidCount = 0;
    var overdueCount = 0;
    var paidAmount = 0.0;
    DateTime? nextDue;

    for (final preview in schedule) {
      final dueDay = DateTime(
        preview.dueDate.year,
        preview.dueDate.month,
        preview.dueDate.day,
      );

      final direct = byInstallment[preview.number];
      LoanInstallmentStatus status;
      String? paymentId;
      DateTime? paidDate;

      if (direct != null) {
        status = LoanInstallmentStatus.paid;
        paymentId = direct.id;
        paidDate = _paymentDate(direct);
        paidCount++;
        paidAmount += LoanSimulator.parseAmount(direct.amount) ?? preview.amount;
      } else {
        DateTime? lastLegacyPaymentDate;
        while (legacyPoolAmount + 0.009 < preview.amount &&
            legacyIndex < legacyPool.length) {
          lastLegacyPaymentDate = _paymentDate(legacyPool[legacyIndex]);
          legacyPoolAmount += LoanSimulator.parseAmount(
                legacyPool[legacyIndex].amount,
              ) ??
              0;
          legacyIndex++;
        }

        if (legacyPoolAmount + 0.009 >= preview.amount) {
          status = LoanInstallmentStatus.paid;
          paidDate = lastLegacyPaymentDate;
          legacyPoolAmount -= preview.amount;
          paidCount++;
          paidAmount += preview.amount;
        } else if (dueDay.isBefore(today)) {
          status = LoanInstallmentStatus.overdue;
          overdueCount++;
          nextDue ??= preview.dueDate;
        } else {
          status = LoanInstallmentStatus.pending;
          nextDue ??= preview.dueDate;
        }
      }

      items.add(
        LoanInstallmentItem(
          number: preview.number,
          dueDate: preview.dueDate,
          amount: preview.amount,
          status: status,
          paidAmount: status == LoanInstallmentStatus.paid ? preview.amount : 0,
          paymentId: paymentId,
          paidDate: paidDate,
        ),
      );
    }

    if (nextDue == null) {
      for (final item in items) {
        if (!item.isPaid) {
          nextDue = item.dueDate;
          break;
        }
      }
    }

    final remainingInstallments = installments - paidCount;
    final remainingAmount = totalWithInterest - paidAmount;

    return LoanDetailData(
      installments: items,
      manager: LoanManagerStats(
        principal: principal,
        totalWithInterest: totalWithInterest,
        installmentCount: installments,
        installmentAmount: installmentAmount,
        interestPercent: interest,
        periodicityLabel: periodicity.label,
        totalProfit: totalProfit,
        profitPerInstallment:
            installments > 0 ? totalProfit / installments : 0,
      ),
      overview: LoanOverviewStats(
        paidAmount: paidAmount,
        remainingAmount: remainingAmount < 0 ? 0 : remainingAmount,
        paidInstallments: paidCount,
        remainingInstallments: remainingInstallments < 0
            ? 0
            : remainingInstallments,
        overdueInstallments: overdueCount,
        totalInstallments: installments,
        nextDueDate: nextDue,
      ),
    );
  }

  static LoanCardSummary? cardSummary({
    required Loan loan,
    required List<Payment> payments,
    DateTime? asOf,
  }) {
    final detail = build(loan: loan, payments: payments, asOf: asOf);
    if (detail == null) {
      final total = loan.installments ?? 0;
      if (total < 1) return null;
      return LoanCardSummary(
        paidInstallments: 0,
        totalInstallments: total,
        nextDueDate: loan.firstDueDate != null
            ? DateTime.tryParse(loan.firstDueDate!)
            : null,
      );
    }

    LoanInstallmentItem? nextOpen;
    for (final installment in detail.installments) {
      if (!installment.isPaid) {
        nextOpen = installment;
        break;
      }
    }

    return LoanCardSummary(
      paidInstallments: detail.overview.paidInstallments,
      totalInstallments: detail.overview.totalInstallments,
      nextDueDate: nextOpen?.dueDate ?? detail.overview.nextDueDate,
      isNextDueOverdue:
          nextOpen?.status == LoanInstallmentStatus.overdue,
      overdueInstallments: detail.overview.overdueInstallments,
    );
  }

  static String amountToStorage(double value) => value.toStringAsFixed(2);

  static DateTime? _paymentDate(Payment payment) {
    if (payment.paymentDate != null) {
      return DateTime.tryParse(payment.paymentDate!);
    }
    if (payment.createdAt != null) {
      return DateTime.tryParse(payment.createdAt!);
    }
    return null;
  }
}

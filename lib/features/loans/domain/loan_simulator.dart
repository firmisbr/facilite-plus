import '../../settings/domain/daily_loan_sunday_policy.dart';
import 'daily_loan_due_dates.dart';
import 'loan_periodicity.dart';

class LoanInstallmentPreview {
  const LoanInstallmentPreview({
    required this.number,
    required this.dueDate,
    required this.amount,
  });

  final int number;
  final DateTime dueDate;
  final double amount;
}

class LoanSimulationResult {
  const LoanSimulationResult({
    required this.principal,
    required this.installmentAmount,
    required this.totalAmount,
    required this.totalInterest,
    required this.schedule,
  });

  final double principal;
  final double installmentAmount;
  final double totalAmount;
  final double totalInterest;
  final List<LoanInstallmentPreview> schedule;
}

/// Simula empréstimo com parcelas iguais.
/// A taxa informada é **% sobre o valor emprestado** (juros totais no contrato).
abstract final class LoanSimulator {
  static double? parseAmount(String raw) {
    final cleaned = raw.trim().replaceAll(RegExp(r'[^\d,.-]'), '');
    if (cleaned.isEmpty) return null;

    final hasComma = cleaned.contains(',');
    final hasDot = cleaned.contains('.');

    String normalized;
    if (hasComma && hasDot) {
      normalized = cleaned.replaceAll('.', '').replaceAll(',', '.');
    } else if (hasComma) {
      normalized = cleaned.replaceAll(',', '.');
    } else {
      normalized = cleaned;
    }

    return double.tryParse(normalized);
  }

  static LoanSimulationResult? simulate({
    required double principal,
    required int installments,
    required double interestPercent,
    required LoanPeriodicity periodicity,
    required DateTime firstDueDate,
    int maxScheduleRows = 6,
    bool? skipSundayOnDaily,
  }) {
    if (principal <= 0 || installments < 1 || interestPercent < 0) {
      return null;
    }

    final totalInterest = principal * (interestPercent / 100);
    final totalAmount = principal + totalInterest;
    final installment = totalAmount / installments;

    final schedule = <LoanInstallmentPreview>[];
    final showCount =
        installments < maxScheduleRows ? installments : maxScheduleRows;

    for (var i = 0; i < showCount; i++) {
      schedule.add(
        LoanInstallmentPreview(
          number: i + 1,
          dueDate: _nextDueDate(
            firstDueDate,
            periodicity,
            i,
            skipSundayOnDaily: skipSundayOnDaily,
          ),
          amount: installment,
        ),
      );
    }

    return LoanSimulationResult(
      principal: principal,
      installmentAmount: installment,
      totalAmount: totalAmount,
      totalInterest: totalInterest,
      schedule: schedule,
    );
  }

  /// Cronograma completo de parcelas (para detalhe do empréstimo).
  static List<LoanInstallmentPreview>? buildFullSchedule({
    required double principal,
    required int installments,
    required double interestPercent,
    required LoanPeriodicity periodicity,
    required DateTime firstDueDate,
    bool? skipSundayOnDaily,
  }) {
    final sim = simulate(
      principal: principal,
      installments: installments,
      interestPercent: interestPercent,
      periodicity: periodicity,
      firstDueDate: firstDueDate,
      maxScheduleRows: installments,
      skipSundayOnDaily: skipSundayOnDaily,
    );
    if (sim == null) return null;

    return List.generate(
      installments,
      (i) => LoanInstallmentPreview(
        number: i + 1,
        dueDate: _nextDueDate(
          firstDueDate,
          periodicity,
          i,
          skipSundayOnDaily: skipSundayOnDaily,
        ),
        amount: sim.installmentAmount,
      ),
    );
  }

  static DateTime _nextDueDate(
    DateTime first,
    LoanPeriodicity periodicity,
    int index, {
    bool? skipSundayOnDaily,
  }) {
    final skipSunday = skipSundayOnDaily ?? DailyLoanSundayPolicy.skipSunday;
    return switch (periodicity) {
      LoanPeriodicity.diaria => DailyLoanDueDates.dueDate(
          first,
          installmentIndex: index,
          skipSunday: skipSunday,
        ),
      LoanPeriodicity.semanal => first.add(Duration(days: 7 * index)),
      LoanPeriodicity.quinzenal => first.add(Duration(days: 14 * index)),
      LoanPeriodicity.mensal => DateTime(
          first.year,
          first.month + index,
          first.day,
        ),
    };
  }

  static String formatMoney(double value) {
    final fixed = value.toStringAsFixed(2);
    final parts = fixed.split('.');
    final intPart = parts[0];
    final dec = parts[1];
    final withThousands = intPart.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return 'R\$ $withThousands,$dec';
  }

  static String formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }
}

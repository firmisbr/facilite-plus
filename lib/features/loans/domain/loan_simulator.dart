import '../../../shared/utils/br_currency_input_formatter.dart';
import '../../settings/domain/daily_loan_sunday_policy.dart';
import 'daily_loan_due_dates.dart';
import 'loan_periodicity.dart';
import 'quinzenal_fixed_days.dart';

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
    } else if (hasDot) {
      // App é BR: "1.500" / "1.000.000" = milhar; "1.5" / "1500.50" = decimal.
      // "1.000.00" (edição sem máscara) = milhar + centavos.
      normalized = _normalizeDotOnlyAmount(cleaned);
    } else {
      normalized = cleaned;
    }

    return double.tryParse(normalized);
  }

  /// Interpreta string só com pontos no padrão brasileiro (milhar) ou decimal.
  static String _normalizeDotOnlyAmount(String cleaned) {
    final parts = cleaned.split('.');
    if (parts.length == 1) return cleaned;

    if (parts.length == 2 && parts[1].length <= 2) {
      return cleaned;
    }

    final thousandGroups = parts.skip(1).every((p) => p.length == 3);
    if (thousandGroups) {
      return cleaned.replaceAll('.', '');
    }

    final last = parts.last;
    final middle = parts.skip(1).take(parts.length - 2);
    if (last.length <= 2 && middle.every((p) => p.length == 3)) {
      return '${parts.take(parts.length - 1).join()}.$last';
    }

    // Ambíguo: remove pontos (evita quebrar cronograma na edição).
    return cleaned.replaceAll('.', '');
  }

  /// Valor para o campo com [BrCurrencyInputFormatter] a partir do que está no banco.
  static String amountForCurrencyInput(String raw) {
    final parsed = parseAmount(raw);
    if (parsed == null) return '';
    final cents = (parsed * 100).round().abs();
    return BrCurrencyInputFormatter.formatFromDigits(cents.toString());
  }

  static LoanSimulationResult? simulate({
    required double principal,
    required int installments,
    required double interestPercent,
    required LoanPeriodicity periodicity,
    required DateTime firstDueDate,
    int maxScheduleRows = 6,
    bool? skipSundayOnDaily,
    int? quinzenalDay1,
    int? quinzenalDay2,
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
            quinzenalDay1: quinzenalDay1,
            quinzenalDay2: quinzenalDay2,
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
    int? quinzenalDay1,
    int? quinzenalDay2,
  }) {
    final sim = simulate(
      principal: principal,
      installments: installments,
      interestPercent: interestPercent,
      periodicity: periodicity,
      firstDueDate: firstDueDate,
      maxScheduleRows: installments,
      skipSundayOnDaily: skipSundayOnDaily,
      quinzenalDay1: quinzenalDay1,
      quinzenalDay2: quinzenalDay2,
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
          quinzenalDay1: quinzenalDay1,
          quinzenalDay2: quinzenalDay2,
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
    int? quinzenalDay1,
    int? quinzenalDay2,
  }) {
    final skipSunday = skipSundayOnDaily ?? DailyLoanSundayPolicy.skipSunday;
    return switch (periodicity) {
      LoanPeriodicity.diaria => DailyLoanDueDates.dueDate(
          first,
          installmentIndex: index,
          skipSunday: skipSunday,
        ),
      LoanPeriodicity.semanal => first.add(Duration(days: 7 * index)),
      LoanPeriodicity.quinzenal =>
        QuinzenalFixedDays.isActive(quinzenalDay1, quinzenalDay2)
            ? QuinzenalFixedDays.dueDate(
                firstDueDate: first,
                day1: quinzenalDay1!,
                day2: quinzenalDay2!,
                index: index,
              )
            : first.add(Duration(days: 14 * index)),
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

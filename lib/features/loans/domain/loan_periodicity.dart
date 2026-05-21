enum LoanPeriodicity {
  diaria('diaria', 'Diária', 30),
  semanal('semanal', 'Semanal', 4),
  quinzenal('quinzenal', 'Quinzenal', 2),
  mensal('mensal', 'Mensal', 1);

  const LoanPeriodicity(this.value, this.label, this.periodsPerMonth);

  final String value;
  final String label;

  /// Parcelas por mês (para converter taxa mensal % em taxa por período).
  final int periodsPerMonth;

  static LoanPeriodicity fromValue(String? value) {
    return LoanPeriodicity.values.firstWhere(
      (p) => p.value == value,
      orElse: () => LoanPeriodicity.mensal,
    );
  }
}

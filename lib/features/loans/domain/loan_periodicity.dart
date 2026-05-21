enum LoanPeriodicity {
  diaria('diaria', 'Diária', 30),
  semanal('semanal', 'Semanal', 4),
  quinzenal('quinzenal', 'Quinzenal', 2),
  mensal('mensal', 'Mensal', 1);

  const LoanPeriodicity(this.value, this.label, this.periodsPerMonth);

  final String value;
  final String label;

  /// Parcelas por mês (referência; vencimentos usam a periodicidade).
  final int periodsPerMonth;

  static LoanPeriodicity fromValue(String? value) {
    return LoanPeriodicity.values.firstWhere(
      (p) => p.value == value,
      orElse: () => LoanPeriodicity.mensal,
    );
  }
}

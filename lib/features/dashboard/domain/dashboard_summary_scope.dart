enum DashboardSummaryScope {
  total('Total', 'Carteira ativa (como antes)'),
  currentMonth('Mês atual', 'Movimentação do calendário em curso');

  const DashboardSummaryScope(this.label, this.description);

  final String label;
  final String description;
}

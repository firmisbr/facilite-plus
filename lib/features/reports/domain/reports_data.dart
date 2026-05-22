import 'report_period.dart';
import 'reports_portfolio_overview.dart';
import 'reports_snapshot.dart';

/// Dados completos da tela de relatórios (período + carteira).
class ReportsData {
  const ReportsData({
    required this.periodReport,
    required this.portfolio,
    required this.generatedAt,
  });

  final ReportsSnapshot periodReport;
  final ReportsPortfolioOverview portfolio;
  final DateTime generatedAt;

  ReportPeriodRange get period => periodReport.period;

  bool get hasActiveLoans => periodReport.hasActiveLoans;
}

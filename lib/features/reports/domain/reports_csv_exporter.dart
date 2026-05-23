import 'package:intl/intl.dart';

import '../../loans/domain/loan_simulator.dart';
import 'reports_data.dart';
import 'reports_portfolio_overview.dart';
import 'reports_snapshot.dart';

abstract final class ReportsCsvExporter {
  static final _dateFmt = DateFormat('dd/MM/yyyy', 'pt_BR');
  static final _generatedFmt = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');

  static String export(ReportsData data) {
    final b = StringBuffer();

    b.writeln('Facilite Plus — Relatório completo');
    _line(b, 'Gerado em', _generatedFmt.format(data.generatedAt));
    b.writeln();

    _appendPortfolio(b, data.portfolio);
    b.writeln();
    _appendPeriod(b, data.periodReport);

    return b.toString();
  }

  static void _appendPortfolio(StringBuffer b, ReportsPortfolioOverview p) {
    _section(b, 'Visão geral da carteira');
    _line(b, 'Emprestado (carteira ativa)', _money(p.totalLent));
    if (p.hasMixedPortfolio || p.isHistoricalOnly) {
      _line(b, 'Emprestado (histórico — todos)', _money(p.lifetimeTotalLent));
    }
    _line(b, 'Total recebido', _money(p.totalReceived));
    _line(b, 'Total a receber (com juros)', _money(p.totalRemaining));
    _line(b, 'Lucro a receber', _money(p.remainingProfit));
    _line(b, 'Lucro realizado', _money(p.realizedProfit));
    _line(b, 'Lucro total dos contratos', _money(p.expectedProfit));
    _line(b, 'Média de lucro por empréstimo', _money(p.averageProfitPerLoan));
    _line(b, 'Ticket médio', _money(p.averageTicketPerLoan));
    _line(b, 'Taxa de recuperação', '${p.recoveryRatePercent.toStringAsFixed(1)}%');
    _line(b, 'Margem de lucro', '${p.profitMarginPercent.toStringAsFixed(1)}%');
    _line(b, 'Empréstimos ativos', '${p.activeLoans}');
    _line(b, 'Clientes com empréstimo', '${p.activeClients}');
    _line(b, 'Empréstimos quitados', '${p.quitadosLoans}');
    _line(b, 'Em atraso', _money(p.overdueAmount));
    _line(b, 'Parcelas em atraso', '${p.overdueInstallments}');
    _line(b, 'A vencer neste mês', _money(p.dueThisMonth));
    _line(b, 'A vencer no próximo mês', _money(p.dueNextMonth));

    if (p.delinquentClients.isNotEmpty) {
      b.writeln();
      _section(b, 'Inadimplência atual');
      b.writeln('Cliente;Parcelas;Valor;Máx dias atraso');
      for (final row in p.delinquentClients) {
        b.writeln(
          '${_csv(row.clientName)};${row.overdueInstallments};'
          '${_moneyRaw(row.overdueAmount)};${row.maxDaysOverdue}',
        );
      }
    }
  }

  static void _appendPeriod(StringBuffer b, ReportsSnapshot snapshot) {
    final period = snapshot.period;
    final s = snapshot.summary;

    _section(b, 'Por período — ${period.label} (${period.rangeCaption})');
    _line(b, 'Recebido', _money(s.receivedInPeriod));
    _line(b, 'Pagamentos', '${s.paymentsCount}');
    _line(b, 'A receber no período', _money(s.dueInPeriod));
    _line(b, 'Parcelas a receber', '${s.dueInstallmentsCount}');
    _line(b, 'Em atraso no período', _money(s.overdueInPeriod));
    _line(b, 'Parcelas em atraso no período', '${s.overdueInstallmentsCount}');

    if (snapshot.dueInPeriod.isNotEmpty) {
      b.writeln();
      b.writeln('Parcelas a receber;Vencimento;Cliente;Parcela;Valor');
      for (final row in snapshot.dueInPeriod) {
        b.writeln(
          ';${_dateFmt.format(row.dueDate)};${_csv(row.clientName)};'
          '${row.installmentNumber};${_moneyRaw(row.amount)}',
        );
      }
    }

    if (snapshot.paymentsInPeriod.isNotEmpty) {
      b.writeln();
      b.writeln('Recebimentos;Data;Cliente;Parcela;Valor;Forma');
      for (final row in snapshot.paymentsInPeriod) {
        b.writeln(
          ';${_dateFmt.format(row.date)};${_csv(row.clientName)};'
          '${row.installmentNumber ?? ''};${_moneyRaw(row.amount)};'
          '${_csv(row.method ?? '')}',
        );
      }
    }
  }

  static void _section(StringBuffer b, String title) {
    b.writeln('[$title]');
  }

  static void _line(StringBuffer b, String label, String value) {
    b.writeln('$label: $value');
  }

  static String _money(double v) => LoanSimulator.formatMoney(v);

  static String _moneyRaw(double v) =>
      v.toStringAsFixed(2).replaceAll('.', ',');

  static String _csv(String value) {
    if (value.contains(';') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}

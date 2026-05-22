import 'client_list_entry.dart';

enum ClientListFilter {
  todos,
  comEmprestimo,
  emAtraso,
}

class ClientPortfolioCounts {
  const ClientPortfolioCounts({
    required this.total,
    required this.comEmprestimo,
    required this.emAtraso,
  });

  final int total;
  final int comEmprestimo;
  final int emAtraso;

  static ClientPortfolioCounts compute(List<ClientListEntry> entries) {
    var comEmprestimo = 0;
    var emAtraso = 0;
    for (final e in entries) {
      if (e.activeLoansCount > 0) comEmprestimo++;
      if (e.hasDelinquency) emAtraso++;
    }
    return ClientPortfolioCounts(
      total: entries.length,
      comEmprestimo: comEmprestimo,
      emAtraso: emAtraso,
    );
  }
}

abstract final class ClientListFilterHelper {
  static List<ClientListEntry> apply({
    required List<ClientListEntry> items,
    required ClientListFilter filter,
  }) {
    return switch (filter) {
      ClientListFilter.todos => items,
      ClientListFilter.comEmprestimo =>
        items.where((e) => e.activeLoansCount > 0).toList(),
      ClientListFilter.emAtraso =>
        items.where((e) => e.hasDelinquency).toList(),
    };
  }
}

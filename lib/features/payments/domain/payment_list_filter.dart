import 'payments_overview.dart';

enum PaymentListFilter { todos, atrasados, aVencer }

class PaymentPortfolioCounts {
  const PaymentPortfolioCounts({
    required this.total,
    required this.atrasados,
    required this.aVencer,
  });

  final int total;
  final int atrasados;
  final int aVencer;

  static PaymentPortfolioCounts fromCards(List<PaymentLoanCardItem> cards) {
    var atrasados = 0;
    var aVencer = 0;
    for (final card in cards) {
      if (card.hasOverdue) atrasados++;
      if (card.hasDueSoon) aVencer++;
    }
    return PaymentPortfolioCounts(
      total: cards.length,
      atrasados: atrasados,
      aVencer: aVencer,
    );
  }

  /// Filtro inicial da aba Cobranças conforme a carteira.
  PaymentListFilter suggestedDefaultFilter() {
    if (atrasados > 0) return PaymentListFilter.atrasados;
    if (aVencer > 0) return PaymentListFilter.aVencer;
    return PaymentListFilter.todos;
  }
}

abstract final class PaymentListFilterHelper {
  static List<PaymentLoanCardItem> apply({
    required List<PaymentLoanCardItem> items,
    required PaymentListFilter filter,
  }) {
    return switch (filter) {
      PaymentListFilter.todos => items,
      PaymentListFilter.atrasados =>
        items.where((c) => c.hasOverdue).toList(),
      PaymentListFilter.aVencer => items.where((c) => c.hasDueSoon).toList(),
    };
  }

  static List<PaymentLoanCardItem> search({
    required List<PaymentLoanCardItem> items,
    required String query,
  }) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return items;

    return items.where((item) {
      final haystack = [
        item.clientName,
        item.remainingAmount.toString(),
        item.overdueAmount.toString(),
        if (item.overdueInstallments > 0) '${item.overdueInstallments}',
        if (item.dueSoonInstallments > 0) '${item.dueSoonInstallments}',
        if (item.nextDueDate != null) item.nextDueDate.toString(),
        item.clientPhone ?? '',
      ].join(' ').toLowerCase();

      return haystack.contains(q);
    }).toList();
  }
}

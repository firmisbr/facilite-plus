import 'package:flutter_test/flutter_test.dart';
import 'package:facilite_plus/features/payments/domain/payment_list_filter.dart';

void main() {
  group('PaymentPortfolioCounts.suggestedDefaultFilter', () {
    test('prioriza atrasados quando houver', () {
      const counts = PaymentPortfolioCounts(
        total: 3,
        atrasados: 1,
        aVencer: 2,
      );

      expect(
        counts.suggestedDefaultFilter(),
        PaymentListFilter.atrasados,
      );
    });

    test('usa a vencer sem atrasados', () {
      const counts = PaymentPortfolioCounts(
        total: 2,
        atrasados: 0,
        aVencer: 1,
      );

      expect(counts.suggestedDefaultFilter(), PaymentListFilter.aVencer);
    });

    test('cai em todos sem pendências', () {
      const counts = PaymentPortfolioCounts(
        total: 1,
        atrasados: 0,
        aVencer: 0,
      );

      expect(counts.suggestedDefaultFilter(), PaymentListFilter.todos);
    });
  });
}

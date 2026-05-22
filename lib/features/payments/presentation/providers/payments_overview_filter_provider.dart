import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/payment_list_filter.dart';

/// Filtro pedido ao abrir a aba Cobranças (ex.: alerta de atraso no dashboard).
final paymentsOverviewFilterRequestProvider =
    StateProvider<PaymentListFilter?>((ref) => null);

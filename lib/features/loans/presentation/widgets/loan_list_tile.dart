import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/loan_with_client.dart';
import '../providers/loan_list_layout_provider.dart';
import 'loan_list_card.dart';
import 'loan_list_card_compact.dart';

/// Empréstimo na lista — layout estendido ou compacto.
class LoanListTile extends ConsumerWidget {
  const LoanListTile({required this.item, super.key});

  final LoanWithClient item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(loanListLayoutProvider);

    return switch (layout) {
      LoanListCardLayout.extended => LoanListCard(item: item),
      LoanListCardLayout.compact => LoanListCardCompact(item: item),
    };
  }
}

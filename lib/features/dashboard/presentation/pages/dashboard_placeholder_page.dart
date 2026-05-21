import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_page_scaffold.dart';

class DashboardPlaceholderPage extends StatelessWidget {
  const DashboardPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'Dashboard',
      body: const AppEmptyState(
        icon: Icons.dashboard_outlined,
        title: 'Dashboard em construção',
        subtitle:
            'Totais emprestados, recebidos, lucro e inadimplência virão na Fase 3 do PRD.',
      ),
    );
  }
}

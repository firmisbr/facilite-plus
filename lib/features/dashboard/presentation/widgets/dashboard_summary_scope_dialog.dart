import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/dashboard_summary_scope.dart';
import '../providers/dashboard_summary_scope_provider.dart';

Future<void> showDashboardSummaryScopeDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final current = ref.read(dashboardSummaryScopeProvider);

  final selected = await showDialog<DashboardSummaryScope>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Resumo do início'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Escolha quais valores exibir no card principal.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          ...DashboardSummaryScope.values.map(
            (scope) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(scope.label),
              subtitle: Text(scope.description),
              trailing: current == scope
                  ? Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
              onTap: () => Navigator.pop(context, scope),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    ),
  );

  if (selected != null && selected != current) {
    await ref.read(dashboardSummaryScopeProvider.notifier).setScope(selected);
  }
}

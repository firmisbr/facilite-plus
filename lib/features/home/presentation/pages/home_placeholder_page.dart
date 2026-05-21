import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/database/drift/drift_providers.dart';
import '../../../../services/supabase/supabase_providers.dart';
import '../../../../services/sync/sync_providers.dart';

/// Home mínima — valida fundação (Drift local + fila de sync).
class HomePlaceholderPage extends ConsumerWidget {
  const HomePlaceholderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appDatabaseProvider);
    final pendingSync = ref.watch(pendingSyncCountProvider);
    final userId = ref.watch(currentUserIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Facilite Plus'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fundação offline-first',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const _StatusRow(
              label: 'SQLite + Drift (fonte local)',
              ok: true,
            ),
            _StatusRow(
              label: 'Fila de sync',
              ok: true,
              detail: pendingSync.when(
                data: (n) => '$n pendente(s)',
                loading: () => 'carregando…',
                error: (e, _) => 'erro',
              ),
            ),
            _StatusRow(
              label: 'Supabase',
              ok: userId != null,
              detail: userId ?? 'não autenticado (esperado nesta fase)',
            ),
            const SizedBox(height: 24),
            const Text(
              'Próxima etapa: login e CRUD com enqueue automático na sync_queue.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.ok,
    this.detail,
  });

  final String label;
  final bool ok;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle_outline : Icons.hourglass_empty,
            color: ok ? Colors.green : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              detail != null ? '$label — $detail' : label,
            ),
          ),
        ],
      ),
    );
  }
}

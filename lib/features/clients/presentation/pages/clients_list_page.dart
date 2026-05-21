import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../features/auth/presentation/providers/auth_controller.dart';
import '../../../../services/sync/sync_providers.dart';
import '../providers/clients_providers.dart';

class ClientsListPage extends ConsumerWidget {
  const ClientsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(clientsStreamProvider);
    final pendingSync = ref.watch(pendingSyncCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        actions: [
          pendingSync.when(
            data: (n) => n > 0
                ? Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Chip(
                      label: Text('$n sync'),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (e, _) => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sincronizar agora',
            onPressed: () async {
              final sync = ref.read(syncServiceProvider);
              await sync.processQueue();
              await sync.pullRemoteChanges();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sincronização concluída')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: clientsAsync.when(
        data: (clients) {
          if (clients.isEmpty) {
            return const Center(
              child: Text('Nenhum cliente. Toque em + para cadastrar.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: clients.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final client = clients[index];
              return Card(
                child: ListTile(
                  title: Text(client.name),
                  subtitle: Text(
                    [
                      if (client.phone != null) client.phone,
                      if (client.document != null) client.document,
                    ].whereType<String>().join(' · '),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(
                    AppRoutes.clientEdit(client.id),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.clientNew),
        child: const Icon(Icons.add),
      ),
    );
  }
}

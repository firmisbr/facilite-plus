import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shell de login — fluxo real na Fase 1 (auth).
class LoginPlaceholderPage extends ConsumerWidget {
  const LoginPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entrar')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Autenticação será implementada na próxima etapa.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => _showDevHint(context),
              child: const Text('Configurar Supabase'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDevHint(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configuração'),
        content: const Text(
          'Edite lib/core/config/app_config.dart com URL e anon key '
          'do Supabase. Dados ficam no SQLite local; a fila sync_queue '
          'envia alterações quando houver internet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

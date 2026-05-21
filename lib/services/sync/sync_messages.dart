import 'sync_service.dart';

/// Mensagens amigáveis para o usuário sobre sincronização.
abstract final class SyncMessages {
  static String forRunResult(SyncRunResult result) {
    if (result.skipped) {
      return forSkipReason(result.reason);
    }
    if (result.failed > 0 && result.synced > 0) {
      return '${result.synced} enviado(s), ${result.failed} com erro. '
          'Toque em sincronizar para tentar de novo.';
    }
    if (result.failed > 0) {
      return 'Não foi possível enviar ${result.failed} alteração(ões). '
          'Verifique a internet e tente novamente.';
    }
    if (result.synced > 0) {
      return '${result.synced} alteração(ões) sincronizada(s) com sucesso.';
    }
    return 'Tudo sincronizado — nada pendente na fila.';
  }

  static String forSkipReason(String? reason) {
    switch (reason) {
      case 'Sem sessão autenticada':
        return 'Faça login para sincronizar seus dados.';
      case 'Sem conexão':
        return 'Sem internet. As alterações ficam salvas no aparelho '
            'e serão enviadas quando você estiver online.';
      case 'Sync já em andamento':
        return 'Sincronização em andamento…';
      default:
        return reason ?? 'Sincronização não realizada.';
    }
  }

  static String forError(Object error) {
    final msg = error.toString().toLowerCase();

    if (msg.contains('jwt') ||
        msg.contains('session') ||
        msg.contains('not authenticated') ||
        msg.contains('401')) {
      return 'Sessão expirada. Saia e entre novamente para sincronizar.';
    }
    if (msg.contains('network') ||
        msg.contains('socket') ||
        msg.contains('connection') ||
        msg.contains('failed host lookup') ||
        msg.contains('timeout')) {
      return 'Falha de conexão. Verifique a internet e tente de novo.';
    }
    if (msg.contains('duplicate') || msg.contains('23505')) {
      return 'Registro já existe na nuvem. Tente sincronizar novamente.';
    }
    if (msg.contains('foreign key') || msg.contains('23503')) {
      return 'Dados relacionados não encontrados na nuvem. '
          'Sincronize clientes e empréstimos antes.';
    }
    if (msg.contains('permission') ||
        msg.contains('row-level security') ||
        msg.contains('42501')) {
      return 'Sem permissão para salvar na nuvem. Verifique sua conta.';
    }

    return 'Erro ao sincronizar. Tente novamente em instantes.';
  }
}

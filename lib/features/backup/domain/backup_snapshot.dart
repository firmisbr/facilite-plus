class BackupSnapshot {
  const BackupSnapshot({
    required this.version,
    required this.app,
    required this.exportedAt,
    required this.userId,
    this.userEmail,
    required this.clients,
    required this.loans,
    required this.payments,
  });

  static const appId = 'facilite_plus';
  static const currentVersion = 1;

  final int version;
  final String app;
  final String exportedAt;
  final String userId;
  final String? userEmail;
  final List<Map<String, dynamic>> clients;
  final List<Map<String, dynamic>> loans;
  final List<Map<String, dynamic>> payments;

  int get totalRecords => clients.length + loans.length + payments.length;

  Map<String, dynamic> toJson() => {
        'version': version,
        'app': app,
        'exported_at': exportedAt,
        'user_id': userId,
        if (userEmail != null) 'user_email': userEmail,
        'clients': clients,
        'loans': loans,
        'payments': payments,
      };

  factory BackupSnapshot.fromJson(Map<String, dynamic> json) {
    return BackupSnapshot(
      version: json['version'] as int? ?? 0,
      app: json['app'] as String? ?? '',
      exportedAt: json['exported_at'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      userEmail: json['user_email'] as String?,
      clients: _listOfMaps(json['clients']),
      loans: _listOfMaps(json['loans']),
      payments: _listOfMaps(json['payments']),
    );
  }

  static List<Map<String, dynamic>> _listOfMaps(dynamic value) {
    if (value is! List) return [];
    return value
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  void validateForRestore({required String currentUserId}) {
    if (version != currentVersion) {
      throw BackupException(
        'Versão do backup não suportada ($version). '
        'Atualize o aplicativo.',
      );
    }
    if (app != appId) {
      throw BackupException('Arquivo inválido: não é um backup do Facilite Plus.');
    }
    if (userId.isEmpty) {
      throw BackupException('Backup sem identificação de usuário.');
    }
    if (userId != currentUserId) {
      throw BackupException(
        'Este backup pertence a outra conta. '
        'Entre com o mesmo e-mail usado ao exportar.',
      );
    }

    final clientIds = clients.map((c) => c['id']).whereType<String>().toSet();
    for (final loan in loans) {
      final clientId = loan['client_id'] as String?;
      if (clientId == null || !clientIds.contains(clientId)) {
        throw BackupException('Backup corrompido: empréstimo sem cliente válido.');
      }
    }

    final loanIds = loans.map((l) => l['id']).whereType<String>().toSet();
    for (final payment in payments) {
      final loanId = payment['loan_id'] as String?;
      if (loanId == null || !loanIds.contains(loanId)) {
        throw BackupException('Backup corrompido: pagamento sem empréstimo válido.');
      }
    }
  }
}

class BackupException implements Exception {
  BackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

class BackupExportFile {
  const BackupExportFile({
    required this.snapshot,
    required this.filePath,
    required this.fileName,
  });

  final BackupSnapshot snapshot;
  final String filePath;
  final String fileName;
}

class BackupRestoreSummary {
  const BackupRestoreSummary({
    required this.clients,
    required this.loans,
    required this.payments,
  });

  final int clients;
  final int loans;
  final int payments;

  int get total => clients + loans + payments;
}

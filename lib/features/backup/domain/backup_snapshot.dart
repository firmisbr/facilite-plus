import 'backup_transfer_pin.dart';

class BackupSnapshot {
  const BackupSnapshot({
    required this.version,
    required this.app,
    required this.exportedAt,
    required this.userId,
    this.userEmail,
    this.transferPinSalt,
    this.transferPinHash,
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
  final String? transferPinSalt;
  final String? transferPinHash;
  final List<Map<String, dynamic>> clients;
  final List<Map<String, dynamic>> loans;
  final List<Map<String, dynamic>> payments;

  int get totalRecords => clients.length + loans.length + payments.length;

  bool get hasTransferPin =>
      transferPinSalt != null &&
      transferPinSalt!.isNotEmpty &&
      transferPinHash != null &&
      transferPinHash!.isNotEmpty;

  bool isSameAccount(String currentUserId) => userId == currentUserId;

  bool requiresCrossAccountImport(String currentUserId) =>
      userId.isNotEmpty && !isSameAccount(currentUserId);

  Map<String, dynamic> toJson() => {
        'version': version,
        'app': app,
        'exported_at': exportedAt,
        'user_id': userId,
        if (userEmail != null) 'user_email': userEmail,
        if (hasTransferPin) ...{
          'transfer_pin_salt': transferPinSalt,
          'transfer_pin_hash': transferPinHash,
        },
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
      transferPinSalt: json['transfer_pin_salt'] as String?,
      transferPinHash: json['transfer_pin_hash'] as String?,
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

  void validateIntegrity() {
    if (version != currentVersion) {
      throw BackupException(
        'Versão do backup não suportada ($version). '
        'Atualize o aplicativo.',
      );
    }
    if (app != appId) {
      throw BackupException(
        'Arquivo inválido: não é um backup do Facilite Plus.',
      );
    }
    if (userId.isEmpty) {
      throw BackupException('Backup sem identificação de usuário.');
    }

    final clientIds = clients.map((c) => c['id']).whereType<String>().toSet();
    for (final loan in loans) {
      final clientId = loan['client_id'] as String?;
      if (clientId == null || !clientIds.contains(clientId)) {
        throw BackupException(
          'Backup corrompido: empréstimo sem cliente válido.',
        );
      }
    }

    final loanIds = loans.map((l) => l['id']).whereType<String>().toSet();
    for (final payment in payments) {
      final loanId = payment['loan_id'] as String?;
      if (loanId == null || !loanIds.contains(loanId)) {
        throw BackupException(
          'Backup corrompido: pagamento sem empréstimo válido.',
        );
      }
    }
  }

  /// Restauração na mesma conta (sem PIN).
  void validateForSameAccountRestore({required String currentUserId}) {
    validateIntegrity();
    if (!isSameAccount(currentUserId)) {
      throw BackupException(
        'Este backup é de outra conta. Use "Importar em outra conta" '
        'e informe o PIN definido na exportação.',
      );
    }
  }

  /// Importação em outra conta — exige PIN definido na exportação.
  void validateForCrossAccountImport({required String pin}) {
    validateIntegrity();
    if (!hasTransferPin) {
      throw BackupException(
        'Este backup não possui PIN de transferência. '
        'Crie um novo backup na conta original com PIN de 4 dígitos.',
      );
    }
    if (!BackupTransferPin.verify(
      pin: pin,
      salt: transferPinSalt!,
      expectedHash: transferPinHash!,
    )) {
      throw BackupException('PIN incorreto.');
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
    this.downloadsPath,
  });

  final BackupSnapshot snapshot;
  /// Arquivo temporário usado pelo compartilhamento.
  final String filePath;
  final String fileName;
  /// Cópia em Downloads (ou pasta equivalente), se disponível no dispositivo.
  final String? downloadsPath;
}

class BackupRestoreSummary {
  const BackupRestoreSummary({
    required this.clients,
    required this.loans,
    required this.payments,
    this.importedFromOtherAccount = false,
    this.sourceUserEmail,
  });

  final int clients;
  final int loans;
  final int payments;
  final bool importedFromOtherAccount;
  final String? sourceUserEmail;

  int get total => clients + loans + payments;
}

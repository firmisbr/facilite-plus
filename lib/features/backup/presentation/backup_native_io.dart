import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// Compartilhar arquivo de backup (API atual do share_plus).
Future<void> shareBackupFile({
  required String filePath,
  required String fileName,
  required String shareText,
}) async {
  try {
    await Share.shareXFiles(
      [XFile(filePath, name: fileName)],
      text: shareText,
    );
  } on MissingPluginException {
    throw BackupNativeIoException(BackupNativeIoException.rebuildHint);
  }
}

/// Seleciona arquivo JSON de backup.
Future<List<int>?> pickBackupJsonBytes() async {
  try {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return null;
    final bytes = picked.files.single.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw BackupNativeIoException('Arquivo vazio ou inacessível.');
    }
    return bytes;
  } on MissingPluginException {
    throw BackupNativeIoException(BackupNativeIoException.rebuildHint);
  }
}

class BackupNativeIoException implements Exception {
  BackupNativeIoException(this.message);

  static const rebuildHint =
      'Reinstale o app após atualizar: pare o debug, execute '
      '"flutter clean", depois "flutter run" (hot reload não carrega '
      'compartilhar/arquivo).';

  final String message;

  @override
  String toString() => message;
}

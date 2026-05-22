import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Salva backup na pasta Downloads visível ao usuário.
class BackupDownloadsStorage {
  BackupDownloadsStorage._();

  static const _channel =
      MethodChannel('com.firmis.facilite_plus/backup_downloads');

  /// Retorna caminho amigável (ex. `Downloads/arquivo.json`) ou caminho absoluto.
  static Future<String?> saveJsonFile({
    required String fileName,
    required List<int> bytes,
  }) async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final saved = await _channel.invokeMethod<String>(
          'saveToDownloads',
          {'fileName': fileName, 'bytes': bytes},
        );
        return saved;
      } on PlatformException {
        return null;
      }
    }

    try {
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir == null) return null;
      final destPath = p.join(downloadsDir.path, fileName);
      await File(destPath).writeAsBytes(bytes);
      return destPath;
    } catch (_) {
      return null;
    }
  }
}

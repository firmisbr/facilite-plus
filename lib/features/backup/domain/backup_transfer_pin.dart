import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import 'backup_snapshot.dart';

/// PIN de 4 dígitos para importar backup em outra conta (hash + salt no JSON).
class BackupTransferPin {
  BackupTransferPin._();

  static final _pinPattern = RegExp(r'^\d{4}$');

  static void validateFormat(String pin) {
    if (!_pinPattern.hasMatch(pin)) {
      throw BackupException('O PIN deve ter exatamente 4 dígitos.');
    }
  }

  static String generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  static String hash(String pin, String salt) {
    validateFormat(pin);
    final digest = sha256.convert(utf8.encode('$pin:$salt'));
    return base64Url.encode(digest.bytes);
  }

  static bool verify({
    required String pin,
    required String salt,
    required String expectedHash,
  }) {
    try {
      return hash(pin, salt) == expectedHash;
    } on BackupException {
      return false;
    }
  }

  static ({String salt, String hash}) createForExport(String pin) {
    validateFormat(pin);
    final salt = generateSalt();
    return (salt: salt, hash: hash(pin, salt));
  }
}

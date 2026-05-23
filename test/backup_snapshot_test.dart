import 'package:flutter_test/flutter_test.dart';
import 'package:facilite_plus/features/backup/domain/backup_snapshot.dart';
import 'package:facilite_plus/features/backup/domain/backup_transfer_pin.dart';

BackupSnapshot _sampleSnapshot({
  required String userId,
  bool withPin = false,
  String pin = '1234',
}) {
  String? salt;
  String? hash;
  if (withPin) {
    final data = BackupTransferPin.createForExport(pin);
    salt = data.salt;
    hash = data.hash;
  }
  return BackupSnapshot(
    version: BackupSnapshot.currentVersion,
    app: BackupSnapshot.appId,
    exportedAt: '2026-01-01T00:00:00Z',
    userId: userId,
    userEmail: 'a@example.com',
    transferPinSalt: salt,
    transferPinHash: hash,
    clients: [
      {'id': 'c1', 'user_id': userId, 'name': 'Maria'},
    ],
    loans: [
      {'id': 'l1', 'client_id': 'c1', 'amount': '100'},
    ],
    payments: [],
  );
}

void main() {
  test('mesma conta restaura sem PIN', () {
    final snapshot = _sampleSnapshot(userId: 'user-a', withPin: true);
    expect(
      () => snapshot.validateForSameAccountRestore(currentUserId: 'user-a'),
      returnsNormally,
    );
  });

  test('outra conta na restauração mesma conta falha', () {
    final snapshot = _sampleSnapshot(userId: 'user-a');
    expect(
      () => snapshot.validateForSameAccountRestore(currentUserId: 'user-b'),
      throwsA(isA<BackupException>()),
    );
  });

  test('importação cross-account exige PIN correto', () {
    final snapshot = _sampleSnapshot(userId: 'user-a', withPin: true, pin: '5678');
    expect(
      () => snapshot.validateForCrossAccountImport(pin: '5678'),
      returnsNormally,
    );
    expect(
      () => snapshot.validateForCrossAccountImport(pin: '0000'),
      throwsA(
        predicate<BackupException>((e) => e.message.contains('PIN incorreto')),
      ),
    );
  });

  test('importação cross-account sem PIN no arquivo falha', () {
    final snapshot = _sampleSnapshot(userId: 'user-a', withPin: false);
    expect(
      () => snapshot.validateForCrossAccountImport(pin: '1234'),
      throwsA(isA<BackupException>()),
    );
  });
}

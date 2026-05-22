import 'package:flutter_test/flutter_test.dart';
import 'package:facilite_plus/features/backup/domain/backup_snapshot.dart';

void main() {
  test('rejeita backup de outra conta', () {
    final snapshot = BackupSnapshot(
      version: BackupSnapshot.currentVersion,
      app: BackupSnapshot.appId,
      exportedAt: '2026-01-01T00:00:00Z',
      userId: 'user-a',
      clients: [
        {'id': 'c1', 'user_id': 'user-a', 'name': 'Maria'},
      ],
      loans: [
        {'id': 'l1', 'client_id': 'c1', 'amount': '100'},
      ],
      payments: [],
    );

    expect(
      () => snapshot.validateForRestore(currentUserId: 'user-b'),
      throwsA(isA<BackupException>()),
    );
  });
}

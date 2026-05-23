/// Entidades que participam da sincronização com Supabase.
enum SyncEntityType {
  client('clients'),
  loan('loans'),
  payment('payments');

  const SyncEntityType(this.tableName);

  final String tableName;

  static SyncEntityType? fromTableName(String name) {
    for (final type in SyncEntityType.values) {
      if (type.tableName == name) return type;
    }
    return null;
  }
}

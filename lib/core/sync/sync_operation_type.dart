enum SyncOperationType {
  insert('insert'),
  update('update'),
  delete('delete');

  const SyncOperationType(this.value);

  final String value;

  static SyncOperationType fromValue(String value) {
    return SyncOperationType.values.firstWhere((e) => e.value == value);
  }
}

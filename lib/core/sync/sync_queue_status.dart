enum SyncQueueStatus {
  pending('pending'),
  syncing('syncing'),
  synced('synced'),
  failed('failed');

  const SyncQueueStatus(this.value);

  final String value;

  static SyncQueueStatus fromValue(String value) {
    return SyncQueueStatus.values.firstWhere((e) => e.value == value);
  }
}

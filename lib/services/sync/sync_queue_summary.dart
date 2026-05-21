class SyncQueueSummary {
  const SyncQueueSummary({
    required this.pending,
    required this.failed,
  });

  final int pending;
  final int failed;

  int get total => pending + failed;

  bool get hasFailures => failed > 0;

  bool get hasPending => pending > 0;
}

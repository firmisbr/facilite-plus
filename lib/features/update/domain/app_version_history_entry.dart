class AppVersionHistoryEntry {
  const AppVersionHistoryEntry({
    required this.version,
    required this.build,
    required this.releasedAt,
    this.changelog,
  });

  final String version;
  final int build;
  final DateTime releasedAt;
  final String? changelog;

  factory AppVersionHistoryEntry.fromMap(Map<String, dynamic> map) {
    return AppVersionHistoryEntry(
      version: map['version'] as String,
      build: (map['build'] as num).toInt(),
      changelog: map['changelog'] as String?,
      releasedAt: DateTime.parse(map['released_at'] as String),
    );
  }
}

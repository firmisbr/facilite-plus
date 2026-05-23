/// Dados do manifesto remoto de atualização.
class AppUpdateInfo {
  const AppUpdateInfo({
    required this.version,
    required this.build,
    required this.apkUrl,
    this.minVersion,
    this.changelog,
  });

  final String version;
  final int build;
  final String apkUrl;
  final String? minVersion;
  final String? changelog;

  factory AppUpdateInfo.fromMap(Map<String, dynamic> map) {
    return AppUpdateInfo(
      version: map['version'] as String,
      build: (map['build'] as num).toInt(),
      apkUrl: map['apk_url'] as String,
      minVersion: map['min_version'] as String?,
      changelog: map['changelog'] as String?,
    );
  }
}

enum UpdateStatus {
  /// App já está na versão mais recente.
  upToDate,

  /// Atualização disponível (não obrigatória).
  available,

  /// Atualização obrigatória — versão atual abaixo do min_version.
  required,
}

class UpdateCheckResult {
  const UpdateCheckResult({
    required this.status,
    this.info,
    this.currentVersion,
  });

  final UpdateStatus status;
  final AppUpdateInfo? info;
  final String? currentVersion;

  bool get hasUpdate =>
      status == UpdateStatus.available || status == UpdateStatus.required;
}

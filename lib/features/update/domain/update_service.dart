import '../../../core/config/app_version.dart';
import '../data/update_repository.dart';
import 'app_update_info.dart';

class UpdateService {
  const UpdateService(this._repo);

  final UpdateRepository _repo;

  Future<UpdateCheckResult> check() async {
    final currentVersion = await AppVersion.resolve();
    final manifest = await _repo.fetchManifest();

    if (manifest == null) {
      return UpdateCheckResult(
        status: UpdateStatus.upToDate,
        currentVersion: currentVersion,
      );
    }

    final isNewer = _isNewer(manifest.version, currentVersion);

    if (!isNewer) {
      return UpdateCheckResult(
        status: UpdateStatus.upToDate,
        info: manifest,
        currentVersion: currentVersion,
      );
    }

    final minVer = manifest.minVersion;
    final isRequired = minVer != null && _isNewer(minVer, currentVersion);

    return UpdateCheckResult(
      status: isRequired ? UpdateStatus.required : UpdateStatus.available,
      info: manifest,
      currentVersion: currentVersion,
    );
  }

  /// `true` se [remote] é mais novo que [local].
  static bool _isNewer(String remote, String local) {
    final r = _parse(remote);
    final l = _parse(local);
    for (var i = 0; i < 3; i++) {
      if (r[i] > l[i]) return true;
      if (r[i] < l[i]) return false;
    }
    return false;
  }

  static List<int> _parse(String version) {
    final parts = version.trim().split('.');
    return List.generate(
      3,
      (i) => i < parts.length ? (int.tryParse(parts[i]) ?? 0) : 0,
    );
  }
}

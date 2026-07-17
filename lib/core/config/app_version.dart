import 'package:package_info_plus/package_info_plus.dart';

/// VersÃ£o do app (fonte: `pubspec.yaml` via build nativo).
abstract final class AppVersion {
  /// Fallback sÃ­ncrono â€” manter igual ao campo `version` do pubspec.
  static const fallback = '1.5.1';

  static Future<String> resolve() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (info.version.isNotEmpty) return info.version;
    } catch (_) {
      // Hot reload ou plataforma sem metadata â€” usa fallback.
    }
    return fallback;
  }
}

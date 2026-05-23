import 'package:package_info_plus/package_info_plus.dart';

/// Versão do app (fonte: `pubspec.yaml` via build nativo).
abstract final class AppVersion {
  /// Fallback síncrono — manter igual ao campo `version` do pubspec.
  static const fallback = '1.0.4';

  static Future<String> resolve() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (info.version.isNotEmpty) return info.version;
    } catch (_) {
      // Hot reload ou plataforma sem metadata — usa fallback.
    }
    return fallback;
  }
}

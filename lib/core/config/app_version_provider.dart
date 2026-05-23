import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_version.dart';

/// Versão instalada (`package_info` / fallback do pubspec).
final appVersionProvider = FutureProvider<String>((ref) async {
  return AppVersion.resolve();
});

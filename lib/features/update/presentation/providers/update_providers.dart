import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../services/supabase/supabase_providers.dart';
import '../../data/update_repository.dart';
import '../../domain/app_update_info.dart';
import '../../domain/app_version_history_entry.dart';
import '../../domain/update_service.dart';

final updateRepositoryProvider = Provider<UpdateRepository>((ref) {
  return UpdateRepository(ref.watch(supabaseClientProvider));
});

final updateServiceProvider = Provider<UpdateService>((ref) {
  return UpdateService(ref.watch(updateRepositoryProvider));
});

final updateCheckProvider = FutureProvider<UpdateCheckResult>((ref) async {
  ref.watch(sessionProvider);
  return ref.watch(updateServiceProvider).check();
});

final versionHistoryProvider =
    FutureProvider<List<AppVersionHistoryEntry>>((ref) async {
  ref.watch(sessionProvider);
  return ref.watch(updateRepositoryProvider).fetchVersionHistory();
});

final hasUpdateBadgeProvider = Provider<bool>((ref) {
  return ref.watch(updateCheckProvider).valueOrNull?.hasUpdate ?? false;
});

// ──── Download state ────────────────────────────────────────────────────────

enum DownloadPhase { idle, downloading, installing, error }

class DownloadState {
  const DownloadState({
    this.phase = DownloadPhase.idle,
    this.progress = 0,
    this.errorMessage,
  });

  final DownloadPhase phase;

  /// 0.0–1.0
  final double progress;
  final String? errorMessage;

  DownloadState copyWith({
    DownloadPhase? phase,
    double? progress,
    String? errorMessage,
  }) {
    return DownloadState(
      phase: phase ?? this.phase,
      progress: progress ?? this.progress,
      errorMessage: errorMessage,
    );
  }
}

class DownloadNotifier extends StateNotifier<DownloadState> {
  DownloadNotifier() : super(const DownloadState());

  Future<void> downloadAndInstall(String apkUrl) async {
    state = const DownloadState(phase: DownloadPhase.downloading, progress: 0);

    try {
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/facilite_plus_update.apk';

      final dio = Dio();
      await dio.download(
        apkUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            state = state.copyWith(progress: received / total);
          }
        },
        options: Options(receiveTimeout: const Duration(minutes: 10)),
      );

      state = const DownloadState(phase: DownloadPhase.installing, progress: 1);

      final file = File(filePath);
      if (!file.existsSync()) throw Exception('Arquivo não encontrado após download.');

      await OpenFilex.open(filePath, type: 'application/vnd.android.package-archive');

      state = const DownloadState(phase: DownloadPhase.idle);
    } catch (e) {
      state = DownloadState(
        phase: DownloadPhase.error,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() {
    state = const DownloadState();
  }
}

final downloadNotifierProvider =
    StateNotifierProvider<DownloadNotifier, DownloadState>(
  (_) => DownloadNotifier(),
);

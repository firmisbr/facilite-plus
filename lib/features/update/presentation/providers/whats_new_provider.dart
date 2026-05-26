import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_version.dart';
import '../../data/whats_new_seen_store.dart';
import '../../domain/app_version_history_entry.dart';
import 'update_providers.dart';

class WhatsNewState {
  const WhatsNewState({
    required this.shouldShow,
    required this.currentVersion,
    this.entry,
  });

  final bool shouldShow;
  final String currentVersion;
  final AppVersionHistoryEntry? entry;
}

/// Lê o changelog do [app_update_manifest] (mesmo que o script -Changelog
/// já popula), sem precisar de migration separada para app_version_history.
final whatsNewProvider = FutureProvider<WhatsNewState>((ref) async {
  final currentVersion = await AppVersion.resolve();
  final lastSeen = await WhatsNewSeenStore.lastSeenVersion();

  if (lastSeen == currentVersion) {
    return WhatsNewState(shouldShow: false, currentVersion: currentVersion);
  }

  final checkResult = await ref.watch(updateCheckProvider.future);
  final info = checkResult.info;

  // O manifesto pode trazer a versão atual (upToDate) ou uma mais nova.
  // Em ambos os casos o changelog já é o da versão mais recente publicada.
  final changelog = info?.changelog?.trim();
  final hasChangelog = changelog != null && changelog.isNotEmpty;

  if (!hasChangelog) {
    // Sem changelog → marca como visto para não tentar de novo.
    await WhatsNewSeenStore.markSeen(currentVersion);
    return WhatsNewState(shouldShow: false, currentVersion: currentVersion);
  }

  final entry = AppVersionHistoryEntry(
    version: info!.version,
    build: info.build,
    releasedAt: DateTime.now(),
    changelog: info.changelog,
  );

  return WhatsNewState(
    shouldShow: true,
    currentVersion: currentVersion,
    entry: entry,
  );
});

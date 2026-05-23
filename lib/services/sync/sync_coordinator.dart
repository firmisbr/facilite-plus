import 'dart:async' show StreamSubscription, unawaited;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../supabase/supabase_providers.dart';
import 'sync_providers.dart';

final _log = Logger('sync-coordinator');

/// Dispara sync ao autenticar ou quando a rede volta.
class SyncCoordinator {
  SyncCoordinator(this._ref);

  final Ref _ref;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _hadSession = false;

  void start() {
    final session = _ref.read(sessionProvider).valueOrNull;
    _hadSession = session != null;
    if (_hadSession) {
      unawaited(_runSync());
    }

    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final online = !results.contains(ConnectivityResult.none);
      if (online && _ref.read(sessionProvider).valueOrNull != null) {
        unawaited(_runSync());
      }
    });

    _ref.listen(sessionProvider, (previous, next) {
      final wasLoggedIn = previous?.valueOrNull != null;
      final isLoggedIn = next.valueOrNull != null;
      if (!wasLoggedIn && isLoggedIn) {
        unawaited(_runSync());
      }
      _hadSession = isLoggedIn;
    });
  }

  void dispose() {
    _connectivitySub?.cancel();
  }

  Future<void> _runSync() async {
    final sync = _ref.read(syncServiceProvider);
    try {
      final push = await sync.processQueue();
      if (!push.skipped) {
        _log.info('Upload: ${push.synced} ok, ${push.failed} falha(s)');
      }
      await sync.pullRemoteChanges();
    } catch (e, st) {
      _log.warning('Sync falhou', e, st);
    }
  }
}

final syncCoordinatorProvider = Provider<SyncCoordinator>((ref) {
  final coordinator = SyncCoordinator(ref);
  coordinator.start();
  ref.onDispose(coordinator.dispose);
  return coordinator;
});

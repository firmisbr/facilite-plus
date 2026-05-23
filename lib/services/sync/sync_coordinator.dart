import 'dart:async' show StreamSubscription, unawaited;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../shared/widgets/sync_feedback.dart';
import '../supabase/supabase_providers.dart';
import 'sync_providers.dart';

final _log = Logger('sync-coordinator');

/// Sync automático: login, rede, retorno ao app, fila pendente. Atualiza telas após cada ciclo.
class SyncCoordinator with WidgetsBindingObserver {
  SyncCoordinator(this._ref);

  final Ref _ref;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _hadSession = false;
  bool _syncing = false;
  DateTime? _lastSyncFinishedAt;

  static const _minIntervalBetweenSyncs = Duration(seconds: 15);

  void start() {
    WidgetsBinding.instance.addObserver(this);

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
        unawaited(_runSync(force: true));
      }
      _hadSession = isLoggedIn;
    });

    _ref.listen(syncQueueSummaryProvider, (previous, next) {
      final total = next.valueOrNull?.total ?? 0;
      final prevTotal = previous?.valueOrNull?.total ?? 0;
      if (total > 0 && total != prevTotal) {
        unawaited(_runSync(force: true));
      }
    });
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySub?.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _ref.read(sessionProvider).valueOrNull != null) {
      unawaited(_runSync(force: _queueHasWork()));
    }
  }

  /// Dispara ciclo completo (ex.: após restaurar backup).
  Future<void> requestSync({bool force = true}) => _runSync(force: force);

  bool _queueHasWork() {
    final summary = _ref.read(syncQueueSummaryProvider).valueOrNull;
    return summary != null && summary.total > 0;
  }

  Future<void> _runSync({bool force = false}) async {
    if (_syncing) return;

    final hasWork = _queueHasWork();
    if (!force &&
        !hasWork &&
        _lastSyncFinishedAt != null &&
        DateTime.now().difference(_lastSyncFinishedAt!) <
            _minIntervalBetweenSyncs) {
      return;
    }

    if (_ref.read(sessionProvider).valueOrNull == null) return;

    _syncing = true;
    try {
      final push = await runBackgroundSync(_ref);
      if (!push.skipped) {
        _log.info('Sync automático: ${push.synced} ok, ${push.failed} falha(s)');
      }
    } catch (e, st) {
      _log.warning('Sync automático falhou', e, st);
    } finally {
      _syncing = false;
      _lastSyncFinishedAt = DateTime.now();
    }
  }
}

final syncCoordinatorProvider = Provider<SyncCoordinator>((ref) {
  final coordinator = SyncCoordinator(ref);
  coordinator.start();
  ref.onDispose(coordinator.dispose);
  return coordinator;
});

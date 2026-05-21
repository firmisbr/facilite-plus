import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'services/database/drift/drift_providers.dart';
import 'services/sync/sync_coordinator.dart';

class FacilitePlusApp extends ConsumerWidget {
  const FacilitePlusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    ref.watch(appDatabaseProvider);
    ref.watch(syncCoordinatorProvider);

    return MaterialApp.router(
      title: 'Facilite Plus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}

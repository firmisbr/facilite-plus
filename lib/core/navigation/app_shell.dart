import 'package:flutter/material.dart';

import '../../shared/widgets/app_drawer.dart';

/// Chave do Scaffold do shell — abre o drawer das telas internas.
final GlobalKey<ScaffoldState> appShellScaffoldKey = GlobalKey<ScaffoldState>();

void openAppDrawer() {
  appShellScaffoldKey.currentState?.openDrawer();
}

/// Layout autenticado com menu lateral.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: appShellScaffoldKey,
      drawer: const AppDrawer(),
      body: child,
    );
  }
}

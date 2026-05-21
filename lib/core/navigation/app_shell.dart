import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../shared/widgets/floating_notched_nav_bar.dart';

/// Layout autenticado com barra inferior flutuante (referência).
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          navigationShell,
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingNotchedNavBar(
              currentIndex: navigationShell.currentIndex,
              onTabSelected: _goBranch,
              onCreateLoan: () => context.push(AppRoutes.loanCreate),
            ),
          ),
        ],
      ),
    );
  }
}

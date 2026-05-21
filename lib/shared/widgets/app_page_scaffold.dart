import 'package:flutter/material.dart';

import '../../core/navigation/app_shell.dart';
import '../../core/theme/app_decorations.dart';

/// Scaffold de telas principais do shell (menu + AppBar).
class AppPageScaffold extends StatelessWidget {
  const AppPageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          tooltip: 'Menu',
          onPressed: openAppDrawer,
        ),
        title: Text(title),
        actions: actions,
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppDecorations.screenBackground(brightness),
        ),
        child: SafeArea(
          top: false,
          child: body,
        ),
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}

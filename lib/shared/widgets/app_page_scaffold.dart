import 'package:flutter/material.dart';

import '../../core/theme/app_decorations.dart';

/// Scaffold de telas principais do shell (barra inferior).
class AppPageScaffold extends StatelessWidget {
  const AppPageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.showBackButton = false,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: showBackButton,
        leading: showBackButton ? const BackButton() : null,
        title: Text(title),
        actions: actions,
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppDecorations.screenBackground(brightness),
        ),
        child: SafeArea(
          top: false,
          bottom: false,
          child: body,
        ),
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}

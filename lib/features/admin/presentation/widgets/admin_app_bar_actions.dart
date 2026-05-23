import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_controller.dart';

class AdminAppBarActions extends ConsumerWidget {
  const AdminAppBarActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.logout_rounded),
      tooltip: 'Sair',
      onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
    );
  }
}

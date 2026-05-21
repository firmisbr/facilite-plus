import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../services/sync/sync_messages.dart';
import '../../services/sync/sync_service.dart';

void showSyncSnackBar(BuildContext context, SyncRunResult result) {
  final text = SyncMessages.forRunResult(result);
  final hasFailure = !result.skipped && result.failed > 0;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
      backgroundColor: hasFailure ? AppColors.error : null,
      duration: Duration(seconds: hasFailure ? 5 : 3),
    ),
  );
}

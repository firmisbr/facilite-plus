import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/app_update_info.dart';
import '../domain/app_version_history_entry.dart';

class UpdateRepository {
  const UpdateRepository(this._supabase);

  final SupabaseClient _supabase;

  Future<AppUpdateInfo?> fetchManifest() async {
    try {
      final row = await _supabase
          .from('app_update_manifest')
          .select()
          .eq('id', 1)
          .maybeSingle();
      if (row == null) return null;
      return AppUpdateInfo.fromMap(Map<String, dynamic>.from(row));
    } catch (_) {
      return null;
    }
  }

  Future<List<AppVersionHistoryEntry>> fetchVersionHistory() async {
    try {
      final rows = await _supabase
          .from('app_version_history')
          .select()
          .order('released_at', ascending: false);
      return rows
          .map(
            (row) => AppVersionHistoryEntry.fromMap(
              Map<String, dynamic>.from(row),
            ),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }
}

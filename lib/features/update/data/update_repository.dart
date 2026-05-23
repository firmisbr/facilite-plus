import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/app_update_info.dart';

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
}

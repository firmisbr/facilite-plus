import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/user_profile.dart';

class ProfileRepository {
  const ProfileRepository(this._supabase);

  final SupabaseClient _supabase;

  Future<UserProfile?> fetch(String userId) async {
    final row = await _supabase
        .from('profiles')
        .select('id, name, email, created_at')
        .eq('id', userId)
        .maybeSingle();
    if (row == null) return null;
    return UserProfile.fromMap(Map<String, dynamic>.from(row));
  }

  Future<void> updateName(String userId, String name) async {
    await _supabase
        .from('profiles')
        .update({'name': name.trim()})
        .eq('id', userId);
  }
}

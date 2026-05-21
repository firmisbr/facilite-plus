import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return supabaseClient;
});

final sessionProvider = StreamProvider<Session?>((ref) async* {
  final auth = ref.watch(supabaseClientProvider).auth;
  yield auth.currentSession;
  await for (final event in auth.onAuthStateChange) {
    yield event.session;
  }
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(sessionProvider).valueOrNull != null;
});

final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(sessionProvider).valueOrNull?.user.id;
});

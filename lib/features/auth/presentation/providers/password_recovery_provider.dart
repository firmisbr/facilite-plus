import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../services/supabase/supabase_providers.dart';

/// `true` quando o usuário abriu o link de redefinição de senha no app.
final passwordRecoveryActiveProvider = StreamProvider<bool>((ref) async* {
  final auth = ref.watch(supabaseClientProvider).auth;
  yield false;
  await for (final event in auth.onAuthStateChange) {
    yield event.event == AuthChangeEvent.passwordRecovery;
  }
});

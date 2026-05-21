import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';

Future<void> initializeSupabase() async {
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
}

SupabaseClient get supabaseClient => Supabase.instance.client;

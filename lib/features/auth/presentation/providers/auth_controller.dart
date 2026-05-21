import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/supabase/supabase_service.dart';

class AuthState {
  const AuthState({this.isLoading = false, this.error});

  final bool isLoading;
  final String? error;

  AuthState copyWith({bool? isLoading, String? error, bool clearError = false}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(Ref ref) : super(const AuthState());

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await supabaseClient.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      state = const AuthState();
    } catch (e) {
      state = AuthState(isLoading: false, error: _friendlyError(e));
    }
  }

  Future<void> signUp(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await supabaseClient.auth.signUp(
        email: email.trim(),
        password: password,
      );
      state = const AuthState();
    } catch (e) {
      state = AuthState(isLoading: false, error: _friendlyError(e));
    }
  }

  Future<void> signOut() async {
    await supabaseClient.auth.signOut();
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('Invalid login credentials')) {
      return 'E-mail ou senha inválidos.';
    }
    return 'Não foi possível autenticar. Tente novamente.';
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref);
});

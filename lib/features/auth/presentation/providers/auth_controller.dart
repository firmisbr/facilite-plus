import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../services/supabase/supabase_service.dart';

/// Deep link para redefinição de senha (configure no Supabase → Auth → URL).
const kPasswordResetRedirect = 'com.firmis.facilite_plus://reset-password';

class AuthState {
  const AuthState({
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  final bool isLoading;
  final String? error;
  final String? successMessage;

  AuthState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(Ref ref) : super(const AuthState());

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
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
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      final response = await supabaseClient.auth.signUp(
        email: email.trim(),
        password: password,
      );

      if (response.session == null && response.user != null) {
        state = const AuthState(
          successMessage:
              'Conta criada! Confira seu e-mail para confirmar o cadastro '
              'antes de entrar.',
        );
        return;
      }

      state = const AuthState();
    } catch (e) {
      state = AuthState(isLoading: false, error: _friendlyError(e));
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      await supabaseClient.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: kPasswordResetRedirect,
      );
      state = AuthState(
        successMessage:
            'Enviamos um link para ${email.trim()}. '
            'Abra o e-mail neste aparelho para definir uma nova senha.',
      );
    } catch (e) {
      state = AuthState(isLoading: false, error: _friendlyError(e));
    }
  }

  Future<void> updatePassword(String newPassword) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      await supabaseClient.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      state = const AuthState(
        successMessage: 'Senha atualizada! Você já pode usar o app.',
      );
    } catch (e) {
      state = AuthState(isLoading: false, error: _friendlyError(e));
    }
  }

  Future<void> signOut() async {
    await supabaseClient.auth.signOut();
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  String _friendlyError(Object e) {
    if (e is AuthException) {
      return _friendlyAuthMessage(e.message);
    }
    return _friendlyAuthMessage(e.toString());
  }

  String _friendlyAuthMessage(String msg) {
    final lower = msg.toLowerCase();

    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid_credentials')) {
      return 'E-mail ou senha incorretos.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Confirme seu e-mail antes de entrar. Verifique a caixa de entrada.';
    }
    if (lower.contains('user already registered') ||
        lower.contains('already been registered')) {
      return 'Este e-mail já possui cadastro. Tente entrar ou recuperar a senha.';
    }
    if (lower.contains('password should be at least')) {
      return 'A senha deve ter pelo menos 6 caracteres.';
    }
    if (lower.contains('unable to validate email') ||
        lower.contains('invalid email')) {
      return 'Informe um e-mail válido.';
    }
    if (lower.contains('rate limit') || lower.contains('too many requests')) {
      return 'Muitas tentativas. Aguarde alguns minutos e tente novamente.';
    }
    if (lower.contains('signup requires a valid password')) {
      return 'Informe uma senha válida (mínimo 6 caracteres).';
    }

    return 'Não foi possível concluir. Tente novamente.';
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref);
});

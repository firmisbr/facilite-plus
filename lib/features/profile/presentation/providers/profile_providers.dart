import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../services/supabase/supabase_providers.dart';
import '../../data/profile_repository.dart';
import '../../domain/user_profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseClientProvider));
});

final profileProvider = FutureProvider<UserProfile?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  return ref.watch(profileRepositoryProvider).fetch(userId);
});

// ── Controller ───────────────────────────────────────────────────────────────

class ProfileState {
  const ProfileState({
    this.isSaving = false,
    this.error,
    this.successMessage,
  });

  final bool isSaving;
  final String? error;
  final String? successMessage;

  ProfileState copyWith({
    bool? isSaving,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) =>
      ProfileState(
        isSaving: isSaving ?? this.isSaving,
        error: clearError ? null : (error ?? this.error),
        successMessage:
            clearSuccess ? null : (successMessage ?? this.successMessage),
      );
}

class ProfileController extends StateNotifier<ProfileState> {
  ProfileController(this._ref) : super(const ProfileState());

  final Ref _ref;

  Future<void> saveName(String name) async {
    if (name.trim().isEmpty) {
      state = state.copyWith(error: 'Informe um nome.');
      return;
    }
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return;
    state = state.copyWith(isSaving: true, clearError: true, clearSuccess: true);
    try {
      await _ref.read(profileRepositoryProvider).updateName(userId, name);
      _ref.invalidate(profileProvider);
      state = state.copyWith(
        isSaving: false,
        successMessage: 'Nome atualizado!',
      );
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: 'Não foi possível salvar. Tente novamente.',
      );
    }
  }

  Future<void> sendPasswordReset(String email) async {
    state = state.copyWith(isSaving: true, clearError: true, clearSuccess: true);
    try {
      await _ref
          .read(supabaseClientProvider)
          .auth
          .resetPasswordForEmail(
            email,
            redirectTo: 'com.firmis.facilite_plus://reset-password',
          );
      state = state.copyWith(
        isSaving: false,
        successMessage: 'Link enviado para $email. Abra o e-mail neste aparelho.',
      );
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        error: 'Não foi possível enviar o link. Tente novamente.',
      );
    }
  }

  void clearMessages() =>
      state = state.copyWith(clearError: true, clearSuccess: true);
}

final profileControllerProvider =
    StateNotifierProvider<ProfileController, ProfileState>((ref) {
  return ProfileController(ref);
});

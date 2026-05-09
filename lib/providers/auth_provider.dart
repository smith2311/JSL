import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/token_helper.dart';

class AuthState {
  final bool isAuthenticated;
  final String? error;
  final bool isLoading;

  AuthState({
    this.isAuthenticated = false,
    this.error,
    this.isLoading = false,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? error,
    bool? isLoading,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthStateNotifier extends StateNotifier<AuthState> {
  AuthStateNotifier() : super(AuthState()) {
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    state = state.copyWith(isLoading: true);
    try {
      final token = await TokenHelper.getValidToken();
      state = state.copyWith(
        isAuthenticated: token != null,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refreshAuthState() async => _checkAuthState();
}

final authStateProvider =
StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier();
});
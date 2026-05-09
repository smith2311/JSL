import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/data/models/registration.dart';

class RegistrationNotifier extends StateNotifier<RegistrationState> {
  RegistrationNotifier() : super(RegistrationState());

  void setEmail(String email) {
    state = state.copyWith(email: email);
  }

  void setEmailVerified(bool value) {
    state = state.copyWith(isEmailVerified: value);
  }

  void setOtp(String otp) {
    state = state.copyWith(otp: otp);
  }

  void setAccessToken(String token) {
    state = state.copyWith(accessToken: token);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setShowPasswordScreen(bool value) {
    state = state.copyWith(showPasswordScreen: value);
  }

  void togglePasswordVisibility() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  void toggleConfirmPasswordVisibility() {
    state = state.copyWith(obscureConfirmPassword: !state.obscureConfirmPassword);
  }

  void resetCountdown() {
    state = state.copyWith(countdown: 30);
  }

  void decrementCountdown() {
    if (state.countdown > 0) {
      state = state.copyWith(countdown: state.countdown - 1);
    }
  }

  void validatePassword(String password, String confirmPassword) {
    if (password.isEmpty) {
      state = state.copyWith(
        passwordError: "Password is required",
        isPasswordValid: false,
      );
    } else if (password.length < 8) {
      state = state.copyWith(
        passwordError: "Password must be at least 8 characters",
        isPasswordValid: false,
      );
    } else {
      state = state.copyWith(
        passwordError: null,
        isPasswordValid: true,
      );

      if (confirmPassword.isNotEmpty) {
        validateConfirmPassword(password, confirmPassword);
      }
    }
  }

  void validateConfirmPassword(String password, String confirmPassword) {
    if (confirmPassword.isEmpty) {
      state = state.copyWith(
        confirmPasswordError: "Please confirm your password",
        isConfirmPasswordValid: false,
      );
    } else if (confirmPassword != password) {
      state = state.copyWith(
        confirmPasswordError: "Passwords do not match",
        isConfirmPasswordValid: false,
      );
    } else {
      state = state.copyWith(
        confirmPasswordError: null,
        isConfirmPasswordValid: true,
      );
    }
  }

  void reset() {
    state = RegistrationState();
  }
}

final registrationProvider = StateNotifierProvider<RegistrationNotifier, RegistrationState>(
      (ref) => RegistrationNotifier(),
);
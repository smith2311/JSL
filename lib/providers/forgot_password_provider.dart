import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:jhaveri_jsl_app/core/config/env.dart';
import '../features/auth/data/models/forgot_password.dart';

class ForgotPasswordNotifier extends StateNotifier<ForgotPasswordState> {
  ForgotPasswordNotifier() : super(ForgotPasswordState());

  void setOtpValue(String value) {
    state = state.copyWith(otpValue: value);
  }

  void setShowPasswordScreen(bool value) {
    state = state.copyWith(showPasswordScreen: value);
  }

  void togglePasswordVisibility() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  void toggleConfirmPasswordVisibility() {
    state = state.copyWith(
        obscureConfirmPassword: !state.obscureConfirmPassword);
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

      // Also validate confirm password if it has value
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

  Future<bool> sendOtp(String email) async {
    state = state.copyWith(isLoading: true);

    try {
      final baseUrl = EnvConfig.apiBaseUrl;
      final url = Uri.parse('$baseUrl/client/forgot-password');

      print('📤 Sending OTP to: $email');
      print('📤 URL: $url');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      print('📤 Send OTP Response: ${response.statusCode}');
      print('📤 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['status'] == 1 &&
            jsonResponse['data'] != null &&
            jsonResponse['data']['is_otp_send'] == true) {
          print('✅ OTP sent successfully');
          state = state.copyWith(isLoading: false);
          return true;
        }
      }

      print('❌ Failed to send OTP: Status ${response.statusCode}');
      state = state.copyWith(isLoading: false);
      return false;
    } on SocketException {
      print('❌ No internet connection');
      state = state.copyWith(isLoading: false);
      return false;
    } catch (e) {
      print('❌ Error sending OTP: $e');
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    state = state.copyWith(isLoading: true);

    try {
      final baseUrl = EnvConfig.apiBaseUrl;
      final url = Uri.parse('$baseUrl/client/verify-email-otp');

      print('📤 Verifying OTP for: $email');
      print('📤 URL: $url');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'otp': otp,
          'email': email,
        }),
      );

      print('📤 Verify OTP Response: ${response.statusCode}');
      print('📤 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['data'] != null &&
            jsonResponse['data']['is_otp_verified'] == true) {
          final accessToken = jsonResponse['data']['access_token'] ?? '';

          print('✅ OTP verified successfully');

          state = state.copyWith(
            accessToken: accessToken,
            showPasswordScreen: true,
            isLoading: false,
          );

          return {'success': true};
        } else {
          final message = jsonResponse['message'] ?? 'OTP verification failed';
          print('❌ OTP Verification Failed: $message');

          state = state.copyWith(isLoading: false);
          return {'success': false, 'message': message};
        }
      } else {
        final jsonResponse = jsonDecode(response.body);
        final message = jsonResponse['message'] ?? 'OTP verification failed';

        state = state.copyWith(isLoading: false);
        return {'success': false, 'message': message};
      }
    } on SocketException {
      state = state.copyWith(isLoading: false);
      return {'success': false, 'message': 'No internet connection'};
    } catch (e) {
      print('❌ Error verifying OTP: $e');
      state = state.copyWith(isLoading: false);
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> updatePassword({
    required String email,
    required String password,
    required String confirmPassword,
    required String accessToken,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      final baseUrl = EnvConfig.apiBaseUrl;
      final url = Uri.parse('$baseUrl/client/update-password');

      print('📤 Updating password for: $email');
      print('📤 URL: $url');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'confirm_password': confirmPassword,
          'access_token': accessToken,
        }),
      );

      print('📤 Update Password Response: ${response.statusCode}');
      print('📤 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['status'] == 1) {
          final message =
              jsonResponse['message'] ?? 'Password updated successfully';

          print('✅ Password updated successfully');

          state = state.copyWith(isLoading: false);
          return {'success': true, 'message': message};
        } else {
          final message =
              jsonResponse['message'] ?? 'Failed to update password';
          print('❌ Password Update Failed: $message');

          state = state.copyWith(isLoading: false);
          return {'success': false, 'message': message};
        }
      } else {
        final jsonResponse = jsonDecode(response.body);
        final message = jsonResponse['message'] ?? 'Failed to update password';
        print('❌ Password Update Failed: $message');

        state = state.copyWith(isLoading: false);
        return {'success': false, 'message': message};
      }
    } on SocketException {
      state = state.copyWith(isLoading: false);
      return {'success': false, 'message': 'No internet connection'};
    } catch (e) {
      print('❌ Error updating password: $e');
      state = state.copyWith(isLoading: false);
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  void reset() {
    state = ForgotPasswordState();
  }
}

// Provider
final forgotPasswordProvider =
StateNotifierProvider<ForgotPasswordNotifier, ForgotPasswordState>(
      (ref) => ForgotPasswordNotifier(),
);
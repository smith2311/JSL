import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jhaveri_jsl_app/constants/strings.dart';
import '../../../../../providers/forgot_password_provider.dart';
import '../../../../../widgets/custom_otp_field.dart';
import '../../data/models/forgot_password.dart';

class ForgotPasswordOtpScreen extends ConsumerStatefulWidget {
  final String email;

  const ForgotPasswordOtpScreen({
    super.key,
    required this.email,
  });

  @override
  ConsumerState<ForgotPasswordOtpScreen> createState() => _ForgotPasswordOtpScreenState();
}

class _ForgotPasswordOtpScreenState extends ConsumerState<ForgotPasswordOtpScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Delay the provider modification until after the widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startCountdown();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    ref.read(forgotPasswordProvider.notifier).resetCountdown();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final countdown = ref.read(forgotPasswordProvider).countdown;
      if (countdown > 0) {
        ref.read(forgotPasswordProvider.notifier).decrementCountdown();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _resendOtp() async {
    final success = await ref.read(forgotPasswordProvider.notifier).sendOtp(widget.email);

    if (success) {
      _startCountdown();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP resent successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to resend OTP'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _verifyOtp() async {
    final state = ref.read(forgotPasswordProvider);

    if (state.otpValue.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter complete OTP'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = await ref.read(forgotPasswordProvider.notifier).verifyOtp(widget.email, state.otpValue);

    if (!mounted) return;

    if (result['success'] == true) {
      // OTP verified successfully, screen will automatically show password fields
      // because showPasswordScreen is set to true in the provider
    } else {
      final message = result['message'] ?? 'OTP verification failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updatePassword() async {
    final state = ref.read(forgotPasswordProvider);
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (!state.isPasswordValid || !state.isConfirmPasswordValid) {
      return;
    }

    final result = await ref.read(forgotPasswordProvider.notifier).updatePassword(
      email: widget.email,
      password: password,
      confirmPassword: confirmPassword,
      accessToken: state.accessToken,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      final message = result['message'] ?? 'Password updated successfully';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // Reset the provider state
      ref.read(forgotPasswordProvider.notifier).reset();

      // Wait a moment for the snackbar to show, then navigate
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      // Navigate to email login screen (shows email entry part)
      context.go('/email_login', extra: {'clear_email': true});
    } else {
      final message = result['message'] ?? 'Failed to update password';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;

    final username = parts[0];
    final domain = parts[1];

    // Mask username: show last 3 characters
    String maskedUsername;
    if (username.length <= 3) {
      maskedUsername = username;
    } else {
      final visiblePart = username.substring(username.length - 3);
      maskedUsername = '****$visiblePart';
    }

    // Mask domain: show first 2 and last 2 characters
    String maskedDomain;
    if (domain.length <= 4) {
      maskedDomain = domain;
    } else {
      final firstPart = domain.substring(0, 2);
      final lastPart = domain.substring(domain.length - 2);
      maskedDomain = '$firstPart****$lastPart';
    }

    return '$maskedUsername@$maskedDomain';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordProvider);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF1F3F5),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(state.showPasswordScreen),
            const SizedBox(height: 36),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: state.showPasswordScreen
                    ? _buildPasswordContent(state)
                    : _buildOtpContent(state),
              ),
            ),
            _buildContinueButton(state),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(bool showPasswordScreen) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, left: 10, right: 16),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (showPasswordScreen) {
                // Go back to OTP screen (within the same page)
                ref.read(forgotPasswordProvider.notifier).setShowPasswordScreen(false);
              } else {
                // Go back to previous screen (forgot password email entry or login)
                context.pop();
              }
            },
            icon: SvgPicture.asset(
              AppStrings.back_icon,
              height: 28,
              width: 28,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            showPasswordScreen ? "Create a Password" : "Verification",
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpContent(ForgotPasswordState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'We have sent a 6-Digit OTP on your Email ID',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _maskEmail(widget.email),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 32),
        CustomOtpField(
          length: 6,
          onChanged: (value) {
            ref.read(forgotPasswordProvider.notifier).setOtpValue(value);
          },
          onCompleted: (value) {
            ref.read(forgotPasswordProvider.notifier).setOtpValue(value);
          },
        ),
        const SizedBox(height: 16),
        state.countdown > 0
            ? Text(
          "Didn't receive it? (${state.countdown}s)",
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        )
            : GestureDetector(
          onTap: _resendOtp,
          child: const Text(
            "Resend OTP",
            style: TextStyle(
              color: Color(0xFF0060A6),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordContent(ForgotPasswordState state) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 10),
            child: Text(
              "Create a Password",
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: state.obscurePassword,
            onChanged: (value) {
              ref.read(forgotPasswordProvider.notifier).validatePassword(
                value,
                _confirmPasswordController.text,
              );
            },
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(
              hintText: "Enter your password",
              errorText: state.passwordError,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  state.obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () {
                  ref.read(forgotPasswordProvider.notifier).togglePasswordVisibility();
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.only(left: 10),
            child: Text(
              "Confirm a Password",
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmPasswordController,
            obscureText: state.obscureConfirmPassword,
            onChanged: (value) {
              ref.read(forgotPasswordProvider.notifier).validateConfirmPassword(
                _passwordController.text,
                value,
              );
            },
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(
              hintText: "Re-Enter your password",
              errorText: state.confirmPasswordError,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  state.obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () {
                  ref.read(forgotPasswordProvider.notifier).toggleConfirmPasswordVisibility();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton(ForgotPasswordState state) {
    final canContinue = state.showPasswordScreen
        ? (state.isPasswordValid && state.isConfirmPasswordValid)
        : state.otpValue.length == 6;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: (canContinue && !state.isLoading)
              ? () {
            if (state.showPasswordScreen) {
              _updatePassword();
            } else {
              _verifyOtp();
            }
          }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canContinue ? const Color(0xFF0060A6) : Colors.grey,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: state.isLoading
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
              : const Text(
            "Continue",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
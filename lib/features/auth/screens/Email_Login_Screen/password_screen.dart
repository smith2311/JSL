import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:jhaveri_jsl_app/constants/strings.dart';
import 'package:jhaveri_jsl_app/features/auth/data/repo/auth_repo.dart';
import 'package:jhaveri_jsl_app/providers/user_provider.dart';
import 'package:jhaveri_jsl_app/providers/forgot_password_provider.dart';

class PasswordLoginScreen extends ConsumerStatefulWidget {
  final String email;

  const PasswordLoginScreen({super.key, required this.email});

  @override
  ConsumerState<PasswordLoginScreen> createState() => _PasswordLoginScreenState();
}

class _PasswordLoginScreenState extends ConsumerState<PasswordLoginScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final ValueNotifier<bool> _obscurePassword = ValueNotifier(true);
  final ValueNotifier<String?> _passwordError = ValueNotifier(null);
  final ValueNotifier<bool> _isPasswordValid = ValueNotifier(false);
  final ValueNotifier<bool> _isLoading = ValueNotifier(false);
  final ValueNotifier<bool> _isForgotPasswordLoading = ValueNotifier(false);
  final AuthRepo _authRepo = AuthRepo();

  void _onPasswordChanged(String value) {
    if (value.isEmpty) {
      _passwordError.value = "Password is required";
      _isPasswordValid.value = false;
    } else if (value.length < 8) {
      _passwordError.value = "Password must be at least 8 characters";
      _isPasswordValid.value = false;
    } else {
      _passwordError.value = null;
      _isPasswordValid.value = true;
    }
  }

  Future<void> _performLogin() async {
    final password = _passwordController.text;
    final email = widget.email;

    if (password.isEmpty || password.length < 8) return;

    _isLoading.value = true;
    try {
      final data = await _authRepo.login(email, password);

      if (data != null) {
        final token = data['token'];
        final name = data['user_name'] ?? 'User';
        final avatar = data['image_url'];

        if (token != null) {
          ref.read(userProvider.notifier).setToken(token);
        }
        ref.read(userProvider.notifier).setUserName(name);
        ref.read(userProvider.notifier).setAvatar(avatar);

        if (!mounted) return;
        context.go('/dashboard');
      } else {
        _passwordError.value = "Incorrect email or password";
      }
    } on SocketException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Connect to the server")),
      );
    } catch (e) {
      _passwordError.value = "Login failed. Try again.";
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _handleForgotPassword() async {
    // Show loading and disable screen
    _isForgotPasswordLoading.value = true;

    try {
      // Send OTP
      final success = await ref.read(forgotPasswordProvider.notifier).sendOtp(widget.email);

      if (!mounted) return;

      if (success) {
        // Only navigate on successful API call
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP sent successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate to OTP verification screen
        context.push('/forgot-password-otp', extra: {'email': widget.email});
      } else {
        // Show error and stay on the same screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send OTP. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      // Handle any unexpected errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      // Reset loading state
      if (mounted) {
        _isForgotPasswordLoading.value = false;
      }
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _obscurePassword.dispose();
    _passwordError.dispose();
    _isPasswordValid.dispose();
    _isLoading.dispose();
    _isForgotPasswordLoading.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isForgotPasswordLoading,
      builder: (context, isForgotPasswordLoading, _) {
        return PopScope(
          canPop: !isForgotPasswordLoading,
          child: Stack(
            children: [
              Scaffold(
                backgroundColor: const Color(0xFFF1F3F5),
                body: SafeArea(
                  child: Column(
                    children: [
                      _buildAppBar(isForgotPasswordLoading),
                      const SizedBox(height: 36),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            _buildPasswordInput(isForgotPasswordLoading),
                            const SizedBox(height: 8),
                            _buildForgotPasswordLink(isForgotPasswordLoading),
                          ],
                        ),
                      ),
                      const Spacer(),
                      _buildLoginButton(isForgotPasswordLoading),
                    ],
                  ),
                ),
              ),
              if (isForgotPasswordLoading)
                Container(
                  color: Colors.black54,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 24,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: Color(0xFF0060A6),
                            strokeWidth: 3,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Sending OTP...',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBar(bool isDisabled) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, left: 10, right: 16),
      child: Row(
        children: [
          IconButton(
            onPressed: isDisabled ? null : () => context.pop(),
            icon: SvgPicture.asset(
              AppStrings.back_icon,
              height: 28,
              width: 28,
              color: isDisabled ? Colors.grey : Colors.black,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            AppStrings.pwd_login_title,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordInput(bool isDisabled) {
    return ValueListenableBuilder<bool>(
      valueListenable: _obscurePassword,
      builder: (_, obscure, __) {
        return ValueListenableBuilder<String?>(
          valueListenable: _passwordError,
          builder: (_, passErr, __) {
            return TextField(
              controller: _passwordController,
              obscureText: obscure,
              onChanged: isDisabled ? null : _onPasswordChanged,
              enabled: !isDisabled,
              decoration: InputDecoration(
                hintText: AppStrings.enter_passw,
                errorText: passErr,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF0060A6), width: 2),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscure ? Icons.visibility_off : Icons.visibility,
                    color: isDisabled ? Colors.grey.shade400 : Colors.grey,
                  ),
                  onPressed: isDisabled
                      ? null
                      : () => _obscurePassword.value = !_obscurePassword.value,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildForgotPasswordLink(bool isDisabled) {
    return Align(
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: isDisabled ? null : _handleForgotPassword,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Forgot password ?',
            style: TextStyle(
              color: isDisabled ? Colors.grey : const Color(0xFF0060A6),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(bool isDisabled) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ValueListenableBuilder<bool>(
          valueListenable: _isPasswordValid,
          builder: (_, valid, __) {
            return ValueListenableBuilder<bool>(
              valueListenable: _isLoading,
              builder: (_, loading, __) {
                return ElevatedButton(
                  onPressed: (valid && !loading && !isDisabled) ? _performLogin : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    valid ? const Color(0xFF0060A6) : Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: loading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    AppStrings.continue_btn,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
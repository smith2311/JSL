import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:jhaveri_jsl_app/constants/strings.dart';
import 'package:jhaveri_jsl_app/features/auth/data/repo/auth_repo.dart';
import 'package:jhaveri_jsl_app/providers/registration_provider.dart';

import '../../data/models/registration.dart';

class RegistrationCreatePasswordScreen extends ConsumerStatefulWidget {
  const RegistrationCreatePasswordScreen({super.key});

  @override
  ConsumerState<RegistrationCreatePasswordScreen> createState() =>
      _RegistrationCreatePasswordScreenState();
}

class _RegistrationCreatePasswordScreenState
    extends ConsumerState<RegistrationCreatePasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();
  final AuthRepo _authRepo = AuthRepo();
  bool _isSubmitting = false; // ✅ Prevent multiple calls

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onPasswordChanged(String value) {
    ref.read(registrationProvider.notifier).validatePassword(
      value,
      _confirmPasswordController.text,
    );
  }

  void _onConfirmPasswordChanged(String value) {
    ref.read(registrationProvider.notifier).validateConfirmPassword(
      _passwordController.text,
      value,
    );
  }

  Future<void> _createPassword() async {
    if (_isSubmitting) return; // ✅ Prevent rapid re-taps
    _isSubmitting = true;

    final state = ref.read(registrationProvider);

    if (!state.isPasswordValid || !state.isConfirmPasswordValid) {
      _isSubmitting = false;
      return;
    }

    // Disable button immediately
    ref.read(registrationProvider.notifier).setLoading(true);

    final email = state.email;
    final accessToken = state.accessToken;
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    print("📧 Email: $email");
    print("🔑 Access Token: $accessToken");
    print("🔐 Creating password for user...");

    try {
      // ✅ Call store-password API
      final response = await _authRepo.storePassword(
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        accessToken: accessToken,
      );

      if (response != null) {
        print("📥 Store password response: $response");

        // ✅ Status 1 means success
        if (response['status'] == 1) {
          print("✅ Password created successfully");

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
              Text(response['message'] ?? 'Password created successfully'),
              backgroundColor: Colors.green,
            ),
          );

          // Reset provider & navigate to login
          ref.read(registrationProvider.notifier).reset();
          context.go('/login');
        } else {
          print("❌ Failed to create password - ${response['message']}");
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Failed to create password'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        print("❌ Null response from store-password API");
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create password. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on SocketException {
      print("🌐 No internet connection");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No internet connection"),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      print("❌ Error creating password: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to create password. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      _isSubmitting = false;
      ref.read(registrationProvider.notifier).setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registrationProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F5),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create Password',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create a strong password for your account',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildPasswordField(state),
                    const SizedBox(height: 20),
                    _buildConfirmPasswordField(state),
                    const SizedBox(height: 16),
                    _buildPasswordRequirements(),
                  ],
                ),
              ),
            ),
            _buildContinueButton(state),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 24, left: 10, right: 16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: SvgPicture.asset(
              AppStrings.back_icon,
              height: 28,
              width: 28,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Set Password',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField(RegistrationState state) {
    return TextField(
      controller: _passwordController,
      obscureText: state.obscurePassword,
      onChanged: _onPasswordChanged,
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: 'Enter your password',
        errorText: state.passwordError,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF0060A6), width: 2),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            state.obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: () {
            ref.read(registrationProvider.notifier).togglePasswordVisibility();
          },
        ),
      ),
    );
  }

  Widget _buildConfirmPasswordField(RegistrationState state) {
    return TextField(
      controller: _confirmPasswordController,
      obscureText: state.obscureConfirmPassword,
      onChanged: _onConfirmPasswordChanged,
      decoration: InputDecoration(
        labelText: 'Confirm Password',
        hintText: 'Re-enter your password',
        errorText: state.confirmPasswordError,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF0060A6), width: 2),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            state.obscureConfirmPassword
                ? Icons.visibility_off
                : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: () {
            ref
                .read(registrationProvider.notifier)
                .toggleConfirmPasswordVisibility();
          },
        ),
      ),
    );
  }

  Widget _buildPasswordRequirements() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password Requirements:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade900,
            ),
          ),
          const SizedBox(height: 8),
          _buildRequirementItem('At least 8 characters'),
          _buildRequirementItem('Both passwords must match'),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: Colors.blue.shade700,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton(RegistrationState state) {
    final isValid = state.isPasswordValid && state.isConfirmPasswordValid;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: (isValid && !state.isLoading) ? _createPassword : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: isValid ? const Color(0xFF0060A6) : Colors.grey,
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
            'Continue',
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
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:email_validator/email_validator.dart';
import 'package:jhaveri_jsl_app/constants/strings.dart';
import 'package:jhaveri_jsl_app/features/auth/data/repo/auth_repo.dart';
import 'package:jhaveri_jsl_app/providers/registration_provider.dart';

class EmailLoginScreen extends ConsumerStatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  ConsumerState<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends ConsumerState<EmailLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final ValueNotifier<bool> _isValidEmail = ValueNotifier(false);
  final ValueNotifier<String?> _emailError = ValueNotifier(null);
  final ValueNotifier<bool> _isLoading = ValueNotifier(false);
  final AuthRepo _authRepo = AuthRepo();

  bool _validateEmail(String email) => EmailValidator.validate(email.trim());

  void _onEmailChanged(String value) {
    if (value.isEmpty) {
      _emailError.value = "Email is required";
      _isValidEmail.value = false;
    } else if (!_validateEmail(value)) {
      _emailError.value = "Enter a valid email";
      _isValidEmail.value = false;
    } else {
      _emailError.value = null;
      _isValidEmail.value = true;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _isValidEmail.dispose();
    _emailError.dispose();
    _isLoading.dispose();
    super.dispose();
  }

  Future<void> _onContinue() async {
    final email = _emailController.text.trim();

    // Validate email before proceeding
    if (email.isEmpty) {
      _emailError.value = "Email is required";
      _isValidEmail.value = false;
      return;
    }

    if (!_validateEmail(email)) {
      _emailError.value = "Enter a valid email";
      _isValidEmail.value = false;
      return;
    }

    _isLoading.value = true;

    try {
      print("🔍 Checking user existence for: $email");

      // Call check-user API
      final checkUserResponse = await _authRepo.checkUser(email);

      if (checkUserResponse == null) {
        _showErrorSnackBar("Network error. Please try again.");
        return;
      }

      print("📥 Check user response: $checkUserResponse");

      // ✅ Check if user exists based on API response
      // The API should return a field indicating user existence
      final message =
          (checkUserResponse['message'] as String? ?? '').toLowerCase();
      final userExistsFallback = checkUserResponse['status'] == 1 &&
          message.contains('exists') &&
          !message.contains('not');
      final userExists = (checkUserResponse['user_exists'] as bool?) ??
          (checkUserResponse['data']?['user_exists'] as bool?) ??
          userExistsFallback;

      print("🔍 User exists: $userExists");
      print("📋 Full response: $checkUserResponse");

      if (userExists == true) {
        print("✅ User exists, navigating to password screen");
        if (!mounted) return;
        context.push('/password_login', extra: {'email': email});
      } else {
        print("❌ User doesn't exist, showing registration dialog");
        if (!mounted) return;
        _showRegistrationDialog(email);
      }
    } on SocketException {
      print("🌐 No internet connection");
      _showErrorSnackBar("No internet connection");
    } catch (e) {
      print("❌ Error checking user: $e");
      _showErrorSnackBar("Something went wrong. Please try again.");
    } finally {
      _isLoading.value = false;
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showRegistrationDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => WillPopScope(
        // ✅ Disable back button on dialog
        onWillPop: () async => false,
        child: ValueListenableBuilder<bool>(
          valueListenable: _isLoading,
          builder: (context, isLoading, child) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: const Text(
                'User Not Registered',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
              ),
              content: const Text(
                'Would you like to register a new user?',
                style: TextStyle(fontSize: 16),
              ),
              actions: [
                TextButton(
                  // ✅ Disable Cancel button when loading
                  onPressed: isLoading ? null : () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: isLoading ? Colors.grey : Colors.grey.shade700,
                      fontSize: 16,
                    ),
                  ),
                ),
                ElevatedButton(
                  // ✅ Disable OK button when loading
                  onPressed: isLoading ? null : () async {
                    Navigator.of(dialogContext).pop();
                    await _initiateRegistration(email);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLoading ? Colors.grey : const Color(0xFF0060A6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'OK',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _initiateRegistration(String email) async {
    _isLoading.value = true;

    try {
      print("📧 Sending OTP to: $email");

      // Call email-otp API for registration
      final success = await _authRepo.sendEmailOtp(email);

      if (success) {
        print("✅ OTP sent successfully");

        // Save email in registration provider
        ref.read(registrationProvider.notifier).setEmail(email);

        if (!mounted) return;

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("OTP sent successfully!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate to OTP verification screen
        context.push('/registration-otp');
      } else {
        print("❌ Failed to send OTP");
        _showErrorSnackBar("Failed to send OTP. Please try again.");
      }
    } on SocketException {
      print("🌐 No internet connection");
      _showErrorSnackBar("No internet connection");
    } catch (e) {
      print("❌ Error sending OTP: $e");
      _showErrorSnackBar("Failed to send OTP. Please try again.");
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isLoading,
      builder: (context, isLoading, child) {
        return WillPopScope(
          // ✅ Disable back button when loading
          onWillPop: () async => !isLoading,
          child: Scaffold(
            backgroundColor: const Color(0xFFF1F3F5),
            body: SafeArea(
              child: Column(
                children: [
                  _buildAppBar(isLoading),
                  const SizedBox(height: 36),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildEmailInput(),
                  ),
                  const Spacer(),
                  _buildContinueButton(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(bool isLoading) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, left: 10, right: 16),
      child: Row(
        children: [
          IconButton(
            // ✅ Disable back button when loading
            onPressed: isLoading ? null : () => context.go('/login'),
            icon: SvgPicture.asset(
              AppStrings.back_icon,
              height: 28,
              width: 28,
              color: isLoading ? Colors.grey : Colors.black,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            AppStrings.email_login_title,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailInput() {
    return ValueListenableBuilder<String?>(
      valueListenable: _emailError,
      builder: (_, emailErr, __) {
        return TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          onChanged: _onEmailChanged,
          decoration: InputDecoration(
            hintText: AppStrings.email_lbl,
            errorText: emailErr,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF0060A6), width: 2),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContinueButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ValueListenableBuilder<bool>(
          valueListenable: _isValidEmail,
          builder: (_, valid, __) {
            return ValueListenableBuilder<bool>(
              valueListenable: _isLoading,
              builder: (_, loading, __) {
                return ElevatedButton(
                  onPressed: (valid && !loading) ? _onContinue : null,
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
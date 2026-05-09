import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jhaveri_jsl_app/constants/strings.dart';
import '../../../../../providers/forgot_password_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final ValueNotifier<bool> _isValidEmail = ValueNotifier(false);
  final ValueNotifier<String?> _emailError = ValueNotifier(null);

  @override
  void dispose() {
    _emailController.dispose();
    _isValidEmail.dispose();
    _emailError.dispose();
    super.dispose();
  }

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

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !_validateEmail(email)) {
      _emailError.value = "Please enter a valid email address";
      return;
    }

    final success = await ref.read(forgotPasswordProvider.notifier).sendOtp(email);

    if (success) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP sent successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to OTP verification screen
      context.push('/forgot-password-otp', extra: {'email': email});
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send OTP. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF1F3F5),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            const SizedBox(height: 36),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildEmailContent(),
              ),
            ),
            _buildContinueButton(),
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
            "Forgot Password",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 10),
          child: Text(
            "Enter your email address",
            style: TextStyle(fontSize: 18, color: Colors.black54),
          ),
        ),
        const SizedBox(height: 12),
        ValueListenableBuilder<String?>(
          valueListenable: _emailError,
          builder: (_, emailErr, __) {
            return TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              onChanged: _onEmailChanged,
              decoration: InputDecoration(
                hintText: "Enter your email",
                errorText: emailErr,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildContinueButton() {
    final isLoading = ref.watch(forgotPasswordProvider.select((state) => state.isLoading));

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ValueListenableBuilder<bool>(
          valueListenable: _isValidEmail,
          builder: (_, canContinue, __) {
            return ElevatedButton(
              onPressed: (canContinue && !isLoading) ? _sendOtp : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canContinue ? const Color(0xFF0060A6) : Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isLoading
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
        ),
      ),
    );
  }
}
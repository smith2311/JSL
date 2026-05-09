import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:jhaveri_jsl_app/constants/strings.dart';
import 'package:jhaveri_jsl_app/features/auth/data/repo/auth_repo.dart';
import 'package:jhaveri_jsl_app/providers/registration_provider.dart';
import '../../../../widgets/custom_otp_field.dart';

class RegistrationOtpScreen extends ConsumerStatefulWidget {
  const RegistrationOtpScreen({super.key});

  @override
  ConsumerState<RegistrationOtpScreen> createState() =>
      _RegistrationOtpScreenState();
}

class _RegistrationOtpScreenState
    extends ConsumerState<RegistrationOtpScreen> {
  final AuthRepo _authRepo = AuthRepo();
  Timer? _timer;
  String _otpValue = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startCountdown());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    ref.read(registrationProvider.notifier).resetCountdown();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final countdown = ref.read(registrationProvider).countdown;
      if (countdown > 0) {
        ref.read(registrationProvider.notifier).decrementCountdown();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _resendOtp() async {
    final email = ref.read(registrationProvider).email;
    try {
      print("📧 Resending OTP to: $email");
      final success = await _authRepo.sendEmailOtp(email);

      if (success) {
        _startCountdown();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("OTP resent successfully"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to resend OTP"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("❌ Error resending OTP: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to resend OTP"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpValue.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter complete OTP")),
      );
      return;
    }

    final email = ref.read(registrationProvider).email;
    ref.read(registrationProvider.notifier).setLoading(true);

    try {
      print("🔐 Verifying OTP for: $email | OTP: $_otpValue");

      // ✅ Call API with email and OTP
      final data = await _authRepo.verifyEmailOtp(email, _otpValue);

      if (data != null && data['is_otp_verified'] == true) {
        final accessToken = data['access_token'] ?? '';

        print("✅ OTP verified successfully");
        print("🔑 Access Token: $accessToken");

        // ✅ Save verification status and access token
        final notifier = ref.read(registrationProvider.notifier);
        notifier.setAccessToken(accessToken);
        notifier.setEmailVerified(true);

        if (!mounted) return;

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("OTP verified successfully!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // ✅ Navigate to password creation screen
        context.push('/registration-create-password');
      } else {
        print("❌ Invalid OTP or verification failed");
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Invalid OTP. Please try again."),
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
      print("❌ Error verifying OTP: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Verification failed. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      ref.read(registrationProvider.notifier).setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final registrationState = ref.watch(registrationProvider);
    final countdown = registrationState.countdown;
    final isLoading = registrationState.isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F5),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAppBar(),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter OTP',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We sent a verification code to ${registrationState.email}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),
                  CustomOtpField(
                    length: 6,
                    onChanged: (value) => setState(() => _otpValue = value),
                    onCompleted: (value) => setState(() => _otpValue = value),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: countdown > 0
                        ? Text(
                      'Resend OTP in ${countdown}s',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    )
                        : TextButton(
                      onPressed: _resendOtp,
                      child: const Text(
                        'Resend OTP',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0060A6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            _buildContinueButton(isLoading),
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
            'Verify Email',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton(bool isLoading) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: (_otpValue.length == 6 && !isLoading) ? _verifyOtp : null,
          style: ElevatedButton.styleFrom(
            backgroundColor:
            _otpValue.length == 6 ? const Color(0xFF0060A6) : Colors.grey,
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
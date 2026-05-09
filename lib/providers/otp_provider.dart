import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/env.dart';
import '../core/token_helper.dart';

class RedemptionOtpState {
  final String otp;
  final int secondsLeft;
  final bool canResend;
  final bool isLoading;
  final bool isVerified;
  final String? errorMessage;
  final String? email;
  final String? mobile;
  final bool otpSent;
  final String? verifiedAccessToken;

  const RedemptionOtpState({
    this.otp = '',
    this.secondsLeft = 30,
    this.canResend = false,
    this.isLoading = false,
    this.isVerified = false,
    this.errorMessage,
    this.email,
    this.mobile,
    this.otpSent = false,
    this.verifiedAccessToken,
  });

  RedemptionOtpState copyWith({
    String? otp,
    int? secondsLeft,
    bool? canResend,
    bool? isLoading,
    bool? isVerified,
    String? errorMessage,
    String? email,
    String? mobile,
    bool? otpSent,
    String? verifiedAccessToken,
  }) {
    return RedemptionOtpState(
      otp: otp ?? this.otp,
      secondsLeft: secondsLeft ?? this.secondsLeft,
      canResend: canResend ?? this.canResend,
      isLoading: isLoading ?? this.isLoading,
      isVerified: isVerified ?? this.isVerified,
      errorMessage: errorMessage,
      email: email ?? this.email,
      mobile: mobile ?? this.mobile,
      otpSent: otpSent ?? this.otpSent,
      verifiedAccessToken: verifiedAccessToken ?? this.verifiedAccessToken,
    );
  }

  String getOtpSentMessage() {
    final bool hasEmail = email != null && email!.isNotEmpty;
    final bool hasMobile = mobile != null && mobile!.isNotEmpty;

    if (hasEmail && hasMobile) {
      final maskedMobile = _maskMobile(mobile!);
      final maskedEmail = _maskEmail(email!);
      return 'We have sent a 6-Digit OTP on your mobile number $maskedMobile & Email ID $maskedEmail';
    } else if (hasMobile) {
      final maskedMobile = _maskMobile(mobile!);
      return 'We have sent a 6-Digit OTP on your mobile number $maskedMobile';
    } else if (hasEmail) {
      final maskedEmail = _maskEmail(email!);
      return 'We have sent a 6-Digit OTP on your Email ID $maskedEmail';
    }
    return 'OTP sent successfully';
  }

  String _maskMobile(String mobile) {
    if (mobile.length >= 4) {
      return '+91 ******${mobile.substring(mobile.length - 4)}';
    }
    return mobile;
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length == 2 && parts[0].length >= 3) {
      return '***${parts[0].substring(parts[0].length - 3)}@${parts[1]}';
    }
    return email;
  }
}

class RedemptionOtpNotifier extends StateNotifier<RedemptionOtpState> {
  Timer? _timer;

  RedemptionOtpNotifier() : super(const RedemptionOtpState());

  void _startTimer() {
    _timer?.cancel();
    state = state.copyWith(secondsLeft: 60, canResend: false);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.secondsLeft <= 1) {
        timer.cancel();
        state = state.copyWith(secondsLeft: 0, canResend: true);
      } else {
        state = state.copyWith(secondsLeft: state.secondsLeft - 1);
      }
    });
  }

  void updateOtp(String otp) {
    print('📝 OTP updated: ${otp.substring(0, min(2, otp.length))}****');
    state = state.copyWith(otp: otp);
  }

  Future<void> sendOtp({required int clientId}) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final token = await TokenHelper.getValidToken();
      if (token == null) throw Exception("No valid token");

      print('🚀 Sending OTP...');
      print('Client ID: $clientId');

      final response = await http.post(
        Uri.parse('${EnvConfig.apiBaseUrl}/portfolio/verification/send-otp'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"client_id": clientId}),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      final json = jsonDecode(response.body);
      if (response.statusCode == 200 && json['status'] == 1) {
        final data = json['data'];
        final email = data['email'];
        final mobile = data['mobile'];

        state = state.copyWith(
          isLoading: false,
          otpSent: true,
          email: email,
          mobile: mobile,
        );
        _startTimer();
        print('✅ OTP sent successfully');
      } else {
        throw Exception(json['message'] ?? 'Failed to send OTP');
      }
    } catch (e) {
      print('❌ Exception: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> resendOtp({required int clientId}) async {
    await sendOtp(clientId: clientId);
  }

  Future<void> verifyOtp() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final token = await TokenHelper.getValidToken();
      if (token == null) throw Exception("No valid token");

      print('🚀 Verifying OTP...');
      print('OTP: ${state.otp.substring(0, min(2, state.otp.length))}****');

      final response = await http.post(
        Uri.parse('${EnvConfig.apiBaseUrl}/portfolio/verification/verify-otp'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "email": state.email ?? "",
          "mobile": state.mobile ?? "",
          "otp": state.otp,
        }),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      final json = jsonDecode(response.body);
      if (response.statusCode == 200 && json['status'] == 1) {
        final verifiedToken = json['data']?['access_token'] as String?;

        print('✅ OTP verified successfully');
        print('🔑 Verified token received: ${verifiedToken != null ? "YES" : "NO"}');
        print('📝 Original OTP preserved: ${state.otp.substring(0, min(2, state.otp.length))}****');

        // ✅ CRITICAL: Keep the original OTP in state
        // The verified token is stored but NOT used for SWP API calls
        state = state.copyWith(
          isLoading: false,
          isVerified: true,
          verifiedAccessToken: verifiedToken,
          // DO NOT clear the OTP - we need it for the SWP API call
        );
      } else {
        throw Exception(json['message'] ?? 'Invalid OTP');
      }
    } catch (e) {
      print('❌ Exception: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() {
    _timer?.cancel();
    state = const RedemptionOtpState();
    print('🧹 OTP provider reset');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final redemptionOtpProvider = StateNotifierProvider<RedemptionOtpNotifier, RedemptionOtpState>((ref) {
  return RedemptionOtpNotifier();
});
class ForgotPasswordState {
  final String otpValue;
  final String accessToken;
  final bool showPasswordScreen;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final String? passwordError;
  final String? confirmPasswordError;
  final bool isPasswordValid;
  final bool isConfirmPasswordValid;
  final bool isLoading;
  final int countdown;

  ForgotPasswordState({
    this.otpValue = '',
    this.accessToken = '',
    this.showPasswordScreen = false,
    this.obscurePassword = true,
    this.obscureConfirmPassword = true,
    this.passwordError,
    this.confirmPasswordError,
    this.isPasswordValid = false,
    this.isConfirmPasswordValid = false,
    this.isLoading = false,
    this.countdown = 30,
  });

  ForgotPasswordState copyWith({
    String? otpValue,
    String? accessToken,
    bool? showPasswordScreen,
    bool? obscurePassword,
    bool? obscureConfirmPassword,
    String? passwordError,
    String? confirmPasswordError,
    bool? isPasswordValid,
    bool? isConfirmPasswordValid,
    bool? isLoading,
    int? countdown,
  }) {
    return ForgotPasswordState(
      otpValue: otpValue ?? this.otpValue,
      accessToken: accessToken ?? this.accessToken,
      showPasswordScreen: showPasswordScreen ?? this.showPasswordScreen,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      obscureConfirmPassword:
      obscureConfirmPassword ?? this.obscureConfirmPassword,
      passwordError: passwordError,
      confirmPasswordError: confirmPasswordError,
      isPasswordValid: isPasswordValid ?? this.isPasswordValid,
      isConfirmPasswordValid:
      isConfirmPasswordValid ?? this.isConfirmPasswordValid,
      isLoading: isLoading ?? this.isLoading,
      countdown: countdown ?? this.countdown,
    );
  }
}


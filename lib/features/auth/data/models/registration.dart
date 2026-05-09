class RegistrationState {
  final String email;
  final String otp;
  final String accessToken;
  final bool isLoading;
  final String? errorMessage;
  final bool showPasswordScreen;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final String? passwordError;
  final String? confirmPasswordError;
  final bool isPasswordValid;
  final bool isConfirmPasswordValid;
  final int countdown;

  // 🆕 Add this field
  final bool isEmailVerified;

  RegistrationState({
    this.email = '',
    this.otp = '',
    this.accessToken = '',
    this.isLoading = false,
    this.errorMessage,
    this.showPasswordScreen = false,
    this.obscurePassword = true,
    this.obscureConfirmPassword = true,
    this.passwordError,
    this.confirmPasswordError,
    this.isPasswordValid = false,
    this.isConfirmPasswordValid = false,
    this.countdown = 30,
    this.isEmailVerified = false, // 🆕 Default false
  });

  RegistrationState copyWith({
    String? email,
    String? otp,
    String? accessToken,
    bool? isLoading,
    String? errorMessage,
    bool? showPasswordScreen,
    bool? obscurePassword,
    bool? obscureConfirmPassword,
    String? passwordError,
    String? confirmPasswordError,
    bool? isPasswordValid,
    bool? isConfirmPasswordValid,
    int? countdown,
    bool? isEmailVerified, // 🆕 Add to copyWith
  }) {
    return RegistrationState(
      email: email ?? this.email,
      otp: otp ?? this.otp,
      accessToken: accessToken ?? this.accessToken,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      showPasswordScreen: showPasswordScreen ?? this.showPasswordScreen,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      obscureConfirmPassword:
      obscureConfirmPassword ?? this.obscureConfirmPassword,
      passwordError: passwordError ?? this.passwordError,
      confirmPasswordError:
      confirmPasswordError ?? this.confirmPasswordError,
      isPasswordValid: isPasswordValid ?? this.isPasswordValid,
      isConfirmPasswordValid:
      isConfirmPasswordValid ?? this.isConfirmPasswordValid,
      countdown: countdown ?? this.countdown,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified, // 🆕 Add here
    );
  }
}
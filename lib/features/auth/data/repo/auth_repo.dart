import 'package:jhaveri_jsl_app/core/network/http_client.dart';
import 'package:jhaveri_jsl_app/core/secure_store.dart';

class AuthRepo {
  final HttpClient _client = HttpClient();

  /// ✅ Check if user exists
  Future<Map<String, dynamic>?> checkUser(String email) async {
    try {
      final response = await _client.post("/client/check-user", body: {
        "email": email,
      });

      print("📤 Check User Response: $response");
      return response;
    } catch (e) {
      print("❌ Check User exception: $e");
      return null;
    }
  }

  /// ✅ Send Email OTP
  /// Endpoint: /client/email-otp
  /// Body: { "email": "example@email.com" }
  Future<bool> sendEmailOtp(String email) async {
    try {
      final response = await _client.post("/client/email-otp", body: {
        "email": email,
      });

      print("📤 Send Email OTP Response: $response");

      if (response['status'] == 1) {
        print("✅ OTP sent successfully");
        return true;
      } else {
        print("❌ OTP send failed: ${response['message']}");
        return false;
      }
    } catch (e) {
      print("❌ Send Email OTP exception: $e");
      return false;
    }
  }

  /// ✅ Verify Email OTP
  /// Endpoint: /client/verify-email-otp
  /// Body: { "email": "...", "otp": "123456" }
  Future<Map<String, dynamic>?> verifyEmailOtp(
      String email, String otp) async {
    try {
      final response = await _client.post("/client/verify-email-otp", body: {
        "email": email,
        "otp": otp,
      });

      print("📤 Verify Email OTP Response: $response");

      if (response['status'] == 1) {
        print("✅ OTP verified successfully");
        return response['data'];
      } else {
        print("❌ OTP verification failed: ${response['message']}");
        return null;
      }
    } catch (e) {
      print("❌ Verify Email OTP exception: $e");
      return null;
    }
  }

  /// ✅ Store Password for new user
  /// Endpoint: /client/store-password
  /// Body:
  /// {
  ///   "password": "...",
  ///   "confirm_password": "...",
  ///   "email": "...",
  ///   "access_token": "..."
  /// }
  Future<Map<String, dynamic>?> storePassword({
    required String email,
    required String password,
    required String confirmPassword,
    required String accessToken,
  }) async {
    try {
      print("📧 Email: $email");
      print("🔑 Access Token: $accessToken");
      print("🔐 Creating password for user...");

      final response = await _client.post("/client/store-password", body: {
        "email": email,
        "password": password,
        "confirm_password": confirmPassword,
        "access_token": accessToken,
      });

      print("📤 Store Password Response: $response");

      if (response['status'] == 1) {
        print("✅ Password stored successfully");
        return response; // ✅ Return success response
      } else {
        print("❌ Failed to store password - Message: ${response['message']}");
        return null; // ❌ Explicitly mark as failure
      }
    } catch (e) {
      print("❌ Store Password exception: $e");
      return null;
    }
  }

  /// ✅ Login API
  /// Endpoint: /client/signin
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await _client.post("/client/signin", body: {
        "email": email,
        "password": password,
      });

      print("📤 Login Response: $response");

      if (response['status'] == 1 && response['data'] != null) {
        final data = response['data'];
        final accessToken = data['token'];
        final expiry = data['expiration_time'];

        if (accessToken != null && expiry != null) {
          await SecureStore.saveToken(
            accessToken: accessToken,
            expiry: expiry.toString(),
          );
          print("✅ Login successful, token saved.");
        } else {
          print("⚠️ Missing token or expiry in login response.");
        }

        return data;
      } else {
        print("❌ Login failed: ${response['message']}");
        return null;
      }
    } catch (e) {
      print("❌ Login exception: $e");
      return null;
    }
  }

  /// ✅ Get valid token from SecureStore
  Future<String?> getValidToken() async {
    final tokenData = await SecureStore.getTokenData();
    if (tokenData == null) return null;

    final expired = await SecureStore.isTokenExpired();
    if (expired) {
      await SecureStore.clearTokens();
      return null;
    }

    return tokenData.accessToken;
  }
}
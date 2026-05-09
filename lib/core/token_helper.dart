import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jhaveri_jsl_app/core/config/env.dart';
import 'secure_store.dart';

class TokenHelper {
  /// Returns a valid access token, refreshes automatically if expired
  static Future<String?> getValidToken() async {
    if (await SecureStore.isTokenExpired()) {
      final refreshToken = await SecureStore.getRefreshToken();
      if (refreshToken == null) {
        await SecureStore.clearTokens();
        print("No refresh token found. User must login again.");
        return null;
      }

      final baseUrl = EnvConfig.apiBaseUrl;
      final url = Uri.parse('$baseUrl/auth/refresh-token');

      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refresh_token': refreshToken}),
        );

        if (response.statusCode == 200) {
          final jsonRes = jsonDecode(response.body);
          if (jsonRes['status'] == 1 && jsonRes['data'] != null) {
            final data = jsonRes['data'];
            final newAccess = data['access_token'];
            final newRefresh = data['refresh_token'];
            final expiry = data['expiration_time'];

            if (newAccess != null && newRefresh != null && expiry != null) {
              await SecureStore.saveToken(
                accessToken: newAccess,
                expiry: expiry.toString(),
              );
              print("✅ Access token refreshed successfully.");
              return newAccess;
            }
          }
        }
      } catch (e) {
        print("Error refreshing token: $e");
      }

      await SecureStore.clearTokens();
      return null;
    }

    return await SecureStore.getToken();
  }
}
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import './secure_store.dart';
import '../core/config/env.dart';
import '../providers/user_provider.dart'; // ✅ Add this import

class AuthHelper {
  static Future<bool> isAuthenticated() async {
    try {
      final token = await SecureStore.getToken();
      if (token == null) return false;

      final isExpired = await SecureStore.isTokenExpired();
      return !isExpired;
    } catch (e) {
      debugPrint("❌ Error checking authentication: $e");
      return false;
    }
  }

  /// 🚀 LOGOUT API CALL + CLEAR TOKENS + CLEAR USER DATA
  static Future<void> logout(BuildContext context, WidgetRef ref) async {
    try {
      final token = await SecureStore.getToken();
      final baseUrl = EnvConfig.apiBaseUrl;
      final logoutUrl = Uri.parse('$baseUrl/logout');

      if (token != null) {
        try {
          final response = await http.post(
            logoutUrl,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          );

          if (response.statusCode == 200) {
            debugPrint("✅ Logout API successful");
          } else {
            debugPrint(
                "⚠️ Logout API failed [${response.statusCode}]: ${response.body}");
          }
        } catch (apiError) {
          debugPrint("❌ Network error during logout: $apiError");
        }
      }

      // Clear local auth data
      await SecureStore.clearTokens();

      // ✅ Clear user data from provider (which also clears SharedPreferences)
      await ref.read(userProvider.notifier).logout();

      debugPrint("✅ Local logout completed");

      if (context.mounted) {
        context.go('/login');
      }
    } catch (e) {
      debugPrint("❌ Error during logout: $e");
    }
  }

  static Future<bool> hasCompletedOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool("onboarding_complete") ?? false;
    } catch (e) {
      debugPrint("❌ Error checking onboarding status: $e");
      return false;
    }
  }

  static Future<void> completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool("onboarding_complete", true);
      debugPrint("✅ Onboarding_Screen marked as complete");
    } catch (e) {
      debugPrint("❌ Error completing onboarding: $e");
    }
  }

  static Future<void> resetOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool("onboarding_complete", false);
      debugPrint("✅ Onboarding_Screen reset");
    } catch (e) {
      debugPrint("❌ Error resetting onboarding: $e");
    }
  }
}
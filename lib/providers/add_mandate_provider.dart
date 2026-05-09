import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../core/config/env.dart';
import '../core/token_helper.dart';

class AddMandateNotifier extends StateNotifier<AsyncValue<void>> {
  AddMandateNotifier() : super(const AsyncValue.data(null));

  static final String baseUrl = EnvConfig.apiBaseUrl;

  Future<String?> addMandate({
    required BuildContext context,
    required String bseClientId,
    required String accountNo,
    required String accountType,
    required String ifscCode,
    required String registrationType,
    required double mandateAmount,
    required String mandatePeriodFrom,
    required String mandatePeriodTo,
  }) async {
    state = const AsyncValue.loading();

    try {
      final token = await TokenHelper.getValidToken();
      if (token == null) {
        throw Exception('Authentication required.');
      }

      // Show loading dialog
      if (context.mounted) {
        _showLoader(context);
      }

      final uri = Uri.parse('$baseUrl/profile/mandate/add');
      final body = {
        "bse_client_id": bseClientId,
        "account_no": accountNo,
        "account_type": accountType,
        "ifsc_code": ifscCode,
        "registration_type": registrationType,
        "mandate_amount": mandateAmount,
        "mandate_period_from": mandatePeriodFrom,
        "mandate_period_to": mandatePeriodTo,
      };

      debugPrint('[AddMandateProvider] 📤 Request body: ${jsonEncode(body)}');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      // Close loading dialog
      if (context.mounted) {
        _closeLoader(context);
      }

      debugPrint('[AddMandateProvider] 📥 Response status: ${response.statusCode}');
      debugPrint('[AddMandateProvider] 📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 1) {
          final link = data['link'] as String?;
          final message = data['message'] as String? ?? 'Mandate registered successfully';

          if (context.mounted) {
            _showSnackBar(context, '✅ $message', isError: false);
          }

          // Open link based on registration type
          if (link != null && link.isNotEmpty) {
            debugPrint('[AddMandateProvider] 🌐 Opening URL: $link');
            debugPrint('[AddMandateProvider] 📋 Registration Type: $registrationType');

            try {
              if (registrationType == 'N') {
                // eNach - Open in Chrome browser
                await _openInBrowser(link, context);
              } else {
                // UPI - Open in-app (default app handling)
                await _openInApp(link, context);
              }
            } catch (urlError) {
              debugPrint('[AddMandateProvider] ⚠️ URL launch failed: $urlError');
              if (context.mounted) {
                _showUrlFailureDialog(context, link, registrationType);
              }
            }
          }

          state = const AsyncValue.data(null);
          return link;
        } else {
          final errorMsg = data['message'] ?? 'Failed to add mandate';
          if (context.mounted) {
            _showSnackBar(context, '❌ $errorMsg', isError: true);
          }
          state = AsyncValue.error(errorMsg, StackTrace.current);
          return null;
        }
      } else {
        final msg = 'Server error: ${response.statusCode}';
        if (context.mounted) {
          _showSnackBar(context, '❌ $msg', isError: true);
        }
        state = AsyncValue.error(msg, StackTrace.current);
        return null;
      }
    } catch (e, st) {
      if (context.mounted) {
        _closeLoader(context);
        _showSnackBar(context, '❌ Error: $e', isError: true);
      }
      debugPrint('[AddMandateProvider] ❌ Error: $e');
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Open URL in browser with fallback options
  Future<void> _openInBrowser(String url, BuildContext context) async {
    try {
      final uri = Uri.parse(url);
      debugPrint('[AddMandateProvider] 🔍 Attempting to launch: $url');

      // First, try to open in external application (default browser or chooser)
      // This will:
      // 1. Open in default browser if set
      // 2. Show app chooser if no default is set
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (launched) {
        debugPrint('[AddMandateProvider] ✅ Successfully opened URL');
      } else {
        debugPrint('[AddMandateProvider] ⚠️ launchUrl returned false, trying fallback');

        // Fallback: Try with externalNonBrowserApplication
        // This forces opening in browser apps only
        final fallbackLaunched = await launchUrl(
          uri,
          mode: LaunchMode.externalNonBrowserApplication,
        );

        if (!fallbackLaunched) {
          throw Exception('Could not launch URL - no browser available');
        }
      }
    } catch (e) {
      debugPrint('[AddMandateProvider] ❌ Error opening browser: $e');
      rethrow;
    }
  }

  /// Open URL for UPI with app chooser
  Future<void> _openInApp(String url, BuildContext context) async {
    try {
      final uri = Uri.parse(url);
      debugPrint('[AddMandateProvider] 🔍 Attempting to launch UPI: $url');

      // For UPI, externalApplication will show chooser with all UPI apps
      // User can select their preferred app (GPay, PhonePe, Paytm, etc.)
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (launched) {
        debugPrint('[AddMandateProvider] ✅ Successfully opened UPI app chooser');
      } else {
        debugPrint('[AddMandateProvider] ❌ Could not open UPI app');
        throw Exception('Could not launch UPI app - no UPI apps found');
      }
    } catch (e) {
      debugPrint('[AddMandateProvider] ❌ Error opening UPI: $e');
      rethrow;
    }
  }

  /// Show dialog when URL launch fails with copy option
  void _showUrlFailureDialog(BuildContext context, String url, String type) {
    final isEnach = type == 'N';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEnach ? '⚠️ Browser Not Available' : '⚠️ UPI App Not Found'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEnach
                  ? 'Unable to open browser automatically. Please copy the link below and open it in your browser.'
                  : 'No UPI apps found. Please install a UPI app (GPay, PhonePe, Paytm) or copy the link.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                url,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: url));
              Navigator.pop(ctx);
              if (context.mounted) {
                _showSnackBar(context, '✅ Link copied to clipboard', isError: false);
              }
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copy Link'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0060A6),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Show loading dialog
  void _showLoader(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF0060A6)),
        ),
      ),
    );
  }

  /// Close loading dialog safely
  void _closeLoader(BuildContext context) {
    try {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('[AddMandateProvider] ⚠️ Error closing loader: $e');
    }
  }

  /// Show snackbar message
  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

/// Provider instance
final addMandateProvider = StateNotifierProvider<AddMandateNotifier, AsyncValue<void>>((ref) {
  return AddMandateNotifier();
});
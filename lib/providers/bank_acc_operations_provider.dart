import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../core/config/env.dart';
import '../core/token_helper.dart';
import '../features/auth/data/models/bank_details.dart';

/// Helper – shows loader dialog
void _showLoader(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(
      child: CircularProgressIndicator(color: Color(0xFF0060A6)),
    ),
  );
}

/// Helper – safely close loader
void _closeLoader(BuildContext context) {
  if (Navigator.canPop(context)) Navigator.pop(context);
}

/// Helper – show snackbar
void _showSnackBar(BuildContext context, String message,
    {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

class BankAccountsNotifier extends StateNotifier<AsyncValue<List<BankAccount>>> {
  BankAccountsNotifier() : super(const AsyncValue.loading());

  static final String baseUrl = EnvConfig.apiBaseUrl;

  /// ✅ Fetch Bank Accounts List
  Future<void> fetchBankDetails(String bseClientId) async {
    state = const AsyncValue.loading();
    try {
      final token = await TokenHelper.getValidToken();
      if (token == null) {
        state =
            AsyncValue.error('Authentication required.', StackTrace.current);
        return;
      }

      final uri = Uri.parse('$baseUrl/profile/bank/details');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'bse_client_id': bseClientId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bankDetailsResponse = BankDetailsResponse.fromJson(data);
        state = AsyncValue.data(bankDetailsResponse.data.dataList);
      } else {
        final msg =
            jsonDecode(response.body)['message'] ?? 'Failed to fetch data';
        state = AsyncValue.error(msg, StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error('Error: $e', st);
    }
  }

  /// ✅ Add Bank Account WITHOUT Loader (for external loader handling)
  Future<Map<String, dynamic>> addBankAccountWithoutLoader({
    required String bseClientId,
    required String ifscCode,
    required String accountNo,
    required String accountType,
    required String accountOwner,
  }) async {
    try {
      final token = await TokenHelper.getValidToken();
      if (token == null) throw Exception('No valid token found.');

      final uri = Uri.parse('$baseUrl/profile/add-bank-details');
      final body = {
        "bse_client_id": bseClientId,
        "ifsc_code": ifscCode,
        "account_no": accountNo,
        "account_type": accountType,
        "account_owner": accountOwner,
      };

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Check the actual status field in response
        return {
          'status': data['status'] ?? 0,
          'message': data['message'] ?? 'Unknown response',
        };
      } else {
        final msg = jsonDecode(response.body)['message'] ?? 'Failed to add account';
        return {
          'status': 0,
          'message': msg,
        };
      }
    } catch (e) {
      return {
        'status': 0,
        'message': e.toString(),
      };
    }
  }

  /// ✅ Add Bank Account with Loader + Refresh
  Future<void> addBankAccount({
    required BuildContext context,
    required String bseClientId,
    required String ifscCode,
    required String accountNo,
    required String accountType,
    required String accountOwner,
  }) async {
    try {
      final token = await TokenHelper.getValidToken();
      if (token == null) throw Exception('No valid token found.');

      _showLoader(context);

      final uri = Uri.parse('$baseUrl/profile/add-bank-details');
      final body = {
        "bse_client_id": bseClientId,
        "ifsc_code": ifscCode,
        "account_no": accountNo,
        "account_type": accountType,
        "account_owner": accountOwner,
      };

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      _closeLoader(context);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // ✅ Check the actual status field
        if (data['status'] == 1) {
          await fetchBankDetails(bseClientId);
          _showSnackBar(context, '✅ ${data['message'] ?? 'Bank account added successfully'}');
        } else {
          _showSnackBar(context, '❌ ${data['message'] ?? 'Failed to add account'}', isError: true);
        }
      } else {
        final msg =
            jsonDecode(response.body)['message'] ?? 'Failed to add account';
        _showSnackBar(context, '❌ $msg', isError: true);
      }
    } catch (e) {
      _closeLoader(context);
      _showSnackBar(context, '❌ Error adding account: $e', isError: true);
    }
  }

  /// ✅ Delete Bank Account (Simple Loader + Refresh)
  Future<void> deleteBankAccount({
    required BuildContext context,
    required String bseClientId,
    required String ifscCode,
    required String accountNo,
    required String accountType,
    required String accountOwner,
  }) async {
    try {
      final token = await TokenHelper.getValidToken();
      if (token == null) throw Exception('No valid token found.');

      _showLoader(context);

      final uri = Uri.parse('$baseUrl/profile/delete-bank-details');
      final body = {
        "bse_client_id": bseClientId,
        "ifsc_code": ifscCode,
        "account_no": accountNo,
        "account_type": accountType,
        "account_owner": accountOwner,
      };

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      _closeLoader(context);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // ✅ Check the actual status field
        if (data['status'] == 1) {
          await fetchBankDetails(bseClientId);
          _showSnackBar(context, '✅ ${data['message'] ?? 'Bank account deleted successfully'}');
        } else {
          _showSnackBar(context, '❌ ${data['message'] ?? 'Failed to delete account'}', isError: true);
        }
      } else {
        final msg =
            jsonDecode(response.body)['message'] ?? 'Failed to delete account';
        _showSnackBar(context, '❌ $msg', isError: true);
      }
    } catch (e) {
      _closeLoader(context);
      _showSnackBar(context, '❌ Error deleting account: $e', isError: true);
    }
  }

  /// ✅ Delete Bank Account WITHOUT Loader (for when you handle loader externally)
  Future<Map<String, dynamic>> deleteBankAccountWithoutLoader({
    required String bseClientId,
    required String ifscCode,
    required String accountNo,
    required String accountType,
    required String accountOwner,
  }) async {
    try {
      final token = await TokenHelper.getValidToken();
      if (token == null) throw Exception('No valid token found.');

      final uri = Uri.parse('$baseUrl/profile/delete-bank-details');
      final body = {
        "bse_client_id": bseClientId,
        "ifsc_code": ifscCode,
        "account_no": accountNo,
        "account_type": accountType,
        "account_owner": accountOwner,
      };

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': data['status'] ?? 0,
          'message': data['message'] ?? 'Unknown response',
        };
      } else {
        final msg = jsonDecode(response.body)['message'] ?? 'Failed to delete account';
        return {
          'status': 0,
          'message': msg,
        };
      }
    } catch (e) {
      return {
        'status': 0,
        'message': e.toString(),
      };
    }
  }

  /// ✅ Reset Provider State
  void reset() => state = const AsyncValue.loading();
}

/// ✅ Provider with Auto-Fetch on Creation
final bankAccountsProvider = StateNotifierProvider.family<
    BankAccountsNotifier,
    AsyncValue<List<BankAccount>>,
    String>((ref, bseClientId) {
  final notifier = BankAccountsNotifier();
  Future.microtask(() => notifier.fetchBankDetails(bseClientId));
  return notifier;
});
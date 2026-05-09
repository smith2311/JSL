import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../core/config/env.dart';
import '../core/token_helper.dart';
import '../features/auth/data/models/bank_details.dart';

class BankDetailsNotifier extends StateNotifier<AsyncValue<List<BankAccount>>> {
  BankDetailsNotifier() : super(const AsyncValue.loading());
  static final String baseUrl = EnvConfig.apiBaseUrl;

  Future<void> fetchBankDetails(String bseClientId) async {
    print('🔍 fetchBankDetails called with bseClientId: $bseClientId');

    if (bseClientId.isEmpty) {
      print('❌ BSE Client ID is empty');
      state = AsyncValue.error('BSE Client ID is required', StackTrace.current);
      return;
    }

    state = const AsyncValue.loading();

    try {
      // Get valid token using TokenHelper (handles refresh automatically)
      final token = await TokenHelper.getValidToken();

      if (token == null) {
        print('❌ No valid token found. User needs to login.');
        state = AsyncValue.error('Authentication required. Please login again.', StackTrace.current);
        return;
      }

      print('🔑 Auth token: Found (${token.substring(0, 20)}...)');

      final uri = Uri.parse('$baseUrl/profile/bank/details');
      print('📡 API URL: $uri');

      final requestBody = jsonEncode({'bse_client_id': bseClientId});
      print('📤 Request body: $requestBody');

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.post(
        uri,
        headers: headers,
        body: requestBody,
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Decoded data: $data');

        final bankDetailsResponse = BankDetailsResponse.fromJson(data);
        print('✅ Bank accounts count: ${bankDetailsResponse.data.dataList.length}');

        state = AsyncValue.data(bankDetailsResponse.data.dataList);
      } else if (response.statusCode == 403) {
        print('❌ 403 Forbidden - Authentication failed');
        state = AsyncValue.error('Authentication failed. Please login again.', StackTrace.current);
      } else if (response.statusCode == 401) {
        print('❌ 401 Unauthorized - Token expired or invalid');
        state = AsyncValue.error('Session expired. Please login again.', StackTrace.current);
      } else {
        String errorMessage = 'Failed to fetch bank details (Status: ${response.statusCode})';
        try {
          final body = jsonDecode(response.body);
          errorMessage = body['message'] ?? errorMessage;
        } catch (_) {}
        print('❌ Error: $errorMessage');
        state = AsyncValue.error(errorMessage, StackTrace.current);
      }
    } on http.ClientException catch (e) {
      print('❌ Connection error: $e');
      state = AsyncValue.error('Connection error: $e', StackTrace.current);
    } on FormatException catch (e) {
      print('❌ Format error: $e');
      state = AsyncValue.error('Invalid response format: $e', StackTrace.current);
    } catch (e, stackTrace) {
      print('❌ Unexpected error: $e');
      print('Stack trace: $stackTrace');
      state = AsyncValue.error('An unexpected error occurred: $e', stackTrace);
    }
  }

  void reset() {
    state = const AsyncValue.loading();
  }
}

// Use a family provider to create separate instances per bseClientId
final bankDetailsProvider = StateNotifierProvider.family<
    BankDetailsNotifier,
    AsyncValue<List<BankAccount>>,
    String
>(
      (ref, bseClientId) {
    print('🏭 Creating BankDetailsNotifier for bseClientId: $bseClientId');
    final notifier = BankDetailsNotifier();
    // Auto-fetch when provider is created
    Future.microtask(() => notifier.fetchBankDetails(bseClientId));
    return notifier;
  },
);
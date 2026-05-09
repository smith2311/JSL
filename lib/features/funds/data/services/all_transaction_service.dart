import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/env.dart';
import '../../../../core/token_helper.dart';

class AllTransactionsApiService {
  /// Fetch all transactions for a specific fund and folio
  Future<Map<String, dynamic>> fetchAllTransactions({
    required int fundId,
    required String folioNo,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final token = await TokenHelper.getValidToken();
      if (token == null) throw Exception("No valid token");

      print('📋 Fetching All Transactions...');
      print('   Fund ID: $fundId');
      print('   Folio No: $folioNo');
      print('   Page: $page');

      final response = await http.post(
        Uri.parse('${EnvConfig.apiBaseUrl}/portfolio/all-transactions'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "page": page,
          "page_size": pageSize,
          "fund_id": fundId,
          "folio_no": folioNo,
        }),
      );

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 1) {
          print('✅ Transactions fetched successfully');
          print('   Total Records: ${data['data']['total_records']}');
          return data;
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch transactions');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception in fetchAllTransactions: $e');
      rethrow;
    }
  }
}
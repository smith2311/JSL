import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/env.dart';
import '../../../../core/token_helper.dart';
import '../models/switch_fund.dart';

class SwitchFundsRepository {
  Future<SwitchFundsListResponse> fetchSwitchFunds({
    required int fundId,
    int page = 1,
    int pageSize = 10,
    String searchTerm = '',
    String sortOrder = '',
    String sortBy = '',
  }) async {
    final token = await TokenHelper.getValidToken();
    if (token == null) throw Exception("No valid token");

    print('🔍 Fetching switch funds for fundId: $fundId, page: $page');

    final response = await http.post(
      Uri.parse('${EnvConfig.apiBaseUrl}/portfolio/switch/list'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "fund_id": fundId,
        "page": page,
        "page_size": pageSize,
        "search_term": searchTerm,
        "sort_order": sortOrder,
        "sort_by": sortBy,
      }),
    );

    print('📡 Response Status: ${response.statusCode}');
    print('📦 Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 1) {
        return SwitchFundsListResponse.fromJson(data);
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch switch funds');
      }
    } else {
      throw Exception("Failed to fetch switch funds: ${response.statusCode}");
    }
  }
}
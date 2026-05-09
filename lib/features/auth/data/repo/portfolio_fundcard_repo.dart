import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/env.dart';
import '../../../../core/token_helper.dart';
import '../../../funds/data/models/portfolio_fund_card.dart';

class FundRepository {
  Future<Map<String, dynamic>> fetchFundsWithMetadata({
    required int page,
    required int pageSize,
    List<int>? clientIds,
    String searchTerm = '',
    String sortBy = '',
    String sortOrder = '',
    List<String> amcs = const [],
    List<String> fundCategory = const [],
    List<String> subCategory = const [],
  }) async {
    final token = await TokenHelper.getValidToken();
    if (token == null) {
      throw Exception("No valid token");
    }

    final response = await http.post(
      Uri.parse('${EnvConfig.apiBaseUrl}/portfolio/list'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "client_id": clientIds ?? [],
        "page": page,
        "page_size": pageSize,
        "search_term": searchTerm,
        "sort_by": sortBy,
        "sort_order": sortOrder,
        "filter": {
          "amcs": amcs,
          "fund_category": fundCategory,
          "sub_category": subCategory,
        },
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 1) {
        final dataList = data['data']['data_list'] as List;
        final funds = dataList.map((e) => FundModel.fromJson(e)).toList();
        final totalRecords = data['data']['total_records'] ?? 0;

        return {
          'funds': funds,
          'totalRecords': totalRecords,
        };
      } else {
        throw Exception(data['message'] ?? "Failed to fetch funds");
      }
    } else {
      throw Exception("HTTP error: ${response.statusCode}");
    }
  }
}
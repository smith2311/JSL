import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/env.dart';
import '../../../../core/token_helper.dart';
import '../models/portfolio_model.dart';

class OrderRepository {
  Future<List<OrderModel>> fetchOrders({
    int page = 1,
    int pageSize = 10,
    List<int>? clientIds,
    String searchTerm = '',
    String sortBy = '',
    String sortOrder = '',
    List<String> amcs = const [],
    List<String> fundCategory = const [],
    List<String> subCategory = const [],
  }) async {
    final token = await TokenHelper.getValidToken();
    if (token == null) throw Exception("No valid token");

    final uri = Uri.parse('${EnvConfig.apiBaseUrl}/orders/list');

    final response = await http.post(
      uri,
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

    if (response.statusCode != 200) {
      throw Exception("Failed to fetch orders: ${response.statusCode}");
    }

    final responseBody = jsonDecode(response.body);
    final rawList = responseBody['data']['data_list'] as List<dynamic>?;

    if (rawList == null) return [];

    return rawList
        .map<OrderModel>((item) => OrderModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}
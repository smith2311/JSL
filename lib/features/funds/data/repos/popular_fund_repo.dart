import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../../../../core/secure_store.dart';
import '../models/popular_fund.dart';

class PopularFundRepo {
  final String baseUrl;

  PopularFundRepo({required this.baseUrl});

  Future<List<PopularFund>> fetchPopularFunds({
    required int page,
    required int pageSize,
    Set<String>? subCategoryIds,
    Map<String, Set<String>>? filters,
  }) async {
    debugPrint("🚀 [PopularFundRepo] fetchPopularFunds");
    debugPrint("📄 [PopularFundRepo] Page: $page, PageSize: $pageSize");
    debugPrint("🔍 [PopularFundRepo] SubCategory IDs: $subCategoryIds");
    debugPrint("🔍 [PopularFundRepo] Filters: $filters");

    try {
      final token = await SecureStore.getToken();
      if (token == null || token.isEmpty) {
        throw Exception("No auth token found");
      }

      final url = Uri.parse('$baseUrl/funds/popular');

      // Build the filter object properly - convert Sets to Lists of integers/strings
      final Map<String, dynamic> filterPayload = {
        "amcs": _convertToIntList(filters?['Fund House']),
        "fund_category": _convertToIntList(filters?['Fund Category']),
        "sub_category": _convertToIntList(filters?['Sub Category'] ?? subCategoryIds),
        "risk_level": _convertToStringList(filters?['Risk Level']),
        "fund_size": _convertToStringList(filters?['Fund Size']),
      };

      final body = {
        "page": page,
        "page_size": pageSize,
        "search_term": "",
        "sort_order": "",
        "sort_by": "",
        "filter": filterPayload,
      };

      debugPrint("🌐 [PopularFundRepo] API Call: POST $url");
      debugPrint("📤 [PopularFundRepo] Request body: ${jsonEncode(body)}");

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      debugPrint("📨 [PopularFundRepo] Response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        debugPrint("📨 [PopularFundRepo] Response: ${response.body.substring(0, 200)}...");

        final status = decoded['status'];
        if (status == 1 || status == '1') {
          final dataList = (decoded['data']?['data_list'] as List<dynamic>?) ?? [];
          debugPrint("✅ [PopularFundRepo] Fetched ${dataList.length} funds");

          return dataList.map((json) {
            try {
              return PopularFund.fromJson(json as Map<String, dynamic>);
            } catch (e) {
              debugPrint("⚠️ [PopularFundRepo] Error parsing fund: $e");
              debugPrint("📦 [PopularFundRepo] Problematic JSON: $json");
              rethrow;
            }
          }).toList();
        } else {
          final errorMsg = decoded['message'] ?? 'Unknown error';
          debugPrint("❌ [PopularFundRepo] API error: $errorMsg");
          throw Exception(errorMsg);
        }
      } else {
        debugPrint("❌ [PopularFundRepo] HTTP Error: ${response.statusCode} - ${response.reasonPhrase}");
        throw Exception("HTTP ${response.statusCode}: ${response.reasonPhrase}");
      }
    } catch (e) {
      debugPrint("❌ [PopularFundRepo] Exception: $e");
      rethrow;
    }
  }

  // Helper method to convert Set<String> to List<int>
  List<int> _convertToIntList(Set<String>? values) {
    if (values == null || values.isEmpty) return [];

    return values
        .map((v) => int.tryParse(v))
        .where((v) => v != null)
        .cast<int>()
        .toList();
  }

  // Helper method to convert Set<String> to List<String>
  List<String> _convertToStringList(Set<String>? values) {
    if (values == null || values.isEmpty) return [];
    return values.toList();
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/http_client.dart';
import '../../../funds/data/models/popular_fund.dart';

class PopularFundRepo {
  final HttpClient _client;

  PopularFundRepo() : _client = HttpClient();

  final popularFundRepoProvider = Provider<PopularFundRepo>((ref) {
    return PopularFundRepo();
  });
  Future<List<PopularFund>> fetchPopularFunds({
    int page = 1,
    int pageSize = 10,
    String searchTerm = "",
    Set<String>? subCategoryIds,
    Map<String, Set<String>>? filters,
  }) async {
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
      "search_term": searchTerm,
      "sort_order": "",
      "sort_by": "",
      "filter": filterPayload,
    };

    debugPrint("📤 [PopularFundRepo] Request body: $body");

    final response = await _client.post(
      "/funds/popular",
      body: body,
    );

    if (response['status'] == 1 && response['data'] != null) {
      final data = response['data'] as Map<String, dynamic>;
      final List<dynamic> dataList = data['data_list'] ?? [];

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
      final errorMsg = response['message'] ?? "Unknown API error";
      debugPrint("❌ [PopularFundRepo] API error: $errorMsg");
      throw Exception(errorMsg);
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
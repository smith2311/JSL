import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/token_helper.dart';
import '../models/jhaveri_pick.dart';

class JhaveriPicksRepo {
  final String baseUrl;
  String? lastRawResponse;

  JhaveriPicksRepo({required this.baseUrl});

  Future<List<JhaveriPick>> fetchFundsWithFilters({
    required Map<String, Set<String>> filters,
    int page = 1,
    int pageSize = 10,
  }) async {
    debugPrint("[JhaveriPicksRepo] 🔄 Starting API call...");
    debugPrint("[JhaveriPicksRepo] Base URL: $baseUrl");
    debugPrint("[JhaveriPicksRepo] Endpoint: $baseUrl/funds/jhaveri-picks");

    try {
      final token = await TokenHelper.getValidToken();
      if (token == null) {
        debugPrint("[JhaveriPicksRepo] ❌ No valid token");
        throw Exception("AUTH_ERROR");
      }

      debugPrint("[JhaveriPicksRepo] ✅ Token obtained");

      final apiFilters = {
        "amcs": (filters["Fund House"] ?? {}).toList(),
        "fund_category": (filters["Fund Category"] ?? {}).toList(),
        "sub_category": (filters["Sub Category"] ?? {}).toList(),
        "risk_level": (filters["Risk Level"] ?? {}).toList(),
        "fund_size": (filters["Fund Size"] ?? {}).toList(),
      };

      final body = {
        "page": page,
        "page_size": pageSize,
        "search_term": "",
        "sort_order": "",
        "sort_by": "",
        "filter": apiFilters,
      };

      debugPrint("[JhaveriPicksRepo] 📤 Request body: ${jsonEncode(body)}");

      final res = await http.post(
        Uri.parse('$baseUrl/funds/jhaveri-picks'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      lastRawResponse = res.body;

      debugPrint("[JhaveriPicksRepo] 📥 Response status: ${res.statusCode}");
      debugPrint("[JhaveriPicksRepo] 📥 Response body: ${res.body}");

      if (res.statusCode == 200) {
        final jsonRes = jsonDecode(res.body);

        if (jsonRes['status'] == 1) {
          final dataList = jsonRes['data']?['data_list'] as List<dynamic>?;

          if (dataList == null) {
            debugPrint("[JhaveriPicksRepo] ⚠️ data_list is null");
            return [];
          }

          debugPrint("[JhaveriPicksRepo] ✅ Parsing ${dataList.length} funds");
          final funds = dataList.map((e) => JhaveriPick.fromJson(e)).toList();
          debugPrint(
              "[JhaveriPicksRepo] ✅ Successfully parsed ${funds.length} funds");
          return funds;
        } else {
          final errorMsg = jsonRes['message'] ?? "API returned error status";
          debugPrint("[JhaveriPicksRepo] ❌ API error: $errorMsg");
          throw Exception(errorMsg);
        }
      } else if (res.statusCode == 401) {
        debugPrint("[JhaveriPicksRepo] ❌ Unauthorized (401)");
        throw Exception("AUTH_ERROR");
      } else if (res.statusCode == 404) {
        debugPrint("[JhaveriPicksRepo] ❌ Endpoint not found (404)");
        debugPrint(
            "[JhaveriPicksRepo] Check if this URL is correct: $baseUrl/funds/jhaveri-picks");
        throw Exception("ENDPOINT_ERROR - The API endpoint was not found");
      } else {
        debugPrint("[JhaveriPicksRepo] ❌ HTTP Error ${res.statusCode}");
        try {
          final jsonRes = jsonDecode(res.body);
          final errorMsg = jsonRes['message'] ??
              "Server error: ${res.statusCode}";
          throw Exception(errorMsg);
        } catch (e) {
          throw Exception("Server error: ${res.statusCode}");
        }
      }
    } on http.ClientException catch (e) {
      debugPrint("[JhaveriPicksRepo] ❌ Network error: $e");
      throw Exception("Network error. Please check your internet connection.");
    } on FormatException catch (e) {
      debugPrint("[JhaveriPicksRepo] ❌ JSON parsing error: $e");
      debugPrint("[JhaveriPicksRepo] Raw response: $lastRawResponse");
      throw Exception("Invalid response format from server");
    } catch (e) {
      debugPrint("[JhaveriPicksRepo] ❌ Unexpected error: $e");
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchSubCategories() async {
    debugPrint("[JhaveriPicksRepo] 🔄 Fetching sub-categories...");

    try {
      final token = await TokenHelper.getValidToken();
      if (token == null) {
        debugPrint("[JhaveriPicksRepo] ❌ No valid token for sub-categories");
        throw Exception("AUTH_ERROR");
      }

      final res = await http.post(
        Uri.parse('$baseUrl/funds/sub-category'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"search_term": ""}),
      );

      debugPrint(
          "[JhaveriPicksRepo] Sub-categories response: ${res.statusCode}");

      if (res.statusCode == 200) {
        final jsonRes = jsonDecode(res.body);

        if (jsonRes['status'] == 1) {
          final list = (jsonRes['data']['data_list'] as List<dynamic>? ?? []);
          debugPrint(
              "[JhaveriPicksRepo] ✅ Fetched ${list.length} sub-categories");
          return [
            {"id": -1, "name": "All"},
            ...list.map((e) => {"id": e['id'], "name": e['name']})
          ];
        } else {
          final errorMsg = jsonRes['message'] ??
              "Failed to fetch sub-categories";
          debugPrint("[JhaveriPicksRepo] ❌ API error: $errorMsg");
          throw Exception(errorMsg);
        }
      } else if (res.statusCode == 404) {
        debugPrint(
            "[JhaveriPicksRepo] ❌ Sub-categories endpoint not found (404)");
        throw Exception("ENDPOINT_ERROR");
      } else {
        debugPrint("[JhaveriPicksRepo] ❌ HTTP Error ${res.statusCode}");
        final jsonRes = jsonDecode(res.body);
        throw Exception(jsonRes['message'] ?? "Failed to fetch sub-categories");
      }
    } catch (e) {
      debugPrint("[JhaveriPicksRepo] ❌ Error fetching sub-categories: $e");
      rethrow;
    }
  }
}
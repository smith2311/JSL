import 'package:flutter/foundation.dart';
import 'package:jhaveri_jsl_app/core/network/http_client.dart';
import 'package:jhaveri_jsl_app/core/secure_store.dart';

class MarketRepo {
  final HttpClient _client = HttpClient();

  /// Fetch market indices securely
  Future<List<Map<String, dynamic>>> fetchIndices() async {
    if (kDebugMode) debugPrint("\n🚀 [MarketRepo] fetchIndices");

    // 🔑 Get access token from secure storage
    final token = await SecureStore.getToken();
    if (token == null || token.isEmpty) {
      throw Exception("❌ [Auth] No access token found in secure storage");
    }

    // 🔹 API call
    final response = await _client.get(
      "/funds/indices",
      headers: {"Authorization": "Bearer $token"},
    );

    if (response["status"] == 1 && response["data"] != null) {
      final List<dynamic> list = response["data"]["data_list"];
      return list.map((e) {
        return {
          "name": e["name"].toString().toUpperCase(),
          "value": e["value"].toString(),
          "difference": e["difference"].toString(),
          "percentage": e["percentage"].toString(),
        };
      }).toList();
    } else {
      throw Exception(
          "❌ [MarketRepo] Failed to fetch indices: ${response["message"]}");
    }
  }
}
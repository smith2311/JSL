import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/api_client.dart';
import '../models/mandates.dart';

class MandateRepository {
  Future<List<Mandate>> fetchAllMandates({
    required String clientCode,
  }) async {
    debugPrint("[MandateRepo] 🔄 Fetching all mandates for client: $clientCode");

    try {
      final response = await ApiClient.post(
        '/mf-buy/sip-mandates',
        body: {
          "client_code": clientCode,
          "is_all": true,
        },
      );

      debugPrint("[MandateRepo] 📥 Response status: ${response.statusCode}");
      debugPrint("[MandateRepo] 📥 Response body: ${response.body}");

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['status'] == 1) {
          final dataList = jsonData['data']?['data_list'] as List<dynamic>?;

          if (dataList == null || dataList.isEmpty) {
            debugPrint("[MandateRepo] ⚠️ No mandates found");
            return [];
          }

          final mandates = dataList
              .map((json) => Mandate.fromJson(json))
              .toList();

          debugPrint("[MandateRepo] ✅ Successfully fetched ${mandates.length} mandates");
          return mandates;
        } else {
          final errorMsg = jsonData['message'] ?? 'Failed to fetch mandates';
          debugPrint("[MandateRepo] ❌ API error: $errorMsg");
          throw Exception(errorMsg);
        }
      } else if (response.statusCode == 401) {
        debugPrint("[MandateRepo] ❌ Unauthorized (401)");
        throw Exception("AUTH_ERROR");
      } else {
        debugPrint("[MandateRepo] ❌ HTTP Error ${response.statusCode}");
        throw Exception("Server error: ${response.statusCode}");
      }
    } on http.ClientException catch (e) {
      debugPrint("[MandateRepo] ❌ Network error: $e");
      throw Exception("Network error. Please check your internet connection.");
    } catch (e) {
      debugPrint("[MandateRepo] ❌ Unexpected error: $e");
      rethrow;
    }
  }
}
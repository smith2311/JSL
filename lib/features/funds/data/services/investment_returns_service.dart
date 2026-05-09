// services/investment_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/investment_performance.dart';
import '../models/investment_return.dart';

class InvestmentService {
  final String baseUrl;
  String? authToken;
  Map<String, String>? customHeaders;

  InvestmentService({
    required this.baseUrl,
    this.authToken,
    this.customHeaders,
  });

  // Helper method to get headers with authentication
  Map<String, String> _getHeaders() {
    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
    };

    if (authToken != null && authToken!.isNotEmpty) {
      headers["Authorization"] = "Bearer $authToken";
    }

    if (customHeaders != null) {
      headers.addAll(customHeaders!);
    }

    return headers;
  }

  // ✅ Method to update auth token
  void setAuthToken(String? token) {
    authToken = token;
  }

  Future<InvestmentPerformanceResponse> getInvestmentPerformance({
    required int fundId,
    required double amount,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/funds/investments-performance');

      print('🌐 Calling Performance API:');
      print('   URL: $url');
      print('   Fund ID: $fundId');
      print('   Amount: $amount');
      print('   Has Auth Token: ${authToken != null}');

      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: json.encode({
          "fund_id": fundId,
          "amount": amount,
        }),
      );

      print('📥 Performance Response:');
      print('   Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return InvestmentPerformanceResponse.fromJson(jsonData);
      } else if (response.statusCode == 403) {
        throw Exception("Access forbidden (403): Check authentication token or permissions");
      } else if (response.statusCode == 401) {
        throw Exception("Unauthorized (401): Authentication required");
      } else {
        throw Exception("Failed to load investment performance: ${response.statusCode}");
      }
    } catch (e) {
      print('❌ Performance API Error: $e');
      rethrow;
    }
  }

  Future<InvestmentReturnsResponse> getInvestmentReturns({
    required int fundId,
    required String type,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/funds/investments-returns');

      print('🌐 Calling Returns API:');
      print('   URL: $url');
      print('   Fund ID: $fundId');
      print('   Type: $type');
      print('   Has Auth Token: ${authToken != null}');

      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: json.encode({
          'fund_id': fundId,
          'type': type,
        }),
      );

      print('📥 Returns Response:');
      print('   Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return InvestmentReturnsResponse.fromJson(jsonData);
      } else if (response.statusCode == 403) {
        throw Exception("Access forbidden (403): Check authentication token or permissions");
      } else if (response.statusCode == 401) {
        throw Exception("Unauthorized (401): Authentication token missing or invalid");
      } else {
        throw Exception('Failed to load investment returns: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Returns API Error: $e');
      rethrow;
    }
  }
}

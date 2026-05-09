import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/env.dart';
import '../../../../core/token_helper.dart';
import '../models/portfolio.dart';

class PortfolioRepository {
  /// Fetch portfolio for given client IDs
  Future<PortfolioModel> fetchPortfolio({List<int>? clientIds}) async {
    final token = await TokenHelper.getValidToken();
    if (token == null) throw Exception("No valid token");

    final response = await http.post(
      Uri.parse('${EnvConfig.apiBaseUrl}/home/portfolio'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"client_id": clientIds ?? []}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 1) {
        return PortfolioModel.fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? "Failed to fetch portfolio");
      }
    } else {
      throw Exception("HTTP error: ${response.statusCode}");
    }
  }

  /// Fetch XIRR for given client IDs
  Future<double> fetchXirr({List<int>? clientIds}) async {
    final token = await TokenHelper.getValidToken();
    if (token == null) throw Exception("No valid token");

    final response = await http.post(
      Uri.parse('${EnvConfig.apiBaseUrl}/home/portfolio-xirr'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"client_id": clientIds ?? []}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 1 && data['data'] != null) {
        return (data['data']['xirr'] ?? 0).toDouble();
      } else {
        throw Exception(data['message'] ?? "Failed to fetch XIRR");
      }
    } else {
      throw Exception("HTTP error: ${response.statusCode}");
    }
  }
}
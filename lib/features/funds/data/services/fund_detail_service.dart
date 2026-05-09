// File: lib/features/funds/data/services/fund_detail_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/fund_details_models.dart';

class FundDetailService {
  final String baseUrl;
  final String authToken;

  FundDetailService({required this.baseUrl, required this.authToken});

  Map<String, String> get _headers => {
    "Content-Type": "application/json",
    "Authorization": "Bearer $authToken",
  };

  Future<HoldingSummary> fetchHoldingSummary(int fundId) async {
    final res = await http.post(
      Uri.parse("$baseUrl/funds/holding-summary"),
      headers: _headers,
      body: jsonEncode({"fund_id": fundId}),
    );
    final data = jsonDecode(res.body);
    return HoldingSummary.fromJson(data["data"]);
  }

  Future<InvestmentReturns> fetchInvestmentReturns(int fundId, String type) async {
    final res = await http.post(
      Uri.parse("$baseUrl/funds/investments-returns"),
      headers: _headers,
      body: jsonEncode({"fund_id": fundId, "type": type}),
    );
    final data = jsonDecode(res.body);
    return InvestmentReturns.fromJson(data["data"]);
  }

  Future<InvestmentPerformance> fetchInvestmentPerformance(int fundId, double amount) async {
    final res = await http.post(
      Uri.parse("$baseUrl/funds/investments-performance"),
      headers: _headers,
      body: jsonEncode({"fund_id": fundId, "amount": amount}),
    );
    final data = jsonDecode(res.body);
    return InvestmentPerformance.fromJson(data["data"]);
  }

  Future<NavHistory> fetchNavHistory(int fundId, String period) async {
    final res = await http.post(
      Uri.parse("$baseUrl/nav/nav-history"),
      headers: _headers,
      body: jsonEncode({"fund_id": fundId, "period": period}),
    );
    final data = jsonDecode(res.body);
    return NavHistory.fromJson(data["data"]);
  }

  Future<FundInfo> fetchFundInfo(int fundId) async {
    final res = await http.post(
      Uri.parse("$baseUrl/funds/info"),
      headers: _headers,
      body: jsonEncode({"fund_id": fundId}),
    );
    final data = jsonDecode(res.body);
    return FundInfo.fromJson(data["data"]);
  }
}
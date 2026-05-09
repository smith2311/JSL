import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/env.dart';
import '../core/token_helper.dart';
import '../features/auth/data/models/stp_detail.dart';
import '../features/auth/data/models/swp_detail.dart';
import '../features/auth/data/models/transaction_history.dart';

// ==================== STP Detail Provider ====================
final stpDetailProvider = FutureProvider.autoDispose
    .family<StpDetailModel, String>((ref, sxpId) async {
  print('[DEBUG] stpDetailProvider - fetching STP details for sxpId: $sxpId');

  final token = await TokenHelper.getValidToken();
  if (token == null) {
    print('[DEBUG] stpDetailProvider - Token is null');
    throw Exception("Authentication token not available");
  }

  print('[DEBUG] stpDetailProvider - Making API call...');
  final response = await http.post(
    Uri.parse('${EnvConfig.apiBaseUrl}/portfolio/stp/fund-details'),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
    body: jsonEncode({"sxp_id": sxpId}),
  );

  print('[DEBUG] stpDetailProvider - Response status: ${response.statusCode}');
  print('[DEBUG] stpDetailProvider - Response body: ${response.body}');

  return _handleStpDetailResponse(response);
});

StpDetailModel _handleStpDetailResponse(http.Response response) {
  if (response.statusCode != 200) {
    print('[DEBUG] _handleStpDetailResponse - Non-200 status code');
    throw Exception(
        "Failed to fetch STP details. Status code: ${response.statusCode}");
  }

  final data = jsonDecode(response.body);

  if (data['status'] != 1) {
    print('[DEBUG] _handleStpDetailResponse - API status != 1');
    throw Exception(data['message'] ?? "Unable to retrieve STP details");
  }

  if (data['data'] == null) {
    print('[DEBUG] _handleStpDetailResponse - Data field is null');
    throw Exception("Invalid response: data field is missing");
  }

  print('[DEBUG] _handleStpDetailResponse - Successfully parsed STP details');
  return StpDetailModel.fromJson(data['data']);
}

// ==================== STP Transaction History Provider ====================
final stpTransactionHistoryProvider =
FutureProvider.autoDispose.family<List<TransactionHistoryItem>, String>(
      (ref, sxpId) async {
    print('[DEBUG] stpTransactionHistoryProvider - fetching history for sxpId: $sxpId');

    final token = await TokenHelper.getValidToken();
    if (token == null) {
      print('[DEBUG] stpTransactionHistoryProvider - Token is null');
      throw Exception("Authentication token not available");
    }

    print('[DEBUG] stpTransactionHistoryProvider - Making API call...');
    final response = await http.post(
      Uri.parse('${EnvConfig.apiBaseUrl}/portfolio/sxp/transaction-history'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"sxp_id": sxpId}),
    );

    print('[DEBUG] stpTransactionHistoryProvider - Response status: ${response.statusCode}');
    print('[DEBUG] stpTransactionHistoryProvider - Response body: ${response.body}');

    return _handleTransactionHistoryResponse(response);
  },
);

List<TransactionHistoryItem> _handleTransactionHistoryResponse(
    http.Response response) {
  if (response.statusCode != 200) {
    print('[DEBUG] _handleTransactionHistoryResponse - Non-200 status code');
    throw Exception(
        "Failed to fetch transaction history. Status code: ${response.statusCode}");
  }

  final data = jsonDecode(response.body);

  if (data['status'] == 0 ||
      data['data'] == null ||
      data['data']['data_list'] == null) {
    print('[DEBUG] _handleTransactionHistoryResponse - No transaction data available');
    return [];
  }

  if (data['status'] != 1) {
    print('[DEBUG] _handleTransactionHistoryResponse - API status != 1');
    throw Exception(
        data['message'] ?? "Unable to retrieve transaction history");
  }

  final List<dynamic> transactions = data['data']['data_list'];
  print('[DEBUG] _handleTransactionHistoryResponse - Found ${transactions.length} transactions');

  return transactions
      .map((json) => TransactionHistoryItem.fromJson(json))
      .toList();
}
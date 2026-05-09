import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/env.dart';
import '../core/token_helper.dart';
import '../features/auth/data/models/swp_detail.dart';
import '../features/auth/data/models/transaction_history.dart';

// ==================== SWP Detail Provider ====================
final swpDetailProvider = FutureProvider.autoDispose
    .family<SwpDetailModel, String>((ref, sxpId) async {
  // Force immediate execution - don't use keepAlive for fresh data
  final token = await TokenHelper.getValidToken();
  if (token == null) {
    throw Exception("Authentication token not available");
  }

  final response = await http.post(
    Uri.parse('${EnvConfig.apiBaseUrl}/portfolio/swp/fund-details'),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
    body: jsonEncode({"sxp_id": sxpId}),
  );

  return _handleSwpDetailResponse(response);
});

SwpDetailModel _handleSwpDetailResponse(http.Response response) {
  if (response.statusCode != 200) {
    throw Exception(
        "Failed to fetch SWP details. Status code: ${response.statusCode}");
  }

  final data = jsonDecode(response.body);

  if (data['status'] != 1) {
    throw Exception(data['message'] ?? "Unable to retrieve SWP details");
  }

  if (data['data'] == null) {
    throw Exception("Invalid response: data field is missing");
  }

  return SwpDetailModel.fromJson(data['data']);
}

// ==================== Transaction History Provider ====================
final swpTransactionHistoryProvider =
FutureProvider.autoDispose.family<List<TransactionHistoryItem>, String>(
      (ref, sxpId) async {
    final token = await TokenHelper.getValidToken();
    if (token == null) {
      throw Exception("Authentication token not available");
    }

    final response = await http.post(
      Uri.parse('${EnvConfig.apiBaseUrl}/portfolio/sxp/transaction-history'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"sxp_id": sxpId}),
    );

    return _handleTransactionHistoryResponse(response);
  },
);

List<TransactionHistoryItem> _handleTransactionHistoryResponse(
    http.Response response) {
  if (response.statusCode != 200) {
    throw Exception(
        "Failed to fetch transaction history. Status code: ${response.statusCode}");
  }

  final data = jsonDecode(response.body);

  if (data['status'] == 0 ||
      data['data'] == null ||
      data['data']['data_list'] == null) {
    return [];
  }

  if (data['status'] != 1) {
    throw Exception(
        data['message'] ?? "Unable to retrieve transaction history");
  }

  final List<dynamic> transactions = data['data']['data_list'];
  return transactions
      .map((json) => TransactionHistoryItem.fromJson(json))
      .toList();
}

// ==================== Cancel Reasons Provider ====================
final cancelReasonsProvider =
FutureProvider.autoDispose<List<CancelReason>>((ref) async {
  final token = await TokenHelper.getValidToken();
  if (token == null) {
    throw Exception("Authentication token not available");
  }

  final response = await http.get(
    Uri.parse('${EnvConfig.apiBaseUrl}/portfolio/sxp/cancel-reason'),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
  );

  return _handleCancelReasonsResponse(response);
});

List<CancelReason> _handleCancelReasonsResponse(http.Response response) {
  if (response.statusCode != 200) {
    throw Exception(
        "Failed to fetch cancel reasons. Status code: ${response.statusCode}");
  }

  final data = jsonDecode(response.body);

  print('=== CANCEL REASONS API RESPONSE ===');
  print('Full response body: ${response.body}');
  print('Status: ${data['status']}');
  print('Data: ${data['data']}');
  print('===================================');

  if (data['status'] != 1 || data['data'] == null) {
    throw Exception(data['message'] ?? "Unable to retrieve cancel reasons");
  }

  if (data['data']['data_list'] != null) {
    final List<dynamic> reasonsList = data['data']['data_list'];
    print('Parsing ${reasonsList.length} reasons');

    return reasonsList.map((json) {
      print('Raw JSON item: $json');
      print('Value field: ${json['value']}, Label field: ${json['label']}');
      return CancelReason.fromJson(json);
    }).toList();
  }

  throw Exception("Unexpected response format for cancel reasons");
}
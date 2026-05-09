// Add this file to: features/auth/data/repo/switch_detail_repo.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/env.dart';
import '../../../../core/token_helper.dart';
import '../models/switch_detail.dart';

class SwitchDetailRepository {
  /// Fetch scheme constraints for switch transaction
  Future<SchemeConstraint> fetchSchemeConstraints({
    required int fundId,
    String orderType = 'lumpsum',
    String transactionType = 'Switch-IN',
  }) async {
    final token = await TokenHelper.getValidToken();
    if (token == null) throw Exception("No valid token");

    print('📋 Fetching scheme constraints for fundId: $fundId');

    final response = await http.post(
      Uri.parse('${EnvConfig.apiBaseUrl}/mf-buy/scheme-constraint'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "fund_id": fundId,
        "order_type": orderType,
        "transaction_type": transactionType,
      }),
    );

    print('📡 Response Status: ${response.statusCode}');
    print('📦 Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 1) {
        return SchemeConstraint.fromJson(data);
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch scheme constraints');
      }
    } else {
      throw Exception("Failed to fetch scheme constraints: ${response.statusCode}");
    }
  }

  /// Fetch BSE client accounts
  Future<List<BseClient>> fetchBseClients() async {
    final token = await TokenHelper.getValidToken();
    if (token == null) throw Exception("No valid token");

    print('📋 Fetching BSE clients');

    // TODO: Replace with actual BSE client API endpoint
    final response = await http.get(
      Uri.parse('${EnvConfig.apiBaseUrl}/bse/clients'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    print('📡 Response Status: ${response.statusCode}');
    print('📦 Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 1) {
        final List<dynamic> clients = data['data']['clients'] ?? [];
        return clients.map((e) => BseClient.fromJson(e)).toList();
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch BSE clients');
      }
    } else {
      throw Exception("Failed to fetch BSE clients: ${response.statusCode}");
    }
  }

  /// Submit switch transaction
  Future<Map<String, dynamic>> submitSwitchTransaction({
    required int fromFundId,
    required int toFundId,
    required String folioNo,
    required String clientId,
    required bool isAmount,
    required double value,
    required String bseClientCode,
  }) async {
    final token = await TokenHelper.getValidToken();
    if (token == null) throw Exception("No valid token");

    print('📋 Submitting switch transaction');

    final response = await http.post(
      Uri.parse('${EnvConfig.apiBaseUrl}/portfolio/switch/submit'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "from_fund_id": fromFundId,
        "to_fund_id": toFundId,
        "folio_no": folioNo,
        "client_id": clientId,
        "switch_type": isAmount ? "amount" : "units",
        "value": value,
        "bse_client_code": bseClientCode,
      }),
    );

    print('📡 Response Status: ${response.statusCode}');
    print('📦 Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 1) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to submit switch transaction');
      }
    } else {
      throw Exception("Failed to submit switch transaction: ${response.statusCode}");
    }
  }
}
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/env.dart';
import '../token_helper.dart';

class StpApiService {

  /// Fetch list of funds available for STP/Switch
  Future<Map<String, dynamic>> fetchStpFundList({
    required int fundId,
    int page = 1,
    int pageSize = 10,
    String searchTerm = '',
    String sortOrder = '',
    String sortBy = '',
  }) async {
    try {
      final token = await TokenHelper.getValidToken();
      if (token == null) throw Exception("No valid token");

      print('📋 Fetching STP fund list...');
      print('   Fund ID: $fundId');
      print('   Page: $page');
      print('   Search: $searchTerm');

      final response = await http.post(
        Uri.parse('${EnvConfig.apiBaseUrl}/portfolio/switch/list'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "fund_id": fundId,
          "page": page,
          "page_size": pageSize,
          "search_term": searchTerm,
          "sort_order": sortOrder,
          "sort_by": sortBy,
        }),
      );

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 1) {
          print('✅ STP fund list fetched successfully');
          return data;
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch fund list');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception in fetchStpFundList: $e');
      rethrow;
    }
  }

  /// Fetch SXP constraints for a specific fund
  ///
  /// Transaction Types:
  /// - STP-IN (for STP orders)
  /// - SIP (for SIP orders)
  /// - SWP (for SWP orders)
  /// - Switch-IN (for switch orders)
  /// - Purchase (for lumpsum)
  /// - Redemption (for redemption)
  Future<Map<String, dynamic>> fetchSxpConstraints({
    required int fundId,
    required String orderType, // 'sxp' or 'lumpsum'
    required String transactionType, // 'STP-IN', 'SIP', 'SWP', 'Switch-IN', 'Purchase', 'Redemption'
    required String frequency, // 'daily', 'weekly', 'monthly'
  }) async {
    try {
      final token = await TokenHelper.getValidToken();
      if (token == null) throw Exception("No valid token");

      print('🔍 Fetching SXP constraints...');
      print('   Fund ID: $fundId');
      print('   Order Type: $orderType');
      print('   Transaction Type: $transactionType');
      print('   Frequency: $frequency');

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
          "frequency": frequency,
        }),
      );

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 1) {
          print('✅ SXP constraints fetched successfully');
          print('   Min Amount: ${data['data']['min_amount']}');
          print('   Max Amount: ${data['data']['max_amount']}');
          print('   Min Installments: ${data['data']['min_installments']}');
          print('   Max Installments: ${data['data']['max_installments']}');
          return data;
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch constraints');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception in fetchSxpConstraints: $e');
      rethrow;
    }
  }

  /// Place STP order (Direct API call - NO OTP/verifiedToken in payload)
  Future<Map<String, dynamic>> placeStpOrder({
    required int fundIdFrom,
    required int fundIdTo,
    required String folioNo,
    required double amount,
    required String frequency,
    required String stpDate, // Format: yyyy-MM-dd
    required int noOfInstallments,
    required String bseClientId,
    required bool firstOrder,
    required String transferBy, // 'amount' or 'units'
  }) async {
    try {
      final token = await TokenHelper.getValidToken();
      if (token == null) throw Exception("No valid token");

      print('========== PLACING STP ORDER (API SERVICE) ==========');
      print('🔑 Auth Token: ${token.substring(0, min(20, token.length))}...');
      print('🌐 Endpoint: ${EnvConfig.apiBaseUrl}/portfolio/stp/confirm');
      print('📋 Parameters:');
      print('   fund_id_from: $fundIdFrom');
      print('   fund_id_to: $fundIdTo');
      print('   folio_no: $folioNo');
      print('   amount: $amount');
      print('   frequency: $frequency');
      print('   stp_date: $stpDate');
      print('   no_of_installments: $noOfInstallments');
      print('   bse_client_id: $bseClientId');
      print('   first_order: $firstOrder');
      print('   transfer_by: $transferBy');

      // Validate date format
      if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(stpDate)) {
        throw Exception('Invalid date format. Expected yyyy-MM-dd, got: $stpDate');
      }

      // ✅ CRITICAL: STP API payload does NOT include OTP or verifiedToken
      final payload = {
        "fund_id_from": fundIdFrom,
        "fund_id_to": fundIdTo,
        "folio_no": folioNo,
        "amount": amount,
        "frequency": frequency,
        "stp_date": stpDate,
        "no_of_installments": noOfInstallments,
        "bse_client_id": bseClientId,
        "first_order": firstOrder,
        "transfer_by": transferBy,
        // ❌ NO OTP
        // ❌ NO verified_token
      };

      print('📤 Request Payload:');
      print(jsonEncode(payload));

      final response = await http.post(
        Uri.parse('${EnvConfig.apiBaseUrl}/portfolio/stp/confirm'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token", // Only standard auth token
        },
        body: jsonEncode(payload),
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');
      print('====================================================');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 1) {
          print('✅ STP order placed successfully');
          return {
            'status': 1,
            'orderId': data['data']?['order_id']?.toString(),
            'message': data['message'] ?? 'STP order placed successfully',
          };
        } else {
          print('❌ API returned status: ${data['status']}');
          print('❌ Error message: ${data['message']}');
          throw Exception(data['message'] ?? 'Failed to place STP order');
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        try {
          final data = jsonDecode(response.body);
          throw Exception(data['message'] ?? 'Server error: ${response.statusCode}');
        } catch (e) {
          throw Exception(response.body.isNotEmpty ? response.body : 'Server error: ${response.statusCode}');
        }
      }
    } catch (e, st) {
      print('❌ EXCEPTION in placeStpOrder:');
      print('   Error: $e');
      print('   Stack: $st');
      rethrow;
    }
  }
}

final stpApiServiceProvider = Provider<StpApiService>((ref) => StpApiService());
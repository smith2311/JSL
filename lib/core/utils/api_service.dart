import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/env.dart';
import '../token_helper.dart';

class ApiService {
  Future<Map<String, dynamic>> placeSwpOrder({
    required int fundId,
    required String folioNo,
    required String bseClientId,
    required String withdrawalBy,
    required double amount,
    required String otp,
    required String frequency,
    required String swpDate,
    required int noOfInstallments,
    required bool firstOrder,
    String? verifiedToken,
  }) async {
    try {
      final token = await TokenHelper.getValidToken();
      if (token == null) throw Exception("No valid token");

      print('========== SWP ORDER API CALL ==========');
      print('🔐 Auth Token: ${token.substring(0, min(20, token.length))}...');
      print('🔐 Original OTP: ${otp.substring(0, min(2, otp.length))}****');
      print('🔐 Verified Token: ${verifiedToken ?? "none"}');
      print('🌐 Endpoint: ${EnvConfig.apiBaseUrl}/portfolio/swp/confirm');
      print('📋 Parameters:');
      print('   fund_id: $fundId');
      print('   folio_no: $folioNo');
      print('   bse_client_id: $bseClientId');
      print('   withdrawal_by: $withdrawalBy');
      print('   amount: $amount');
      print('   frequency: $frequency');
      print('   swp_date: $swpDate');
      print('   no_of_installments: $noOfInstallments');
      print('   first_order: $firstOrder');

      if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(swpDate)) {
        throw Exception('Invalid date format. Expected yyyy-MM-dd');
      }

      // ✅ CRITICAL: Always use the ORIGINAL OTP number for SWP
      // The verified token is NOT used in the API call
      final payload = {
        "fund_id": fundId,
        "folio_no": folioNo,
        "bse_client_id": bseClientId,
        "withdrawal_by": withdrawalBy,
        "amount": amount,
        "frequency": frequency,
        "swp_date": swpDate,
        "no_of_installments": noOfInstallments,
        "first_order": firstOrder,
        "otp": otp, // ← ALWAYS the original OTP number
      };

      print('📤 Request Payload:');
      print(jsonEncode(payload));

      final response = await http.post(
        Uri.parse('${EnvConfig.apiBaseUrl}/portfolio/swp/confirm'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(payload),
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');
      print('========================================');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 1) {
          print('✅ SWP order placed successfully');
          return {
            'status': 1,
            'orderId': data['data']?['order_id']?.toString(),
            'message': data['message'] ?? 'SWP order placed successfully',
          };
        } else {
          print('❌ API returned status: ${data['status']}');
          print('❌ Error message: ${data['message']}');
          throw Exception(data['message'] ?? 'Failed to place SWP order');
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
      print('❌ EXCEPTION in placeSwpOrder:');
      print('   Error: $e');
      print('   Stack: $st');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> placeRedeemOrder({
    required int fundId,
    required String folioNo,
    required String bseClientId,
    required String redeemType,
    required String redeemBy,
    required double amount,
    required String otp,
    String? verifiedToken,
  }) async {
    try {
      final token = await TokenHelper.getValidToken();
      if (token == null) throw Exception("No valid token");

      print('🚀 Placing redemption order...');
      print('🌐 Endpoint: ${EnvConfig.apiBaseUrl}/portfolio/redeem');
      print('🔐 Using OTP: ${otp.substring(0, min(2, otp.length))}****');

      final payload = {
        "fund_id": fundId,
        "folio_no": folioNo,
        "bse_client_id": bseClientId,
        "redeem": redeemType,
        "redeem_by": redeemBy,
        "amount": amount,
        "otp": otp,
      };

      print('📋 Payload: ${jsonEncode(payload)}');

      final response = await http.post(
        Uri.parse('${EnvConfig.apiBaseUrl}/portfolio/redeem'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(payload),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 1) {
        print('✅ Redemption order placed successfully');
        return {
          'status': 1,
          'orderId': data['data']?['order_id'],
          'message': data['message'] ?? 'Redemption order placed successfully',
        };
      } else {
        print('❌ API Error: ${data['message']}');
        throw Exception(data['message'] ?? 'Failed to place redemption order');
      }
    } catch (e, st) {
      print('❌ Exception in placeRedeemOrder: $e');
      rethrow;
    }
  }
}

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
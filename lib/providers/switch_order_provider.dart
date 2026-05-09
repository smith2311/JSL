import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/env.dart';
import '../core/token_helper.dart';

class SwitchOrderState {
  final bool isSuccess;
  final String? orderId;
  final String? errorMessage;

  const SwitchOrderState({
    this.isSuccess = false,
    this.orderId,
    this.errorMessage,
  });

  SwitchOrderState copyWith({
    bool? isSuccess,
    String? orderId,
    String? errorMessage,
  }) {
    return SwitchOrderState(
      isSuccess: isSuccess ?? this.isSuccess,
      orderId: orderId ?? this.orderId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class SwitchOrderNotifier extends StateNotifier<SwitchOrderState> {
  SwitchOrderNotifier() : super(const SwitchOrderState());

  Future<void> placeSwitchOrder({
    required int fundIdFrom,
    required int fundIdTo,
    required String folioNo,
    required String bseClientId,
    required String switchBy,
    required String switchTo,
    required double value,
    required String verifiedToken,
  }) async {
    try {
      // ✅ CRITICAL: Get the REGULAR auth token, not the verified token
      final token = await TokenHelper.getValidToken();
      if (token == null) throw Exception("No valid token");

      print('========== PLACING SWITCH ORDER ==========');
      print('📋 Switch Data:');
      print('   fundIdFrom: $fundIdFrom');
      print('   fundIdTo: $fundIdTo');
      print('   folioNo: $folioNo');
      print('   bseClientId: $bseClientId');
      print('   switchBy: $switchBy');
      print('   switchTo: $switchTo');
      print('   value: $value');
      print('🔑 Using REGULAR auth token (not verified token)');
      print('🔑 Verified token provided: $verifiedToken (NOT USED FOR API)');

      final body = {
        "bse_client_id": bseClientId,
        "fund_id_from": fundIdFrom,
        "fund_id_to": fundIdTo,
        "folio_no": folioNo,
        "switch_by": switchBy,
        "switch_to": switchTo,
      };

      if (switchBy == 'amount') {
        body['amount'] = value;
      } else {
        body['units'] = value;
      }

      print('📤 Request body: ${jsonEncode(body)}');

      final response = await http.post(
        Uri.parse('${EnvConfig.apiBaseUrl}/portfolio/switch/confirm'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",  // ← Use REGULAR token, not verifiedToken
        },
        body: jsonEncode(body),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      final json = jsonDecode(response.body);
      if (response.statusCode == 200 && json['status'] == 1) {
        state = state.copyWith(
          isSuccess: true,
          orderId: json['data']['order_id'].toString(),
        );
        print('✅ Switch order placed successfully');
      } else {
        throw Exception(json['message'] ?? 'Failed to place switch order');
      }
    } catch (e, stackTrace) {
      print('❌ Order placement error: $e');
      print('Stack trace: $stackTrace');
      state = state.copyWith(
        isSuccess: false,
        errorMessage: e.toString(),
      );
    }
  }
}

final switchOrderProvider = StateNotifierProvider<SwitchOrderNotifier, SwitchOrderState>((ref) => SwitchOrderNotifier());
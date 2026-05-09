import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env.dart';
import '../../../../core/token_helper.dart';
import 'package:http/http.dart' as http;
class SwpOrderState {
  final bool isLoading;
  final bool isSuccess;
  final String? orderId;
  final String? bseClientId;
  final String? errorMessage;

  SwpOrderState({
    this.isLoading = false,
    this.isSuccess = false,
    this.orderId,
    this.bseClientId,
    this.errorMessage,
  });

  SwpOrderState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? orderId,
    String? bseClientId,
    String? errorMessage,
  }) {
    return SwpOrderState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      orderId: orderId ?? this.orderId,
      bseClientId: bseClientId ?? this.bseClientId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class SwpOrderNotifier extends StateNotifier<SwpOrderState> {
  SwpOrderNotifier() : super(SwpOrderState());

  Future<void> placeSwpOrder({
    required int fundId,
    required String folioNo,
    required double amount,
    required String frequency,
    required String swpDate,
    required int noOfInstallments,
    required String bseClientId,
    required String withdrawalBy,
    required bool firstOrder,
    required String otp,
  }) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final token = await TokenHelper.getValidToken();
      if (token == null) throw Exception("No valid token");

      print('🚀 Placing SWP order...');
      print('Fund ID: $fundId');
      print('Folio No: $folioNo');
      print('Amount: $amount');
      print('Frequency: $frequency');
      print('SWP Date: $swpDate');
      print('No of Installments: $noOfInstallments');
      print('BSE Client ID: $bseClientId');
      print('Withdrawal By: $withdrawalBy');
      print('First Order: $firstOrder');
      print('OTP: $otp');

      final response = await http.post(
        Uri.parse('${EnvConfig.apiBaseUrl}/portfolio/swp/confirm'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "fund_id": fundId,
          "folio_no": folioNo,
          "amount": amount,
          "frequency": frequency,
          "swp_date": swpDate,
          "no_of_installments": noOfInstallments,
          "bse_client_id": bseClientId,
          "withdrawal_by": withdrawalBy,
          "first_order": firstOrder,
          "otp": otp,
        }),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 1) {
          print('✅ SWP order placed successfully');
          final orderId = data['data']['order_id'] as String?;
          state = state.copyWith(
            isLoading: false,
            isSuccess: true,
            orderId: orderId,
            bseClientId: bseClientId,
          );
        } else {
          print('❌ API returned error status');
          state = state.copyWith(
            isLoading: false,
            errorMessage: data['message'] ?? "Failed to place SWP order",
          );
        }
      } else {
        print('❌ HTTP error');
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'HTTP error: ${response.statusCode}',
        );
      }
    } catch (e, st) {
      print('❌ Exception: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() {
    state = SwpOrderState();
  }
}

final swpOrderProvider = StateNotifierProvider<SwpOrderNotifier, SwpOrderState>(
      (ref) => SwpOrderNotifier(),
);
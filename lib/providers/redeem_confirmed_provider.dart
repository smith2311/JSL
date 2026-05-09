import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/env.dart';
import '../core/token_helper.dart';
import '../core/utils/api_service.dart';
import '../features/auth/data/models/redeem_confirm.dart';

// ---------------- Redeem Details Notifier ----------------
class RedeemDetailsNotifier extends StateNotifier<AsyncValue<ConfirmRedeemDetails>> {
  RedeemDetailsNotifier() : super(const AsyncValue.loading());

  Future<void> fetchRedeemDetails({
    required int fundId,
    required String folioNo,
    required String bseClientId,
    required String redeem, // 'full' or 'partial'
    required String redeemBy, // 'amount' or 'units'
    required double amount,
  }) async {

    print('🚨 DEBUG: fetchRedeemDetails called from:');
    print(StackTrace.current);
    try {
      state = const AsyncValue.loading();

      final token = await TokenHelper.getValidToken();
      if (token == null) throw Exception("No valid token");

      print('🚀 Fetching redeem details...');
      print('Fund ID: $fundId');
      print('Folio No: $folioNo');
      print('BSE Client ID: $bseClientId');
      print('Redeem: $redeem');
      print('Redeem By: $redeemBy');
      print('Amount: $amount');

      final response = await http.post(
        Uri.parse('${EnvConfig.apiBaseUrl}/portfolio/redeem/details'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "fund_id": fundId,
          "folio_no": folioNo,
          "bse_client_id": bseClientId,
          "redeem": redeem,
          "redeem_by": redeemBy,
          "amount": amount,
        }),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 1) {
          print('✅ Redeem details fetched successfully');
          final details = ConfirmRedeemDetails.fromJson(data['data']);
          state = AsyncValue.data(details);
        } else {
          print('❌ API returned error status');
          state = AsyncValue.error(
            data['message'] ?? "Failed to fetch redemption details",
            StackTrace.current,
          );
        }
      } else {
        print('❌ HTTP error');
        state = AsyncValue.error(
          'HTTP error: ${response.statusCode}',
          StackTrace.current,
        );
      }
    } catch (e, st) {
      print('❌ Exception: $e');
      state = AsyncValue.error(e, st);
    }
  }
}

final redeemDetailsProvider = StateNotifierProvider<RedeemDetailsNotifier, AsyncValue<ConfirmRedeemDetails>>(
      (ref) => RedeemDetailsNotifier(),
);

// ---------------- Redeem Order State ----------------

class RedeemOrderState {
  final bool isLoading;
  final bool isSuccess;
  final String? orderId;
  final String? bseClientId;
  final String? errorMessage;

  const RedeemOrderState({
    this.isLoading = false,
    this.isSuccess = false,
    this.orderId,
    this.bseClientId,
    this.errorMessage,
  });

  RedeemOrderState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? orderId,
    String? bseClientId,
    String? errorMessage,
  }) {
    return RedeemOrderState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      orderId: orderId ?? this.orderId,
      bseClientId: bseClientId ?? this.bseClientId,
      errorMessage: errorMessage,
    );
  }
}

class RedeemOrderNotifier extends StateNotifier<RedeemOrderState> {
  RedeemOrderNotifier(this._apiService) : super(const RedeemOrderState());

  final ApiService _apiService;

  Future<void> placeRedeemOrder({
    required int fundId,
    required String folioNo,
    required String bseClientId,
    required String redeem,
    required String redeemBy,
    required double amount,
    required String otp,
    Map<String, dynamic>? redemptionData,
    String? verifiedToken, // 🆕 Accept verified token
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    print('========== REDEEM ORDER NOTIFIER ==========');
    print('📋 Input Parameters:');
    print('   redeem type: $redeem');
    print('   fundId: $fundId');
    print('   folioNo: $folioNo');
    print('   bseClientId: $bseClientId');
    print('   redeemBy: $redeemBy');
    print('   amount: $amount');
    print('   otp: ${otp.substring(0, 2)}****');
    print('   redemptionData: $redemptionData');
    print('   verifiedToken: ${verifiedToken != null ? "PROVIDED" : "NOT PROVIDED"}');

    try {
      Map<String, dynamic> response;

      if (redeem == 'SWP') {
        print('🔄 Processing SWP order...');

        final frequency = redemptionData?['frequency'] as String? ?? '';
        final swpDate = redemptionData?['swpDate'] as String? ?? '';
        final noOfInstallments = redemptionData?['noOfInstallments'] as int? ?? 0;
        final firstOrder = redemptionData?['firstOrder'] as bool? ?? false;

        print('📋 SWP Specific Data:');
        print('   frequency: $frequency');
        print('   swpDate: $swpDate');
        print('   noOfInstallments: $noOfInstallments');
        print('   firstOrder: $firstOrder');

        // Final validation before API call
        if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(swpDate)) {
          print('❌ Date validation failed in provider');
          throw Exception('Invalid date format in provider: $swpDate');
        }

        response = await _apiService.placeSwpOrder(
          fundId: fundId,
          folioNo: folioNo,
          bseClientId: bseClientId,
          withdrawalBy: redeemBy,
          amount: amount,
          otp: otp,
          frequency: frequency,
          swpDate: swpDate,
          noOfInstallments: noOfInstallments,
          firstOrder: firstOrder,
          verifiedToken: verifiedToken, // 🔑 Pass verified token
        );
      } else {
        print('🔄 Processing standard redemption...');

        response = await _apiService.placeRedeemOrder(
          fundId: fundId,
          folioNo: folioNo,
          bseClientId: bseClientId,
          redeemType: redeem,
          redeemBy: redeemBy,
          amount: amount,
          otp: otp,
          verifiedToken: verifiedToken, // 🔑 Pass verified token
        );
      }

      print('📥 API Response:');
      print('   status: ${response['status']}');
      print('   orderId: ${response['orderId']}');
      print('   message: ${response['message']}');

      if (response['status'] == 1) {
        print('✅ Order placed successfully');
        state = state.copyWith(
          isLoading: false,
          isSuccess: true,
          orderId: response['orderId']?.toString(),
          bseClientId: bseClientId,
        );
      } else {
        print('❌ Order placement failed: ${response['message']}');
        throw Exception(response['message'] ?? 'Failed to place order');
      }
    } catch (e, st) {
      print('❌ EXCEPTION in placeRedeemOrder:');
      print('   Error: $e');
      print('   Stack: $st');

      state = state.copyWith(
        isLoading: false,
        isSuccess: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }

    print('==========================================');
  }
}

// ✅ CRITICAL: Provider declaration MUST be at the top level (outside any class)
final redeemOrderProvider = StateNotifierProvider<RedeemOrderNotifier, RedeemOrderState>(
      (ref) => RedeemOrderNotifier(ref.watch(apiServiceProvider)),
);
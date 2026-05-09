import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../core/config/env.dart';
import '../core/token_helper.dart';
import '../features/auth/data/models/portfolio_fund_detail.dart';


// ---------------- Scheme Constraint Model ----------------
class SchemeConstraint {
  final double minAmount;
  final double maxAmount;
  final double minUnits;
  final double maxUnits;

  SchemeConstraint({
    required this.minAmount,
    required this.maxAmount,
    required this.minUnits,
    required this.maxUnits,
  });

  factory SchemeConstraint.fromJson(Map<String, dynamic> json) {
    return SchemeConstraint(
      minAmount: (json['min_amount'] ?? 0).toDouble(),
      maxAmount: (json['max_amount'] ?? 0).toDouble(),
      minUnits: (json['min_units'] ?? 0).toDouble(),
      maxUnits: (json['max_units'] ?? 0).toDouble(),
    );
  }
}

// ---------------- Scheme Constraint Provider ----------------
final schemeConstraintProvider = FutureProvider.autoDispose.family<
    SchemeConstraint,
    int>((ref, fundId) async {

  print('🚀 Fetching scheme constraints for fundId: $fundId');

  final token = await TokenHelper.getValidToken();
  if (token == null) throw Exception("No valid token");

  final uri = Uri.parse('${EnvConfig.apiBaseUrl}/mf-buy/scheme-constraint');

  final response = await http.post(
    uri,
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
    body: jsonEncode({
      "fund_id": fundId,
      "order_type": "lumpsum",
      "transaction_type": "Redemption",
    }),
  );

  print('📡 Scheme constraint response status: ${response.statusCode}');

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['status'] == 1) {
      print('✅ Scheme constraints fetched successfully');
      return SchemeConstraint.fromJson(data['data']);
    } else {
      throw Exception(data['message'] ?? "Failed to fetch scheme constraints");
    }
  } else {
    throw Exception("HTTP error: ${response.statusCode}");
  }
});


// ---------------- Redeem Form State Management ----------------
class RedeemFormState {
  final bool isAmountMode;
  final String inputValue;
  final bool isRedeemAll;
  final String? errorMessage;
  final double? maxValue;

  RedeemFormState({
    this.isAmountMode = false,
    this.inputValue = '',
    this.isRedeemAll = false,
    this.errorMessage,
    this.maxValue,
  });

  RedeemFormState copyWith({
    bool? isAmountMode,
    String? inputValue,
    bool? isRedeemAll,
    String? errorMessage,
    double? maxValue,
  }) {
    return RedeemFormState(
      isAmountMode: isAmountMode ?? this.isAmountMode,
      inputValue: inputValue ?? this.inputValue,
      isRedeemAll: isRedeemAll ?? this.isRedeemAll,
      errorMessage: errorMessage,
      maxValue: maxValue ?? this.maxValue,
    );
  }
}

class RedeemFormNotifier extends StateNotifier<RedeemFormState> {
  RedeemFormNotifier() : super(RedeemFormState());

  void toggleMode() {
    state = state.copyWith(
      isAmountMode: !state.isAmountMode,
      inputValue: '',
      isRedeemAll: false,
      errorMessage: null,
    );
  }

  void updateInputValue(String value, {double? maxValue}) {
    bool shouldUncheckRedeemAll = false;

    if (state.isRedeemAll && maxValue != null) {
      // final currentValue = double.tryParse(value);
      final expectedMax = state.isAmountMode
          ? maxValue.toStringAsFixed(3)
          : maxValue.toStringAsFixed(2);

      if (value != expectedMax) {
        shouldUncheckRedeemAll = true;
      }
    }

    state = state.copyWith(
      inputValue: value,
      isRedeemAll: shouldUncheckRedeemAll ? false : state.isRedeemAll,
      errorMessage: null,
      maxValue: maxValue,
    );
  }

  void toggleRedeemAll(bool value, {double? maxValue}) {
    if (value && maxValue != null) {
      state = state.copyWith(
        isRedeemAll: true,
        inputValue: state.isAmountMode
            ? maxValue.toStringAsFixed(3)
            : maxValue.toStringAsFixed(2),
        errorMessage: null,
        maxValue: maxValue,
      );
    } else {
      state = state.copyWith(
        isRedeemAll: false,
        inputValue: '',
        errorMessage: null,
      );
    }
  }

  void validateInput(
      double maxValue,
      bool isAmount,
      SchemeConstraint constraints,
      ) {
    if (state.inputValue.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Please enter ${isAmount ? 'amount' : 'units'}',
      );
      return;
    }

    final value = double.tryParse(state.inputValue);
    if (value == null) {
      state = state.copyWith(
        errorMessage: 'Please enter a valid number',
      );
      return;
    }

    if (isAmount) {
      if (value < constraints.minAmount) {
        state = state.copyWith(
          errorMessage: 'Minimum amount is ₹${constraints.minAmount.toStringAsFixed(2)}',
        );
        return;
      }
      if (value > maxValue) {
        state = state.copyWith(
          errorMessage: 'Amount cannot exceed ₹${maxValue.toStringAsFixed(2)}',
        );
        return;
      }
    } else {
      if (value < constraints.minUnits) {
        state = state.copyWith(
          errorMessage: 'Minimum units is ${constraints.minUnits.toStringAsFixed(3)}',
        );
        return;
      }
      if (value > maxValue) {
        state = state.copyWith(
          errorMessage: 'Units cannot exceed ${maxValue.toStringAsFixed(3)}',
        );
        return;
      }
    }

    state = state.copyWith(errorMessage: null);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final redeemFormProvider =
StateNotifierProvider.autoDispose<RedeemFormNotifier, RedeemFormState>(
      (ref) => RedeemFormNotifier(),
);

// ---------------- BSE Account Model ----------------
class BseAccount {
  final String bseClientId;
  final String taxStatus;
  final String holdingStatus;
  final String secondHolderName;
  final String? bankAccNo;
  final String? bankNm;

  BseAccount({
    required this.bseClientId,
    required this.taxStatus,
    required this.holdingStatus,
    required this.secondHolderName,
    this.bankAccNo,
    this.bankNm,
  });

  factory BseAccount.fromJson(Map<String, dynamic> json) {
    return BseAccount(
      bseClientId: json['bse_client_id'] ?? '',
      taxStatus: json['tax_status'] ?? '',
      holdingStatus: json['holding_status'] ?? '',
      secondHolderName: json['second_holding_name'] ?? '',
      bankAccNo: json['bank_acc_no'],
      bankNm: json['bank_nm'],
    );
  }

  String get displayName => '$bseClientId - $taxStatus';
}

// ---------------- BSE Account Notifier ----------------
class RedeemBseAccountNotifier extends StateNotifier<AsyncValue<List<BseAccount>>> {
  RedeemBseAccountNotifier() : super(const AsyncValue.loading());

  Future<void> fetchAccounts(String clientId) async {
    try {
      state = const AsyncValue.loading();
      final token = await TokenHelper.getValidToken();
      if (token == null) throw Exception("No valid token");

      final response = await http.post(
        Uri.parse('${EnvConfig.apiBaseUrl}/mf-buy/accounts-list'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "client_id": [clientId],
          "search_term": ""
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 1) {
          final list = data['data']['data_list'] as List;
          final accounts = list.map((e) => BseAccount.fromJson(e)).toList();
          state = AsyncValue.data(accounts);
        } else {
          state = AsyncValue.error(data['message'] ?? "Failed to fetch accounts", StackTrace.current);
        }
      } else {
        state = AsyncValue.error('HTTP error: ${response.statusCode}', StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final redeemBseAccountProvider = StateNotifierProvider<RedeemBseAccountNotifier, AsyncValue<List<BseAccount>>>(
      (ref) => RedeemBseAccountNotifier(),
);


// ---------------- Fund Detail Provider ----------------
class FundDetailParams {
  final int fundId;
  final String folioNo;

  const FundDetailParams({
    required this.fundId,
    required this.folioNo,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is FundDetailParams &&
              runtimeType == other.runtimeType &&
              fundId == other.fundId &&
              folioNo == other.folioNo;

  @override
  int get hashCode => fundId.hashCode ^ folioNo.hashCode;
}

final portfolioFundDetailProvider = FutureProvider.autoDispose.family<
    PortfolioFundDetailModel,
    FundDetailParams>((ref, params) async {

  print('🚀 Provider called with fundId: ${params.fundId}, folioNo: ${params.folioNo}');

  final token = await TokenHelper.getValidToken();
  print('🔑 Token obtained: ${token != null}');

  if (token == null) throw Exception("No valid token");

  final uri = Uri.parse('${EnvConfig.apiBaseUrl}/portfolio/details');

  print('🌐 Calling API: $uri');

  final response = await http.post(
    uri,
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
    body: jsonEncode({
      "fund_id": params.fundId,
      "folio_no": params.folioNo,
    }),
  );

  print('📡 Response status: ${response.statusCode}');
  print('📦 Response body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['status'] == 1) {
      print('✅ Success - parsing data');
      final model = PortfolioFundDetailModel.fromJson(data['data']);
      print('✅ Model created successfully');
      return model;
    } else {
      print('❌ API returned error status');
      throw Exception(data['message'] ?? "Failed to fetch fund details");
    }
  } else {
    print('❌ HTTP error');
    throw Exception("HTTP error: ${response.statusCode}");
  }
});
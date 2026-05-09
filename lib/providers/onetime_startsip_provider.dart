import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../../../../core/token_helper.dart';
import '../../../../core/config/env.dart';
import 'package:http/http.dart' as http;


// Fix 3: Update Mandate model to ensure unique displayName
// In onetime_startsip_provider.dart, update the Mandate class:
class Mandate {
  final int mandateId;
  final String bankName;
  final String accountNo;
  final String ifsc;
  final double amount;

  Mandate({
    required this.mandateId,
    required this.bankName,
    required this.accountNo,
    required this.ifsc,
    required this.amount,
  });

  factory Mandate.fromJson(Map<String, dynamic> json) {
    return Mandate(
      mandateId: json['mandate_id'] ?? 0,
      bankName: json['bank_name'] ?? '',
      accountNo: json['account_no'] ?? '',
      ifsc: json['ifsc'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
    );
  }

  /// Display name (for dropdown UI)
  /// Shows bank name + masked account number
  String get displayName {
    final maskedAccount = accountNo.length > 4
        ? '*' * (accountNo.length - 4) + accountNo.substring(accountNo.length - 4)
        : accountNo;
    return '$bankName - $maskedAccount';
  }

  /// Unique key (for dropdown value)
  /// This ensures each mandate is unique in the dropdown
  String get uniqueValue => '$mandateId';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Mandate && other.mandateId == mandateId;
  }

  @override
  int get hashCode => mandateId.hashCode;

}
// -----------------------
// Onetime Startsip Constraint Model
// -----------------------
class OnetimeStartsipConstraint {
  final double minAmount;
  final double maxAmount;

  OnetimeStartsipConstraint({required this.minAmount, required this.maxAmount});

  factory OnetimeStartsipConstraint.fromJson(Map<String, dynamic> json) {
    return OnetimeStartsipConstraint(
      minAmount: (json['min_amount'] ?? 0).toDouble(),
      maxAmount: (json['max_amount'] ?? 0).toDouble(),
    );
  }

  OnetimeStartsipConstraint copyWith({double? minAmount, double? maxAmount}) {
    return OnetimeStartsipConstraint(
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
    );
  }
}

// -----------------------
// SIP Constraint Model
// -----------------------
class SipConstraint {
  final List<int> frequencyDates;
  final int minInstallments;
  final int maxInstallments;
  final double minAmount;
  final double maxAmount;

  SipConstraint({
    required this.frequencyDates,
    required this.minInstallments,
    required this.maxInstallments,
    required this.minAmount,
    required this.maxAmount,
  });

  factory SipConstraint.fromJson(Map<String, dynamic> json) {
    return SipConstraint(
      frequencyDates: (json['frequency_dates'] as List).map((e) => e as int).toList(),
      minInstallments: json['min_installments'] ?? 36,
      maxInstallments: json['max_installments'] ?? 9999,
      minAmount: (json['min_amount'] ?? 0).toDouble(),
      maxAmount: (json['max_amount'] ?? 0).toDouble(),
    );
  }

  SipConstraint copyWith({
    List<int>? frequencyDates,
    int? minInstallments,
    int? maxInstallments,
    double? minAmount,
    double? maxAmount,
  }) {
    return SipConstraint(
      frequencyDates: frequencyDates ?? this.frequencyDates,
      minInstallments: minInstallments ?? this.minInstallments,
      maxInstallments: maxInstallments ?? this.maxInstallments,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
    );
  }
}

// -----------------------
// BSE Account Model
// -----------------------
class BseAccount {
  final String bseClientId;
  final String taxStatus;
  final String holdingStatus;
  final String secondHolderName;

  BseAccount({
    required this.bseClientId,
    required this.taxStatus,
    required this.holdingStatus,
    required this.secondHolderName,
  });

  factory BseAccount.fromJson(Map<String, dynamic> json) {
    return BseAccount(
      bseClientId: json['bse_client_id'] ?? '',
      taxStatus: json['tax_status'] ?? '',
      holdingStatus: json['holding_status'] ?? '',
      secondHolderName: json['second_holding_name'] ?? '',
    );
  }

  String get displayName => '$bseClientId - $taxStatus';
}


// -----------------------
// OnetimeStartsip Notifier
// -----------------------
class OnetimeStartsipNotifier extends StateNotifier<AsyncValue<OnetimeStartsipConstraint>> {
  OnetimeStartsipNotifier() : super(const AsyncValue.loading());

  Future<void> fetchConstraint(int fundId) async {
    try {
      state = const AsyncValue.loading();

      final response = await ApiClient.post(
        '/mf-buy/scheme-constraint',
        body: {
          'fund_id': fundId,
          'order_type': 'lumpsum',
          'transaction_type': 'Purchase',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['status'] == 1 && responseData['data'] != null) {
          final constraint = OnetimeStartsipConstraint.fromJson(responseData['data']);
          state = AsyncValue.data(constraint);
        } else {
          state = AsyncValue.error(
            responseData['message'] ?? 'Failed to load constraints',
            StackTrace.current,
          );
        }
      } else {
        state = AsyncValue.error('HTTP error: ${response.statusCode}', StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void updateMinAmount(double newMin) {
    state.whenData((constraint) {
      state = AsyncValue.data(constraint.copyWith(minAmount: newMin));
    });
  }
}

// -----------------------
// SIP Frequency Notifier
// -----------------------
class SipFrequencyNotifier extends StateNotifier<AsyncValue<List<String>>> {
  SipFrequencyNotifier() : super(const AsyncValue.loading());

  Future<void> fetchFrequencies(int fundId) async {
    try {
      state = const AsyncValue.loading();

      final response = await ApiClient.post(
        '/mf-buy/frequency-list',
        body: {
          'fund_id': fundId,
          'transaction_type': 'SIP',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['status'] == 1 && responseData['data'] != null) {
          final frequencies = (responseData['data']['data_list'] as List)
              .map((e) => e.toString())
              .toList();
          state = AsyncValue.data(frequencies);
        } else {
          state = AsyncValue.error(
            responseData['message'] ?? 'Failed to load frequencies',
            StackTrace.current,
          );
        }
      } else {
        state = AsyncValue.error('HTTP error: ${response.statusCode}', StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}


// -----------------------
// Order Placement Functions
// -----------------------
class OrderPlacementNotifier extends StateNotifier<AsyncValue<void>> {
  OrderPlacementNotifier() : super(const AsyncValue.data(null));

  Future<void> placeLumpsumOrder({
    required int fundId,
    required String folioNo,
    required double amount,
    required String bseClientId,
  }) async {
    try {
      state = const AsyncValue.loading();
      final token = await TokenHelper.getValidToken();
      if (token == null) throw Exception("No valid token");

      final response = await http.post(
        Uri.parse('${EnvConfig.apiBaseUrl}/mf-buy/lumpsum'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "fund_id": fundId,
          "folio_no": folioNo,
          "amount": amount,
          "bse_client_id": bseClientId,
        }),
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 && responseData['status'] == 1) {
        state = const AsyncValue.data(null);
      } else {
        state = AsyncValue.error(
          responseData['message'] ?? 'Failed to place lumpsum order',
          StackTrace.current,
        );
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> placeSipOrder({
    required String bseClientId,
    required int fundId,
    required String folioNo,
    required double amount,
    required String frequency,
    required String startDate,
    required int noOfInstallments,
    required int mandateId,
    required bool firstOrder,
  }) async {
    try {
      state = const AsyncValue.loading();
      final token = await TokenHelper.getValidToken();
      if (token == null) throw Exception("No valid token");

      final response = await http.post(
        Uri.parse('${EnvConfig.apiBaseUrl}/mf-buy/sip'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "bse_client_id": bseClientId,
          "fund_id": fundId,
          "folio_no": folioNo,
          "amount": amount,
          "frequency": frequency,
          "start_date": startDate,
          "no_of_installments": noOfInstallments,
          "mandate_id": mandateId,
          "first_order": firstOrder,
        }),
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 && responseData['status'] == 1) {
        state = const AsyncValue.data(null);
      } else {
        state = AsyncValue.error(
          responseData['message'] ?? 'Failed to place SIP order',
          StackTrace.current,
        );
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// Provider for order placement
final orderPlacementProvider = StateNotifierProvider<OrderPlacementNotifier, AsyncValue<void>>(
      (ref) => OrderPlacementNotifier(),
);
// -----------------------
// SIP Constraint Notifier
// -----------------------

class SipConstraintNotifier extends StateNotifier<AsyncValue<SipConstraint>> {
  SipConstraintNotifier() : super(const AsyncValue.loading());

  Future<void> fetchSipConstraint(int fundId, String frequency) async {
    try {
      state = const AsyncValue.loading();

      final response = await ApiClient.post(
        '/mf-buy/scheme-constraint',
        body: {
          'fund_id': fundId,
          'order_type': 'sxp',
          'transaction_type': 'SIP',
          'frequency': frequency,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['status'] == 1 && responseData['data'] != null) {
          final constraint = SipConstraint.fromJson(responseData['data']);
          state = AsyncValue.data(constraint);
        } else {
          state = AsyncValue.error(
            responseData['message'] ?? 'Failed to load SIP constraints',
            StackTrace.current,
          );
        }
      } else {
        state = AsyncValue.error('HTTP error: ${response.statusCode}', StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void updateMinAmount(double newMin) {
    state.whenData((constraint) {
      state = AsyncValue.data(constraint.copyWith(minAmount: newMin));
    });
  }
}

// -----------------------
// BSE Account Notifier
// -----------------------
class BseAccountNotifier extends StateNotifier<AsyncValue<List<BseAccount>>> {
  BseAccountNotifier() : super(const AsyncValue.loading());

  Future<void> fetchAccounts(int clientId) async {
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

// -----------------------
// Folio Notifier
// -----------------------
class FolioNotifier extends StateNotifier<AsyncValue<List<String>>> {
  FolioNotifier() : super(const AsyncValue.loading());

  Future<void> fetchFolios(int clientId) async {
    try {
      state = const AsyncValue.loading();
      final token = await TokenHelper.getValidToken();
      if (token == null) throw Exception("No valid token");

      final response = await http.post(
        Uri.parse('${EnvConfig.apiBaseUrl}/report/folio/list'),
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
          final folios = list.map((e) => e.toString()).toList();
          state = AsyncValue.data(folios);
        } else {
          state = AsyncValue.error(data['message'] ?? "Failed to fetch folios", StackTrace.current);
        }
      } else {
        state = AsyncValue.error('HTTP error: ${response.statusCode}', StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// -----------------------
// Mandate Notifier
// -----------------------
class MandateNotifier extends StateNotifier<AsyncValue<List<Mandate>>> {
  MandateNotifier() : super(const AsyncValue.loading());

  Future<void> fetchMandates(String clientCode) async {
    try {
      state = const AsyncValue.loading();
      final token = await TokenHelper.getValidToken();
      if (token == null) throw Exception("No valid token");

      final response = await http.post(
        Uri.parse('${EnvConfig.apiBaseUrl}/mf-buy/sip-mandates'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "client_code": clientCode,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 1) {
          final list = data['data']['data_list'] as List;
          final mandates = list.map((e) => Mandate.fromJson(e)).toList();
          state = AsyncValue.data(mandates);
        } else {
          state = AsyncValue.error(data['message'] ?? "Failed to fetch mandates", StackTrace.current);
        }
      } else {
        state = AsyncValue.error('HTTP error: ${response.statusCode}', StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// -----------------------
// Riverpod Providers
// -----------------------
final fundConstraintProvider = StateNotifierProvider<OnetimeStartsipNotifier, AsyncValue<OnetimeStartsipConstraint>>(
      (ref) => OnetimeStartsipNotifier(),
);

final sipFrequencyProvider = StateNotifierProvider<SipFrequencyNotifier, AsyncValue<List<String>>>(
      (ref) => SipFrequencyNotifier(),
);

final sipConstraintProvider = StateNotifierProvider<SipConstraintNotifier, AsyncValue<SipConstraint>>(
      (ref) => SipConstraintNotifier(),
);

final bseAccountProvider = StateNotifierProvider<BseAccountNotifier, AsyncValue<List<BseAccount>>>(
      (ref) => BseAccountNotifier(),
);

final folioProvider = StateNotifierProvider<FolioNotifier, AsyncValue<List<String>>>(
      (ref) => FolioNotifier(),
);

final mandateProvider = StateNotifierProvider<MandateNotifier, AsyncValue<List<Mandate>>>(
      (ref) => MandateNotifier(),
);
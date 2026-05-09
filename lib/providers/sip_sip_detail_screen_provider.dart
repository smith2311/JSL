import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/env.dart';
import '../core/token_helper.dart';
import '../features/auth/data/models/sip_sip_details.dart';
import '../features/auth/data/models/swp_detail.dart';
import '../features/auth/data/models/transaction_history.dart';

// ==================== SIP Detail Provider ====================
final sipDetailProvider = FutureProvider.autoDispose
    .family<SipDetailModel, String>((ref, sxpId) async {
  final token = await TokenHelper.getValidToken();
  if (token == null) {
    throw Exception("Authentication token not available");
  }

  final response = await http.post(
    Uri.parse('${EnvConfig.apiBaseUrl}/portfolio/sip/fund-details'),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
    body: jsonEncode({"sxp_id": sxpId}),
  );

  return _handleSipDetailResponse(response);
});

SipDetailModel _handleSipDetailResponse(http.Response response) {
  if (response.statusCode != 200) {
    throw Exception(
        "Failed to fetch SIP details. Status code: ${response.statusCode}");
  }

  final data = jsonDecode(response.body);

  if (data['status'] != 1) {
    throw Exception(data['message'] ?? "Unable to retrieve SIP details");
  }

  if (data['data'] == null) {
    throw Exception("Invalid response: data field is missing");
  }

  return SipDetailModel.fromJson(data['data']);
}

// ==================== SIP Transaction History Provider ====================
final sipTransactionHistoryProvider =
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

// ==================== Pause SIP Provider ====================
class PauseSipState {
  final DateTime? selectedDate;
  final int noOfInstallments;
  final String? errorMessage;
  final bool isProcessing;

  PauseSipState({
    this.selectedDate,
    this.noOfInstallments = 1,
    this.errorMessage,
    this.isProcessing = false,
  });

  PauseSipState copyWith({
    DateTime? selectedDate,
    int? noOfInstallments,
    String? errorMessage,
    bool? isProcessing,
  }) {
    return PauseSipState(
      selectedDate: selectedDate ?? this.selectedDate,
      noOfInstallments: noOfInstallments ?? this.noOfInstallments,
      errorMessage: errorMessage,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}

class PauseSipNotifier extends StateNotifier<PauseSipState> {
  // ✅ Initialize with today's date by default
  PauseSipNotifier() : super(PauseSipState(selectedDate: DateTime.now()));

  void selectDate(DateTime date) {
    state = state.copyWith(
      selectedDate: date,
      errorMessage: null,
    );
  }

  void updateInstallments(int count) {
    state = state.copyWith(
      noOfInstallments: count,
      errorMessage: null,
    );
  }

  bool validate(int maxAllowed) {
    if (state.selectedDate == null) {
      state = state.copyWith(errorMessage: 'Please select a start date');
      return false;
    }

    if (state.noOfInstallments < 1 || state.noOfInstallments > maxAllowed) {
      state = state.copyWith(
          errorMessage: 'Installments must be between 1 and $maxAllowed');
      return false;
    }

    return true;
  }

  void setProcessing(bool value) {
    state = state.copyWith(isProcessing: value);
  }

  // ✅ Reset also sets today's date
  void reset() {
    state = PauseSipState(selectedDate: DateTime.now());
  }

  Future<void> pauseSip({
    required String regNo,
    required DateTime pausedFrom,
    required int noOfInstallments,
  }) async {
    try {
      setProcessing(true);

      final token = await TokenHelper.getValidToken();
      if (token == null) {
        throw Exception("Authentication token not available");
      }

      final formattedDate =
          '${pausedFrom.year}-${pausedFrom.month.toString().padLeft(2, '0')}-${pausedFrom.day.toString().padLeft(2, '0')}';

      final response = await http.post(
        Uri.parse('${EnvConfig.apiBaseUrl}/portfolio/sip/pause'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "reg_no": regNo,
          "no_of_installments": noOfInstallments,
          "paused_from": formattedDate,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
            "Failed to pause SIP. Status code: ${response.statusCode}");
      }

      final data = jsonDecode(response.body);
      if (data['status'] != 1) {
        throw Exception(data['message'] ?? "Unable to pause SIP");
      }
    } catch (e) {
      setProcessing(false);
      rethrow;
    }
  }

  Future<void> resumeSip({required String regNo}) async {
    try {
      setProcessing(true);

      final token = await TokenHelper.getValidToken();
      if (token == null) {
        throw Exception("Authentication token not available");
      }

      final response = await http.post(
        Uri.parse('${EnvConfig.apiBaseUrl}/portfolio/sip/resume'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"reg_no": regNo}),
      );

      if (response.statusCode != 200) {
        throw Exception(
            "Failed to resume SIP. Status code: ${response.statusCode}");
      }

      final data = jsonDecode(response.body);
      if (data['status'] != 1) {
        throw Exception(data['message'] ?? "Unable to resume SIP");
      }
    } catch (e) {
      setProcessing(false);
      rethrow;
    }
  }
}

final pauseSipStateProvider =
StateNotifierProvider.autoDispose<PauseSipNotifier, PauseSipState>(
      (ref) => PauseSipNotifier(),
);
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../core/config/env.dart';
import '../core/token_helper.dart';

class CancelSipState {
  final int? selectedReasonId;
  final String otherReasonText;
  final String? errorMessage;
  final bool isProcessing;

  CancelSipState({
    this.selectedReasonId,
    this.otherReasonText = '',
    this.errorMessage,
    this.isProcessing = false,
  });

  CancelSipState copyWith({
    int? selectedReasonId,
    String? otherReasonText,
    String? errorMessage,
    bool? isProcessing,
  }) {
    return CancelSipState(
      selectedReasonId: selectedReasonId ?? this.selectedReasonId,
      otherReasonText: otherReasonText ?? this.otherReasonText,
      errorMessage: errorMessage,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}

class CancelSipNotifier extends StateNotifier<CancelSipState> {
  CancelSipNotifier() : super(CancelSipState());

  void selectReason(int reasonId, bool isOthersOption) {
    print('Selecting reason ID: $reasonId (isOthers: $isOthersOption)');
    state = state.copyWith(
      selectedReasonId: reasonId,
      errorMessage: null,
      otherReasonText: isOthersOption ? state.otherReasonText : '',
    );
    print('New selected ID: ${state.selectedReasonId}');
  }

  void updateOtherReasonText(String text) {
    state = state.copyWith(
      otherReasonText: text,
      errorMessage: null,
    );
  }

  bool validate(int? othersReasonId) {
    // Check if "Others" option is selected
    if (state.selectedReasonId == othersReasonId) {
      if (state.otherReasonText.trim().isEmpty) {
        state = state.copyWith(errorMessage: 'Please enter a reason');
        return false;
      }
    }
    return true;
  }

  void setProcessing(bool value) {
    state = state.copyWith(isProcessing: value);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  void reset() {
    state = CancelSipState();
  }

  Future<void> cancelSxp({
    required String regNo,
    required int reasonCode,
    required String reasonMsg,
    required String sxpType,
  }) async {
    print('=== CANCEL SXP API CALL STARTED ===');
    print('Parameters:');
    print('  regNo: $regNo');
    print('  reasonCode: $reasonCode');
    print('  reasonMsg: $reasonMsg');
    print('  sxpType: $sxpType');

    try {
      setProcessing(true);
      print('Processing state set to true');

      final token = await TokenHelper.getValidToken();
      print('Token retrieved: ${token != null ? "Yes" : "No"}');

      if (token == null) {
        print('ERROR: Token is null');
        throw Exception("Authentication token not available");
      }

      final requestBody = {
        "reg_no": regNo,
        "reason_code": reasonCode,
        "reason_msg": reasonMsg,
        "sxp_type": sxpType,
      };
      print('Request body: ${jsonEncode(requestBody)}');

      final url = '${EnvConfig.apiBaseUrl}/portfolio/sxp/cancel';
      print('API URL: $url');

      print('Making HTTP POST request...');
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(requestBody),
      );

      print('Response received:');
      print('  Status Code: ${response.statusCode}');
      print('  Response Body: ${response.body}');

      if (response.statusCode != 200) {
        print('ERROR: Non-200 status code');
        throw Exception(
            "Failed to cancel SXP. Status code: ${response.statusCode}");
      }

      final data = jsonDecode(response.body);
      print('Parsed response data: $data');

      if (data['status'] != 1) {
        print('ERROR: API returned status != 1');
        throw Exception(data['message'] ?? "Unable to cancel SXP");
      }

      print('=== CANCEL SXP API CALL SUCCESSFUL ===');
      // Success - processing will be set to false after navigation
    } catch (e, stackTrace) {
      print('=== CANCEL SXP API CALL FAILED ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      setProcessing(false);
      rethrow;
    }
  }
}

final cancelSipStateProvider = StateNotifierProvider.autoDispose<CancelSipNotifier, CancelSipState>(
      (ref) => CancelSipNotifier(),
);
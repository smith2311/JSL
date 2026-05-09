import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/stp_api_service.dart';
import '../features/auth/data/models/stp_fund_list.dart';
// ============ STP Fund List State ============

class StpFundListState {
  final bool isLoading;
  final List<StpFundListItem> funds;
  final String? errorMessage;
  final int currentPage;
  final int totalPages;
  final int totalRecords;

  const StpFundListState({
    this.isLoading = false,
    this.funds = const [],
    this.errorMessage,
    this.currentPage = 1,
    this.totalPages = 0,
    this.totalRecords = 0,
  });

  StpFundListState copyWith({
    bool? isLoading,
    List<StpFundListItem>? funds,
    String? errorMessage,
    int? currentPage,
    int? totalPages,
    int? totalRecords,
  }) {
    return StpFundListState(
      isLoading: isLoading ?? this.isLoading,
      funds: funds ?? this.funds,
      errorMessage: errorMessage,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalRecords: totalRecords ?? this.totalRecords,
    );
  }
}

class StpFundListNotifier extends StateNotifier<StpFundListState> {
  final StpApiService _apiService;

  StpFundListNotifier(this._apiService) : super(const StpFundListState());

  Future<void> fetchFunds({
    required int fundId,
    int page = 1,
    String searchTerm = '',
  }) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final response = await _apiService.fetchStpFundList(
        fundId: fundId,
        page: page,
        searchTerm: searchTerm,
      );

      if (response['status'] == 1) {
        final data = StpFundListResponse.fromJson(response['data']);

        state = state.copyWith(
          isLoading: false,
          funds: data.dataList,
          currentPage: data.pageIndex,
          totalPages: data.totalPages,
          totalRecords: data.totalRecords,
        );
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch funds');
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final stpFundListProvider = StateNotifierProvider<StpFundListNotifier, StpFundListState>(
      (ref) => StpFundListNotifier(ref.watch(stpApiServiceProvider)),
);

// ============ SXP Constraints State ============

class SxpConstraintsState {
  final bool isLoading;
  final SxpConstraints? constraints;
  final String? errorMessage;

  const SxpConstraintsState({
    this.isLoading = false,
    this.constraints,
    this.errorMessage,
  });

  SxpConstraintsState copyWith({
    bool? isLoading,
    SxpConstraints? constraints,
    String? errorMessage,
  }) {
    return SxpConstraintsState(
      isLoading: isLoading ?? this.isLoading,
      constraints: constraints ?? this.constraints,
      errorMessage: errorMessage,
    );
  }
}

class SxpConstraintsNotifier extends StateNotifier<SxpConstraintsState> {
  final StpApiService _apiService;

  SxpConstraintsNotifier(this._apiService) : super(const SxpConstraintsState());

  /// Fetch STP constraints
  /// Use transaction_type: "STP-IN" for the API
  Future<void> fetchStpConstraints({
    required int fundId,
    required String frequency, // 'daily', 'weekly', 'monthly'
  }) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      print('🔍 Fetching STP constraints for fundId: $fundId, frequency: $frequency');

      final response = await _apiService.fetchSxpConstraints(
        fundId: fundId,
        orderType: 'sxp',
        transactionType: 'STP-IN', // ✅ Use "STP-IN" for STP orders
        frequency: frequency,
      );

      if (response['status'] == 1) {
        final constraints = SxpConstraints.fromJson(response['data']);

        print('✅ STP constraints fetched:');
        print('   Min Amount: ${constraints.minAmount}');
        print('   Max Amount: ${constraints.maxAmount}');
        print('   Min Installments: ${constraints.minInstallments}');
        print('   Max Installments: ${constraints.maxInstallments}');

        state = state.copyWith(
          isLoading: false,
          constraints: constraints,
        );
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch constraints');
      }
    } catch (e) {
      print('❌ Error fetching STP constraints: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Fetch SWP constraints
  /// Use transaction_type: "SWP" for the API
  Future<void> fetchSwpConstraints({
    required int fundId,
    required String frequency,
  }) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final response = await _apiService.fetchSxpConstraints(
        fundId: fundId,
        orderType: 'sxp',
        transactionType: 'SWP', // ✅ Use "SWP" for SWP orders
        frequency: frequency,
      );

      if (response['status'] == 1) {
        final constraints = SxpConstraints.fromJson(response['data']);
        state = state.copyWith(
          isLoading: false,
          constraints: constraints,
        );
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch constraints');
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Fetch Switch constraints
  /// Use transaction_type: "Switch-IN" for the API
  Future<void> fetchSwitchConstraints({
    required int fundId,
  }) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final response = await _apiService.fetchSxpConstraints(
        fundId: fundId,
        orderType: 'lumpsum',
        transactionType: 'Switch-IN', // ✅ Use "Switch-IN" for switch orders
        frequency: '', // Not needed for switch
      );

      if (response['status'] == 1) {
        final constraints = SxpConstraints.fromJson(response['data']);
        state = state.copyWith(
          isLoading: false,
          constraints: constraints,
        );
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch constraints');
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  void reset() {
    state = const SxpConstraintsState();
  }
}

final sxpConstraintsProvider = StateNotifierProvider<SxpConstraintsNotifier, SxpConstraintsState>(
      (ref) => SxpConstraintsNotifier(ref.watch(stpApiServiceProvider)),
);

// ============ STP Order State ============

class StpOrderState {
  final bool isLoading;
  final bool isSuccess;
  final String? orderId;
  final String? errorMessage;
  final String? successMessage;

  const StpOrderState({
    this.isLoading = false,
    this.isSuccess = false,
    this.orderId,
    this.errorMessage,
    this.successMessage,
  });

  StpOrderState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? orderId,
    String? errorMessage,
    String? successMessage,
  }) {
    return StpOrderState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      orderId: orderId ?? this.orderId,
      errorMessage: errorMessage,
      successMessage: successMessage ?? this.successMessage,
    );
  }
}

class StpOrderNotifier extends StateNotifier<StpOrderState> {
  final StpApiService _apiService;

  StpOrderNotifier(this._apiService) : super(const StpOrderState());

  Future<void> placeStpOrder({
    required int fundIdFrom,
    required int fundIdTo,
    required String folioNo,
    required double amount,
    required String frequency,
    required String stpDate,
    required int noOfInstallments,
    required String bseClientId,
    required bool firstOrder,
    required String transferBy,
  }) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      print('========== STP ORDER PROVIDER ==========');
      print('📋 Calling API service with parameters:');
      print('   fundIdFrom: $fundIdFrom');
      print('   fundIdTo: $fundIdTo');
      print('   folioNo: $folioNo');
      print('   amount: $amount');
      print('   frequency: $frequency');
      print('   stpDate: $stpDate');
      print('   noOfInstallments: $noOfInstallments');
      print('   bseClientId: $bseClientId');
      print('   firstOrder: $firstOrder');
      print('   transferBy: $transferBy');

      // ✅ Call the API service (no OTP/verifiedToken needed)
      final response = await _apiService.placeStpOrder(
        fundIdFrom: fundIdFrom,
        fundIdTo: fundIdTo,
        folioNo: folioNo,
        amount: amount,
        frequency: frequency,
        stpDate: stpDate,
        noOfInstallments: noOfInstallments,
        bseClientId: bseClientId,
        firstOrder: firstOrder,
        transferBy: transferBy,
      );

      print('📥 API Response:');
      print('   status: ${response['status']}');
      print('   orderId: ${response['orderId']}');
      print('   message: ${response['message']}');

      if (response['status'] == 1) {
        print('✅ STP order placed successfully');
        print('==========================================');

        state = state.copyWith(
          isLoading: false,
          isSuccess: true,
          orderId: response['orderId'],
          successMessage: response['message'],
        );
      } else {
        throw Exception(response['message'] ?? 'Failed to place STP order');
      }
    } catch (e) {
      print('❌ Exception in StpOrderNotifier: $e');
      print('==========================================');

      state = state.copyWith(
        isLoading: false,
        isSuccess: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }
}

final stpOrderProvider = StateNotifierProvider<StpOrderNotifier, StpOrderState>(
      (ref) => StpOrderNotifier(ref.watch(stpApiServiceProvider)),
);
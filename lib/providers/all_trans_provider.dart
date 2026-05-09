import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/data/models/all_transaction.dart';
import '../features/funds/data/services/all_transaction_service.dart';
// Parameters for the provider
class AllTransactionsParams {
  final int fundId;
  final String folioNo;

  const AllTransactionsParams({
    required this.fundId,
    required this.folioNo,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is AllTransactionsParams &&
              runtimeType == other.runtimeType &&
              fundId == other.fundId &&
              folioNo == other.folioNo;

  @override
  int get hashCode => fundId.hashCode ^ folioNo.hashCode;
}

// State class
class AllTransactionsState {
  final List<TransactionModel> transactions;
  final int currentPage;
  final int totalPages;
  final int totalRecords;
  final bool hasMore;
  final bool isLoadingMore;

  const AllTransactionsState({
    required this.transactions,
    required this.currentPage,
    required this.totalPages,
    required this.totalRecords,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  AllTransactionsState copyWith({
    List<TransactionModel>? transactions,
    int? currentPage,
    int? totalPages,
    int? totalRecords,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return AllTransactionsState(
      transactions: transactions ?? this.transactions,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalRecords: totalRecords ?? this.totalRecords,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

// API Service Provider
final allTransactionsApiServiceProvider = Provider<AllTransactionsApiService>((ref) {
  return AllTransactionsApiService();
});

// Main Provider
final allTransactionsProvider = StateNotifierProvider.family<
    AllTransactionsNotifier,
    AsyncValue<AllTransactionsState>,
    AllTransactionsParams>(
      (ref, params) {
    return AllTransactionsNotifier(
      ref.watch(allTransactionsApiServiceProvider),
      params,
    );
  },
);

class AllTransactionsNotifier extends StateNotifier<AsyncValue<AllTransactionsState>> {
  final AllTransactionsApiService _apiService;
  final AllTransactionsParams _params;

  AllTransactionsNotifier(this._apiService, this._params)
      : super(const AsyncValue.loading()) {
    fetchTransactions();
  }

  Future<void> fetchTransactions({bool refresh = false}) async {
    if (refresh) {
      state = const AsyncValue.loading();
    }

    final currentState = state.valueOrNull;
    final page = refresh ? 1 : (currentState?.currentPage ?? 0) + 1;

    // If loading more, set loading state
    if (!refresh && currentState != null) {
      state = AsyncValue.data(currentState.copyWith(isLoadingMore: true));
    }

    try {
      final response = await _apiService.fetchAllTransactions(
        fundId: _params.fundId,
        folioNo: _params.folioNo,
        page: page,
      );

      final transactionsResponse = AllTransactionsResponse.fromJson(response['data']);

      final List<TransactionModel> updatedList;
      if (refresh || page == 1) {
        updatedList = transactionsResponse.dataList;
      } else {
        updatedList = [
          ...currentState?.transactions ?? [],
          ...transactionsResponse.dataList,
        ];
      }

      state = AsyncValue.data(AllTransactionsState(
        transactions: updatedList,
        currentPage: page,
        totalPages: transactionsResponse.totalPages,
        totalRecords: transactionsResponse.totalRecords,
        hasMore: page < transactionsResponse.totalPages,
        isLoadingMore: false,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void reset() {
    state = const AsyncValue.loading();
    fetchTransactions(refresh: true);
  }
}
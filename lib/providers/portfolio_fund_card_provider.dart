import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/funds/data/models/portfolio_fund_card.dart';
import '../features/funds/data/repos/portfolio_fundcard_repo.dart';

/// State class to hold both funds list and total records
class FundListState {
  final List<FundModel> funds;
  final int totalRecords; // ✅ Stores total count from API
  final bool isLoading;
  final String? error;

  FundListState({
    required this.funds,
    required this.totalRecords,
    this.isLoading = false,
    this.error,
  });

  FundListState copyWith({
    List<FundModel>? funds,
    int? totalRecords,
    bool? isLoading,
    String? error,
  }) {
    return FundListState(
      funds: funds ?? this.funds,
      totalRecords: totalRecords ?? this.totalRecords,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

final fundListProvider =
StateNotifierProvider<FundListNotifier, AsyncValue<FundListState>>(
      (ref) => FundListNotifier(FundRepository()),
);

class FundListNotifier extends StateNotifier<AsyncValue<FundListState>> {
  final FundRepository repository;

  int _page = 1;
  final int _pageSize = 10;
  bool _hasMore = true;

  // Filters and sorting parameters
  List<int>? _currentClientIds;
  String _currentSearchTerm = '';
  String _currentSortBy = '';
  String _currentSortOrder = '';
  List<String> _currentAmcs = [];
  List<String> _currentFundCategory = [];
  List<String> _currentSubCategory = [];

  FundListNotifier(this.repository)
      : super(AsyncValue.data(FundListState(funds: [], totalRecords: 0)));

  bool get hasMore => _hasMore;

  /// Fetches funds list with metadata and pagination.
  Future<void> fetchFunds({
    bool refresh = false,
    List<int>? clientIds,
    String searchTerm = '',
    String sortBy = '',
    String sortOrder = '',
    List<String> amcs = const [],
    List<String> fundCategory = const [],
    List<String> subCategory = const [],
  }) async {
    if (refresh) {
      _page = 1;
      _hasMore = true;
      _currentClientIds = clientIds;
      _currentSearchTerm = searchTerm;
      _currentSortBy = sortBy;
      _currentSortOrder = sortOrder;
      _currentAmcs = amcs;
      _currentFundCategory = fundCategory;
      _currentSubCategory = subCategory;

      // Set loading state
      state = AsyncValue.data(FundListState(funds: [], totalRecords: 0, isLoading: true));
    }

    if (!_hasMore) return;

    try {
      // Fetch paginated data
      final response = await repository.fetchFundsWithMetadata(
        page: _page,
        pageSize: _pageSize,
        clientIds: _currentClientIds,
        searchTerm: _currentSearchTerm,
        sortBy: _currentSortBy,
        sortOrder: _currentSortOrder,
        amcs: _currentAmcs,
        fundCategory: _currentFundCategory,
        subCategory: _currentSubCategory,
      );

      // ✅ Extract totalRecords from API response
      final List<FundModel> newFunds = response['funds'] ?? [];
      final int totalRecords = response['totalRecords'] ?? 0;

      // Combine old + new funds
      final List<FundModel> updatedFunds;
      if (refresh) {
        updatedFunds = newFunds;
      } else {
        final currentFunds = state.maybeWhen(
          data: (fundState) => fundState.funds,
          orElse: () => <FundModel>[],
        );
        updatedFunds = [...currentFunds, ...newFunds];
      }

      // ✅ Check if more pages available
      final totalLoaded = updatedFunds.length;
      _hasMore = totalLoaded < totalRecords;

      // ✅ Update state cleanly
      state = AsyncValue.data(
        FundListState(
          funds: updatedFunds,
          totalRecords: totalRecords,
          isLoading: false,
        ),
      );

      // ✅ Increment page only if more data exists
      if (_hasMore) _page++;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
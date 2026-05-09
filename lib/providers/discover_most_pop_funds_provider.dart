import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../../constants/strings.dart';
import '../../../../core/secure_store.dart';
import '../features/auth/data/repo/popular_fund_repo.dart';
import '../features/funds/data/models/popular_fund.dart';

// Constants
const int kAllCategoryId = -1;
const int kPageSize = 10;

// ============================================================================
// STATE CLASSES
// ============================================================================

class FundsState {
  final List<PopularFund> funds;
  final bool isLoadingFunds;
  final bool isLoadingMore;
  final bool hasError;
  final bool hasMoreData;
  final String errorMessage;
  final int currentPage;

  const FundsState({
    this.funds = const [],
    this.isLoadingFunds = false,
    this.isLoadingMore = false,
    this.hasError = false,
    this.hasMoreData = true,
    this.errorMessage = '',
    this.currentPage = 1,
  });

  FundsState copyWith({
    List<PopularFund>? funds,
    bool? isLoadingFunds,
    bool? isLoadingMore,
    bool? hasError,
    bool? hasMoreData,
    String? errorMessage,
    int? currentPage,
  }) {
    return FundsState(
      funds: funds ?? this.funds,
      isLoadingFunds: isLoadingFunds ?? this.isLoadingFunds,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasError: hasError ?? this.hasError,
      hasMoreData: hasMoreData ?? this.hasMoreData,
      errorMessage: errorMessage ?? this.errorMessage,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class CategoriesState {
  final List<Map<String, dynamic>> categories;
  final bool isLoading;
  final bool hasError;
  final String errorMessage;

  const CategoriesState({
    this.categories = const [],
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage = '',
  });

  CategoriesState copyWith({
    List<Map<String, dynamic>>? categories,
    bool? isLoading,
    bool? hasError,
    String? errorMessage,
  }) {
    return CategoriesState(
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class FilterState {
  final Set<int> selectedSubCategoryIds;
  final bool isAllSelected;
  final Map<String, Set<String>> appliedFilters;

  const FilterState({
    this.selectedSubCategoryIds = const {},
    this.isAllSelected = true,
    this.appliedFilters = const {},
  });

  FilterState copyWith({
    Set<int>? selectedSubCategoryIds,
    bool? isAllSelected,
    Map<String, Set<String>>? appliedFilters,
  }) {
    return FilterState(
      selectedSubCategoryIds: selectedSubCategoryIds ?? this.selectedSubCategoryIds,
      isAllSelected: isAllSelected ?? this.isAllSelected,
      appliedFilters: appliedFilters ?? this.appliedFilters,
    );
  }

  bool get hasAppliedFilters {
    return appliedFilters.values.any((filterSet) => filterSet.isNotEmpty);
  }
}

// ============================================================================
// BASIC PROVIDERS
// ============================================================================

final authTokenProvider = FutureProvider<String?>((ref) async {
  debugPrint("[AuthToken] Fetching auth token...");
  final token = await SecureStore.getToken();
  debugPrint(token != null ? "[AuthToken] Token found" : "[AuthToken] No token found");
  return token;
});

final popularFundRepoProvider = Provider<PopularFundRepo>((ref) {
  final repo = PopularFundRepo();
  debugPrint("[PopularFundRepo] Creating repo with base URL from HttpClient");
  return repo;
});

// ============================================================================
// CATEGORIES NOTIFIER
// ============================================================================

class CategoriesNotifier extends StateNotifier<CategoriesState> {
  CategoriesNotifier() : super(const CategoriesState());

  Future<void> fetchCategories(String baseUrl) async {
    state = state.copyWith(isLoading: true);
    debugPrint("[Categories] Fetching categories...");

    try {
      final token = await SecureStore.getToken();
      if (token == null || token.isEmpty) {
        throw Exception("No auth token found");
      }

      final url = Uri.parse('$baseUrl/funds/sub-category');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({"search_term": ""}),
      );

      debugPrint("[Categories] Response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final status = decoded['status'];

        if (status == 1 || status == '1') {
          final dataList = (decoded['data']?['data_list'] as List<dynamic>?) ?? [];
          final categories = [
            {"id": kAllCategoryId, "name": "All"},
            ...dataList.map((e) => {
              "id": e['id'] as int,
              "name": e['name'] as String,
            })
          ];

          state = state.copyWith(
            categories: categories,
            isLoading: false,
            hasError: false,
          );
          debugPrint("[Categories] Loaded: ${categories.length}");
        } else {
          throw Exception(decoded['message'] ?? 'Unknown error loading categories');
        }
      } else {
        throw Exception("HTTP ${response.statusCode}: ${response.reasonPhrase}");
      }
    } catch (e) {
      debugPrint("[Categories] Error: $e");
      state = state.copyWith(
        isLoading: false,
        hasError: true,
        errorMessage: 'Failed to load categories: $e',
      );
    }
  }
}

final categoriesProvider = StateNotifierProvider<CategoriesNotifier, CategoriesState>((ref) {
  return CategoriesNotifier();
});

// ============================================================================
// FILTER NOTIFIER
// ============================================================================

class FilterNotifier extends StateNotifier<FilterState> {
  FilterNotifier() : super(FilterState(appliedFilters: _initializeFilters()));

  static Map<String, Set<String>> _initializeFilters() {
    final filters = <String, Set<String>>{};
    for (var category in AppStrings.filterCategories) {
      filters[category] = {};
    }
    debugPrint("[Filters] Initialized: ${filters.keys}");
    return filters;
  }

  void toggleSubCategory(int categoryId) {
    debugPrint("[Filters] Toggling category: $categoryId");

    // If "All" is already selected and user clicks "All" again, do nothing
    if (categoryId == kAllCategoryId && state.isAllSelected) return;

    if (categoryId == kAllCategoryId) {
      _selectAllCategories();
    } else {
      _toggleSpecificCategory(categoryId);
    }
  }

  void _selectAllCategories() {
    debugPrint("[Filters] Selecting 'All' category");
    final newFilters = Map<String, Set<String>>.from(state.appliedFilters);
    newFilters['Sub Category'] = {};

    state = state.copyWith(
      isAllSelected: true,
      selectedSubCategoryIds: {},
      appliedFilters: newFilters,
    );
  }

  void _toggleSpecificCategory(int categoryId) {
    final newSelectedIds = Set<int>.from(state.selectedSubCategoryIds);
    final newFilters = Map<String, Set<String>>.from(state.appliedFilters);

    newFilters.putIfAbsent('Sub Category', () => {});
    final subCategorySet = Set<String>.from(newFilters['Sub Category']!);

    if (newSelectedIds.contains(categoryId)) {
      debugPrint("[Filters] Removing category: $categoryId");
      newSelectedIds.remove(categoryId);
      subCategorySet.remove(categoryId.toString());
    } else {
      debugPrint("[Filters] Adding category: $categoryId");
      newSelectedIds.add(categoryId);
      subCategorySet.add(categoryId.toString());
    }

    final isAllSelected = newSelectedIds.isEmpty;
    newFilters['Sub Category'] = isAllSelected ? {} : subCategorySet;

    state = state.copyWith(
      isAllSelected: isAllSelected,
      selectedSubCategoryIds: newSelectedIds,
      appliedFilters: newFilters,
    );

    debugPrint("[Filters] Selected categories: ${state.selectedSubCategoryIds}");
    debugPrint("[Filters] Is all selected: ${state.isAllSelected}");
  }

  void applyFilters(Map<String, Set<String>> selectedFilters) {
    debugPrint("[Filters] Applying filters from bottom sheet: $selectedFilters");

    final subCategoryFilters = Set<String>.from(selectedFilters['Sub Category'] ?? {});
    final newSelectedIds = subCategoryFilters
        .map((id) => int.tryParse(id))
        .whereType<int>()
        .toSet();

    state = state.copyWith(
      appliedFilters: Map<String, Set<String>>.from(selectedFilters),
      selectedSubCategoryIds: newSelectedIds,
      isAllSelected: newSelectedIds.isEmpty,
    );

    debugPrint("[Filters] Filters applied: ${state.appliedFilters}");
    debugPrint("[Filters] Selected subcategory IDs: ${state.selectedSubCategoryIds}");
  }

  void clearAllFilters() {
    debugPrint("[Filters] Clearing all filters");
    state = FilterState(appliedFilters: _initializeFilters());
    debugPrint("[Filters] All filters cleared");
  }

  bool isCategorySelected(int categoryId) {
    return categoryId == kAllCategoryId
        ? state.isAllSelected
        : state.selectedSubCategoryIds.contains(categoryId);
  }
}

final filterProvider = StateNotifierProvider<FilterNotifier, FilterState>((ref) {
  return FilterNotifier();
});

// ============================================================================
// FUNDS NOTIFIER
// ============================================================================

class FundsNotifier extends StateNotifier<FundsState> {
  final PopularFundRepo repo;
  final Ref ref;

  FundsNotifier(this.repo, this.ref) : super(const FundsState());

  Future<void> fetchFunds({bool isRefresh = true}) async {
    if (isRefresh) {
      state = state.copyWith(
        isLoadingFunds: true,
        hasError: false,
        errorMessage: '',
        funds: [],
        currentPage: 1,
        hasMoreData: true,
      );
    }

    final filterState = ref.read(filterProvider);
    debugPrint("[Funds] Fetching funds - Page: ${state.currentPage}");
    debugPrint("[Funds] Current filters: ${filterState.appliedFilters}");
    debugPrint("[Funds] Selected subcategories: ${filterState.selectedSubCategoryIds}");

    try {
      final funds = await repo.fetchPopularFunds(
        page: state.currentPage,
        pageSize: kPageSize,
        subCategoryIds: filterState.isAllSelected
            ? null
            : filterState.selectedSubCategoryIds.map((id) => id.toString()).toSet(),
        filters: filterState.appliedFilters,
      );

      final updatedFunds = isRefresh ? funds : [...state.funds, ...funds];
      final hasMoreData = funds.length >= kPageSize;

      state = state.copyWith(
        funds: updatedFunds,
        isLoadingFunds: false,
        hasMoreData: hasMoreData,
      );

      debugPrint("[Funds] Funds loaded: ${funds.length}, Total: ${updatedFunds.length}");
      if (!hasMoreData) debugPrint("[Funds] No more data to load");

    } catch (e) {
      debugPrint("[Funds] Error fetching funds: $e");
      state = state.copyWith(
        hasError: true,
        errorMessage: 'Failed to load funds: $e',
        isLoadingFunds: false,
      );
    }
  }

  Future<void> loadMoreFunds() async {
    if (state.isLoadingMore || !state.hasMoreData) return;

    state = state.copyWith(isLoadingMore: true);
    debugPrint("[Funds] Loading more funds...");

    final filterState = ref.read(filterProvider);

    try {
      final nextPage = state.currentPage + 1;
      final funds = await repo.fetchPopularFunds(
        page: nextPage,
        pageSize: kPageSize,
        subCategoryIds: filterState.isAllSelected
            ? null
            : filterState.selectedSubCategoryIds.map((id) => id.toString()).toSet(),
        filters: filterState.appliedFilters,
      );

      final updatedFunds = [...state.funds, ...funds];
      final hasMoreData = funds.length >= kPageSize;

      state = state.copyWith(
        funds: updatedFunds,
        currentPage: nextPage,
        isLoadingMore: false,
        hasMoreData: hasMoreData,
      );

      debugPrint("[Funds] More funds loaded: ${funds.length}, Total: ${updatedFunds.length}");
      if (!hasMoreData) debugPrint("[Funds] Reached end of data");

    } catch (e) {
      debugPrint("[Funds] Error loading more funds: $e");
      state = state.copyWith(isLoadingMore: false);
    }
  }
}

final fundsProvider = StateNotifierProvider<FundsNotifier, FundsState>((ref) {
  final repo = ref.watch(popularFundRepoProvider);
  return FundsNotifier(repo, ref);
});
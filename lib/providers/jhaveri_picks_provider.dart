import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../core/token_helper.dart';
import '../features/auth/data/models/jhaveri_pick.dart';
import 'jhaveri_picks_repo_provider.dart';
import '../core/utils/logger.dart';

// ============================================================================
// STATE CLASS
// ============================================================================

class JhaveriPicksState {
  final List<JhaveriPick> funds;
  final bool isLoading;
  final bool hasError;
  final String errorMessage;
  final Map<String, Set<String>> appliedFilters;
  final Set<int> selectedSubCategoryIds;

  const JhaveriPicksState({
    this.funds = const [],
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage = '',
    this.appliedFilters = const {},
    this.selectedSubCategoryIds = const {},
  });

  JhaveriPicksState copyWith({
    List<JhaveriPick>? funds,
    bool? isLoading,
    bool? hasError,
    String? errorMessage,
    Map<String, Set<String>>? appliedFilters,
    Set<int>? selectedSubCategoryIds,
  }) {
    return JhaveriPicksState(
      funds: funds ?? this.funds,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      appliedFilters: appliedFilters ?? this.appliedFilters,
      selectedSubCategoryIds: selectedSubCategoryIds ?? this.selectedSubCategoryIds,
    );
  }

  bool get hasAppliedFilters {
    return appliedFilters.values.any((filterSet) => filterSet.isNotEmpty);
  }

  bool get isAllSelected => selectedSubCategoryIds.isEmpty;
}

// ============================================================================
// PROVIDER
// ============================================================================

final jhaveriPicksProvider = StateNotifierProvider<JhaveriPicksNotifier, JhaveriPicksState>((ref) {
  return JhaveriPicksNotifier(ref);
});

// ============================================================================
// NOTIFIER
// ============================================================================

class JhaveriPicksNotifier extends StateNotifier<JhaveriPicksState> {
  final Ref ref;
  String? lastRawApiResponse;

  JhaveriPicksNotifier(this.ref) : super(JhaveriPicksState(
    appliedFilters: _initializeFilters(),
  )) {
    AppLogger.log("[JhaveriPicks] Provider initialized");
  }

  static Map<String, Set<String>> _initializeFilters() {
    return {
      'Fund House': {},
      'Fund Category': {},
      'Sub Category': {},
      'Risk Level': {},
      'Fund Size': {},
    };
  }

  // Toggle specific sub-category
  void toggleSubCategory(int categoryId) {
    debugPrint("[JhaveriPicks] Toggling category: $categoryId");

    if (categoryId == -1) {
      _selectAllCategories();
    } else {
      _toggleSpecificCategory(categoryId);
    }
  }

  void _selectAllCategories() {
    debugPrint("[JhaveriPicks] Selecting 'All' category");
    final newFilters = Map<String, Set<String>>.from(state.appliedFilters);
    newFilters['Sub Category'] = {};

    state = state.copyWith(
      selectedSubCategoryIds: {},
      appliedFilters: newFilters,
    );

    fetchFunds();
  }

  void _toggleSpecificCategory(int categoryId) {
    final newSelectedIds = Set<int>.from(state.selectedSubCategoryIds);
    final newFilters = Map<String, Set<String>>.from(state.appliedFilters);

    newFilters.putIfAbsent('Sub Category', () => {});
    final subCategorySet = Set<String>.from(newFilters['Sub Category']!);

    if (newSelectedIds.contains(categoryId)) {
      debugPrint("[JhaveriPicks] Removing category: $categoryId");
      newSelectedIds.remove(categoryId);
      subCategorySet.remove(categoryId.toString());
    } else {
      debugPrint("[JhaveriPicks] Adding category: $categoryId");
      newSelectedIds.add(categoryId);
      subCategorySet.add(categoryId.toString());
    }

    newFilters['Sub Category'] = subCategorySet;

    state = state.copyWith(
      selectedSubCategoryIds: newSelectedIds,
      appliedFilters: newFilters,
    );

    debugPrint("[JhaveriPicks] Selected categories: ${state.selectedSubCategoryIds}");

    fetchFunds();
  }

  // Apply filters from bottom sheet
  void applyFilters(Map<String, Set<String>> selectedFilters) {
    debugPrint("[JhaveriPicks] Applying filters from bottom sheet: $selectedFilters");

    final subCategoryFilters = Set<String>.from(selectedFilters['Sub Category'] ?? {});
    final newSelectedIds = subCategoryFilters
        .map((id) => int.tryParse(id))
        .whereType<int>()
        .toSet();

    state = state.copyWith(
      appliedFilters: Map<String, Set<String>>.from(selectedFilters),
      selectedSubCategoryIds: newSelectedIds,
    );

    debugPrint("[JhaveriPicks] Filters applied: ${state.appliedFilters}");
    debugPrint("[JhaveriPicks] Selected subcategory IDs: ${state.selectedSubCategoryIds}");

    fetchFunds();
  }

  // Clear all filters
  void clearAllFilters() {
    debugPrint("[JhaveriPicks] Clearing all filters");
    state = JhaveriPicksState(appliedFilters: _initializeFilters());
    debugPrint("[JhaveriPicks] All filters cleared");
    fetchFunds();
  }

  // Check if category is selected
  bool isCategorySelected(int categoryId) {
    return categoryId == -1
        ? state.isAllSelected
        : state.selectedSubCategoryIds.contains(categoryId);
  }

  // Fetch funds with current filters
  Future<void> fetchFunds() async {
    state = state.copyWith(isLoading: true, hasError: false, errorMessage: '');

    debugPrint("[JhaveriPicks] 🔄 Fetching funds...");
    debugPrint("[JhaveriPicks] Current filters: ${state.appliedFilters}");
    debugPrint("[JhaveriPicks] Selected subcategories: ${state.selectedSubCategoryIds}");

    try {
      final token = await TokenHelper.getValidToken();
      if (token == null) {
        debugPrint("[JhaveriPicks] ❌ No valid token found");
        state = state.copyWith(
          isLoading: false,
          hasError: true,
          errorMessage: "AUTH_ERROR",
        );
        return;
      }

      debugPrint("[JhaveriPicks] ✅ Token validated, calling repository...");

      final repo = ref.read(jhaveriPicksRepoProvider);
      final funds = await repo.fetchFundsWithFilters(
        filters: state.appliedFilters,
        page: 1,
        pageSize: 10,
      );

      lastRawApiResponse = repo.lastRawResponse;

      debugPrint("[JhaveriPicks] ✅ Successfully fetched ${funds.length} funds");

      state = state.copyWith(
        funds: funds,
        isLoading: false,
        hasError: false,
        errorMessage: '',
      );
    } catch (e, st) {
      debugPrint("[JhaveriPicks] ❌ Error fetching funds: $e");
      debugPrint("[JhaveriPicks] Stack trace: $st");

      String errorMsg = e.toString();
      if (errorMsg.contains('No valid access token')) {
        errorMsg = 'AUTH_ERROR';
      }

      state = state.copyWith(
        isLoading: false,
        hasError: true,
        errorMessage: errorMsg,
      );
    }
  }
}
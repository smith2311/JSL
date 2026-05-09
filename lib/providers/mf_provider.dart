import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/env.dart';
import '../../../../core/secure_store.dart';
import '../features/auth/data/models/mutual_fund.dart';

class FundsState {
  final List<MutualFund> funds;
  final int currentPage;
  final int totalPages;
  final bool isLoading;
  final String? error;
  final Map<String, dynamic> filters;

  bool get hasMore => currentPage <= totalPages;

  FundsState({
    this.funds = const [],
    this.currentPage = 1,
    this.totalPages = 1,
    this.isLoading = false,
    this.error,
    this.filters = const {},
  });

  FundsState copyWith({
    List<MutualFund>? funds,
    int? currentPage,
    int? totalPages,
    bool? isLoading,
    String? error,
    Map<String, dynamic>? filters,
  }) {
    return FundsState(
      funds: funds ?? this.funds,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      filters: filters ?? this.filters,
    );
  }
}

class FundsNotifier extends StateNotifier<FundsState> {
  FundsNotifier() : super(FundsState());

  bool _fetching = false;

  Future<void> fetchFunds({bool reset = false}) async {
    if (_fetching) return;
    _fetching = true;

    final page = reset ? 1 : state.currentPage;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final token = await SecureStore.getToken();
      if (token == null || token.isEmpty) {
        state = state.copyWith(isLoading: false, error: "Auth required");
        _fetching = false;
        return;
      }

      final response = await http.post(
        Uri.parse("${EnvConfig.apiBaseUrl}/funds/all"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "page": page,
          "page_size": 10,
          "search_term": "",
          "sort_order": "",
          "sort_by": "",
          "filter": state.filters.isNotEmpty
              ? state.filters
              : {
            "amcs": [],
            "fund_category": [],
            "sub_category": [],
            "risk_level": [],
            "fund_size": [],
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 1 && data['data'] != null) {
          final list = (data['data']['data_list'] as List)
              .map((e) => MutualFund.fromJson(e))
              .toList();
          final totalPages = data['data']['total_pages'] ?? 1;

          state = state.copyWith(
            funds: reset ? list : [...state.funds, ...list],
            currentPage: page + 1,
            totalPages: totalPages,
            isLoading: false,
          );
        } else {
          state = state.copyWith(isLoading: false, error: "No data found");
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          error: "Failed to fetch funds (${response.statusCode})",
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }

    _fetching = false;
  }

  Future<void> fetchNextPage() async {
    if (!state.hasMore || state.isLoading) return;
    await fetchFunds(reset: false);
  }

  Future<void> applyFilters(Map<String, dynamic> filters) async {
    state = state.copyWith(filters: filters, currentPage: 1, totalPages: 1);
    await fetchFunds(reset: true);
  }

  Future<void> refreshFunds() async {
    await fetchFunds(reset: true);
  }

  // ✅ NEW: Search funds (server-side search)
  Future<void> searchFunds(String query) async {
    if (query.isEmpty) {
      await fetchFunds(reset: true);
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final token = await SecureStore.getToken();
      if (token == null || token.isEmpty) {
        state = state.copyWith(isLoading: false, error: "Auth required");
        return;
      }

      final response = await http.post(
        Uri.parse("${EnvConfig.apiBaseUrl}/funds/all"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "page": 1,
          "page_size": 50, // return more results at once for search
          "search_term": query,
          "sort_order": "",
          "sort_by": "",
          "filter": state.filters.isNotEmpty
              ? state.filters
              : {
            "amcs": [],
            "fund_category": [],
            "sub_category": [],
            "risk_level": [],
            "fund_size": [],
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 1 && data['data'] != null) {
          final list = (data['data']['data_list'] as List)
              .map((e) => MutualFund.fromJson(e))
              .toList();

          state = state.copyWith(
            funds: list,
            currentPage: 1,
            totalPages: 1,
            isLoading: false,
          );
        } else {
          state = state.copyWith(isLoading: false, error: "No results found");
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          error: "Search failed (${response.statusCode})",
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final fundsProvider =
StateNotifierProvider<FundsNotifier, FundsState>((ref) => FundsNotifier());
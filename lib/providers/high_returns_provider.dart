import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/env.dart';
import '../../../../core/secure_store.dart';
import '../features/auth/data/models/mutual_fund.dart';

class CollectionsCategoryDetailScreens {
  final List<MutualFund> funds;
  final int currentPage;
  final int totalPages;
  final bool isLoading;
  final String? error;
  final Map<String, dynamic> filters;

  bool get hasMore => currentPage <= totalPages;

  CollectionsCategoryDetailScreens({
    this.funds = const [],
    this.currentPage = 1,
    this.totalPages = 1,
    this.isLoading = false,
    this.error,
    this.filters = const {},
  });

  CollectionsCategoryDetailScreens copyWith({
    List<MutualFund>? funds,
    int? currentPage,
    int? totalPages,
    bool? isLoading,
    String? error,
    Map<String, dynamic>? filters,
  }) {
    return CollectionsCategoryDetailScreens(
      funds: funds ?? this.funds,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      filters: filters ?? this.filters,
    );
  }
}

class CollectionsCategoryDetailScreensNotifier extends StateNotifier<CollectionsCategoryDetailScreens> {
  final String category;

  CollectionsCategoryDetailScreensNotifier(this.category) : super(CollectionsCategoryDetailScreens());

  bool _fetching = false;

  String get apiEndpoint => "${EnvConfig.apiBaseUrl}/funds/$category";

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

      // 🔍 Request body
      final requestBody = {
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
      };

      // ✅ DEBUG: Print API call details
      print('═══════════════════════════════════════');
      print('📡 API CALL DETAILS');
      print('═══════════════════════════════════════');
      print('🔗 URL: $apiEndpoint');
      print('📦 Request Body:');
      print(JsonEncoder.withIndent('  ').convert(requestBody));
      print('═══════════════════════════════════════\n');

      final response = await http.post(
        Uri.parse(apiEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      // ✅ DEBUG: Print response details
      print('═══════════════════════════════════════');
      print('📥 API RESPONSE');
      print('═══════════════════════════════════════');
      print('📊 Status Code: ${response.statusCode}');
      print('📄 Response Body:');
      try {
        final jsonResponse = jsonDecode(response.body);
        print(JsonEncoder.withIndent('  ').convert(jsonResponse));
      } catch (e) {
        print(response.body);
      }
      print('═══════════════════════════════════════\n');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 1 && data['data'] != null) {
          final list = (data['data']['data_list'] as List)
              .map((e) => MutualFund.fromJson(e))
              .toList();
          final totalPages = data['data']['total_pages'] ?? 1;

          print('✅ Successfully fetched ${list.length} funds');
          print('📄 Current Page: $page | Total Pages: $totalPages\n');

          state = state.copyWith(
            funds: reset ? list : [...state.funds, ...list],
            currentPage: page + 1,
            totalPages: totalPages,
            isLoading: false,
          );
        } else {
          print('⚠️ No data found in response\n');
          state = state.copyWith(isLoading: false, error: "No data found");
        }
      } else {
        print('❌ API call failed with status ${response.statusCode}\n');
        state = state.copyWith(
          isLoading: false,
          error: "Failed to fetch funds (${response.statusCode})",
        );
      }
    } catch (e) {
      print('❌ Exception occurred: $e\n');
      state = state.copyWith(isLoading: false, error: e.toString());
    }

    _fetching = false;
  }

  Future<void> fetchNextPage() async {
    if (!state.hasMore || state.isLoading) return;
    print('📄 Fetching next page...\n');
    await fetchFunds(reset: false);
  }

  Future<void> applyFilters(Map<String, dynamic> filters) async {
    print('═══════════════════════════════════════');
    print('🔍 APPLYING FILTERS');
    print('═══════════════════════════════════════');
    print(JsonEncoder.withIndent('  ').convert(filters));
    print('═══════════════════════════════════════\n');

    state = state.copyWith(filters: filters, currentPage: 1, totalPages: 1);
    await fetchFunds(reset: true);
  }

  Future<void> refreshFunds() async {
    print('🔄 Refreshing funds...\n');
    await fetchFunds(reset: true);
  }

  Future<void> searchFunds(String query) async {
    print('═══════════════════════════════════════');
    print('🔍 SEARCHING FUNDS');
    print('═══════════════════════════════════════');
    print('Search Query: "$query"');
    print('═══════════════════════════════════════\n');

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

      final requestBody = {
        "page": 1,
        "page_size": 50,
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
      };

      print('🔗 Search URL: $apiEndpoint');
      print('📦 Search Request Body:');
      print(JsonEncoder.withIndent('  ').convert(requestBody));
      print('\n');

      final response = await http.post(
        Uri.parse(apiEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('📥 Search Response Status: ${response.statusCode}\n');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 1 && data['data'] != null) {
          final list = (data['data']['data_list'] as List)
              .map((e) => MutualFund.fromJson(e))
              .toList();

          print('✅ Found ${list.length} results for "$query"\n');

          state = state.copyWith(
            funds: list,
            currentPage: 1,
            totalPages: 1,
            isLoading: false,
          );
        } else {
          print('⚠️ No results found for "$query"\n');
          state = state.copyWith(isLoading: false, error: "No results found");
        }
      } else {
        print('❌ Search failed with status ${response.statusCode}\n');
        state = state.copyWith(
          isLoading: false,
          error: "Search failed (${response.statusCode})",
        );
      }
    } catch (e) {
      print('❌ Search exception: $e\n');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Clear state when navigating away
  void clearState() {
    print('🧹 Clearing state for category: $category\n');
    state = CollectionsCategoryDetailScreens();
  }
}

// Family provider to support multiple categories
final CollectionsCategoryDetailScreensProvider =
StateNotifierProvider.family<CollectionsCategoryDetailScreensNotifier, CollectionsCategoryDetailScreens, String>(
      (ref, category) {
    print('🏗️ Creating provider for category: $category\n');
    return CollectionsCategoryDetailScreensNotifier(category);
  },
);
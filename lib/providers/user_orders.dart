import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:jhaveri_jsl_app/core/config/env.dart';
import '../core/token_helper.dart';

// Orders State
class OrdersState {
  final bool isLoading;
  final List<dynamic> orders;
  final String? error;
  final int currentPage;
  final int totalPages;
  final int totalRecords;
  final bool hasMore;
  final bool isLoadingMore;

  OrdersState({
    this.isLoading = false,
    this.orders = const [],
    this.error,
    this.currentPage = 0,
    this.totalPages = 0,
    this.totalRecords = 0,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  OrdersState copyWith({
    bool? isLoading,
    List<dynamic>? orders,
    String? error,
    int? currentPage,
    int? totalPages,
    int? totalRecords,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return OrdersState(
      isLoading: isLoading ?? this.isLoading,
      orders: orders ?? this.orders,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalRecords: totalRecords ?? this.totalRecords,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

// Orders Notifier
class OrdersNotifier extends StateNotifier<OrdersState> {
  final Ref ref;

  OrdersNotifier(this.ref) : super(OrdersState());

  Future<void> fetchOrders({
    List<int>? clientIds,
    bool refresh = false
  }) async {
    // If refreshing, reset state
    if (refresh) {
      state = OrdersState(isLoading: true);
    } else {
      // If already loading or no more data, don't fetch
      if (state.isLoadingMore || !state.hasMore) return;
      state = state.copyWith(isLoadingMore: true, error: null);
    }

    try {
      // Get valid token using TokenHelper
      final token = await TokenHelper.getValidToken();

      if (token == null) {
        state = state.copyWith(
            isLoading: false,
            isLoadingMore: false,
            error: "Authentication required. Please login again."
        );
        return;
      }

      final nextPage = refresh ? 1 : state.currentPage + 1;
      final url = Uri.parse("${EnvConfig.apiBaseUrl}/orders/list");

      print('📋 Fetching orders - Page: $nextPage, ClientIds: ${clientIds ?? []}');

      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "client_id": clientIds ?? [],
          "page": nextPage,
          "page_size": 10,
          "search_term": "",
          "sort_order": "",
          "sort_by": ""
        }),
      );

      print('📡 Orders response status: ${response.statusCode}');
      print('📦 Orders response body: ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json["status"] == 1) {
          final data = json["data"];
          final newOrders = data["data_list"] as List<dynamic>;
          final totalPages = data["total_pages"] as int;
          final totalRecords = data["total_records"] as int;
          final pageIndex = data["page_index"] as int;

          // Combine old and new orders
          final updatedOrders = refresh
              ? newOrders
              : [...state.orders, ...newOrders];

          final hasMore = pageIndex < totalPages;

          print('✅ Loaded ${newOrders.length} orders. Total: ${updatedOrders.length}/$totalRecords');
          print('📄 Page $pageIndex/$totalPages - HasMore: $hasMore');

          state = state.copyWith(
            isLoading: false,
            isLoadingMore: false,
            orders: updatedOrders,
            currentPage: pageIndex,
            totalPages: totalPages,
            totalRecords: totalRecords,
            hasMore: hasMore,
          );
        } else {
          state = state.copyWith(
              isLoading: false,
              isLoadingMore: false,
              error: json["message"] ?? "Failed to fetch orders"
          );
        }
      } else if (response.statusCode == 401) {
        state = state.copyWith(
            isLoading: false,
            isLoadingMore: false,
            error: "Session expired. Please login again."
        );
      } else {
        state = state.copyWith(
            isLoading: false,
            isLoadingMore: false,
            error: "Failed to fetch orders: ${response.statusCode}"
        );
      }
    } catch (e) {
      print('❌ Error fetching orders: $e');
      state = state.copyWith(
          isLoading: false,
          isLoadingMore: false,
          error: e.toString()
      );
    }
  }

  void reset() {
    state = OrdersState();
  }
}

// Riverpod provider
final ordersProvider =
StateNotifierProvider<OrdersNotifier, OrdersState>((ref) {
  return OrdersNotifier(ref);
});
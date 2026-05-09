import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../core/token_helper.dart';
import '../core/config/env.dart';

// ======================
// SIP HEADER DETAILS
// ======================

class SipDetails {
  final double totalSipAmount;
  final int activeSips;

  SipDetails({required this.totalSipAmount, required this.activeSips});

  factory SipDetails.fromJson(Map<String, dynamic> json, int subTab) {
    double amount = (json['amount'] ?? 0).toDouble();
    int active;

    if (subTab == 0) {
      active = json['active_sip'] ?? 0;
    } else if (subTab == 1) {
      active = json['active_swp'] ?? 0;
    } else {
      active = json['active_stp'] ?? 0;
    }

    return SipDetails(
      totalSipAmount: amount,
      activeSips: active,
    );
  }
}

final sipDetailsProvider =
StateNotifierProvider<SipDetailsNotifier, AsyncValue<SipDetails>>(
      (ref) => SipDetailsNotifier(),
);

class SipDetailsNotifier extends StateNotifier<AsyncValue<SipDetails>> {
  SipDetailsNotifier() : super(const AsyncValue.loading());

  Future<void> fetchSipDetails(int subTab, {List<int>? clientIds}) async {
    try {
      state = const AsyncValue.loading();

      final token = await TokenHelper.getValidToken();
      if (token == null) throw Exception('No valid token found');

      String endpoint;
      if (subTab == 0) {
        endpoint = '/portfolio/sip/other-details';
      } else if (subTab == 1) {
        endpoint = '/portfolio/swp/other-details';
      } else {
        endpoint = '/portfolio/stp/other-details';
      }

      final response = await http.post(
        Uri.parse('${EnvConfig.apiBaseUrl}$endpoint'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "client_id": clientIds ?? [],
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['status'] == 1) {
          final sipDetails = SipDetails.fromJson(body['data'], subTab);
          state = AsyncValue.data(sipDetails);
        } else {
          state = AsyncValue.error(
            body['message'] ?? 'Failed to fetch data',
            StackTrace.current,
          );
        }
      } else {
        state = AsyncValue.error(
          'HTTP error: ${response.statusCode}',
          StackTrace.current,
        );
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// ======================
// SIP FUND LIST
// ======================

class SipFundItem {
  final int fundId;
  final String fundName;
  final String fundCategory;
  final String fundSubCategory;
  final double amount;
  final String frequency;
  final String nextDate;
  final String folioNo;
  final String id;
  final String clientName;

  SipFundItem({
    required this.fundId,
    required this.fundName,
    required this.fundCategory,
    required this.fundSubCategory,
    required this.amount,
    required this.frequency,
    required this.nextDate,
    required this.folioNo,
    required this.id,
    required this.clientName,
  });

  factory SipFundItem.fromJson(Map<String, dynamic> json, int subTab) {
    String nextDateKey;
    String idKey;

    if (subTab == 0) {
      nextDateKey = 'next_installment_date';
      idKey = 'sip_id';
    } else if (subTab == 1) {
      nextDateKey = 'next_withdrawal_date';
      idKey = 'swp_id';
    } else {
      nextDateKey = 'next_transfer_date';
      idKey = 'stp_id';
    }

    return SipFundItem(
      fundId: json['fund_id'] ?? 0,
      fundName: json['fund_name'] ?? '',
      fundCategory: json['fund_category'] ?? '',
      fundSubCategory: json['fund_sub_category'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      frequency: json['frequency'] ?? '',
      nextDate: json[nextDateKey] ?? '',
      folioNo: json['folio_no'] ?? '',
      id: json[idKey]?.toString() ?? '',
      clientName: json['client_name'] ?? '',
    );
  }
}

class SipListState {
  final List<SipFundItem> items;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? error;

  SipListState({
    required this.items,
    required this.isLoading,
    required this.hasMore,
    required this.currentPage,
    this.error,
  });

  SipListState copyWith({
    List<SipFundItem>? items,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return SipListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error ?? this.error,
    );
  }
}

final sipListProvider =
StateNotifierProvider.family<SipListNotifier, SipListState, int>(
      (ref, subTab) => SipListNotifier(subTab),
);

class SipListNotifier extends StateNotifier<SipListState> {
  final int subTab;

  // Store current filter parameters
  List<int>? _currentClientIds;
  String _currentSearchTerm = '';
  String _currentSortBy = '';
  String _currentSortOrder = '';
  List<String> _currentAmcs = [];
  List<String> _currentFundCategory = [];
  List<String> _currentSubCategory = [];

  SipListNotifier(this.subTab)
      : super(SipListState(
    items: [],
    isLoading: false,
    hasMore: true,
    currentPage: 0,
  ));

  String _getEndpoint() {
    if (subTab == 0) return '/portfolio/sip/list';
    if (subTab == 1) return '/portfolio/swp/list';
    return '/portfolio/stp/list';
  }

  Future<void> fetchList({
    bool refresh = false,
    List<int>? clientIds,
    String searchTerm = '',
    String sortBy = '',
    String sortOrder = '',
    List<String> amcs = const [],
    List<String> fundCategory = const [],
    List<String> subCategory = const [],
  }) async {
    if (state.isLoading) return;
    if (!refresh && !state.hasMore) return;

    // Store current parameters
    if (refresh) {
      _currentClientIds = clientIds;
      _currentSearchTerm = searchTerm;
      _currentSortBy = sortBy;
      _currentSortOrder = sortOrder;
      _currentAmcs = amcs;
      _currentFundCategory = fundCategory;
      _currentSubCategory = subCategory;
    }

    try {
      state = state.copyWith(isLoading: true, error: null);

      final token = await TokenHelper.getValidToken();
      if (token == null) throw Exception('No valid token found');

      final nextPage = refresh ? 1 : state.currentPage + 1;

      final response = await http.post(
        Uri.parse('${EnvConfig.apiBaseUrl}${_getEndpoint()}'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "client_id": _currentClientIds ?? [],
          "page": nextPage,
          "page_size": 10,
          "search_term": _currentSearchTerm,
          "sort_order": _currentSortOrder,
          "sort_by": _currentSortBy,
          "filter": {
            "amcs": _currentAmcs,
            "fund_category": _currentFundCategory,
            "sub_category": _currentSubCategory,
          },
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);

        if (body['status'] == 1) {
          final data = body['data'];
          final List<dynamic> dataList = data['data_list'] ?? [];

          final newItems = dataList
              .map((json) => SipFundItem.fromJson(json, subTab))
              .toList();

          final totalPages = data['total_pages'] ?? 1;
          final hasMore = nextPage < totalPages;

          if (refresh) {
            state = SipListState(
              items: newItems,
              isLoading: false,
              hasMore: hasMore,
              currentPage: nextPage,
            );
          } else {
            state = state.copyWith(
              items: [...state.items, ...newItems],
              isLoading: false,
              hasMore: hasMore,
              currentPage: nextPage,
            );
          }
        } else {
          state = state.copyWith(
            isLoading: false,
            error: body['message'] ?? 'Failed to fetch list',
          );
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'HTTP error: ${response.statusCode}',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void reset() {
    state = SipListState(
      items: [],
      isLoading: false,
      hasMore: true,
      currentPage: 0,
    );
    _currentClientIds = null;
    _currentSearchTerm = '';
    _currentSortBy = '';
    _currentSortOrder = '';
    _currentAmcs = [];
    _currentFundCategory = [];
    _currentSubCategory = [];
  }
}
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../core/token_helper.dart';
import '../core/config/env.dart';

// -------------------
// Model
// -------------------
class SipFundItem {
  final int fundId;
  final String fundName;
  final String fundCategory;
  final String fundSubCategory;
  final double amount;
  final String frequency;
  final String nextDate; // Can be installment, withdrawal, or transfer date
  final String folioNo;
  final String id; // Can be sip_id, swp_id, or stp_id

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
      nextDateKey = 'next_withdrawal_date';
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

// -------------------
// Provider
// -------------------
final sipListProvider = StateNotifierProvider.family<SipListNotifier, SipListState, int>(
      (ref, subTab) => SipListNotifier(subTab),
);

class SipListNotifier extends StateNotifier<SipListState> {
  final int subTab; // 0=SIP, 1=SWP, 2=STP

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

  Future<void> fetchList({bool refresh = false}) async {
    if (state.isLoading) return;
    if (!refresh && !state.hasMore) return;

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
          "page": nextPage,
          "page_size": 10,
          "search_term": "",
          "sort_order": "",
          "sort_by": "",
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
  }
}
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../core/config/env.dart';
import '../core/token_helper.dart';
import '../features/funds/data/models/fund_details_models.dart';

// ------------------- NAV DATA POINT MODEL -------------------
class NavDataPoint {
  final String date;
  final double nav;

  NavDataPoint({required this.date, required this.nav});

  factory NavDataPoint.fromJson(Map<String, dynamic> json) {
    return NavDataPoint(
      date: json['date'] ?? '',
      nav: (json['nav'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// ------------------- NAV HISTORY MODEL -------------------
class NavHistoryModel {
  final String fundName;
  final String period;
  final double returns;
  final List<NavDataPoint> navList;
  final CategoryReturns? categoryReturns;

  NavHistoryModel({
    required this.fundName,
    required this.period,
    required this.returns,
    required this.navList,
    this.categoryReturns,
  });

  factory NavHistoryModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'];

    // Parse nav_list
    List<NavDataPoint> navList = [];
    if (data['nav_list'] != null && data['nav_list'] is List) {
      navList = (data['nav_list'] as List)
          .map((item) => NavDataPoint.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    // Parse category_returns if available
    CategoryReturns? categoryReturns;
    if (data['category_returns'] != null) {
      categoryReturns = CategoryReturns.fromJson(
          data['category_returns'] as Map<String, dynamic>
      );
    }

    return NavHistoryModel(
      fundName: data['fund_name'] ?? '',
      period: data['period'] ?? '',
      returns: (data['returns'] as num?)?.toDouble() ?? 0.0,
      navList: navList,
      categoryReturns: categoryReturns,
    );
  }
}

// ------------------- NOTIFIER -------------------
class NavHistoryNotifier extends StateNotifier<AsyncValue<NavHistoryModel?>> {
  NavHistoryNotifier() : super(const AsyncValue.data(null));

  Future<void> fetchNavHistory(int fundId, {String period = '3Y'}) async {
    state = const AsyncValue.loading();
    try {
      final token = await TokenHelper.getValidToken();
      if (token == null) throw Exception("No valid access token");

      final response = await http.post(
        Uri.parse('${EnvConfig.apiBaseUrl}/nav/nav-history'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'fund_id': fundId, 'period': period}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 1) {
          state = AsyncValue.data(NavHistoryModel.fromJson(data));
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch NAV history');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: Failed to load NAV history');
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// ------------------- PROVIDER -------------------
final navHistoryProvider =
StateNotifierProvider<NavHistoryNotifier, AsyncValue<NavHistoryModel?>>(
        (ref) => NavHistoryNotifier());
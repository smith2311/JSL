import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../core/config/env.dart';
import '../core/token_helper.dart';

// ------------------- FUND INFO MODEL -------------------
class FundInfoModel {
  final double nav;
  final String navDate;
  final String fundName;
  final String fundCategory;
  final String fundSubCategory;
  final double rating;
  final double returns;
  final List<FundInfoItem> fundInfo;

  FundInfoModel({
    required this.nav,
    required this.navDate,
    required this.fundName,
    required this.fundCategory,
    required this.fundSubCategory,
    required this.rating,
    required this.returns,
    required this.fundInfo,
  });

  factory FundInfoModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final otherDetails = data['other_details'];

    final fundInfoList = (data['fund_info'] as List?)
        ?.map((item) => FundInfoItem.fromJson(item))
        .toList() ??
        [];

    final double returnsValue = (data['returns'] as num?)?.toDouble() ?? 0.0;

    return FundInfoModel(
      nav: (otherDetails['nav'] as num?)?.toDouble() ?? 0.0,
      navDate: otherDetails['nav_date'] ?? '',
      fundName: otherDetails['fund_name'] ?? '',
      fundCategory: otherDetails['fund_category'] ?? '',
      fundSubCategory: otherDetails['fund_sub_category'] ?? '',
      rating: (otherDetails['rating'] as num?)?.toDouble() ?? 0.0,
      returns: returnsValue,
      fundInfo: fundInfoList,
    );
  }
}

class FundInfoItem {
  final String label;
  final dynamic value;

  FundInfoItem({required this.label, required this.value});

  factory FundInfoItem.fromJson(Map<String, dynamic> json) {
    return FundInfoItem(
      label: json['label'] ?? '',
      value: json['value'],
    );
  }
}

class FundInfoNotifier extends StateNotifier<AsyncValue<FundInfoModel?>> {
  FundInfoNotifier() : super(const AsyncValue.data(null));

  Future<void> fetchFundInfo(int fundId) async {
    state = const AsyncValue.loading();
    try {
      final token = await TokenHelper.getValidToken();
      if (token == null) throw Exception("No valid access token");

      final response = await http.post(
        Uri.parse('${EnvConfig.apiBaseUrl}/funds/info'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'fund_id': fundId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 1) {
          state = AsyncValue.data(FundInfoModel.fromJson(data));
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch fund info');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: Failed to load fund info');
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final fundInfoProvider =
StateNotifierProvider<FundInfoNotifier, AsyncValue<FundInfoModel?>>(
        (ref) => FundInfoNotifier());
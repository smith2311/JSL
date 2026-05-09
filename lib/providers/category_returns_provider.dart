// File: lib/features/funds/providers/category_returns_provider.dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../core/config/env.dart';
import '../../core/token_helper.dart';

// Model for category returns
class CategoryReturnsModel {
  final double min;
  final double max;

  CategoryReturnsModel({required this.min, required this.max});

  factory CategoryReturnsModel.fromJson(Map<String, dynamic> json) {
    return CategoryReturnsModel(
      min: (json['min'] as num).toDouble(),
      max: (json['max'] as num).toDouble(),
    );
  }
}

// StateNotifier to fetch and hold data
class CategoryReturnsNotifier
    extends StateNotifier<AsyncValue<CategoryReturnsModel?>> {
  CategoryReturnsNotifier() : super(const AsyncValue.loading());

  Future<void> fetchCategoryReturns(int fundId) async {
    state = const AsyncValue.loading();
    try {
      final token = await TokenHelper.getValidToken();
      if (token == null) throw Exception("No valid token");

      final response = await http.post(
        Uri.parse('${EnvConfig.apiBaseUrl}/nav/nav-history'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'fund_id': fundId,
          'period': '3y', // fixed period as per your requirement
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 1) {
          final categoryReturns =
          CategoryReturnsModel.fromJson(data['data']['category_returns']);
          state = AsyncValue.data(categoryReturns);
        } else {
          throw Exception(data['message'] ?? "Failed to fetch data");
        }
      } else {
        throw Exception(
            "HTTP ${response.statusCode}: Failed to fetch category returns");
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// Riverpod provider
final categoryReturnsProvider = StateNotifierProvider<
    CategoryReturnsNotifier, AsyncValue<CategoryReturnsModel?>>(
      (ref) => CategoryReturnsNotifier(),
);
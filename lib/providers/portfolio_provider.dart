import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../core/config/env.dart';
import '../core/token_helper.dart';
import '../features/auth/data/models/portfolio.dart';

/// Portfolio Provider
final portfolioProvider =
StateNotifierProvider<PortfolioNotifier, AsyncValue<PortfolioModel>>(
      (ref) => PortfolioNotifier(),
);

/// XIRR Provider
final xirrProvider =
StateNotifierProvider<XirrNotifier, AsyncValue<double>>(
      (ref) => XirrNotifier(),
);

class PortfolioNotifier extends StateNotifier<AsyncValue<PortfolioModel>> {
  PortfolioNotifier() : super(const AsyncValue.loading());

  Future<void> fetchPortfolio({List<int>? clientIds}) async {
    state = const AsyncValue.loading();
    try {
      final token = await TokenHelper.getValidToken();
      if (token == null) throw Exception("No valid token");

      final response = await http.post(
        Uri.parse('${EnvConfig.apiBaseUrl}/home/portfolio'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"client_id": clientIds ?? []}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 1) {
          state = AsyncValue.data(PortfolioModel.fromJson(data['data']));
        } else {
          throw Exception(data['message'] ?? "Failed to fetch portfolio");
        }
      } else {
        throw Exception("HTTP error: ${response.statusCode}");
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

class XirrNotifier extends StateNotifier<AsyncValue<double>> {
  XirrNotifier() : super(const AsyncValue.loading());

  Future<void> fetchXirr({List<int>? clientIds}) async {
    state = const AsyncValue.loading();
    try {
      final token = await TokenHelper.getValidToken();
      if (token == null) throw Exception("No valid token");

      final response = await http.post(
        Uri.parse('${EnvConfig.apiBaseUrl}/home/portfolio-xirr'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"client_id": clientIds ?? []}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final xirr = (data['data']['xirr'] ?? 0).toDouble();
        state = AsyncValue.data(xirr);
      } else {
        throw Exception("HTTP error: ${response.statusCode}");
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/env.dart';
import '../../../core/token_helper.dart';
import '../features/funds/data/models/fund_details_models.dart';

// ✅ Provider for holding summary
final holdingSummaryProvider =
FutureProvider.family<HoldingSummary, int>((ref, fundId) async {
  final token = await TokenHelper.getValidToken();
  if (token == null) throw Exception("No valid token");

  final response = await http.post(
    Uri.parse('${EnvConfig.apiBaseUrl}/funds/holding-summary'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({'fund_id': fundId}),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['status'] == 1 && data['data'] != null) {
      return HoldingSummary.fromJson(data['data']);
    } else {
      throw Exception("Invalid API response: ${data['message']}");
    }
  } else {
    throw Exception('Failed to fetch holding summary');
  }
});
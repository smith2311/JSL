import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jhaveri_jsl_app/core/config/env.dart';
import 'package:jhaveri_jsl_app/core/secure_store.dart';
import '../../../auth/data/models/jhaveri_pick.dart';

class NfoFundsRepo {
  final String baseUrl;
  final _secureStorage = const FlutterSecureStorage();

  NfoFundsRepo({String? baseUrl})
      : baseUrl = EnvConfig.apiBaseUrl;

  Future<List<JhaveriPick>> fetchNfoFunds({
    int page = 1,
    int pageSize = 10,
    String? category,
  }) async {
    final url = Uri.parse('$baseUrl/funds/all');

    String? token = await SecureStore.getToken();
    token ??= await _secureStorage.read(key: 'auth_token');
    if (token == null || token.isEmpty) {
      throw Exception("No auth token found in secure storage");
    }

    // ✅ If no category/filters → default fetch ALL funds
    final body = {
      "page": page,
      "page_size": pageSize,
      "sub_category": category ?? "all", // <-- API expects "all"
    };

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonRes = jsonDecode(response.body);

      if (jsonRes['status'] == 1 && jsonRes['data'] != null) {
        final List<dynamic> list = jsonRes['data']['data_list'] ?? [];
        return list.map((json) => JhaveriPick.fromJson(json)).toList();
      } else {
        throw Exception(jsonRes['message'] ?? "Unknown error");
      }
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please log in again.');
    } else {
      throw Exception(
        'Server error: ${response.statusCode} → ${response.reasonPhrase}',
      );
    }
  }
}
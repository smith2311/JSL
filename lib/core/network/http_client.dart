import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jhaveri_jsl_app/core/config/env.dart';
import '../secure_store.dart';

class HttpClient {
  final String _baseUrl = EnvConfig.apiBaseUrl;

  String get baseUrl => _baseUrl;

  /// 🔹 POST request
  Future<Map<String, dynamic>> post(
      String endpoint, {
        Map<String, dynamic>? body,
        Map<String, String>? headers,
      }) async {
    final token = await _getValidToken();
    final uri = Uri.parse("$_baseUrl$endpoint");

    final response = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
        ...?headers,
      },
      body: body != null ? jsonEncode(body) : null,
    );

    return _handleResponse(response);
  }

  /// 🔹 GET request
  Future<Map<String, dynamic>> get(
      String endpoint, {
        Map<String, String>? headers,
      }) async {
    final token = await _getValidToken();
    final uri = Uri.parse("$_baseUrl$endpoint");

    final response = await http.get(
      uri,
      headers: {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
        ...?headers,
      },
    );

    return _handleResponse(response);
  }

  /// 🔹 Get valid token from storage
  Future<String?> _getValidToken() async {
    final tokenData = await SecureStore.getTokenData();
    if (tokenData == null) return null;

    final expired = await SecureStore.isTokenExpired();
    if (expired) {
      await SecureStore.clearTokens();
      print("Token expired, cleared storage.");
      return null;
    }

    return tokenData.accessToken;
  }

  /// 🔹 Handle HTTP responses
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception("Unauthorized: Token may be expired.");
    } else {
      throw Exception(
        "HTTP ${response.statusCode}: ${response.body}",
      );
    }
  }
}
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:jhaveri_jsl_app/core/token_helper.dart';

class ApiClient {
  static final String _baseUrl = dotenv.env['API_BASE_URL'] ?? '';

  /// Generic GET request
  static Future<http.Response> get(String endpoint) async {
    final token = await TokenHelper.getValidToken();
    if (token == null) throw Exception("No valid access token. Please login again.");

    final url = Uri.parse('$_baseUrl$endpoint');
    return await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }

  /// Generic POST request
  static Future<http.Response> post(String endpoint, {Map<String, dynamic>? body}) async {
    final token = await TokenHelper.getValidToken();
    if (token == null) throw Exception("No valid access token. Please login again.");

    final url = Uri.parse('$_baseUrl$endpoint');
    return await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body != null ? jsonEncode(body) : null,
    );
  }

  /// Generic PUT request
  static Future<http.Response> put(String endpoint, {Map<String, dynamic>? body}) async {
    final token = await TokenHelper.getValidToken();
    if (token == null) throw Exception("No valid access token. Please login again.");

    final url = Uri.parse('$_baseUrl$endpoint');
    return await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body != null ? jsonEncode(body) : null,
    );
  }

  /// Generic DELETE request
  static Future<http.Response> delete(String endpoint) async {
    final token = await TokenHelper.getValidToken();
    if (token == null) throw Exception("No valid access token. Please login again.");

    final url = Uri.parse('$_baseUrl$endpoint');
    return await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }
}
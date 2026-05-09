import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jhaveri_jsl_app/core/config/env.dart';
import 'package:jhaveri_jsl_app/core/token_helper.dart';
import '../features/auth/data/models/request_services.dart';

final selectedServiceIndexProvider = StateProvider<int?>((ref) => null);

final formDataProvider = StateProvider.family<RequestServiceFormData, int>(
      (ref, index) => RequestServiceFormData(),
);

final timeSlotsProvider = FutureProvider<List<String>>((ref) async {
  try {
    print('🔄 Fetching time slots...');

    final baseUrl = EnvConfig.apiBaseUrl;
    final url = Uri.parse('$baseUrl/request-services/time-slots');
    final token = await TokenHelper.getValidToken(); // ✅ fetch valid access token
    if (token == null) {
      print('❌ No valid token found. User must login again.');
      throw Exception('Authentication required');
    }

    print('📍 URL: $url');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        // Add your auth headers here if needed
         'Authorization': 'Bearer ${token}',
      },
    );

    print('✅ Response received: ${response.statusCode}');
    print('📦 Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['status'] == 1 && data['data'] is List) {
        final slots = List<String>.from(data['data']);
        print('✅ Time slots loaded: ${slots.length} slots');
        return slots;
      } else {
        final errorMsg = data['message'] ?? 'Invalid response format';
        print('❌ API Error: $errorMsg');
        throw Exception(errorMsg);
      }
    } else {
      print('❌ HTTP Error: Status ${response.statusCode}');
      print('❌ Response body: ${response.body}');
      throw Exception('Server returned status ${response.statusCode}');
    }
  } catch (e, stackTrace) {
    print('❌ Error fetching time slots: $e');
    print('📍 Stack trace: $stackTrace');
    rethrow;
  }
});

final isSubmittingProvider = StateProvider<bool>((ref) => false);

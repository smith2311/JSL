import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jhaveri_jsl_app/core/config/env.dart';
import '../models/switch_fund.dart';
import '../models/switch_detail.dart';
import '../../../../core/secure_store.dart';

class StpRepository {
  // Fetch STP funds list
  Future<SwitchFundsListResponse> fetchStpFunds({
    required int fundId,
    int page = 1,
    int pageSize = 10,
    String searchTerm = '',
  }) async {
    try {
      final token = await SecureStore.getToken();
      if (token == null) throw Exception('No auth token found');

      final url = Uri.parse('${EnvConfig.apiBaseUrl}/portfolio/switch/list');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'fund_id': fundId,
          'page': page,
          'page_size': pageSize,
          'search_term': searchTerm,
          'sort_order': '',
          'sort_by': '',
        }),
      );

      print('📡 STP Funds API Response: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['status'] == 1) {
          // ✅ FIX: Pass the 'data' object directly to fromJson
          // The API structure is: {"status":1, "message":"...", "data": {...}}
          final data = jsonData['data'];

          if (data == null) {
            throw Exception('Data object is null in API response');
          }

          print('✅ Parsing STP funds data...');
          return SwitchFundsListResponse.fromJson(data);
        } else {
          throw Exception(jsonData['message'] ?? 'Failed to fetch STP funds');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('❌ Error fetching STP funds: $e');
      print('📚 Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Fetch frequencies for STP
  Future<List<String>> fetchFrequencies({
    required int fundId,
    required String transactionType,
  }) async {
    try {
      final token = await SecureStore.getToken();
      if (token == null) throw Exception('No auth token found');

      final url = Uri.parse('${EnvConfig.apiBaseUrl}/mf-buy/frequency-list');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'fund_id': fundId,
          'transaction_type': transactionType,
        }),
      );

      print('📡 Frequencies API Response: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 1) {
          final dataList = data['data']['data_list'] as List;
          return dataList.map((e) => e.toString()).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch frequencies');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching frequencies: $e');
      rethrow;
    }
  }

  // Fetch scheme constraints for STP
  Future<SchemeConstraint> fetchSchemeConstraints({
    required int fundId,
    required String orderType,
    required String transactionType,
    required String frequency,
  }) async {
    try {
      final token = await SecureStore.getToken();
      if (token == null) throw Exception('No auth token found');

      final url = Uri.parse('${EnvConfig.apiBaseUrl}/mf-buy/scheme-constraint');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'fund_id': fundId,
          'order_type': orderType,
          'transaction_type': transactionType,
          'frequency': frequency,
        }),
      );

      print('📡 Scheme Constraints API Response: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 1) {
          return SchemeConstraint.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch constraints');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching scheme constraints: $e');
      rethrow;
    }
  }

  // Submit STP order
  Future<Map<String, dynamic>> submitStp({
    required int fundIdFrom,
    required int fundIdTo,
    required String folioNo,
    required double amount,
    required String frequency,
    required String stpDate,
    required int noOfInstallments,
    required String bseClientId,
    required bool firstOrder,
    required String transferBy,
  }) async {
    try {
      final token = await SecureStore.getToken();
      if (token == null) throw Exception('No auth token found');

      final url = Uri.parse('${EnvConfig.apiBaseUrl}/portfolio/stp/confirm');

      final payload = {
        'fund_id_from': fundIdFrom,
        'fund_id_to': fundIdTo,
        'folio_no': folioNo,
        'amount': amount,
        'frequency': frequency,
        'stp_date': stpDate,
        'no_of_installments': noOfInstallments,
        'bse_client_id': bseClientId,
        'first_order': firstOrder,
        'transfer_by': transferBy,
      };

      print('📡 Submitting STP order...');
      print('📤 Payload: ${jsonEncode(payload)}');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      print('📡 STP Submit API Response: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 1) {
          return {
            'success': true,
            'message': data['message'],
            'order_id': data['data']['order_id'],
          };
        } else {
          throw Exception(data['message'] ?? 'Failed to submit STP');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error submitting STP: $e');
      rethrow;
    }
  }
}
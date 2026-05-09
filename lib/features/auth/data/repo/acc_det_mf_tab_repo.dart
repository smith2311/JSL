import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/env.dart';
import '../../../../core/secure_store.dart';

class MutualFundDetails {
  final String name;
  final String dateOfBirth;
  final String email;
  final String mobile;
  final String holdingPattern;
  final String panNo;
  final String taxStatus;

  MutualFundDetails({
    required this.name,
    required this.dateOfBirth,
    required this.email,
    required this.mobile,
    required this.holdingPattern,
    required this.panNo,
    required this.taxStatus,
  });

  factory MutualFundDetails.fromJson(Map<String, dynamic> json) {
    return MutualFundDetails(
      name: json['client_name'] ?? '',  // Changed from 'name'
      dateOfBirth: json['dob'] ?? '',   // Changed from 'date_of_birth'
      email: json['email'] ?? '',
      mobile: json['mobile'] ?? '',
      holdingPattern: json['holding_pattern'] ?? '',
      panNo: json['pan_no'] ?? '',
      taxStatus: json['tax_status'] ?? '',
    );
  }
}

class MutualFundDetailsRepository {
  static final String baseUrl = EnvConfig.apiBaseUrl;

  Future<MutualFundDetails> fetchMutualFundDetails(String bseClientId) async {
    try {
      final token = await SecureStore.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      // Fixed endpoint URL
      final response = await http.post(
        Uri.parse('$baseUrl/profile/account/details'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'bse_client_id': bseClientId,
        }),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 1) {
          return MutualFundDetails.fromJson(jsonData['data']);
        } else {
          throw Exception(jsonData['message'] ?? 'Failed to fetch mutual fund details');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else {
        throw Exception('Failed to fetch details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching mutual fund details: $e');
    }
  }
}
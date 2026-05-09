import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jhaveri_jsl_app/core/config/env.dart';
import 'package:jhaveri_jsl_app/features/auth/data/models/account_details.dart';
import '../../../../core/secure_store.dart';

class AccountDetailsRepository {
  static final String baseUrl = EnvConfig.apiBaseUrl;

  /// Fetch profile details for a specific client
  Future<AccountDetails> fetchProfile(int clientId) async {
    try {
      final token = await SecureStore.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/profile/details'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'client_id': clientId,
        }),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 1) {
          final data = jsonData['data'];

          return AccountDetails(
            clientId: clientId,
            clientName: data['name'] ?? '',
            gender: data['gender'],
            groupCode: data['group_code'],
            customerType: data['customer_type'],
            panNumber: data['pan_no'],
            mobile: data['mobile_no'],
            emailId: data['email'],
            rmName: data['rm_name'],
            rmMobile: data['rm_mobile_no'],
            rmEmail: data['rm_email'],
            bseClientId: null, // Not in this API response
            kycStatus: null,
            accountType: null,
            familyMembers: null,
          );
        } else {
          throw Exception(jsonData['message'] ?? 'Failed to fetch profile');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else {
        throw Exception('Failed to fetch profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching profile: $e');
    }
  }
}


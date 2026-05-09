import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/config/env.dart';
import '../../../../core/token_helper.dart';
import '../models/family_member.dart';

class FamilyMemberRepository {
  Future<List<FamilyMember>> fetchFamilyMembers() async {
    final token = await TokenHelper.getValidToken();
    if (token == null) throw Exception("No valid token");

    final response = await http.post(
      Uri.parse('${EnvConfig.apiBaseUrl}/home/clients-list'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "is_all": false,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 1) {
        final list = data['data']['data_list'] as List;
        return list.map((e) => FamilyMember.fromJson(e)).toList();
      } else {
        throw Exception(data['message'] ?? "Failed to fetch family members");
      }
    } else {
      throw Exception("HTTP error: ${response.statusCode}");
    }
  }
}
import 'dart:convert';
import 'dart:developer' as developer; // For detailed logging
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:jhaveri_jsl_app/core/config/env.dart';
import 'package:jhaveri_jsl_app/core/secure_store.dart';
import '../features/auth/data/models/nominee_centre.dart';
import 'package:jhaveri_jsl_app/constants/strings.dart'; // Needed for AppStrings reference

// ✅ Debug function to inspect Nominee parsing
void debugNomineeParsing(Map<String, dynamic> json) {
  print('═══════════════════════════════════════');
  print('🔍 DEBUG: Parsing Nominee Data');
  print('═══════════════════════════════════════');

  // Check all fields from API
  print('📥 Raw API Data:');
  json.forEach((key, value) {
    print('   $key: $value (${value.runtimeType})');
  });

  print('\n📊 Percentage Field Check:');
  print('   allocation_percent: ${json['allocation_percent']}');
  print('   Type: ${json['allocation_percent']?.runtimeType}');

  if (json['allocation_percent'] != null) {
    final rawValue = json['allocation_percent'];
    print('   Converting to double...');

    if (rawValue is int) {
      print('   ✅ It\'s an int: ${rawValue.toDouble()}');
    } else if (rawValue is double) {
      print('   ✅ It\'s already a double: $rawValue');
    } else {
      final parsed = double.tryParse(rawValue.toString());
      print('   ✅ Parsed from string: $parsed');
    }
  }

  print('\n🔗 Relation Field Check:');
  print('   relation: ${json['relation']}');
  print('   Is it a key or label? Checking...');

  final matchingKey = AppStrings.relationOptions.firstWhere(
        (r) => r['value'] == json['relation'],
    orElse: () => {},
  );

  final matchingLabel = AppStrings.relationOptions.firstWhere(
        (r) => r['label'] == json['relation'],
    orElse: () => {},
  );

  if (matchingKey.isNotEmpty) {
    print('   ✅ Found as KEY: ${matchingKey['value']} -> ${matchingKey['label']}');
  } else if (matchingLabel.isNotEmpty) {
    print('   ✅ Found as LABEL: ${matchingLabel['label']} (key: ${matchingLabel['value']})');
  } else {
    print('   ❌ NOT FOUND in relationOptions!');
  }

  print('\n🌍 Country Field Check:');
  print('   country: ${json['country']}');

  final matchingCountryKey = AppStrings.countryOptions.firstWhere(
        (c) => c['value'] == json['country'],
    orElse: () => {},
  );

  final matchingCountryLabel = AppStrings.countryOptions.firstWhere(
        (c) => c['label'] == json['country'],
    orElse: () => {},
  );

  if (matchingCountryKey.isNotEmpty) {
    print('   ✅ Found as KEY: ${matchingCountryKey['value']} -> ${matchingCountryKey['label']}');
  } else if (matchingCountryLabel.isNotEmpty) {
    print('   ✅ Found as LABEL: ${matchingCountryLabel['label']}');
  } else {
    print('   ❌ NOT FOUND in countryOptions! (API returned: ${json['country']})');
    print('   💡 Available options starting with "U": ');
    AppStrings.countryOptions
        .where((c) => c['value']!.startsWith('U') || c['label']!.startsWith('U'))
        .take(5)
        .forEach((c) {
      print('      ${c['value']} -> ${c['label']}');
    });
  }

  print('═══════════════════════════════════════\n');
}

// ✅ Provider Setup
final nomineeListProvider = AsyncNotifierProvider.autoDispose
    .family<NomineeListNotifier, List<Nominee>, String>(NomineeListNotifier.new);

class NomineeListNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<Nominee>, String> {
  @override
  Future<List<Nominee>> build(String bseClientId) async {
    final baseUrl = EnvConfig.apiBaseUrl;
    final token = await SecureStore.getToken();
    final fullUrl = '$baseUrl/profile/nominee/list';

    developer.log('API Request URL: $fullUrl');
    developer.log('API Request Body: {"bse_client_id": "$bseClientId"}');
    developer.log('API Token Present: ${token != null ? "Yes" : "No"}');

    final response = await http.post(
      Uri.parse(fullUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'bse_client_id': bseClientId}),
    );

    developer.log('API Response Status: ${response.statusCode}');
    developer.log('API Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final dynamic data = jsonDecode(response.body);

      // Extract nominee list safely
      final List<dynamic> nomineeList = data['data']['data_list'];

      // ✅ DEBUG: Inspect first nominee
      if (nomineeList.isNotEmpty) {
        print('\n🧪 Testing first nominee parsing:');
        debugNomineeParsing(nomineeList[0] as Map<String, dynamic>);
      }

      return nomineeList
          .map((e) => Nominee.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load nominees: ${response.statusCode}');
    }
  }

  Future<void> refresh(String bseClientId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build(bseClientId));
  }
}
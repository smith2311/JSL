import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:jhaveri_jsl_app/core/config/env.dart';
import 'package:jhaveri_jsl_app/core/secure_store.dart';
import '../constants/strings.dart';
import '../features/auth/data/models/nominee_centre.dart';

// ============================================================================
// PROVIDER
// ============================================================================
final addNomineeProvider =
StateNotifierProvider.autoDispose<AddNomineeNotifier, AddNomineeState>(
      (ref) => AddNomineeNotifier(),
);

// ============================================================================
// STATE
// ============================================================================
class AddNomineeState {
  final List<NomineeForm> nominees;
  final bool isAgreed;
  final bool isSubmitting;
  final String? globalError;

  AddNomineeState({
    required this.nominees,
    this.isAgreed = false,
    this.isSubmitting = false,
    this.globalError,
  });

  AddNomineeState copyWith({
    List<NomineeForm>? nominees,
    bool? isAgreed,
    bool? isSubmitting,
    String? globalError,
  }) {
    return AddNomineeState(
      nominees: nominees ?? this.nominees,
      isAgreed: isAgreed ?? this.isAgreed,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      globalError: globalError,
    );
  }
}

// ============================================================================
// NOMINEE FORM MODEL
// ============================================================================
class NomineeForm {
  String firstName;
  String middleName;
  String lastName;
  String dob;
  String relationKey;
  String relationLabel;
  String applicablePercentage;
  String idTypeKey;
  String idTypeLabel;
  String idNumber;
  String mobile;
  String email;
  String address1;
  String address2;
  String address3;
  String city;
  String pin;
  String state;
  String countryKey;
  String countryLabel;
  bool isMinor;
  String guardianName;
  String guardianPan;
  File? file;
  String? fileError;

  NomineeForm({
    this.firstName = '',
    this.middleName = '',
    this.lastName = '',
    this.dob = '',
    this.relationKey = '',
    this.relationLabel = '',
    this.applicablePercentage = '',
    this.idTypeKey = '',
    this.idTypeLabel = '',
    this.idNumber = '',
    this.mobile = '',
    this.email = '',
    this.address1 = '',
    this.address2 = '',
    this.address3 = '',
    this.city = '',
    this.pin = '',
    this.state = '',
    this.countryKey = '',
    this.countryLabel = '',
    this.isMinor = false,
    this.guardianName = '',
    this.guardianPan = '',
    this.file,
    this.fileError,
  });

  /// Check if user has started filling this nominee
  bool get isStarted => [
    firstName,
    lastName,
    dob,
    relationKey,
    applicablePercentage,
    idTypeKey,
    idNumber,
    mobile,
    email,
    address1,
    city,
    pin,
    state,
    countryKey
  ].any((e) => e.isNotEmpty) ||
      file != null;

  /// Convert to API payload format
  Map<String, dynamic> toJson() {
    // Format date to YYYY-MM-DD for API
    String formattedDob = dob;
    if (dob.isNotEmpty) {
      try {
        DateTime parsedDate;

        // Handle YYYY-MM-DD format (already correct)
        if (dob.contains('-') && dob.split('-')[0].length == 4) {
          parsedDate = DateTime.parse(dob);
        }
        // Handle DD/MM/YYYY format
        else if (dob.contains('/')) {
          final parts = dob.split('/');
          if (parts.length == 3) {
            parsedDate = DateTime(
              int.parse(parts[2]), // year
              int.parse(parts[1]), // month
              int.parse(parts[0]), // day
            );
          } else {
            throw const FormatException('Invalid date format');
          }
        }
        // Handle other formats
        else {
          parsedDate = DateFormat('dd MMM yyyy').parse(dob);
        }

        formattedDob = DateFormat('yyyy-MM-dd').format(parsedDate);
      } catch (e) {
        print('❌ Date format error: $e for date: $dob');
      }
    }

    // Helper to convert empty strings to null
    String? nullIfEmpty(String value) => value.trim().isEmpty ? null : value.trim();

    return {
      'first_name': firstName.trim(),
      'middle_name': nullIfEmpty(middleName),
      'last_name': lastName.trim(),
      'dob': formattedDob,
      'relation': relationKey, // Send API key (e.g., "1", "2")
      'applicable_percentage': applicablePercentage.trim(),
      'id_type': idTypeKey, // Send API key (e.g., "pan", "aadhaar")
      'id_number': idNumber.trim(),
      'mobile': mobile.trim(),
      'email': email.trim(),
      'address_1': address1.trim(),
      'address_2': nullIfEmpty(address2),
      'address_3': nullIfEmpty(address3),
      'city': city.trim(),
      'pin': nullIfEmpty(pin),
      'state': state.trim(),
      'country': countryKey, // Send API key (e.g., "IND", "USA")
      'is_minor': isMinor,
      'guardian_name': isMinor ? nullIfEmpty(guardianName) : null,
      'guardian_pan': isMinor ? nullIfEmpty(guardianPan) : null,
    };
  }
}

// ============================================================================
// NOTIFIER
// ============================================================================
class AddNomineeNotifier extends StateNotifier<AddNomineeState> {
  AddNomineeNotifier()
      : super(AddNomineeState(
    nominees: List.generate(3, (_) => NomineeForm()),
  ));

  // --------------------------------------------------------------------------
  // FIELD UPDATES
  // --------------------------------------------------------------------------

  void updateField(int index, String field, String value) {
    final updated = [...state.nominees];

    switch (field) {
      case 'firstName':
        updated[index].firstName = value;
        break;
      case 'middleName':
        updated[index].middleName = value;
        break;
      case 'lastName':
        updated[index].lastName = value;
        break;
      case 'dob':
        updated[index].dob = value;
        _updateMinorStatus(index, value);
        break;
      case 'applicablePercentage':
        updated[index].applicablePercentage = value;
        break;
      case 'idNumber':
        updated[index].idNumber = value;
        break;
      case 'mobile':
        updated[index].mobile = value;
        break;
      case 'email':
        updated[index].email = value;
        break;
      case 'address1':
        updated[index].address1 = value;
        break;
      case 'address2':
        updated[index].address2 = value;
        break;
      case 'address3':
        updated[index].address3 = value;
        break;
      case 'city':
        updated[index].city = value;
        break;
      case 'pin':
        updated[index].pin = value;
        break;
      case 'state':
        updated[index].state = value;
        break;
      case 'guardianName':
        updated[index].guardianName = value;
        break;
      case 'guardianPan':
        updated[index].guardianPan = value;
        break;
    }

    state = state.copyWith(nominees: updated);
  }

  void updateRelation(int index, String apiKey, String label) {
    final updated = [...state.nominees];
    updated[index].relationKey = apiKey;
    updated[index].relationLabel = label;
    state = state.copyWith(nominees: updated);
  }

  void updateIdType(int index, String apiKey, String label) {
    final updated = [...state.nominees];
    updated[index].idTypeKey = apiKey;
    updated[index].idTypeLabel = label;
    state = state.copyWith(nominees: updated);
  }

  void updateCountry(int index, String apiKey, String label) {
    final updated = [...state.nominees];
    updated[index].countryKey = apiKey;
    updated[index].countryLabel = label;
    state = state.copyWith(nominees: updated);
  }

  void updateFile(int index, File? file, {String? error}) {
    final updated = [...state.nominees];
    updated[index].file = file;
    updated[index].fileError = error;
    state = state.copyWith(nominees: updated);
  }

  void toggleAgree(bool value) {
    state = state.copyWith(isAgreed: value);
  }

  void clearNominee(int index) {
    final updated = [...state.nominees];
    updated[index] = NomineeForm();
    state = state.copyWith(nominees: updated);
  }

  // --------------------------------------------------------------------------
  // HELPER METHODS
  // --------------------------------------------------------------------------

  bool isStarted(int index) => state.nominees[index].isStarted;

  void _updateMinorStatus(int index, String dob) {
    if (dob.isEmpty) return;

    try {
      DateTime date;

      // Handle YYYY-MM-DD format
      if (dob.contains('-') && dob.split('-')[0].length == 4) {
        date = DateTime.parse(dob);
      }
      // Handle DD/MM/YYYY format
      else if (dob.contains('/')) {
        final parts = dob.split('/');
        date = DateTime(
          int.parse(parts[2]), // year
          int.parse(parts[1]), // month
          int.parse(parts[0]), // day
        );
      }
      // Handle other formats
      else {
        date = DateFormat('dd MMM yyyy').parse(dob);
      }

      final age = DateTime.now().difference(date).inDays ~/ 365;
      final updated = [...state.nominees];
      updated[index].isMinor = age < 18;

      // Clear guardian fields if not minor
      if (!updated[index].isMinor) {
        updated[index].guardianName = '';
        updated[index].guardianPan = '';
      }

      state = state.copyWith(nominees: updated);
    } catch (e) {
      print('❌ Error calculating age: $e');
    }
  }

  bool validateGuardianFields(int index) {
    final nominee = state.nominees[index];

    if (nominee.isMinor) {
      // Guardian name is required for minors
      if (nominee.guardianName.trim().isEmpty) {
        return false;
      }

      // Guardian PAN is required and must match pattern
      if (nominee.guardianPan.trim().isEmpty) {
        return false;
      }

      final panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$');
      if (!panRegex.hasMatch(nominee.guardianPan.trim())) {
        return false;
      }
    }

    return true;
  }

  // --------------------------------------------------------------------------
  // SET EXISTING NOMINEES (FOR EDIT MODE)
  // --------------------------------------------------------------------------

  void setExisting(List<Nominee> existing) {
    print('📥 Setting existing nominees: ${existing.length}');

    final updated = List.generate(3, (i) {
      if (i < existing.length) {
        final n = existing[i];

        // Convert API values back to labels for display
        final relationLabel = AppStrings.getRelationLabel(n.relation);
        final idTypeLabel = AppStrings.getDisplayIdType(n.idType);
        final countryLabel = AppStrings.getCountryLabel(n.country);

        print('   Nominee ${i + 1}:');
        print('      Name: ${n.firstName} ${n.lastName}');
        print('      Relation: ${n.relation} → $relationLabel');
        print('      ID Type: ${n.idType} → $idTypeLabel');
        print('      Country: ${n.country} → $countryLabel');
        print('      Percentage: ${n.applicablePercentage}%');

        return NomineeForm(
          firstName: n.firstName,
          middleName: n.middleName,
          lastName: n.lastName,
          dob: n.dob,
          relationKey: n.relation,
          relationLabel: relationLabel,
          applicablePercentage: n.applicablePercentage.toString(),
          idTypeKey: n.idType,
          idTypeLabel: idTypeLabel,
          idNumber: n.idNumber,
          mobile: n.mobile,
          email: n.email,
          address1: n.address1,
          address2: n.address2,
          address3: n.address3,
          city: n.city,
          pin: n.pin,
          state: n.state,
          countryKey: n.country,
          countryLabel: countryLabel,
          isMinor: n.isMinor,
          guardianName: n.guardianName,
          guardianPan: n.guardianPan,
        );
      }
      return NomineeForm();
    });

    state = state.copyWith(nominees: updated);
  }

  // --------------------------------------------------------------------------
  // SUBMIT TO API
  // --------------------------------------------------------------------------

  Future<bool> submit(String bseClientId) async {
    print('\n' + '=' * 70);
    print('🚀 STARTING NOMINEE SUBMISSION');
    print('=' * 70);

    // Set submitting state
    state = state.copyWith(isSubmitting: true, globalError: null);

    // Get only filled nominees
    final validNominees = <Map<String, dynamic>>[];
    final filesToUpload = <File>[];

    for (int i = 0; i < state.nominees.length; i++) {
      if (isStarted(i)) {
        final nominee = state.nominees[i];

        print('\n📋 Nominee ${i + 1}:');
        print('   Name: ${nominee.firstName} ${nominee.lastName}');
        print('   Relation: ${nominee.relationKey} (${nominee.relationLabel})');
        print('   ID Type: ${nominee.idTypeKey} (${nominee.idTypeLabel})');
        print('   Country: ${nominee.countryKey} (${nominee.countryLabel})');
        print('   Percentage: ${nominee.applicablePercentage}%');
        print('   Has File: ${nominee.file != null}');

        validNominees.add(nominee.toJson());

        if (nominee.file != null) {
          filesToUpload.add(nominee.file!);
        }
      }
    }

    // Validate at least one nominee
    if (validNominees.isEmpty) {
      print('❌ No nominees to submit');
      state = state.copyWith(
        isSubmitting: false,
        globalError: 'At least one nominee is required',
      );
      return false;
    }

    print('\n📊 Summary:');
    print('   BSE Client ID: $bseClientId');
    print('   Valid Nominees: ${validNominees.length}');
    print('   Files to Upload: ${filesToUpload.length}');

    final client = http.Client();

    try {
      // Get auth token
      final token = await SecureStore.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No auth token found');
      }

      final String baseUrl = EnvConfig.apiBaseUrl;
      final uri = Uri.parse('$baseUrl/profile/nominee/update');

      print('\n🌐 API Details:');
      print('   URL: $uri');
      print('   Method: POST (multipart/form-data)');

      // Create multipart request
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Connection'] = 'keep-alive';

      // Create payload
      final payload = {
        'bse_client_id': bseClientId,
        'nominee_details': validNominees,
      };

      // Add request field (JSON string)
      request.fields['request'] = jsonEncode(payload);

      print('\n📦 Request Payload:');
      print(const JsonEncoder.withIndent('  ').convert(payload));

      // Add files
      print('\n📎 Adding Files:');
      for (int i = 0; i < filesToUpload.length; i++) {
        final file = filesToUpload[i];
        final fileSize = await file.length();
        final fileSizeMB = fileSize / (1024 * 1024);

        print('   File ${i + 1}:');
        print('      Path: ${file.path}');
        print('      Size: ${fileSizeMB.toStringAsFixed(2)} MB');

        // Validate file size (max 1MB)
        if (fileSize > 1024 * 1024) {
          state = state.copyWith(
            isSubmitting: false,
            globalError:
            'File size must be less than 1MB (File ${i + 1}: ${fileSizeMB.toStringAsFixed(2)} MB)',
          );
          return false;
        }

        // Add file with key 'files' (matching backend expectation)
        request.files.add(
          await http.MultipartFile.fromPath(
            'files', // Backend expects 'files' as the key
            file.path,
          ),
        );
      }

      print('\n⏳ Sending request...');

      // Send request with 60 second timeout
      final streamedResponse = await client.send(request).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw TimeoutException('Request timeout after 60 seconds');
        },
      );

      // Get response
      final response = await http.Response.fromStream(streamedResponse);

      print('\n📥 Response Received:');
      print('   Status Code: ${response.statusCode}');
      print('   Body: ${response.body}');

      // Handle response
      if (response.statusCode == 200) {
        try {
          final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
          final status = jsonResponse['status'];
          final message = jsonResponse['message'] ?? 'No message from server';

          print('\n✅ Response Parsed:');
          print('   Status: $status');
          print('   Message: $message');

          if (status == 1) {
            print('\n🎉 SUCCESS! Nominees updated successfully');
            state = state.copyWith(isSubmitting: false, globalError: null);
            return true;
          } else {
            print('\n❌ Backend Error: $message');
            state = state.copyWith(
              isSubmitting: false,
              globalError: message,
            );
            return false;
          }
        } catch (e) {
          print('\n❌ Error parsing response: $e');
          state = state.copyWith(
            isSubmitting: false,
            globalError: 'Invalid server response',
          );
          return false;
        }
      } else if (response.statusCode == 401) {
        print('\n❌ Unauthorized (401)');
        state = state.copyWith(
          isSubmitting: false,
          globalError: 'Unauthorized. Please login again.',
        );
        return false;
      } else {
        final errorMsg = 'HTTP Error: ${response.statusCode}';
        print('\n❌ $errorMsg');
        print('   Body: ${response.body}');

        // Try to parse error message from response
        try {
          final errorJson = jsonDecode(response.body);
          final errorMessage = errorJson['message'] ?? errorMsg;
          state = state.copyWith(
            isSubmitting: false,
            globalError: errorMessage,
          );
        } catch (e) {
          state = state.copyWith(
            isSubmitting: false,
            globalError: errorMsg,
          );
        }
        return false;
      }
    } on TimeoutException catch (e) {
      print('\n❌ Timeout Error: $e');
      state = state.copyWith(
        isSubmitting: false,
        globalError: 'Request timeout. Please try again.',
      );
      return false;
    } catch (e) {
      print('\n❌ Network Error: $e');
      state = state.copyWith(
        isSubmitting: false,
        globalError: 'Network error: ${e.toString()}',
      );
      return false;
    } finally {
      client.close();
      print('\n' + '=' * 70);
      print('🏁 SUBMISSION COMPLETE');
      print('=' * 70 + '\n');
    }
  }
}
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../../../core/config/env.dart';
import '../../../../core/token_helper.dart';

class FolioLedgerRepository {
  // Fetch folio list for a specific client
  Future<List<String>> fetchFolioList(String clientId) async {
    try {
      final token = await TokenHelper.getValidToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse('${EnvConfig.apiBaseUrl}/report/folio/list'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'client_id': [int.parse(clientId)],
        }),
      );

      print('Folio List Response Status: ${response.statusCode}');
      print('Folio List Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 1) {
          final dataList = responseData['data']['data_list'] as List<dynamic>;
          return dataList.map((e) => e.toString()).toList();
        } else {
          throw Exception(responseData['message'] ?? 'Failed to fetch folio list');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else {
        throw Exception('Failed to fetch folio list. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching folio list: $e');
      throw Exception('Error fetching folio list: $e');
    }
  }

  // Download folio ledger report
  Future<Map<String, dynamic>> downloadFolioLedgerReport({
    required bool isFolio,
    required List<int> clientIds,
    required String fromDate,
    required String toDate,
    required String folioNo,
    String? period,
    required String navDate,
  }) async {
    try {
      final token = await TokenHelper.getValidToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication failed. Please login again.',
        };
      }

      // Prepare request body - exclude period if it's "Custom"
      final requestBody = <String, dynamic>{
        'is_folio': isFolio,
        'client_id': clientIds,
        'from_date': fromDate,
        'to_date': toDate,
        'folio_no': folioNo,
        'nav_date': navDate,
      };

      // Only add period if it's not null or "Custom"
      if (period != null && period.toLowerCase() != 'custom') {
        requestBody['period'] = period;
      }

      print('Download Request Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('${EnvConfig.apiBaseUrl}/reports/folio-ledger'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('Download Response Status: ${response.statusCode}');
      print('Response Content-Type: ${response.headers['content-type']}');

      if (response.statusCode == 200) {
        // Check if response is PDF
        final contentType = response.headers['content-type'];

        if (contentType != null && contentType.contains('application/pdf')) {
          // Validate PDF size - if less than 512 bytes, it's likely empty
          if (response.bodyBytes.length < 512) {
            return {
              'success': false,
              'message': 'No data found for the selected filters. Please check your filter selections.',
            };
          }

          // Save PDF to device
          final result = await _savePdfToDevice(response.bodyBytes);
          return result;
        } else {
          // Handle JSON response
          final data = jsonDecode(response.body);

          if (data['status'] == 1) {
            return {
              'success': true,
              'message': data['message'] ?? 'Report downloaded successfully',
            };
          } else {
            return {
              'success': false,
              'message': data['message'] ?? 'Failed to download report',
            };
          }
        }
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Session expired. Please login again.',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to download report. Status: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error downloading report: $e');
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  // Send folio ledger report via email
  Future<Map<String, dynamic>> emailFolioLedgerReport({
    required bool isFolio,
    required List<int> clientIds,
    required String fromDate,
    required String toDate,
    required String folioNo,
    String? period,
    required String navDate,
  }) async {
    try {
      final token = await TokenHelper.getValidToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication failed. Please login again.',
        };
      }

      // Prepare request body - exclude period if it's "Custom"
      final requestBody = <String, dynamic>{
        'is_folio': isFolio,
        'client_id': clientIds,
        'from_date': fromDate,
        'to_date': toDate,
        'folio_no': folioNo,
        'nav_date': navDate,
      };

      // Only add period if it's not null or "Custom"
      if (period != null && period.toLowerCase() != 'custom') {
        requestBody['period'] = period;
      }

      print('Email Request Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('${EnvConfig.apiBaseUrl}/reports/folio-ledger/email'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('Email Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 1) {
          return {
            'success': true,
            'message': data['message'] ?? 'Report sent via email successfully',
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to send report via email',
          };
        }
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Session expired. Please login again.',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to send report. Status: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error sending report: $e');
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> _savePdfToDevice(List<int> bytes) async {
    try {
      // Get the downloads directory
      Directory? directory;

      if (Platform.isAndroid) {
        // For Android, use external storage downloads directory
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        // For iOS, use application documents directory
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        return {
          'success': false,
          'message': 'Could not access storage directory',
        };
      }

      // Create filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'folio_ledger_report_$timestamp.pdf';
      final filePath = '${directory.path}/$fileName';

      // Write file
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      print('PDF saved to: $filePath');

      return {
        'success': true,
        'message': 'Report downloaded successfully to ${Platform.isAndroid ? 'Downloads' : 'Documents'} folder',
        'filePath': filePath,
        'fileName': fileName,
      };
    } catch (e) {
      print('Error saving PDF: $e');
      return {
        'success': false,
        'message': 'Failed to save report: ${e.toString()}',
      };
    }
  }
}
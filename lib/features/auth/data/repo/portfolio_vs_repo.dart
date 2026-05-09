import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../../../core/config/env.dart';
import '../../../../core/token_helper.dart';

class PortfolioValuationRepository {
  Future<Map<String, dynamic>> downloadPortfolioValuationReport({
    required List<int> clientIds,
    required String transactionUptoDate,
  }) async {
    try {
      final token = await TokenHelper.getValidToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication failed. Please login again.',
        };
      }

      final requestBody = {
        'client_id': clientIds,
        'transaction_upto_date': transactionUptoDate,
      };

      print('📤 Request Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('${EnvConfig.apiBaseUrl}/reports/portfolio-valuation'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('📥 Response Status: ${response.statusCode}');
      final contentType = response.headers['content-type'];

      if (response.statusCode == 200) {
        // ✅ Handle PDF file
        if (contentType != null && contentType.contains('application/pdf')) {
          final result = await _savePdfToDevice(response.bodyBytes);
          return result;
        }

        // ✅ Handle JSON response
        try {
          final data = jsonDecode(response.body);

          if (data['status'] == 0 &&
              (data['message']?.toString().toLowerCase().contains('no data') ?? false)) {
            return {
              'success': false,
              'message': 'No data available for the selected date.',
            };
          }

          if (data['status'] == 1) {
            return {
              'success': true,
              'message': data['message'] ?? 'Report downloaded successfully.',
            };
          }

          return {
            'success': false,
            'message': data['message'] ?? 'Failed to download report.',
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Unexpected response format.',
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
          'message': 'Failed to download report. Status: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Error downloading report: $e');
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> _savePdfToDevice(List<int> bytes) async {
    try {
      Directory? directory;

      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        return {
          'success': false,
          'message': 'Could not access storage directory.',
        };
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'portfolio_valuation_report_$timestamp.pdf';
      final filePath = '${directory.path}/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(bytes);

      print('✅ PDF saved to: $filePath');

      return {
        'success': true,
        'message': 'Report downloaded successfully to ${Platform.isAndroid ? 'Downloads' : 'Documents'} folder.',
        'filePath': filePath,
      };
    } catch (e) {
      print('❌ Error saving PDF: $e');
      return {
        'success': false,
        'message': 'Failed to save report: ${e.toString()}',
      };
    }
  }
}
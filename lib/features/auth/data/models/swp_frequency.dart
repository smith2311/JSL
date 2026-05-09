import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api_client.dart';

// -----------------------
// SWP Frequency Model & Notifier
// -----------------------
class SwpFrequencyNotifier extends StateNotifier<AsyncValue<List<String>>> {
  SwpFrequencyNotifier() : super(const AsyncValue.loading());

  Future<void> fetchFrequencies(int fundId) async {
    try {
      state = const AsyncValue.loading();

      final response = await ApiClient.post(
        '/mf-buy/frequency-list',
        body: {
          'fund_id': fundId,
          'transaction_type': 'SWP',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['status'] == 1 && responseData['data'] != null) {
          final frequencies = (responseData['data']['data_list'] as List)
              .map((e) => e.toString())
              .toList();
          state = AsyncValue.data(frequencies);
        } else {
          state = AsyncValue.error(
            responseData['message'] ?? 'Failed to load frequencies',
            StackTrace.current,
          );
        }
      } else {
        state = AsyncValue.error('HTTP error: ${response.statusCode}', StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final swpFrequencyProvider = StateNotifierProvider<SwpFrequencyNotifier, AsyncValue<List<String>>>(
      (ref) => SwpFrequencyNotifier(),
);
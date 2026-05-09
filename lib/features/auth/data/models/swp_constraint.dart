import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api_client.dart';


class SwpConstraint {
  final List<int> frequencyDates;
  final int minInstallments;
  final int maxInstallments;
  final double minAmount;
  final double maxAmount;

  SwpConstraint({
    required this.frequencyDates,
    required this.minInstallments,
    required this.maxInstallments,
    required this.minAmount,
    required this.maxAmount,
  });

  factory SwpConstraint.fromJson(Map<String, dynamic> json) {
    return SwpConstraint(
      frequencyDates: (json['frequency_dates'] as List).map((e) => e as int).toList(),
      minInstallments: json['min_installments'] ?? 12,
      maxInstallments: json['max_installments'] ?? 9999,
      minAmount: (json['min_amount'] ?? 0).toDouble(),
      maxAmount: (json['max_amount'] ?? 0).toDouble(),
    );
  }

  SwpConstraint copyWith({
    List<int>? frequencyDates,
    int? minInstallments,
    int? maxInstallments,
    double? minAmount,
    double? maxAmount,
  }) {
    return SwpConstraint(
      frequencyDates: frequencyDates ?? this.frequencyDates,
      minInstallments: minInstallments ?? this.minInstallments,
      maxInstallments: maxInstallments ?? this.maxInstallments,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
    );
  }
}

class SwpConstraintNotifier extends StateNotifier<AsyncValue<SwpConstraint>> {
  SwpConstraintNotifier() : super(const AsyncValue.loading());

  Future<void> fetchSwpConstraint(int fundId, String frequency) async {
    try {
      state = const AsyncValue.loading();

      final response = await ApiClient.post(
        '/mf-buy/scheme-constraint',
        body: {
          'fund_id': fundId,
          'order_type': 'sxp',
          'transaction_type': 'SWP',
          'frequency': frequency,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['status'] == 1 && responseData['data'] != null) {
          final constraint = SwpConstraint.fromJson(responseData['data']);
          state = AsyncValue.data(constraint);
        } else {
          state = AsyncValue.error(
            responseData['message'] ?? 'Failed to load SWP constraints',
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

  void updateMinAmount(double newMin) {
    state.whenData((constraint) {
      state = AsyncValue.data(constraint.copyWith(minAmount: newMin));
    });
  }
}

final swpConstraintProvider = StateNotifierProvider<SwpConstraintNotifier, AsyncValue<SwpConstraint>>(
      (ref) => SwpConstraintNotifier(),
);

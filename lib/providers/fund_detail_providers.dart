import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:jhaveri_jsl_app/core/config/env.dart';
import '../features/funds/data/models/fund_details_models.dart';
import '../features/funds/data/services/fund_detail_service.dart';
import '../core/secure_store.dart';

final fundDetailServiceProvider = FutureProvider<FundDetailService>((ref) async {
  final baseUrl = EnvConfig.apiBaseUrl;

  // Get valid token from SecureStore
  final token = await SecureStore.getToken();
  if (token == null) throw Exception("No valid access token found");

  return FundDetailService(
    baseUrl: baseUrl,
    authToken: token,
  );
});

final holdingSummaryProvider = FutureProvider.family<HoldingSummary, int>((ref, fundId) async {
  final service = await ref.watch(fundDetailServiceProvider.future);
  if (service == null) throw Exception("FundDetailService is null");
  return service.fetchHoldingSummary(fundId);
});

final investmentReturnsProvider = FutureProvider.family<InvestmentReturns, Map<String, dynamic>>((ref, params) async {
  final service = await ref.watch(fundDetailServiceProvider.future);
  if (service == null) throw Exception("FundDetailService is null");
  return service.fetchInvestmentReturns(params['fundId'], params['type']);
});

final investmentPerformanceProvider = FutureProvider.family<InvestmentPerformance, Map<String, dynamic>>((ref, params) async {
  final service = await ref.watch(fundDetailServiceProvider.future);
  if (service == null) throw Exception("FundDetailService is null");
  return service.fetchInvestmentPerformance(params['fundId'], params['amount']);
});

final navHistoryProvider = FutureProvider.family<NavHistory, Map<String, dynamic>>(
      (ref, params) async {
    final service = await ref.watch(fundDetailServiceProvider.future);
    if (service == null) throw Exception("FundDetailService is null");

    final fundId = params['fund_id'] as int;
    final period = params['period'] as String;

    return service.fetchNavHistory(fundId, period); // service uses token internally
  },
);

final fundInfoProvider = FutureProvider.family<FundInfo, int>((ref, fundId) async {
  final service = await ref.watch(fundDetailServiceProvider.future);
  if (service == null) throw Exception("FundDetailService is null");
  return service.fetchFundInfo(fundId);
});

// State providers for UI interactions
final selectedReturnTypeProvider = StateProvider<String>((ref) => 'abs');
final selectedPerformanceAmountProvider = StateProvider<double>((ref) => 5000);
final selectedNavPeriodProvider = StateProvider<String>((ref) => '3y');
final selectedHoldingViewProvider = StateProvider<String>((ref) => 'sector_wise');
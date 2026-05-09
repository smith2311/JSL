// providers/investment_returns_service_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jhaveri_jsl_app/core/config/env.dart';
import '../core/token_helper.dart';
import '../features/funds/data/models/investment_performance.dart';
import '../features/funds/data/models/investment_return.dart';
import '../features/funds/data/services/investment_returns_service.dart';

// State providers
final touchedBarIndexProvider = StateProvider<int?>((ref) => null);
final performanceAmountProvider = StateProvider<double>((ref) => 5000);
final sectorViewAllProvider = StateProvider<bool>((ref) => false);
final companyViewAllProvider = StateProvider<bool>((ref) => false);
final fundDetailViewAllProvider = StateProvider<bool>((ref) => false);
final selectedTabProvider = StateProvider<int>((ref) => 0);
final selectedReturnTypeProvider = StateProvider<ReturnType>((ref) => ReturnType.abs);
final selectedFundIdProvider = StateProvider<int>((ref) => 1);

// Service provider - creates a new service instance
final investmentServiceProvider = Provider<InvestmentService>((ref) {
  return InvestmentService(
    baseUrl: EnvConfig.apiBaseUrl,
  );
});

// ✅ Performance provider with authentication
final investmentPerformanceProvider = FutureProvider.family<InvestmentPerformanceResponse, ({int fundId, double amount})>((ref, params) async {
  final service = ref.watch(investmentServiceProvider);
  final token = await TokenHelper.getValidToken();

  // Set the token before making the API call
  service.setAuthToken(token);

  return service.getInvestmentPerformance(
    fundId: params.fundId,
    amount: params.amount,
  );
});

final currentPerformanceProvider = Provider<AsyncValue<InvestmentPerformanceResponse>>((ref) {
  final fundId = ref.watch(selectedFundIdProvider);
  final amount = ref.watch(performanceAmountProvider);
  return ref.watch(investmentPerformanceProvider((fundId: fundId, amount: amount)));
});

// ✅ Returns provider with authentication
final investmentReturnsProvider = FutureProvider.family<InvestmentReturnsResponse, ({int fundId, ReturnType type})>((ref, params) async {
  final service = ref.watch(investmentServiceProvider);
  final token = await TokenHelper.getValidToken();

  // Set the token before making the API call
  service.setAuthToken(token);

  return service.getInvestmentReturns(
    fundId: params.fundId,
    type: params.type.name,
  );
});

// Computed provider for current returns
final currentReturnsProvider = Provider<AsyncValue<InvestmentReturnsResponse>>((ref) {
  final fundId = ref.watch(selectedFundIdProvider);
  final returnType = ref.watch(selectedReturnTypeProvider);

  return ref.watch(investmentReturnsProvider((fundId: fundId, type: returnType)));
});
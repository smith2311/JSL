// Add this file to: providers/switch_detail_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/data/models/switch_detail.dart';
import '../features/auth/data/repo/switch_detail_repo.dart';

// Repository Provider
final switchDetailRepositoryProvider = Provider<SwitchDetailRepository>((ref) {
  return SwitchDetailRepository();
});

// Scheme Constraint Provider with AutoDispose
final schemeConstraintProvider = StateNotifierProvider.autoDispose.family<
    SchemeConstraintNotifier,
    AsyncValue<SchemeConstraint>,
    int>((ref, fundId) {
  final notifier = SchemeConstraintNotifier(
    ref.watch(switchDetailRepositoryProvider),
    fundId,
  );
  // Auto-fetch on creation
  notifier.fetchConstraints();
  return notifier;
});

class SchemeConstraintNotifier extends StateNotifier<AsyncValue<SchemeConstraint>> {
  final SwitchDetailRepository repository;
  final int fundId;

  SchemeConstraintNotifier(this.repository, this.fundId)
      : super(const AsyncValue.loading());

  Future<void> fetchConstraints({
    String orderType = 'lumpsum',
    String transactionType = 'Switch-IN',
  }) async {
    state = const AsyncValue.loading();

    try {
      final constraints = await repository.fetchSchemeConstraints(
        fundId: fundId,
        orderType: orderType,
        transactionType: transactionType,
      );

      state = AsyncValue.data(constraints);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void reset() {
    state = const AsyncValue.loading();
  }
}

// BSE Clients Provider
final bseClientsProvider = StateNotifierProvider<
    BseClientsNotifier,
    AsyncValue<List<BseClient>>>((ref) {
  return BseClientsNotifier(ref.watch(switchDetailRepositoryProvider));
});

class BseClientsNotifier extends StateNotifier<AsyncValue<List<BseClient>>> {
  final SwitchDetailRepository repository;

  BseClientsNotifier(this.repository) : super(const AsyncValue.loading()) {
    fetchClients();
  }

  Future<void> fetchClients() async {
    state = const AsyncValue.loading();

    try {
      final clients = await repository.fetchBseClients();
      state = AsyncValue.data(clients);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void reset() {
    state = const AsyncValue.loading();
  }
}

// Switch Transaction Submit Provider
final switchTransactionProvider = StateNotifierProvider<
    SwitchTransactionNotifier,
    AsyncValue<Map<String, dynamic>?>>((ref) {
  return SwitchTransactionNotifier(ref.watch(switchDetailRepositoryProvider));
});

class SwitchTransactionNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  final SwitchDetailRepository repository;

  SwitchTransactionNotifier(this.repository) : super(const AsyncValue.data(null));

  Future<void> submitTransaction({
    required int fromFundId,
    required int toFundId,
    required String folioNo,
    required String clientId,
    required bool isAmount,
    required double value,
    required String bseClientCode,
  }) async {
    state = const AsyncValue.loading();

    try {
      final result = await repository.submitSwitchTransaction(
        fromFundId: fromFundId,
        toFundId: toFundId,
        folioNo: folioNo,
        clientId: clientId,
        isAmount: isAmount,
        value: value,
        bseClientCode: bseClientCode,
      );

      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}
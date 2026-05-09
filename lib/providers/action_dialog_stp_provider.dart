import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/data/models/switch_fund.dart';
import '../features/auth/data/models/switch_detail.dart';
import '../features/auth/data/repo/action_dialog_stp_repo.dart';

// ========== STP Funds Provider ==========
class StpFundsParams {
  final int fundId;

  const StpFundsParams({required this.fundId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is StpFundsParams &&
              runtimeType == other.runtimeType &&
              fundId == other.fundId;

  @override
  int get hashCode => fundId.hashCode;
}

class StpFundsState {
  final List<SwitchFundModel> funds;
  final int totalRecords;
  final int currentPage;
  final bool hasMore;
  final String searchTerm;

  StpFundsState({
    required this.funds,
    required this.totalRecords,
    required this.currentPage,
    required this.hasMore,
    required this.searchTerm,
  });

  StpFundsState copyWith({
    List<SwitchFundModel>? funds,
    int? totalRecords,
    int? currentPage,
    bool? hasMore,
    String? searchTerm,
  }) {
    return StpFundsState(
      funds: funds ?? this.funds,
      totalRecords: totalRecords ?? this.totalRecords,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      searchTerm: searchTerm ?? this.searchTerm,
    );
  }
}

final stpFundsProvider = StateNotifierProvider.family<
    StpFundsNotifier,
    AsyncValue<StpFundsState>,
    StpFundsParams>(
      (ref, params) => StpFundsNotifier(
    StpRepository(),
    params.fundId,
  ),
);

class StpFundsNotifier extends StateNotifier<AsyncValue<StpFundsState>> {
  final StpRepository repository;
  final int fundId;

  StpFundsNotifier(this.repository, this.fundId)
      : super(const AsyncValue.loading()) {
    fetchFunds();
  }

  Future<void> fetchFunds({bool refresh = false}) async {
    if (refresh) {
      state = const AsyncValue.loading();
    }

    final currentState = state.valueOrNull;
    final page = refresh ? 1 : (currentState?.currentPage ?? 0) + 1;
    final searchTerm = currentState?.searchTerm ?? '';

    try {
      final response = await repository.fetchStpFunds(
        fundId: fundId,
        page: page,
        searchTerm: searchTerm,
      );

      final List<SwitchFundModel> updatedList;
      if (refresh || page == 1) {
        updatedList = response.dataList;
      } else {
        updatedList = [
          ...currentState?.funds ?? [],
          ...response.dataList,
        ];
      }

      state = AsyncValue.data(StpFundsState(
        funds: updatedList,
        totalRecords: response.totalRecords,
        currentPage: page,
        hasMore: response.dataList.length == response.pageSize,
        searchTerm: searchTerm,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> searchFunds(String searchTerm) async {
    state = const AsyncValue.loading();

    try {
      final response = await repository.fetchStpFunds(
        fundId: fundId,
        page: 1,
        searchTerm: searchTerm,
      );

      state = AsyncValue.data(StpFundsState(
        funds: response.dataList,
        totalRecords: response.totalRecords,
        currentPage: 1,
        hasMore: response.dataList.length == response.pageSize,
        searchTerm: searchTerm,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void clearSearch() {
    fetchFunds(refresh: true);
  }
}

// ========== STP Frequencies Provider ==========
final stpFrequenciesProvider = StateNotifierProvider.family<
    StpFrequenciesNotifier,
    AsyncValue<List<String>>,
    int>((ref, fundId) {
  return StpFrequenciesNotifier(
    ref.watch(stpRepositoryProvider),
    fundId,
  );
});

class StpFrequenciesNotifier extends StateNotifier<AsyncValue<List<String>>> {
  final StpRepository repository;
  final int fundId;

  StpFrequenciesNotifier(this.repository, this.fundId)
      : super(const AsyncValue.loading()) {
    fetchFrequencies();
  }

  Future<void> fetchFrequencies() async {
    state = const AsyncValue.loading();

    try {
      final frequencies = await repository.fetchFrequencies(
        fundId: fundId,
        transactionType: 'STP-IN',
      );

      state = AsyncValue.data(frequencies);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void reset() {
    state = const AsyncValue.loading();
  }
}

// ========== STP Scheme Constraint Provider ==========
class StpConstraintParams {
  final int fundId;
  final String frequency;

  const StpConstraintParams({
    required this.fundId,
    required this.frequency,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is StpConstraintParams &&
              runtimeType == other.runtimeType &&
              fundId == other.fundId &&
              frequency == other.frequency;

  @override
  int get hashCode => Object.hash(fundId, frequency);
}

final stpSchemeConstraintProvider = StateNotifierProvider.autoDispose.family<
    StpSchemeConstraintNotifier,
    AsyncValue<SchemeConstraint>,
    StpConstraintParams>((ref, params) {
  final notifier = StpSchemeConstraintNotifier(
    ref.watch(stpRepositoryProvider),
    params.fundId,
    params.frequency,
  );
  notifier.fetchConstraints();
  return notifier;
});

class StpSchemeConstraintNotifier extends StateNotifier<AsyncValue<SchemeConstraint>> {
  final StpRepository repository;
  final int fundId;
  final String frequency;

  StpSchemeConstraintNotifier(this.repository, this.fundId, this.frequency)
      : super(const AsyncValue.loading());

  Future<void> fetchConstraints() async {
    state = const AsyncValue.loading();

    try {
      final constraints = await repository.fetchSchemeConstraints(
        fundId: fundId,
        orderType: 'sxp',
        transactionType: 'STP-IN',
        frequency: frequency.toLowerCase(),
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

// ========== STP Submit Provider ==========
final stpSubmitProvider = StateNotifierProvider<
    StpSubmitNotifier,
    AsyncValue<Map<String, dynamic>?>>((ref) {
  return StpSubmitNotifier(ref.watch(stpRepositoryProvider));
});

class StpSubmitNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  final StpRepository repository;

  StpSubmitNotifier(this.repository) : super(const AsyncValue.data(null));

  Future<void> submitStp({
    required int fundIdFrom,
    required int fundIdTo,
    required String folioNo,
    required double amount,
    required String frequency,
    required String stpDate,
    required int noOfInstallments,
    required String bseClientId,
    required bool firstOrder,
    required String transferBy,
  }) async {
    state = const AsyncValue.loading();

    try {
      final result = await repository.submitStp(
        fundIdFrom: fundIdFrom,
        fundIdTo: fundIdTo,
        folioNo: folioNo,
        amount: amount,
        frequency: frequency,
        stpDate: stpDate,
        noOfInstallments: noOfInstallments,
        bseClientId: bseClientId,
        firstOrder: firstOrder,
        transferBy: transferBy,
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

// ========== Repository Provider ==========
final stpRepositoryProvider = Provider<StpRepository>((ref) {
  return StpRepository();
});
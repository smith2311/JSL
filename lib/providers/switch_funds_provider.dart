import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/data/models/switch_fund.dart';
import '../features/auth/data/repo/switch_funds_repo.dart';

class SwitchFundsState {
  final List<SwitchFundModel> funds;
  final int totalRecords;
  final int currentPage;
  final bool hasMore;
  final String searchTerm;

  SwitchFundsState({
    required this.funds,
    required this.totalRecords,
    required this.currentPage,
    required this.hasMore,
    required this.searchTerm,
  });

  SwitchFundsState copyWith({
    List<SwitchFundModel>? funds,
    int? totalRecords,
    int? currentPage,
    bool? hasMore,
    String? searchTerm,
  }) {
    return SwitchFundsState(
      funds: funds ?? this.funds,
      totalRecords: totalRecords ?? this.totalRecords,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      searchTerm: searchTerm ?? this.searchTerm,
    );
  }
}

class SwitchFundsParams {
  final int fundId;

  const SwitchFundsParams({required this.fundId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is SwitchFundsParams &&
              runtimeType == other.runtimeType &&
              fundId == other.fundId;

  @override
  int get hashCode => fundId.hashCode;
}

final switchFundsProvider = StateNotifierProvider.family<
    SwitchFundsNotifier,
    AsyncValue<SwitchFundsState>,
    SwitchFundsParams>(
      (ref, params) => SwitchFundsNotifier(
    SwitchFundsRepository(),
    params.fundId,
  ),
);

class SwitchFundsNotifier extends StateNotifier<AsyncValue<SwitchFundsState>> {
  final SwitchFundsRepository repository;
  final int fundId;

  SwitchFundsNotifier(this.repository, this.fundId)
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
      final response = await repository.fetchSwitchFunds(
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

      state = AsyncValue.data(SwitchFundsState(
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
      final response = await repository.fetchSwitchFunds(
        fundId: fundId,
        page: 1,
        searchTerm: searchTerm,
      );

      state = AsyncValue.data(SwitchFundsState(
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
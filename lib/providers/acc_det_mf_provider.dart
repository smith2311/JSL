import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/data/repo/acc_det_mf_tab_repo.dart';

final mutualFundDetailsRepositoryProvider = Provider<MutualFundDetailsRepository>((ref) {
  return MutualFundDetailsRepository();
});

final mutualFundDetailsProvider = StateNotifierProvider<MutualFundDetailsNotifier, AsyncValue<MutualFundDetails>>((ref) {
  return MutualFundDetailsNotifier(ref.read(mutualFundDetailsRepositoryProvider));
});

class MutualFundDetailsNotifier extends StateNotifier<AsyncValue<MutualFundDetails>> {
  final MutualFundDetailsRepository repository;

  MutualFundDetailsNotifier(this.repository) : super(const AsyncValue.loading());

  Future<void> fetchDetails(String bseClientId) async {
    state = const AsyncValue.loading();
    try {
      final details = await repository.fetchMutualFundDetails(bseClientId);
      state = AsyncValue.data(details);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void reset() {
    state = const AsyncValue.loading();
  }
}
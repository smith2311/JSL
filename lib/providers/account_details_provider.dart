import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jhaveri_jsl_app/features/auth/data/models/account_details.dart';
import 'package:jhaveri_jsl_app/features/auth/data/repo/acc_details_repo.dart';

final AccountDetailsRepositoryProvider = Provider<AccountDetailsRepository>((ref) {
  return AccountDetailsRepository();
});

final AccountProfileProvider = StateNotifierProvider<AccountDetailsNotifier, AsyncValue<AccountDetails>>((ref) {
  return AccountDetailsNotifier(ref.read(AccountDetailsRepositoryProvider));
});

class AccountDetailsNotifier extends StateNotifier<AsyncValue<AccountDetails>> {
  final AccountDetailsRepository repository;

  AccountDetailsNotifier(this.repository) : super(const AsyncValue.loading());

  Future<void> fetchProfile(int clientId) async {
    state = const AsyncValue.loading();
    try {
      final profile = await repository.fetchProfile(clientId);
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}